-- ***************************************************************************
-- This script "hybridizes" a database such that its schema will be compatible with application
-- clients running on two different versions of Xstore.
-- 
-- This is useful when an Xstore version upgrade is being implemented gradually, such that at any 
-- given time, some clients may be running under the old version of the application while others are
-- running under the new version.  Xcenter is the most common target for scripts of this kind, as it
-- generally must support all of an organization's Xstore clients simultaneously.
--
-- NOTE: Do NOT run an "upgrade" script against a database you wish instead to hybridize until such
-- time as all clients have been upgraded to the target Xstore version.
-- 
-- "Hybridize" scripts are less destructive than their "upgrade" counterparts.  Whereas the 
-- latter is free to remove all remnants of the legacy schema it upgrades, the former -- which must
-- still support clients compatible with that legacy schema -- cannot.  Table and column drops, for
-- example, are usually excluded from "hybridize" scripts or handled in some other non-destructive 
-- manner.  "Hybridize" scripts and "upgrade" scripts are therefore mutually exclusive during a 
-- phased upgrade process.
--
-- After an A-to-B upgrade process is complete, convert any A-and-B databases previously modified by
-- this script to their A-to-B final forms by running the following against them in the order 
-- specified:
-- (1) "unhybridize" A-and-B
--
-- Source version:  21.0.*
-- Target version:  22.0.0
-- DB platform:     Microsoft SQL Server 2012/2014/2016
-- ***************************************************************************

PRINT '*******************************************';
PRINT '*****           HYBRIDIZING           *****';
PRINT '***** From:  21.0.*                   *****';
PRINT '*****   To:  22.0.0                   *****';
PRINT '*******************************************';
GO


PRINT '***** Prefix scripts start *****';


IF  OBJECT_ID('Create_Property_Table') is not null
       DROP PROCEDURE Create_Property_Table
GO

CREATE PROCEDURE Create_Property_Table
  -- Add the parameters for the stored procedure here
  @tableName nvarchar(30)
AS
BEGIN
  declare @sql nvarchar(max),
      @column nvarchar(30),
      @pk nvarchar(max),
      @datatype nvarchar(10),
      @maxlen nvarchar(4),
      @prec nvarchar(3),
      @scale nvarchar(3),
      @deflt nvarchar(50);
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

  set @sql=@sql + 'property_code nvarchar(30) NOT NULL,
    type nvarchar(30) NULL,
    string_value nvarchar(4000) NULL,
    date_value datetime NULL,
    decimal_value decimal(17,6) NULL,
    create_date datetime NULL,
    create_user_id nvarchar(256) NULL,
    update_date datetime NULL,
    update_user_id nvarchar(256) NULL,
    record_state nvarchar(30) NULL,
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

CREATE FUNCTION dbo.SP_DEFAULT_CONSTRAINT_EXISTS (@tableName nvarchar(max), @columnName varchar(max))
RETURNS nvarchar(255)
AS 
BEGIN
    DECLARE @return nvarchar(255)
    
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

CREATE FUNCTION dbo.SP_PK_CONSTRAINT_EXISTS (@tableName nvarchar(max))
RETURNS nvarchar(255)
AS 
BEGIN
    DECLARE @return nvarchar(255)
    
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

CREATE FUNCTION dbo.SP_INDEX_COLUMNS (@indexName nvarchar(max))
RETURNS nvarchar(255)
AS 
BEGIN
  DECLARE @return nvarchar(255),
      @tableName nvarchar(255),
      @obtainedIndexName nvarchar(255),
      @columnName nvarchar(255),
      @expression nvarchar(255);
    
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

PRINT '     Step Add Column: DTX[LegalEntity] Fields{[Field=companyBusinessName]} starting...';
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'loc_legal_entity') AND name in (N'company_business_name'))
  PRINT '      Column loc_legal_entity.company_business_name already exists';
ELSE
  BEGIN
    EXEC('    ALTER TABLE loc_legal_entity ADD company_business_name nvarchar(254)');
    PRINT '     Column loc_legal_entity.company_business_name created';
  END
GO


PRINT '     Step Add Column: DTX[LegalEntity] Fields{[Field=companyBusinessName]} end.';



PRINT '     Step Add Column: DTX[RetailLocationTaxMapping] Fields{[Field=externalSystem]} starting...';
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'tax_rtl_loc_tax_mapping') AND name in (N'external_system'))
  PRINT '      Column tax_rtl_loc_tax_mapping.external_system already exists';
ELSE
  BEGIN
    EXEC('    ALTER TABLE tax_rtl_loc_tax_mapping ADD external_system nvarchar(60)');
    PRINT '     Column tax_rtl_loc_tax_mapping.external_system created';
  END
GO


PRINT '     Step Add Column: DTX[RetailLocationTaxMapping] Fields{[Field=externalSystem]} end.';



PRINT '     Step Add Table: DTX[SequenceJournal] starting...';
IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('COM_SEQUENCE_JOURNAL'))
  PRINT '      Table com_sequence_journal already exists';
ELSE
  BEGIN
    EXEC('CREATE TABLE dbo.com_sequence_journal(
organization_id INT,
rtl_loc_id INT,
wkstn_id BIGINT,
sequence_id nvarchar(255),
sequence_mode nvarchar(30) DEFAULT (''ACTIVE''),
sequence_value nvarchar(60),
sequence_timestamp DATETIME,
create_user_id nvarchar(256),
create_date DATETIME,
update_user_id nvarchar(256),
update_date DATETIME,
record_state nvarchar(30))
');
  PRINT '      Table com_sequence_journal created';
  END
GO


IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('COM_SEQUENCE_JOURNAL_P'))
  PRINT '      Table com_sequence_journal_P already exists';
ELSE
  BEGIN
    EXEC('CREATE_PROPERTY_TABLE com_sequence_journal;');
  PRINT '     Table com_sequence_journal_P created';
  END
GO


PRINT '     Step Add Table: DTX[SequenceJournal] end.';



PRINT '     Step Add Table: DTX[MerchHierarchyLevel] starting...';
IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ITM_MERCH_HIERARCHY_LEVELS'))
  PRINT '      Table itm_merch_hierarchy_levels already exists';
ELSE
  BEGIN
    EXEC('CREATE TABLE dbo.itm_merch_hierarchy_levels(
organization_id INT NOT NULL,
level_id INT NOT NULL,
level_code nvarchar(30),
description nvarchar(150),
create_user_id nvarchar(256),
create_date DATETIME,
update_user_id nvarchar(256),
update_date DATETIME,
record_state nvarchar(30), 
CONSTRAINT pk_itm_merch_hierarchy_levels PRIMARY KEY CLUSTERED (organization_id, level_id))
');
  PRINT '      Table itm_merch_hierarchy_levels created';
  END
GO


IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ITM_MERCH_HIERARCHY_LEVELS_P'))
  PRINT '      Table itm_merch_hierarchy_levels_P already exists';
ELSE
  BEGIN
    EXEC('CREATE_PROPERTY_TABLE itm_merch_hierarchy_levels;');
  PRINT '     Table itm_merch_hierarchy_levels_P created';
  END
GO


PRINT '     Step Add Table: DTX[MerchHierarchyLevel] end.';



PRINT '     Step Add Table: DTX[ServiceResponseLog] starting...';
IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('CTL_SERVICE_RESPONSE_LOG'))
  PRINT '      Table ctl_service_response_log already exists';
ELSE
  BEGIN
    EXEC('CREATE TABLE dbo.ctl_service_response_log(
organization_id INT NOT NULL,
system_id nvarchar(25) NOT NULL,
message_id nvarchar(255) NOT NULL,
message_count INT,
reference_id nvarchar(255),
error nvarchar(MAX),
detail nvarchar(MAX),
create_user_id nvarchar(256),
create_date DATETIME,
update_user_id nvarchar(256),
update_date DATETIME,
record_state nvarchar(30), 
CONSTRAINT pk_ctl_service_response_log PRIMARY KEY CLUSTERED (organization_id, system_id, message_id))
');
  PRINT '      Table ctl_service_response_log created';
  END
GO


PRINT '     Step Add Table: DTX[ServiceResponseLog] end.';



PRINT '     Step Sets the correct workstation id when the invoice is issued on a different workstation than the transaction one starting...';
UPDATE civc_invoice_xref
SET wkstn_id = t5.wkstn_id_new
FROM civc_invoice_xref t0
INNER JOIN (SELECT t4.organization_id, t4.rtl_loc_id, t4.business_year, t4.wkstn_id, t4.sequence_nbr, t1.wkstn_id wkstn_id_new
FROM trn_trans t1
INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
      FROM civc_invoice t2
      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = 'RETAIL_SALE' AND t2.gross_amt = t3.total OR t3.trans_typcode = 'DEFERRED_INVOICE') AND t2.create_date between DATEADD(s, -1, t3.create_date) AND DATEADD(s, 1, t3.create_date)
      WHERE t3.organization_id is null) t4
ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = 'DEFERRED_INVOICE' AND t1.create_date between DATEADD(s, -1, t4.create_date) AND DATEADD(s, 1, t4.create_date)) t5
ON t0.organization_id = t5.organization_id AND t0.rtl_loc_id = t5.rtl_loc_id AND t0.business_year = t5.business_year AND t0.wkstn_id = t5.wkstn_id AND t0.sequence_nbr = t5.sequence_nbr;
GO

UPDATE civc_invoice
SET wkstn_id = t5.wkstn_id_new
FROM civc_invoice t0
INNER JOIN (SELECT t4.organization_id, t4.rtl_loc_id, t4.business_year, t4.wkstn_id, t4.sequence_nbr, t1.wkstn_id wkstn_id_new
FROM trn_trans t1
INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
      FROM civc_invoice t2
      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = 'RETAIL_SALE' AND t2.gross_amt = t3.total OR t3.trans_typcode = 'DEFERRED_INVOICE') AND t2.create_date between DATEADD(s, -1, t3.create_date) AND DATEADD(s, 1, t3.create_date)
      WHERE t3.organization_id is null) t4
ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = 'DEFERRED_INVOICE' AND t1.create_date between DATEADD(s, -1, t4.create_date) AND DATEADD(s, 1, t4.create_date)) t5
ON t0.organization_id = t5.organization_id AND t0.rtl_loc_id = t5.rtl_loc_id AND t0.business_year = t5.business_year AND t0.wkstn_id = t5.wkstn_id AND t0.sequence_nbr = t5.sequence_nbr;
GO
PRINT '     Step Sets the correct workstation id when the invoice is issued on a different workstation than the transaction one end.';



PRINT '     Step Sets the correct workstation id when the invoice is issued on a different workstation than the transaction one starting...';
DECLARE @SQL AS NVARCHAR(MAX)
BEGIN

  SET @SQL = 'CREATE TRIGGER civc_invoice_fix_register ON civc_invoice 
  AFTER INSERT AS 
  BEGIN 

	UPDATE civc_invoice_xref
	SET wkstn_id = t5.wkstn_id_new
	FROM civc_invoice_xref t0
	INNER JOIN (SELECT t4.organization_id, t4.rtl_loc_id, t4.business_year, t4.wkstn_id, t4.sequence_nbr, t1.wkstn_id wkstn_id_new
	FROM trn_trans t1
	INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
	      FROM civc_invoice t2
	      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = ''RETAIL_SALE'' AND t2.gross_amt = t3.total OR t3.trans_typcode = ''DEFERRED_INVOICE'') AND t2.create_date between DATEADD(s, -1, t3.create_date) AND DATEADD(s, 1, t3.create_date)
	      WHERE t3.organization_id is null) t4
	ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = ''DEFERRED_INVOICE'' AND t1.create_date between DATEADD(s, -1, t4.create_date) AND DATEADD(s, 1, t4.create_date)) t5
	ON t0.organization_id = t5.organization_id AND t0.rtl_loc_id = t5.rtl_loc_id AND t0.business_year = t5.business_year AND t0.wkstn_id = t5.wkstn_id AND t0.sequence_nbr = t5.sequence_nbr;

	UPDATE civc_invoice
	SET wkstn_id = t5.wkstn_id_new
	FROM civc_invoice t0
	INNER JOIN (SELECT t4.organization_id, t4.rtl_loc_id, t4.business_year, t4.wkstn_id, t4.sequence_nbr, t1.wkstn_id wkstn_id_new
	FROM trn_trans t1
	INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
	      FROM civc_invoice t2
	      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = ''RETAIL_SALE'' AND t2.gross_amt = t3.total OR t3.trans_typcode = ''DEFERRED_INVOICE'') AND t2.create_date between DATEADD(s, -1, t3.create_date) AND DATEADD(s, 1, t3.create_date)
	      WHERE t3.organization_id is null) t4
	ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = ''DEFERRED_INVOICE'' AND t1.create_date between DATEADD(s, -1, t4.create_date) AND DATEADD(s, 1, t4.create_date)) t5
	ON t0.organization_id = t5.organization_id AND t0.rtl_loc_id = t5.rtl_loc_id AND t0.business_year = t5.business_year AND t0.wkstn_id = t5.wkstn_id AND t0.sequence_nbr = t5.sequence_nbr;

  END'
  EXEC (@SQL)
  PRINT '        Trigger for fixing wrong register number on invoices created in a different register than the transaction one';

  SET @SQL = 'CREATE TRIGGER civc_invoice_xref_fix_register ON civc_invoice_xref
  AFTER INSERT AS 
  BEGIN 

	UPDATE civc_invoice_xref
	SET wkstn_id = t5.wkstn_id_new
	FROM civc_invoice_xref t0
	INNER JOIN (SELECT t4.organization_id, t4.rtl_loc_id, t4.business_year, t4.wkstn_id, t4.sequence_nbr, t1.wkstn_id wkstn_id_new
	FROM trn_trans t1
	INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
	      FROM civc_invoice t2
	      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = ''RETAIL_SALE'' AND t2.gross_amt = t3.total OR t3.trans_typcode = ''DEFERRED_INVOICE'') AND t2.create_date between DATEADD(s, -1, t3.create_date) AND DATEADD(s, 1, t3.create_date)
	      WHERE t3.organization_id is null) t4
	ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = ''DEFERRED_INVOICE'' AND t1.create_date between DATEADD(s, -1, t4.create_date) AND DATEADD(s, 1, t4.create_date)) t5
	ON t0.organization_id = t5.organization_id AND t0.rtl_loc_id = t5.rtl_loc_id AND t0.business_year = t5.business_year AND t0.wkstn_id = t5.wkstn_id AND t0.sequence_nbr = t5.sequence_nbr;

	UPDATE civc_invoice
	SET wkstn_id = t5.wkstn_id_new
	FROM civc_invoice t0
	INNER JOIN (SELECT t4.organization_id, t4.rtl_loc_id, t4.business_year, t4.wkstn_id, t4.sequence_nbr, t1.wkstn_id wkstn_id_new
	FROM trn_trans t1
	INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
	      FROM civc_invoice t2
	      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = ''RETAIL_SALE'' AND t2.gross_amt = t3.total OR t3.trans_typcode = ''DEFERRED_INVOICE'') AND t2.create_date between DATEADD(s, -1, t3.create_date) AND DATEADD(s, 1, t3.create_date)
	      WHERE t3.organization_id is null) t4
	ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = ''DEFERRED_INVOICE'' AND t1.create_date between DATEADD(s, -1, t4.create_date) AND DATEADD(s, 1, t4.create_date)) t5
	ON t0.organization_id = t5.organization_id AND t0.rtl_loc_id = t5.rtl_loc_id AND t0.business_year = t5.business_year AND t0.wkstn_id = t5.wkstn_id AND t0.sequence_nbr = t5.sequence_nbr;

  END'
  EXEC (@SQL)
  PRINT '        Trigger for fixing wrong register number on invoices created in a different register than the transaction one';

END
GO
PRINT '     Step Sets the correct workstation id when the invoice is issued on a different workstation than the transaction one end.';



PRINT '     Step Fixing the error introduced in V19 with the conversion of the invoice reports starting...';
UPDATE trn_report_data
SET report_id = t1.invoice_type
FROM trn_report_data t0
INNER JOIN civc_invoice t1 ON t0.organization_id = t1.organization_id AND t0.rtl_loc_id = t1.rtl_loc_id AND t0.business_date = t1.business_date AND t0.wkstn_id = t1.wkstn_id AND t0.trans_seq = t1.invoice_trans_seq
WHERE t0.report_id = 'INVOICE' AND t1.invoice_type = 'CREDIT_NOTE'
PRINT CONCAT('Error previously introduced with the conversion of the report fixed: ', @@ROWCOUNT);
GO
PRINT '     Step Fixing the error introduced in V19 with the conversion of the invoice reports end.';



PRINT '     Step Add Table: DTX[TemporaryTransactionStorage] starting...';
IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('TRN_TEMP_TRANS'))
  PRINT '      Table trn_temp_trans already exists';
ELSE
  BEGIN
    EXEC('CREATE TABLE dbo.trn_temp_trans(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
business_date DATETIME NOT NULL,
wkstn_id BIGINT NOT NULL,
trans_seq BIGINT NOT NULL,
status_code nvarchar(30),
tran_data VARBINARY(MAX),
create_user_id nvarchar(256),
create_date DATETIME,
update_user_id nvarchar(256),
update_date DATETIME,
record_state nvarchar(30), 
CONSTRAINT pk_trn_temp_trans PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq))
');
  PRINT '      Table trn_temp_trans created';
  END
GO


PRINT '     Step Add Table: DTX[TemporaryTransactionStorage] end.';



PRINT '     Step If trn_temp_trans.tran_data is a clob, drop it and add as a blob. starting...';
IF EXISTS (Select * From INFORMATION_SCHEMA.COLUMNS Where column_name = 'tran_data' And table_name = 'trn_temp_trans' and (data_type = 'varchar' or data_type = 'nvarchar') and character_maximum_length = -1)
BEGIN
    TRUNCATE TABLE trn_temp_trans;
    PRINT '      trn_temp_trans.tran_data truncated';
    ALTER TABLE trn_temp_trans DROP COLUMN tran_data;
	PRINT '      trn_temp_trans.tran_data (n)varchar(max) dropped';
	ALTER TABLE trn_temp_trans ADD tran_data varbinary(max);
	PRINT '      trn_temp_trans.tran_data varbinary(max) created';
END;
PRINT '     Step If trn_temp_trans.tran_data is a clob, drop it and add as a blob. end.';



PRINT '     Step Add Index: DTX[DatabaseTranslation] Index[IDX_COM_TRANSLATIONS_ORG_KEY] starting...';
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IDX_COM_TRANSLATIONS_ORG_KEY' AND object_id = OBJECT_ID(N'com_translations'))
  BEGIN
  IF (SELECT dbo.SP_INDEX_COLUMNS('IDX_COM_TRANSLATIONS_ORG_KEY')) = ('ORGANIZATION_ID::TRANSLATION_KEY')
    PRINT '     Index IDX_COM_TRANSLATIONS_ORG_KEY already defined correctly';
  ELSE
  BEGIN
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IDX_COM_TRANSLATIONS_ORG_KEY' AND object_id = OBJECT_ID(N'com_translations'))
  PRINT '     Index IDX_COM_TRANSLATIONS_ORG_KEY is missing';
ELSE
  BEGIN
    EXEC('    DROP INDEX com_translations.IDX_COM_TRANSLATIONS_ORG_KEY;');
    PRINT '     Index IDX_COM_TRANSLATIONS_ORG_KEY dropped';
  END

    EXEC('CREATE INDEX IDX_COM_TRANSLATIONS_ORG_KEY ON dbo.com_translations(organization_id, translation_key)');
    PRINT '     Index IDX_COM_TRANSLATIONS_ORG_KEY created';
  END

  END
ELSE
  BEGIN
    EXEC('CREATE INDEX IDX_COM_TRANSLATIONS_ORG_KEY ON dbo.com_translations(organization_id, translation_key)');
    PRINT '     Index IDX_COM_TRANSLATIONS_ORG_KEY created';
  END
GO


PRINT '     Step Add Index: DTX[DatabaseTranslation] Index[IDX_COM_TRANSLATIONS_ORG_KEY] end.';



PRINT '     Step Add Table: DTX[TokenSigningData] starting...';
IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('SEC_TOKEN_SIGNING_DATA'))
  PRINT '      Table sec_token_signing_data already exists';
ELSE
  BEGIN
    EXEC('CREATE TABLE dbo.sec_token_signing_data(
organization_id INT NOT NULL,
rtl_loc_id INT NOT NULL,
effective_datetime DATETIME NOT NULL,
expiration_datetime DATETIME NOT NULL,
key_id nvarchar(36) NOT NULL,
inactive_flag BIT,
key_algorithm nvarchar(10) NOT NULL,
signature_algorithm nvarchar(10) NOT NULL,
private_key_format nvarchar(10) NOT NULL,
encrypted_private_key nvarchar(MAX) NOT NULL,
public_key_format nvarchar(10) NOT NULL,
public_key nvarchar(MAX) NOT NULL,
create_user_id nvarchar(256),
create_date DATETIME,
update_user_id nvarchar(256),
update_date DATETIME,
record_state nvarchar(30), 
CONSTRAINT pk_sec_token_signing_data PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, effective_datetime))
');
  PRINT '      Table sec_token_signing_data created';
  END
GO


IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IDX_TOKEN_SIGNING_DATA_ID' AND object_id = OBJECT_ID(N'sec_token_signing_data'))
  BEGIN
  IF (SELECT dbo.SP_INDEX_COLUMNS('IDX_TOKEN_SIGNING_DATA_ID')) = ('ORGANIZATION_ID::KEY_ID')
    PRINT '     Index IDX_TOKEN_SIGNING_DATA_ID already defined correctly';
  ELSE
  BEGIN
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IDX_TOKEN_SIGNING_DATA_ID' AND object_id = OBJECT_ID(N'sec_token_signing_data'))
  PRINT '     Index IDX_TOKEN_SIGNING_DATA_ID is missing';
ELSE
  BEGIN
    EXEC('    DROP INDEX sec_token_signing_data.IDX_TOKEN_SIGNING_DATA_ID;');
    PRINT '     Index IDX_TOKEN_SIGNING_DATA_ID dropped';
  END

    EXEC('CREATE INDEX IDX_TOKEN_SIGNING_DATA_ID ON dbo.sec_token_signing_data(organization_id, key_id)');
    PRINT '     Index IDX_TOKEN_SIGNING_DATA_ID created';
  END

  END
ELSE
  BEGIN
    EXEC('CREATE INDEX IDX_TOKEN_SIGNING_DATA_ID ON dbo.sec_token_signing_data(organization_id, key_id)');
    PRINT '     Index IDX_TOKEN_SIGNING_DATA_ID created';
  END
GO


PRINT '     Step Add Table: DTX[TokenSigningData] end.';



PRINT '     Step Add Column: DTX[TenderLineItem] Fields{[Field=tenderDescription]} starting...';
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'ttr_tndr_lineitm') AND name in (N'tndr_description'))
  PRINT '      Column ttr_tndr_lineitm.tndr_description already exists';
ELSE
  BEGIN
    EXEC('    ALTER TABLE ttr_tndr_lineitm ADD tndr_description nvarchar(254)');
    PRINT '     Column ttr_tndr_lineitm.tndr_description created';
  END
GO


PRINT '     Step Add Column: DTX[TenderLineItem] Fields{[Field=tenderDescription]} end.';



PRINT '     Step Add Table: DTX[GroupRole] starting...';
IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('SEC_GROUP_ROLES'))
  PRINT '      Table sec_group_roles already exists';
ELSE
  BEGIN
    EXEC('CREATE TABLE dbo.sec_group_roles(
organization_id INT NOT NULL,
group_id nvarchar(60) NOT NULL,
role nvarchar(50) NOT NULL,
create_user_id nvarchar(256),
create_date DATETIME,
update_user_id nvarchar(256),
update_date DATETIME,
record_state nvarchar(30), 
CONSTRAINT pk_sec_group_roles PRIMARY KEY CLUSTERED (organization_id, group_id, role))
');
  PRINT '      Table sec_group_roles created';
  END
GO


PRINT '     Step Add Table: DTX[GroupRole] end.';



PRINT '     Step Alter Column: DTX[UserRole] Fields{[Field=roleCode]} starting...';
IF (SELECT dbo.SP_DEFAULT_CONSTRAINT_EXISTS('sec_user_role', 'role_code') ) IS NULL
  PRINT '     Default value Constraint for column sec_user_role.role_code is missing';
ELSE
  BEGIN
  DECLARE @sql nvarchar(max) 
  SET @sql = '    ALTER TABLE sec_user_role DROP CONSTRAINT '+dbo.SP_DEFAULT_CONSTRAINT_EXISTS('sec_user_role','role_code')+';' 
  EXEC(@sql) 
  PRINT '     sec_user_role.role_code default value dropped';
  END
GO


BEGIN
    EXEC('ALTER TABLE sec_user_role ALTER COLUMN role_code nvarchar(50) NOT NULL');
  PRINT '     Column sec_user_role.role_code modify';
END
GO
PRINT '     Step Alter Column: DTX[UserRole] Fields{[Field=roleCode]} end.';



PRINT '     Step Drop Primary Key: DTX[ReceiptLookup] starting...';
IF (SELECT dbo.SP_PK_CONSTRAINT_EXISTS('trn_receipt_lookup') ) IS NULL
  PRINT '     PK trn_receipt_lookup is missing';
ELSE
  BEGIN
  DECLARE @sql nvarchar(max) 
  SET @sql = '    ALTER TABLE trn_receipt_lookup DROP CONSTRAINT '+dbo.SP_PK_CONSTRAINT_EXISTS('trn_receipt_lookup')+';' 
  EXEC(@sql) 
    PRINT '     PK trn_receipt_lookup dropped';
  END
GO


IF (SELECT dbo.SP_PK_CONSTRAINT_EXISTS('trn_receipt_lookup_P') ) IS NULL
  PRINT '     PK trn_receipt_lookup_P is missing';
ELSE
  BEGIN
  DECLARE @sql nvarchar(max) 
  SET @sql = '    ALTER TABLE trn_receipt_lookup_P DROP CONSTRAINT '+dbo.SP_PK_CONSTRAINT_EXISTS('trn_receipt_lookup_P')+';' 
  EXEC(@sql) 
    PRINT '     PK trn_receipt_lookup_P dropped';
  END
GO


PRINT '     Step Drop Primary Key: DTX[ReceiptLookup] end.';



PRINT '     Step Add Primary Key: DTX[ReceiptLookup] starting...';
IF (SELECT dbo.SP_PK_CONSTRAINT_EXISTS('trn_receipt_lookup') ) IS NOT NULL
  PRINT '     PK trn_receipt_lookup already exists';
ELSE
  BEGIN
    EXEC('    ALTER TABLE trn_receipt_lookup ADD CONSTRAINT pk_trn_receipt_lookup PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq, receipt_id)');
    PRINT '     PK trn_receipt_lookup created';
  END
GO


IF (SELECT dbo.SP_PK_CONSTRAINT_EXISTS('trn_receipt_lookup_P') ) IS NOT NULL
  PRINT '     PK trn_receipt_lookup_P already exists';
ELSE
  BEGIN
    EXEC('    ALTER TABLE trn_receipt_lookup_P ADD CONSTRAINT pk_trn_receipt_lookup_P PRIMARY KEY CLUSTERED (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq, receipt_id, property_code)');
    PRINT '     PK trn_receipt_lookup_P created';
  END
GO


PRINT '     Step Add Primary Key: DTX[ReceiptLookup] end.';



PRINT '     Step MSSQL: Fix to avoid unique constraint exception starting...';
-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : SP_FLASH
-- Description       : Loads data into the Report tables which are then used by the flash reports.
-- Version           : 19.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....     	Initial Version
-- PGH  02/23/10    Removed the currencyid paramerer, then joining the loc_rtl_loc table to get the default
--                  currencyid for the location.  If the default is not set, defaulting to 'USD'. 
-- BCW  03/07/12	Updated per Padma Golli's instructions.
-- BCW  06/21/12	Updated per Emily Tan's instructions.
-- BCW	12/05/13	Replaced the sale cursor by writing the transaction line item directly into the rpt_sale_line table.
-------------------------------------------------------------------------------------------------------------------
PRINT 'dbo.sp_flash';

IF EXISTS (Select * From sysobjects Where name = 'sp_flash' and type = 'P')
  DROP PROCEDURE sp_flash;
GO

CREATE PROCEDURE dbo.sp_flash (
@argOrganizationId int,  /*organization id*/
@argRetailLocationId int,  /*retail location or store number*/
@argBusinessDate datetime,  /*business date*/
@argWrkstnId bigint,  /*register*/
@argTransSeq bigint)  /*trans sequence*/
as

declare @old_context_info varbinary(128)=context_info();
SET CONTEXT_INFO 0x0111001101110000010111110110011001101100011000010111001101101000

declare -- Quantities
@vActualQuantity decimal(11, 2),
@vGrossQuantity decimal(11, 2),
@vQuantity decimal(11, 2),
@vTotQuantity decimal(11, 2)

declare -- Amounts
@vNetAmount decimal(17, 6),
@vGrossAmount decimal(17, 6),
@vTotGrossAmt decimal(17, 6),
@vTotNetAmt decimal(17, 6),
@vDiscountAmt decimal(17, 6),
@vOverrideAmt decimal(17, 6),
@vPaidAmt decimal(17, 6),
@vTenderAmt decimal(17, 6),
@vForeign_amt decimal(17, 6),
@vLayawayPrice decimal(17, 6),
@vUnitPrice decimal(17, 6)

declare -- Non Physical Items
@vNonPhys nvarchar(30),
@vNonPhysSaleType nvarchar(30),
@vNonPhysType nvarchar(30),
@vNonPhysPrice decimal(17, 6),
@vNonPhysQuantity decimal(11, 2)

declare -- Status codes
@vTransStatcode nvarchar(30),
@vTransTypcode nvarchar(30),
@vSaleLineItmTypcode nvarchar(30),
@vTndrStatcode nvarchar(60),
@vLineitemStatcode nvarchar(30)

declare -- others
@vTransTimeStamp datetime,
@vTransDate datetime,
@vTransCount int,
@vTndrCount int,
@vPostVoidFlag bit,
@vReturnFlag bit,
@vTaxTotal decimal(17, 6),
@vPaid nvarchar(30),
@vLineEnum nvarchar(150),
@vTndrId nvarchar(60),
@vItemId nvarchar(60),
@vRtransLineItmSeq int,
@vDepartmentId nvarchar(90),
@vTndridProp nvarchar(60),
@vCurrencyId nvarchar(3),
@vTndrTypCode nvarchar(30)

declare
@vSerialNbr nvarchar(60),
@vPriceModAmt decimal(17, 6),
@vPriceModReascode nvarchar(60),
@vNonPhysExcludeFlag bit,
@vCustPartyId nvarchar(60),
@vCustLastName nvarchar(90),
@vCustFirstName nvarchar(90),
@vItemDesc nvarchar(120),
@vBeginTimeInt int


select @vTransStatcode = trans_statcode,
@vTransTypcode = trans_typcode,
@vTransTimeStamp = begin_datetime,
@vTransDate = trans_date,
@vTaxTotal = taxtotal,
@vPostVoidFlag = post_void_flag,
@vBeginTimeInt = begin_time_int
from trn_trans with (nolock)
where organization_id = @argOrganizationId
and rtl_loc_id = @argRetailLocationId
and wkstn_id = @argWrkstnId
and business_date = @argBusinessDate
and trans_seq = @argTransSeq

if @@rowcount = 0 
  return  /* Invalid transaction */

select @vCurrencyId = max(currency_id)
from ttr_tndr_lineitm ttl with (nolock)
inner join tnd_tndr tnd with (nolock) on ttl.organization_id=tnd.organization_id and ttl.tndr_id=tnd.tndr_id
where ttl.organization_id = @argOrganizationId
and rtl_loc_id = @argRetailLocationId
and wkstn_id = @argWrkstnId
and business_date = @argBusinessDate
and trans_seq = @argTransSeq

if @vCurrencyId is null
select @vCurrencyId = max(currency_id)
from loc_rtl_loc with (nolock)
where organization_id = @argOrganizationId
and rtl_loc_id = @argRetailLocationId

-- Sundar commented the following as rpt sale line has to capture all the transactions
-- if @vTransStatcode != 'COMPLETE' and @vTransStatcode != 'SUSPEND' 
--  return

set @vTransCount = 1 /* initializing the transaction count */


-- update trans
update trn_trans set flash_sales_flag = 1
where organization_id = @argOrganizationId
and rtl_loc_id = @argRetailLocationId 
and wkstn_id = @argWrkstnId 
and trans_seq = @argTransSeq
and business_date = @argBusinessDate

-- BCW Added code to only update post voids if the original transaction 
if @vPostVoidFlag=1 and not exists(select 1 from rpt_sale_line where organization_id = @argOrganizationId
          and rtl_loc_id = @argRetailLocationId
          and wkstn_id = @argWrkstnId
          and trans_seq = @argTransSeq
          and business_date = @argBusinessDate)
      begin
       insert into rpt_sale_line WITH(ROWLOCK)
      (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq,
      quantity, actual_quantity, gross_quantity, unit_price, net_amt, gross_amt, item_id, 
      item_desc, merch_level_1, serial_nbr, return_flag, override_amt, trans_timestamp, trans_date,
      discount_amt, cust_party_id, last_name, first_name, trans_statcode, sale_lineitm_typcode, begin_time_int,
      currency_id, exclude_from_net_sales_flag)
      select tsl.organization_id, tsl.rtl_loc_id, tsl.business_date, tsl.wkstn_id, tsl.trans_seq, tsl.rtrans_lineitm_seq,
      tsl.net_quantity, tsl.quantity, tsl.gross_quantity, tsl.unit_price,
      -- For VAT taxed items there are rounding problems by which the usage of the tsl.net_amt could create problems.
      -- So, we are calculating it using the tax amount which could have more decimals and because that it is more accurate
      case when vat_amt is null then tsl.net_amt else tsl.gross_amt-tsl.vat_amt-coalesce(d.discount_amt,0) end,
      tsl.gross_amt, tsl.item_id,
      i.DESCRIPTION, coalesce(tsl.merch_level_1,i.MERCH_LEVEL_1,N'DEFAULT'), tsl.serial_nbr, tsl.return_flag, coalesce(o.override_amt,0), @vTransTimeStamp, @vTransDate, 
      coalesce(d.discount_amt,0), tr.cust_party_id, cust.last_name, cust.first_name, 'VOID', tsl.sale_lineitm_typcode, 
      @vBeginTimeInt, @vCurrencyId, tsl.exclude_from_net_sales_flag
      from trl_sale_lineitm tsl with (nolock) 
      inner join trl_rtrans_lineitm r with (nolock)
      on tsl.organization_id=r.organization_id
      and tsl.rtl_loc_id=r.rtl_loc_id
      and tsl.wkstn_id=r.wkstn_id
      and tsl.trans_seq=r.trans_seq
      and tsl.business_date=r.business_date
      and tsl.rtrans_lineitm_seq=r.rtrans_lineitm_seq
      and r.rtrans_lineitm_typcode = N'ITEM'
      left join xom_order_mod xom  with (nolock)
      on tsl.organization_id=xom.organization_id
      and tsl.rtl_loc_id=xom.rtl_loc_id
      and tsl.wkstn_id=xom.wkstn_id
      and tsl.trans_seq=xom.trans_seq
      and tsl.business_date=xom.business_date
      and tsl.rtrans_lineitm_seq=xom.rtrans_lineitm_seq
      left join xom_order_line_detail xold  with (nolock)
      on xom.organization_id=xold.organization_id
      and xom.order_id=xold.order_id
      and xom.detail_seq=xold.detail_seq
      and xom.detail_line_number=xold.detail_line_number
      left join itm_item i
      on tsl.organization_id=i.ORGANIZATION_ID
      and tsl.item_id=i.ITEM_ID
      left join (select TOP 1 extended_amt override_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
        FROM trl_rtl_price_mod with(nolock)
        WHERE void_flag = 0 and rtl_price_mod_reascode=N'PRICE_OVERRIDE' order by organization_id, rtl_loc_id, business_date, wkstn_id, rtrans_lineitm_seq, trans_seq, rtl_price_mod_seq_nbr desc) o
      on tsl.organization_id = o.organization_id 
        AND tsl.rtl_loc_id = o.rtl_loc_id
        AND tsl.business_date = o.business_date 
        AND tsl.wkstn_id = o.wkstn_id 
        AND tsl.trans_seq = o.trans_seq
        AND tsl.rtrans_lineitm_seq = o.rtrans_lineitm_seq
      left join (select sum(extended_amt) discount_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
        FROM trl_rtl_price_mod with(nolock)
        WHERE void_flag = 0 and rtl_price_mod_reascode in (N'LINE_ITEM_DISCOUNT', N'TRANSACTION_DISCOUNT',N'GROUP_DISCOUNT', N'NEW_PRICE_RULE', N'DEAL', N'ENTITLEMENT')
        group by organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq) d
      on tsl.organization_id = d.organization_id 
        AND tsl.rtl_loc_id = d.rtl_loc_id
        AND tsl.business_date = d.business_date 
        AND tsl.wkstn_id = d.wkstn_id 
        AND tsl.trans_seq = d.trans_seq
        AND tsl.rtrans_lineitm_seq = d.rtrans_lineitm_seq
      left join trl_rtrans tr with(nolock)
      on tsl.organization_id = tr.organization_id 
        AND tsl.rtl_loc_id = tr.rtl_loc_id
        AND tsl.business_date = tr.business_date 
        AND tsl.wkstn_id = tr.wkstn_id 
        AND tsl.trans_seq = tr.trans_seq
      left join crm_party cust with(nolock)
      on tsl.organization_id = cust.organization_id 
        AND tr.cust_party_id = cust.party_id
      where tsl.organization_id = @argOrganizationId
      and tsl.rtl_loc_id = @argRetailLocationId
      and tsl.wkstn_id = @argWrkstnId
      and tsl.business_date = @argBusinessDate
      and tsl.trans_seq = @argTransSeq
      and r.void_flag=0
      and ((tsl.SALE_LINEITM_TYPCODE <> N'ORDER'and (xom.detail_type IS NULL OR xold.status_code = N'FULFILLED') )
      or (tsl.SALE_LINEITM_TYPCODE = N'ORDER' and xom.detail_type in (N'FEE', N'PAYMENT') ))
  return;
  end

-- collect transaction data
if abs(@vTaxTotal) > 0 and (@vTransTypcode <> 'POST_VOID' and @vPostVoidFlag = 0) and @vTransStatcode = 'COMPLETE'
  exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
  @argWrkstnId,'TOTALTAX', 1, @vTaxTotal, @vCurrencyId          

IF @vTransTypcode = 'TENDER_CONTROL' and @vPostVoidFlag = 0
  -- process for paid in paid out 
  begin 
    select @vPaid = typcode,@vPaidAmt = amt 
    from tsn_tndr_control_trans with (nolock)  
    where typcode like 'PAID%'
          and organization_id = @argOrganizationId
          and rtl_loc_id = @argRetailLocationId
          and wkstn_id = @argWrkstnId
          and trans_seq = @argTransSeq
          and business_date = @argBusinessDate
            
    IF @@rowcount = 1
      -- it is paid in or paid out
      begin 
        if @vPaid = 'PAID_IN' or @vPaid = 'PAIDIN'
          set @vLineEnum = 'paidin'
        else
          set @vLineEnum = 'paidout'
        -- update flash sales
        if @vTransStatcode = 'COMPLETE'                
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,@vLineEnum, 1, @vPaidAmt, @vCurrencyId

      end 
  end
-- collect tenders  data
if @vPostVoidFlag = 0 and @vTransTypcode <> 'POST_VOID'
  begin

    declare tenderCursor cursor for 
    select t.amt, t.foreign_amt, t.tndr_id, t.tndr_statcode,tr.string_value,tnd.tndr_typcode
    from ttr_tndr_lineitm t with (nolock) 
    inner join trl_rtrans_lineitm r with (nolock)
    on t.organization_id=r.organization_id
    and t.rtl_loc_id=r.rtl_loc_id
    and t.wkstn_id=r.wkstn_id
    and t.trans_seq=r.trans_seq
    and t.business_date=r.business_date
    and t.rtrans_lineitm_seq=r.rtrans_lineitm_seq
  inner join tnd_tndr tnd with (nolock)
    on t.organization_id=tnd.organization_id
    and t.tndr_id=tnd.tndr_id 
  left outer join trl_rtrans_lineitm_p tr with (nolock)
    on tr.organization_id=r.organization_id
    and tr.rtl_loc_id=r.rtl_loc_id
    and tr.wkstn_id=r.wkstn_id
    and tr.trans_seq=r.trans_seq
    and tr.business_date=r.business_date
    and tr.rtrans_lineitm_seq=r.rtrans_lineitm_seq
  and property_code = 'tender_id'
    where t.organization_id = @argOrganizationId
    and t.rtl_loc_id = @argRetailLocationId 
    and t.wkstn_id = @argWrkstnId 
    and t.trans_seq = @argTransSeq
    and t.business_date = @argBusinessDate
    and r.void_flag = 0
  and t.tndr_id <> 'ACCOUNT_CREDIT'

    open tenderCursor
    while 1=1 
      begin
        fetch next from tenderCursor into @vTenderAmt,@vForeign_amt,@vTndrid,@vTndrStatcode,@vTndridProp,@vTndrTypCode           
        if @@fetch_status <> 0 
          BREAK
        if @vTndrTypCode='VOUCHER' or @vTndrStatcode <> 'Change'
          set @vTndrCount = 1  -- only for original tenders
        else 
          set @vTndrCount = 0

         if @vTndridProp IS NOT NULL
           set @vTndrid = @vTndridProp
          
        if @vLineEnum = 'paidout'
          begin
            set @vTenderAmt = coalesce(@vTenderAmt, 0) * -1
            set @vForeign_amt = coalesce(@vForeign_amt, 0) * -1
          end

        -- update flash
        if @vTransStatcode = 'COMPLETE'                
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,@vTndrid,@vTndrCount,@vTenderAmt,@vCurrencyId
    
        if @vTenderAmt > 0 and @vTransStatcode = 'COMPLETE'                
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,'TendersTakenIn', 1,@vTenderAmt,@vCurrencyId
        else
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,'TendersRefunded', 1,@vTenderAmt,@vCurrencyId
    
      end
    close tenderCursor
    deallocate tendercursor
  end

-- collect post void info
if @vTransTypcode = 'POST_VOID' or @vPostVoidFlag = 1
  begin

    set @vTransCount = -1 /* reversing the count */
    if @vPostVoidFlag = 0
      begin
        set @vPostVoidFlag = 1
        -- get the original post voided transaction and set it as original parameters
        select  @argOrganizationId = voided_org_id,
          @argRetailLocationId = voided_rtl_store_id, 
          @argWrkstnId = voided_wkstn_id, 
          @argBusinessDate = voided_business_date, 
          @argTransSeq = voided_trans_id 
        from trn_post_void_trans with (nolock)
        where organization_id = @argOrganizationId
        and rtl_loc_id = @argRetailLocationId
        and wkstn_id = @argWrkstnId
        and business_date = @argBusinessDate
        and trans_seq = @argTransSeq
    
        /* NOTE: From now on the parameter value carries the original post voided
           information rather than the current transaction information in 
           case of post void trans type. This will apply for sales data 
           processing.
        */
              
        if @@rowcount = 0 
           return -- don't know the original post voided record

    if exists(select 1 from rpt_sale_line where organization_id = @argOrganizationId
          and rtl_loc_id = @argRetailLocationId
          and wkstn_id = @argWrkstnId
          and trans_seq = @argTransSeq
          and business_date = @argBusinessDate
      and trans_statcode = 'VOID')
      return;
      end
    -- update the rpt sale line for post void
   update rpt_sale_line
    set trans_statcode='VOID'
    where organization_id = @argOrganizationId
    and rtl_loc_id = @argRetailLocationId
    and wkstn_id = @argWrkstnId
    and business_date = @argBusinessDate
    and trans_seq = @argTransSeq        

    -- reverse padin paidout
    select @vPaid = typcode,@vPaidAmt = amt 
    from tsn_tndr_control_trans with (nolock)  
    where typcode like 'PAID%'
          and organization_id = @argOrganizationId
          and rtl_loc_id = @argRetailLocationId
          and wkstn_id = @argWrkstnId
          and trans_seq = @argTransSeq
          and business_date = @argBusinessDate
            
    IF @@rowcount = 1
      -- it is paid in or paid out
      begin 
        if @vPaid = 'PAID_IN' or @vPaid = 'PAIDIN'
          set @vLineEnum = 'paidin'
        else
          set @vLineEnum = 'paidout'
        set @vPaidAmt = @vPaidAmt * -1
        -- update flash sales  
        if @vTransStatcode = 'COMPLETE'                                
          exec sp_ins_upd_flash_sales @argOrganizationId, @argRetailLocationId, @vTransDate,
          @argWrkstnId, @vLineEnum, -1, @vPaidAmt, @vCurrencyId 

      end 
    -- reverse tax
    select @vTaxTotal=taxtotal from trn_trans with (nolock)
    where organization_id = @argOrganizationId
    and rtl_loc_id = @argRetailLocationId
    and wkstn_id = @argWrkstnId
    and business_date = @argBusinessDate
    and trans_seq = @argTransSeq
    

    if abs(@vTaxTotal) > 0 and @vTransStatcode = 'COMPLETE'
      begin
        set @vTaxTotal = @vTaxTotal * -1
        exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
        @argWrkstnId,'TOTALTAX',-1,@vTaxTotal,@vCurrencyId
      end

    -- reverse tenders
    declare postVoidTenderCursor cursor for 
    select t.amt, t.foreign_amt, t.tndr_id, t.tndr_statcode,tr.string_value
    from ttr_tndr_lineitm t with (nolock) 
    inner join trl_rtrans_lineitm r with (nolock)
    on t.organization_id=r.organization_id
    and t.rtl_loc_id=r.rtl_loc_id
    and t.wkstn_id=r.wkstn_id
    and t.trans_seq=r.trans_seq
    and t.business_date=r.business_date
    and t.rtrans_lineitm_seq=r.rtrans_lineitm_seq
  left outer join trl_rtrans_lineitm_p tr with (nolock)
    on tr.organization_id=r.organization_id
    and tr.rtl_loc_id=r.rtl_loc_id
    and tr.wkstn_id=r.wkstn_id
    and tr.trans_seq=r.trans_seq
    and tr.business_date=r.business_date
    and tr.rtrans_lineitm_seq=r.rtrans_lineitm_seq
  and property_code = 'tender_id'
    where t.organization_id = @argOrganizationId
    and t.rtl_loc_id = @argRetailLocationId 
    and t.wkstn_id = @argWrkstnId 
    and t.trans_seq = @argTransSeq
    and t.business_date = @argBusinessDate
    and r.void_flag = 0
  and t.tndr_id <> 'ACCOUNT_CREDIT'

    open postVoidTenderCursor
    while 1=1 
      begin
        fetch next from postVoidTenderCursor into @vTenderAmt,@vForeign_amt,@vTndrid,@vTndrStatcode,@vTndridProp            
        if @@fetch_status <> 0 
                     BREAK
        if @vTndrStatcode <> 'Change'
          set @vTndrCount = -1  -- only for original tenders
        else 
          set @vTndrCount = 0

         if @vTndridProp IS NOT NULL
           set @vTndrid = @vTndridProp

        -- update flash
        set @vTenderAmt = @vTenderAmt * -1
 
       if @vTransStatcode = 'COMPLETE'
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,@vTndrid,@vTndrCount,@vTenderAmt,@vCurrencyId

        if @vTenderAmt < 0 and @vTransStatcode = 'COMPLETE'
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,'TendersTakenIn',-1,@vTenderAmt,@vCurrencyId
        else
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,'TendersRefunded',-1,@vTenderAmt,@vCurrencyId
  
      end
    close postVoidTenderCursor
    deallocate postVoidTenderCursor
  end

-- collect sales data
      if @vPostVoidFlag = 0 and @vTransTypcode <> 'POST_VOID' -- dont do it for rpt sale line
      begin
         insert into rpt_sale_line WITH(ROWLOCK)
        (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq,
        quantity, actual_quantity, gross_quantity, unit_price, net_amt, gross_amt, item_id, 
        item_desc, merch_level_1, serial_nbr, return_flag, override_amt, trans_timestamp, trans_date,
        discount_amt, cust_party_id, last_name, first_name, trans_statcode, sale_lineitm_typcode, 
        begin_time_int,currency_id, exclude_from_net_sales_flag)
    select tsl.organization_id, tsl.rtl_loc_id, tsl.business_date, tsl.wkstn_id, tsl.trans_seq, tsl.rtrans_lineitm_seq,
    tsl.net_quantity, tsl.quantity, tsl.gross_quantity, tsl.unit_price,
    -- For VAT taxed items there are rounding problems by which the usage of the tsl.net_amt could create problems.
    -- So, we are calculating it using the tax amount which could have more decimals and because that it is more accurate
    case when vat_amt is null then tsl.net_amt else tsl.gross_amt-tsl.vat_amt-coalesce(d.discount_amt,0) end,
    tsl.gross_amt, tsl.item_id,
    i.DESCRIPTION, coalesce(tsl.merch_level_1,i.MERCH_LEVEL_1,N'DEFAULT'), tsl.serial_nbr, tsl.return_flag, coalesce(o.override_amt,0), @vTransTimeStamp, @vTransDate,
    coalesce(d.discount_amt,0), tr.cust_party_id, cust.last_name, cust.first_name, @vTransStatcode, tsl.sale_lineitm_typcode, 
    @vBeginTimeInt, @vCurrencyId, tsl.exclude_from_net_sales_flag
    from trl_sale_lineitm tsl with (nolock) 
    inner join trl_rtrans_lineitm r with (nolock)
    on tsl.organization_id=r.organization_id
    and tsl.rtl_loc_id=r.rtl_loc_id
    and tsl.wkstn_id=r.wkstn_id
    and tsl.trans_seq=r.trans_seq
    and tsl.business_date=r.business_date
    and tsl.rtrans_lineitm_seq=r.rtrans_lineitm_seq
    and r.rtrans_lineitm_typcode = N'ITEM'
    left join xom_order_mod xom  with (nolock)
    on tsl.organization_id=xom.organization_id
    and tsl.rtl_loc_id=xom.rtl_loc_id
    and tsl.wkstn_id=xom.wkstn_id
    and tsl.trans_seq=xom.trans_seq
    and tsl.business_date=xom.business_date
    and tsl.rtrans_lineitm_seq=xom.rtrans_lineitm_seq
    left join xom_order_line_detail xold  with (nolock)
    on xom.organization_id=xold.organization_id
    and xom.order_id=xold.order_id
    and xom.detail_seq=xold.detail_seq
    and xom.detail_line_number=xold.detail_line_number
    left join itm_item i
    on tsl.organization_id=i.ORGANIZATION_ID
    and tsl.item_id=i.ITEM_ID
    left join (select top 1 extended_amt override_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
      FROM trl_rtl_price_mod with(nolock)
      WHERE void_flag = 0 and rtl_price_mod_reascode=N'PRICE_OVERRIDE' 
        and organization_id = @argOrganizationId
        and rtl_loc_id = @argRetailLocationId
        and wkstn_id = @argWrkstnId
        and business_date = @argBusinessDate
        and trans_seq = @argTransSeq 
        order by organization_id, rtl_loc_id, business_date, wkstn_id, rtrans_lineitm_seq, trans_seq, rtl_price_mod_seq_nbr desc) o
    on tsl.organization_id = o.organization_id 
      AND tsl.rtl_loc_id = o.rtl_loc_id
      AND tsl.business_date = o.business_date 
      AND tsl.wkstn_id = o.wkstn_id 
      AND tsl.trans_seq = o.trans_seq
      AND tsl.rtrans_lineitm_seq = o.rtrans_lineitm_seq
    left join (select sum(extended_amt) discount_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
      FROM trl_rtl_price_mod with(nolock)
      WHERE void_flag = 0 and rtl_price_mod_reascode in (N'LINE_ITEM_DISCOUNT', N'TRANSACTION_DISCOUNT',N'GROUP_DISCOUNT', N'NEW_PRICE_RULE', N'DEAL', N'ENTITLEMENT')
      group by organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq) d
    on tsl.organization_id = d.organization_id 
      AND tsl.rtl_loc_id = d.rtl_loc_id
      AND tsl.business_date = d.business_date 
      AND tsl.wkstn_id = d.wkstn_id 
      AND tsl.trans_seq = d.trans_seq
      AND tsl.rtrans_lineitm_seq = d.rtrans_lineitm_seq
    left join trl_rtrans tr with(nolock)
    on tsl.organization_id = tr.organization_id 
      AND tsl.rtl_loc_id = tr.rtl_loc_id
      AND tsl.business_date = tr.business_date 
      AND tsl.wkstn_id = tr.wkstn_id 
      AND tsl.trans_seq = tr.trans_seq
    left join crm_party cust with(nolock)
    on tsl.organization_id = cust.organization_id 
      AND tr.cust_party_id = cust.party_id
    where tsl.organization_id = @argOrganizationId
    and tsl.rtl_loc_id = @argRetailLocationId
    and tsl.wkstn_id = @argWrkstnId
    and tsl.business_date = @argBusinessDate
    and tsl.trans_seq = @argTransSeq
    and r.void_flag=0
    and ((tsl.SALE_LINEITM_TYPCODE <> N'ORDER'and (xom.detail_type IS NULL OR xold.status_code = N'FULFILLED') )
    or (tsl.SALE_LINEITM_TYPCODE = N'ORDER' and xom.detail_type in (N'FEE', N'PAYMENT') ))
   end
    
    if @vTransStatcode = 'COMPLETE' -- only when complete populate flash sales
    begin 
    -- returns
    select @vQuantity=sum(case @vPostVoidFlag when 0 then -1 else 1 end * coalesce(quantity,0)),@vNetAmount=sum(case @vPostVoidFlag when 1 then -1 else 1 end * coalesce(net_amt,0)) 
    from rpt_sale_line rsl with(nolock)
    where rsl.organization_id = @argOrganizationId
      and rtl_loc_id = @argRetailLocationId
      and wkstn_id = @argWrkstnId
      and business_date = @argBusinessDate
      and trans_seq= @argTransSeq
      and return_flag=1
      and coalesce(exclude_from_net_sales_flag,0)=0
 
      if abs(@vQuantity)>0 or abs(@vNetAmount)>0
        -- populate now to flash tables
        exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
        @argWrkstnId,'Returns',@vQuantity, @vNetAmount, @vCurrencyId

    select @vGrossQuantity=sum(case when return_flag=@vPostVoidFlag then 1 else -1 end * coalesce(gross_quantity,0)),
    @vQuantity=sum(case when return_flag=@vPostVoidFlag then 1 else -1 end * coalesce(quantity,0)),
    @vGrossAmount=sum(case @vPostVoidFlag when 1 then -1 else 1 end * coalesce(gross_amt,0)),
    @vNetAmount=sum(case @vPostVoidFlag when 1 then -1 else 1 end * coalesce(net_amt,0)),
    @vOverrideAmt=sum(case @vPostVoidFlag when 1 then 1 else -1 end * coalesce(override_amt,0)),
    @vDiscountAmt=sum(case @vPostVoidFlag when 1 then 1 else -1 end * coalesce(discount_amt,0)) 
    from rpt_sale_line rsl with(nolock)
    where rsl.organization_id = @argOrganizationId
      and rtl_loc_id = @argRetailLocationId
      and wkstn_id = @argWrkstnId
      and business_date = @argBusinessDate
      and trans_seq= @argTransSeq
      AND QUANTITY <> 0
      AND sale_lineitm_typcode not in ('ONHOLD','WORK_ORDER')
      and coalesce(exclude_from_net_sales_flag,0)=0

      -- For VAT taxed items there are rounding problems by which the usage of the SUM(net_amt) could create problems
      -- So we decided to set it as simple difference between the gross amount and the discount, which results in the expected value for both SALES and VAT without rounding issues
      -- We excluded the possibility to round also the tax because several reasons:
      -- 1) It will be possible that the final result is not accurate if both values have 5 as exceeding decimal
      -- 2) The value of the tax is rounded by specific legal requirements, and must match with what specified on the fiscal receipts
      -- 3) The number of decimals used for the tax amount in the database is less (6) than the one used in the calculator (10); 
      --    anyway, this last one is the most accurate, so we cannot rely on the value on the database which is at line level (rpt_sale_line) and could be affected by several roundings
      SET @vNetAmount = @vGrossAmount + @vDiscountAmt - @vTaxTotal

      -- Gross Sales update  
      if abs(@vGrossAmount) > 0
        exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
        @argWrkstnId,'GROSSSALES',@vGrossQuantity, @vGrossAmount, @vCurrencyId
      -- Net Sales update
      if abs(@vNetAmount) > 0
        exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
        @argWrkstnId,'NETSALES',@vQuantity, @vNetAmount, @vCurrencyId  
      -- Discounts
      if abs(@vOverrideAmt) > 0
        exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
        @argWrkstnId,'OVERRIDES',@vQuantity, @vOverrideAmt, @vCurrencyId  
      -- Discounts  
      if abs(@vDiscountAmt) > 0
        exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
        @argWrkstnId,'DISCOUNTS',@vQuantity, @vDiscountAmt, @vCurrencyId  

    -- Hourly sales updates (add for all the line items in the transaction)
      set @vTotQuantity = coalesce(@vTotQuantity, 0) + @vQuantity
      set @vTotNetAmt = coalesce(@vTotNetAmt, 0) + @vNetAmount
      set @vTotGrossAmt = coalesce(@vTotGrossAmt, 0) + @vGrossAmount

      -- non merchandise
      -- Non Merchandise (returns after processing)
    declare saleCursor cursor fast_forward for
    select rsl.item_id,sale_lineitm_typcode,actual_quantity,unit_price,case @vPostVoidFlag when 1 then -1 else 1 end * coalesce(gross_amt,0),case when return_flag=@vPostVoidFlag then 1 else -1 end * coalesce(gross_quantity,0),merch_level_1,case @vPostVoidFlag when 1 then -1 else 1 end * coalesce(net_amt,0),case when return_flag=@vPostVoidFlag then 1 else -1 end * coalesce(quantity,0),return_flag
    from rpt_sale_line rsl with(nolock)
    where rsl.organization_id = @argOrganizationId
      and rtl_loc_id = @argRetailLocationId
      and wkstn_id = @argWrkstnId
      and business_date = @argBusinessDate
      and trans_seq= @argTransSeq
      AND QUANTITY <> 0
      AND sale_lineitm_typcode not in ('ONHOLD','WORK_ORDER')
      and coalesce(exclude_from_net_sales_flag,0)=0

    open saleCursor

    while 1=1
    begin

    fetch from saleCursor into @vItemId,@vSaleLineItmTypcode,@vActualQuantity,@vUnitPrice,@vGrossAmount,@vGrossQuantity,@vDepartmentId,@vNetAmount,@vQuantity,@vReturnFlag;
    if @@FETCH_STATUS <> 0
    break;

      select @vNonPhysType = non_phys_item_typcode from itm_non_phys_item with (nolock)
      where item_id = @vItemId and organization_id = @argOrganizationId    
      IF @@rowcount = 1
        begin      
        -- check for layaway or sp. order payment / deposit
          if @vPostVoidFlag <> @vReturnFlag
            begin
              set @vNonPhysPrice = @vUnitPrice * -1
              set @vNonPhysQuantity = @vActualQuantity * -1
            end
          else
            begin
              set @vNonPhysPrice = @vUnitPrice
              set @vNonPhysQuantity = @vActualQuantity
            end
        
          if @vNonPhysType = 'LAYAWAY_DEPOSIT'
            set @vNonPhys = 'LayawayDeposits'
          else if @vNonPhysType = 'LAYAWAY_PAYMENT'
            set @vNonPhys = 'LayawayPayments'
          else if @vNonPhysType = 'SP_ORDER_DEPOSIT'
            set @vNonPhys = 'SpOrderDeposits'        
          else if @vNonPhysType = 'SP_ORDER_PAYMENT'
            set @vNonPhys = 'SpOrderPayments'        
          else if @vNonPhysType = 'PRESALE_DEPOSIT'
            set @vNonPhys = 'PresaleDeposits'
          else if @vNonPhysType = 'PRESALE_PAYMENT'
            set @vNonPhys = 'PresalePayments'
          else if @vNonPhysType = 'ONHOLD_DEPOSIT'
            set @vNonPhys = 'OnholdDeposits'
          else if @vNonPhysType = 'ONHOLD_PAYMENT'
            set @vNonPhys = 'OnholdPayments'
          else if @vNonPhysType = 'LOCALORDER_DEPOSIT'
            set @vNonPhys = 'LocalInventoryOrderDeposits'
          else if @vNonPhysType = 'LOCALORDER_PAYMENT'
            set @vNonPhys = 'LocalInventoryOrderPayments'
          else 
            begin
              set @vNonPhys = 'NonMerchandise'
              set @vNonPhysPrice = @vGrossAmount
              set @vNonPhysQuantity = @vGrossQuantity
            end
          -- update flash sales for non physical payments / deposits
          exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
          @argWrkstnId,@vNonPhys,@vNonPhysQuantity, @vNonphysPrice, @vCurrencyId
        end  
      else
      set @vNonPhys = '' -- reset 

           -- process layaways, special orders, presales, onholds, and local inventory orders (not sales)
      if @vSaleLineitmTypcode = 'LAYAWAY' or @vSaleLineitmTypcode = 'SPECIAL_ORDER' 
        or @vSaleLineitmTypcode = 'PRESALE' or @vSaleLineitmTypcode = 'ONHOLD' or @vSaleLineitmTypcode = 'LOCALORDER'
        begin
          if (not (@vNonPhys = 'LayawayDeposits' or @vNonPhys = 'LayawayPayments' 
            or @vNonPhys = 'SpOrderDeposits' or @vNonPhys = 'SpOrderPayments' 
            or @vNonPhys = 'OnholdDeposits' or @vNonPhys = 'OnholdPayments' 
            or @vNonPhys = 'LocalInventoryOrderDeposits' or @vNonPhys = 'LocalInventoryOrderPayments' 
            or @vNonPhys = 'PresaleDeposits' or @vNonPhys = 'PresalePayments')) 
            and ((@vLineitemStatcode is null) or (@vLineitemStatcode <> 'CANCEL'))
            begin
            
              set @vNonPhysSaleType = 'SpOrderItems'
              if @vSaleLineitmTypcode = 'LAYAWAY'
                set @vNonPhysSaleType = 'LayawayItems'
              else if @vSaleLineitmTypcode = 'PRESALE'
                set @vNonPhysSaleType = 'PresaleItems'
              else if @vSaleLineitmTypcode = 'ONHOLD'
                set @vNonPhysSaleType = 'OnholdItems'
              else if @vSaleLineitmTypcode = 'LOCALORDER'
                set @vNonPhysSaleType = 'LocalInventoryOrderItems'
              
              -- update flash sales for layaway items
              set @vLayawayPrice = @vUnitPrice * coalesce(@vActualQuantity, 0)
              exec sp_ins_upd_flash_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
              @argWrkstnId,@vNonPhys,@vActualQuantity, @vLayawayPrice, @vCurrencyId
            end  
        end
      -- end flash sales update
      -- department sales
      exec sp_ins_upd_merchlvl1_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
      @argWrkstnId,@vDepartmentId,@vQuantity,@vNetAmount,@vGrossAmount,@vCurrencyId      
    end -- sale cursor ends
  close saleCursor
  deallocate saleCursor 
  end -- only when transaction is complete populate flash sales ends

-- update hourly sales
   exec sp_ins_upd_hourly_sales @argOrganizationId,@argRetailLocationId,@vTransDate,
   @argWrkstnId,@vTransTimeStamp,@vTotquantity,@vTotNetAmt,@vTotGrossAmt,@vTransCount,@vCurrencyId 
if @old_context_info is null
	SET CONTEXT_INFO 0x
else
	SET CONTEXT_INFO @old_context_info
GO
PRINT '     Step MSSQL: Fix to avoid unique constraint exception end.';




PRINT '***** Body scripts end *****';


PRINT '***************************************************************************';
PRINT 'Database now hybridized to support clients running against the following versions:';
PRINT '    21.0.*';
PRINT '    22.0.0';
PRINT 'Please run the corresponding un-hybridize script against this database once all';
PRINT 'clients on earlier supported versions have been updated to the latest supported release.';
PRINT '***************************************************************************';
-- LEAVE BLANK LINE BELOW
