-- ***************************************************************************
-- This script "de-hybridizes" a previously "hybridized" script, discarding schema
-- structures which are removed during the upgrade but were kept for backwards schema compatibility.  It is generally invoked once
-- against any databases which, at one point, needed to simultaneously accommodate clients running
-- on two versions of Xstore.
--
--
-- Source version:  21.0.*
-- Target version:  22.0.0
-- DB platform:     Microsoft SQL Server 2012/2014/2016
-- ***************************************************************************
PRINT '**************************************';
PRINT '*****       UNHYBRIDIZING        *****';
PRINT '***** From:  21.0.*              *****';
PRINT '*****   To:  22.0.0              *****';
PRINT '**************************************';
GO


PRINT '***** Prefix scripts start *****';


IF  OBJECT_ID('Create_Property_Table') is not null
       DROP PROCEDURE Create_Property_Table
GO

CREATE PROCEDURE Create_Property_Table
  -- Add the parameters for the stored procedure here
  @tableName varchar(30)
AS
BEGIN
  declare @sql varchar(max),
      @column varchar(30),
      @pk varchar(max),
      @datatype varchar(10),
      @maxlen varchar(4),
      @prec varchar(3),
      @scale varchar(3),
      @deflt varchar(50);
  SET NOCOUNT ON;

  IF OBJECT_ID(@tableName + '_p') IS NOT NULL or OBJECT_ID(@tableName) IS NULL or RIGHT(@tableName,2)='_p' or NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS C JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS K
  ON C.TABLE_NAME = K.TABLE_NAME AND C.CONSTRAINT_CATALOG = K.CONSTRAINT_CATALOG AND C.CONSTRAINT_SCHEMA = K.CONSTRAINT_SCHEMA AND C.CONSTRAINT_NAME = K.CONSTRAINT_NAME
  WHERE C.CONSTRAINT_TYPE = 'PRIMARY KEY' and K.TABLE_NAME = @tableName and K.COLUMN_NAME = 'organization_id')
    return;

  set @pk = '';
  set @sql='CREATE TABLE dbo.' + @tableName + '_p (
  '
    declare mycur CURSOR Fast_Forward FOR
  SELECT COL.COLUMN_NAME,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH,NUMERIC_PRECISION,NUMERIC_SCALE,replace(replace(COLUMN_DEFAULT,'(',''),')','') FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS C JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS K
  ON C.TABLE_NAME = K.TABLE_NAME AND C.CONSTRAINT_CATALOG = K.CONSTRAINT_CATALOG AND C.CONSTRAINT_SCHEMA = K.CONSTRAINT_SCHEMA AND C.CONSTRAINT_NAME = K.CONSTRAINT_NAME
  join INFORMATION_SCHEMA.COLUMNS col ON C.TABLE_NAME=col.TABLE_NAME and K.COLUMN_NAME=COL.COLUMN_NAME
  WHERE C.CONSTRAINT_TYPE = 'PRIMARY KEY' and K.TABLE_NAME = @tableName
  order by K.ORDINAL_POSITION

  open mycur;

  while 1=1
  BEGIN
    FETCH NEXT FROM mycur INTO @column,@datatype,@maxlen,@prec,@scale,@deflt;
    IF @@FETCH_STATUS <> 0
      BREAK;

      set @pk=@pk + @column + ','

    set @sql=@sql + @column + ' ' + @datatype

    if @datatype='varchar' or @datatype='nvarchar' or @datatype='char' or @datatype='nchar'
      set @sql=@sql + '(' + @maxlen + ')'
    else if @datatype='numeric' or @datatype='decimal'
      set @sql=@sql + '(' + @prec + ',' + @scale + ')'

    if LEN(@deflt)>0
      set @sql=@sql + ' DEFAULT ' + @deflt

    set @sql=@sql + ' NOT NULL,
  '
  END
  close mycur
  deallocate mycur

  set @sql=@sql + 'property_code varchar(30) NOT NULL,
    type varchar(30) NULL,
    string_value varchar(4000) NULL,
    date_value datetime NULL,
    decimal_value decimal(17,6) NULL,
    create_date datetime NULL,
    create_user_id varchar(256) NULL,
    update_date datetime NULL,
    update_user_id varchar(256) NULL,
    record_state varchar(30) NULL,
  '

  if LEN('pk_'+ @tableName + '_p')>30
    set @sql=@sql + 'CONSTRAINT ' + REPLACE('pk_'+ @tableName + '_p','_','') + ' PRIMARY KEY CLUSTERED (' + @pk + 'property_code) WITH (FILLFACTOR = 80))'
  else
    set @sql=@sql + 'CONSTRAINT pk_'+ @tableName + '_p PRIMARY KEY CLUSTERED (' + @pk + 'property_code) WITH (FILLFACTOR = 80))'

  print '--- CREATING TABLE ' + @tableName + '_p ---'
  exec(@sql);
END
GO


IF  OBJECT_ID('dbo.SP_DEFAULT_CONSTRAINT_EXISTS') is not null
  DROP FUNCTION dbo.SP_DEFAULT_CONSTRAINT_EXISTS
GO

CREATE FUNCTION dbo.SP_DEFAULT_CONSTRAINT_EXISTS (@tableName varchar(max), @columnName varchar(max))
RETURNS varchar(255)
AS 
BEGIN
    DECLARE @return varchar(255)
    
    SELECT TOP 1 
            @return = default_constraints.name
        FROM 
            sys.all_columns
                INNER JOIN
            sys.tables
                ON all_columns.object_id = tables.object_id
                INNER JOIN 
            sys.schemas
                ON tables.schema_id = schemas.schema_id
                INNER JOIN
            sys.default_constraints
                ON all_columns.default_object_id = default_constraints.object_id
        WHERE 
                schemas.name = 'dbo'
            AND tables.name = @tableName
            AND all_columns.name = @columnName
            
    RETURN @return
END;
GO

IF  OBJECT_ID('dbo.SP_PK_CONSTRAINT_EXISTS') is not null
  DROP FUNCTION dbo.SP_PK_CONSTRAINT_EXISTS
GO

CREATE FUNCTION dbo.SP_PK_CONSTRAINT_EXISTS (@tableName varchar(max))
RETURNS varchar(255)
AS 
BEGIN
    DECLARE @return varchar(255)
    
    SELECT TOP 1 
            @return = Tab.Constraint_Name 
       FROM 
            INFORMATION_SCHEMA.TABLE_CONSTRAINTS Tab, 
            INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE Col 
       WHERE 
            Col.Constraint_Name = Tab.Constraint_Name
            AND Col.Table_Name = Tab.Table_Name
            AND Constraint_Type = 'PRIMARY KEY'
            AND Col.Table_Name = @tableName
            
    RETURN @return
END;
GO

IF  OBJECT_ID('dbo.SP_INDEX_COLUMNS') is not null
  DROP FUNCTION dbo.SP_INDEX_COLUMNS
GO

CREATE FUNCTION dbo.SP_INDEX_COLUMNS (@indexName varchar(max))
RETURNS varchar(255)
AS 
BEGIN
  DECLARE @return varchar(255),
      @tableName varchar(255),
      @obtainedIndexName varchar(255),
      @columnName varchar(255),
      @expression varchar(255);
    
  DECLARE mycur CURSOR Fast_Forward FOR
  SELECT object_name(i.object_id) TABLENAME
          ,i.NAME AS INDEXNAME
          ,COL_NAME(ic.OBJECT_ID, ic.column_id) AS COLUMNNAME
          ,null AS EXPRESSION
        FROM sys.indexes i
        INNER JOIN sys.index_columns ic ON i.OBJECT_ID = ic.OBJECT_ID
          AND i.index_id = ic.index_id
        INNER JOIN sys.sysobjects o ON i.OBJECT_ID = o.id
          AND o.type = 'U'
        WHERE i.is_primary_key = 0
        AND i.NAME = @indexName
        ORDER BY index_column_id 

  OPEN mycur;

  SET @return = '';

  WHILE 1=1
  BEGIN
    FETCH NEXT FROM mycur INTO @tableName,@obtainedIndexName,@columnName,@expression;
    IF @@FETCH_STATUS <> 0
      BREAK;
    SET @return = @return + UPPER(@columnName) + '::';
  END
  
  -- Remove last separator
  SET @return = LEFT(@return, LEN(@return) - 2);
  
  CLOSE mycur;
  DEALLOCATE mycur;
  
  RETURN @return
END;
GO

PRINT '***** Prefix scripts end *****';


PRINT '***** Body scripts start *****';

PRINT '     Step Drop Trigger: civc_invoice_fix_register starting...';
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'civc_invoice_fix_register') AND type in (N'TR'))
  PRINT '      Trigger civc_invoice_fix_register already dropped';
ELSE
  BEGIN
    EXEC('    DROP TRIGGER civc_invoice_fix_register;');
    PRINT 'Trigger civc_invoice_fix_register dropped';
  END
GO


PRINT '     Step Drop Trigger: civc_invoice_fix_register end.';



PRINT '     Step Drop Trigger: civc_invoice_xref_fix_register starting...';
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'civc_invoice_xref_fix_register') AND type in (N'TR'))
  PRINT '      Trigger civc_invoice_xref_fix_register already dropped';
ELSE
  BEGIN
    EXEC('    DROP TRIGGER civc_invoice_xref_fix_register;');
    PRINT 'Trigger civc_invoice_xref_fix_register dropped';
  END
GO


PRINT '     Step Drop Trigger: civc_invoice_xref_fix_register end.';




PRINT '***** Body scripts end *****';


-- Keep at end of the script

PRINT '**************************************';
PRINT 'Finalizing release version 22.0.0';
PRINT '**************************************';
GO

PRINT '***************************************************************************';
PRINT 'Database now un-hybridized to support clients running against the following versions:';
PRINT '     22.0.0';
PRINT 'This database is no longer compatible with clients running against legacy versions';
PRINT 'previously supported while hybridized.  Please ensure that all clients are updated';
PRINT 'to the appropriate release.';
PRINT '***************************************************************************';
GO
