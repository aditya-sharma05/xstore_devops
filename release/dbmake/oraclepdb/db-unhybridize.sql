-- ***************************************************************************
-- This script "de-hybridizes" a previously "hybridized" script, discarding schema
-- structures which are removed during the upgrade but were kept for backwards schema compatibility.  It is generally invoked once
-- against any databases which, at one point, needed to simultaneously accommodate clients running
-- on two versions of Xstore.
--
--
-- Source version:  21.0.*
-- Target version:  22
-- DB platform:     Oracle 12c
-- ***************************************************************************
PROMPT '**************************************';
PROMPT '*****       UNHYBRIDIZING        *****';
PROMPT '***** From:  21.0.*              *****';
PROMPT '*****   To:  22.0.0              *****';
PROMPT '**************************************';

--
-- Variables
--
DEFINE dbDataTableSpace = '$(DbTblspace)_DATA';-- Name of data file tablespace
DEFINE dbIndexTableSpace = '$(DbTblspace)_INDEX';-- Name of index file tablespace 


alter session set current_schema=$(DbSchema);


PROMPT '***** Prefix scripts start *****';


EXEC dbms_output.put_line('--- CREATING SP_COLUMN_EXISTS --- ');
CREATE OR REPLACE function SP_COLUMN_EXISTS (
 table_name     varchar2,
 column_name    varchar2
) return boolean is
 v_count integer;
begin
  select count(*) into v_count
    from all_tab_columns
   where owner = upper('$(DbSchema)')
     and table_name = upper(SP_COLUMN_EXISTS.table_name)
     and column_name = upper(SP_COLUMN_EXISTS.column_name);
  if v_count = 0 then
    return false;
  else
    return true;
  end if;
end SP_COLUMN_EXISTS;
/

EXEC dbms_output.put_line('--- CREATING SP_TABLE_EXISTS --- ');
create or replace function SP_TABLE_EXISTS (
  table_name varchar2
) return boolean is
  v_count integer;
begin
  select count(*) into v_count
    from all_tables
   where owner = upper('$(DbSchema)')
     and table_name = upper(SP_TABLE_EXISTS.table_name);
  if v_count = 0 then
    return false;
  else
    return true;
  end if;
end SP_TABLE_EXISTS;
/

EXEC dbms_output.put_line('--- CREATING SP_TRIGGER_EXISTS --- ');
create or replace function SP_TRIGGER_EXISTS (
  trigger_name varchar2
) return boolean is
  v_count integer;
begin
  select count(*) into v_count
    from user_triggers
   where trigger_name = upper(SP_TRIGGER_EXISTS.trigger_name);
  if v_count = 0 then
    return false;
  else
    return true;
  end if;
end SP_TRIGGER_EXISTS;
/

EXEC dbms_output.put_line('--- CREATING CREATE_PROPERTY_TABLE --- ');
CREATE OR REPLACE PROCEDURE CREATE_PROPERTY_TABLE
    (vtableNameIn varchar2)
IS
    vsql varchar2(32000);
    vcolumns varchar2(32000);
    vpk varchar2(32000);
    vcnt number(10);
    vtableName varchar2(128);
    vLF char(1) := '
';
    CURSOR mycur IS
      SELECT tc.COLUMN_NAME, tc.DATA_TYPE, tc.CHAR_LENGTH, tc.DATA_PRECISION, tc.DATA_SCALE, tc.DATA_DEFAULT
        FROM USER_CONSTRAINTS c
          INNER JOIN USER_CONS_COLUMNS cc
            ON c.CONSTRAINT_NAME = cc.CONSTRAINT_NAME
           AND c.OWNER = cc.OWNER
          INNER JOIN USER_TAB_COLUMNS tc
            ON cc.TABLE_NAME = tc.TABLE_NAME
           AND cc.COLUMN_NAME = tc.COLUMN_NAME
       WHERE c.TABLE_NAME = UPPER(vtableNameIn)
         AND c.CONSTRAINT_TYPE = 'P' 
      ORDER BY cc.POSITION;
BEGIN
    vtableName := UPPER(vtableNameIn);
    IF SP_TABLE_EXISTS(vtableName || '_P') = true THEN
        dbms_output.put_line(vtableName || '_P already exists');
        return;
    END IF;
    IF SP_TABLE_EXISTS(vtableName) = false THEN
        dbms_output.put_line(vtableName || ' does not exist');
        return;
    END IF;
    IF substr(vtableName, -2) = '_P' THEN
        dbms_output.put_line('will not create a property table for a property table: ' || vtableName);
        return;
    END IF;

    SELECT count(*) into vcnt 
      FROM ALL_CONSTRAINTS CONS, ALL_CONS_COLUMNS COLS
     WHERE COLS.TABLE_NAME = UPPER(vtableName) 
       AND CONS.CONSTRAINT_TYPE = 'P' 
       AND CONS.CONSTRAINT_NAME = COLS.CONSTRAINT_NAME 
       AND COLS.COLUMN_NAME='ORGANIZATION_ID';
    IF vcnt = 0 THEN
        dbms_output.put_line('no primary key');
        return;
    END IF;

    vpk := '';
    vcolumns := '';

    FOR myval IN mycur
    LOOP
      vpk := vpk || myval.column_name || ', ';

      vcolumns := vcolumns || vLF || '  ' || myval.column_name || ' ' || myval.data_type;
      IF myval.data_type LIKE '%CHAR%' THEN
          vcolumns := vcolumns || '(' || myval.char_length || ' char)';
      ELSIF myval.data_type='NUMBER' THEN
          vcolumns := vcolumns || '(' || myval.data_precision || ',' || myval.data_scale || ')';
      END IF;

      IF LENGTH(myval.data_default) > 0 THEN
        IF NOT UPPER(myval.data_default) LIKE '%NEXTVAL' THEN
            vcolumns := vcolumns || ' DEFAULT ' || myval.data_default;
        END IF;
      END IF;

      vcolumns := vcolumns || ' NOT NULL,';
    END LOOP;

    vsql := 'CREATE TABLE ' || vtableName || '_P ('
            || vcolumns || vLF
            || '  PROPERTY_CODE  VARCHAR2(30 char) NOT NULL,' || vLF
            || '  TYPE           VARCHAR2(30 char),' || vLF
            || '  STRING_VALUE   VARCHAR2(4000 char),' || vLF
            || '  DATE_VALUE     TIMESTAMP(6),' || vLF
            || '  DECIMAL_VALUE  NUMBER(17,6),' || vLF
            || '  CREATE_DATE    TIMESTAMP(6),' || vLF
            || '  CREATE_USER_ID VARCHAR2(256 char),' || vLF
            || '  UPDATE_DATE    TIMESTAMP(6),' || vLF
            || '  UPDATE_USER_ID VARCHAR2(256 char),' || vLF
            || '  RECORD_STATE   VARCHAR2(30 char),' || vLF
            || '  CONSTRAINT PK';
   IF LENGTH(vtableName) > 25 THEN
     vsql := vsql || REPLACE(vtableName,'_','');
   ELSE
     vsql := vsql || '_' || vtableName || '_';
   END IF;

   vsql := vsql || 'P PRIMARY KEY (' || vpk || 'PROPERTY_CODE)
    USING INDEX
TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.';

   dbms_output.put_line('--- CREATING TABLE ' || vtableName || '_P ---');
   dbms_output.put_line(vsql);
   EXECUTE IMMEDIATE vsql;
   EXECUTE IMMEDIATE   'GRANT SELECT,INSERT,UPDATE,DELETE ON ' || vtableName || '_P' || ' TO posusers';
   EXECUTE IMMEDIATE   'GRANT SELECT,INSERT,UPDATE,DELETE ON ' || vtableName || '_P' || ' TO dbausers';

END;
/

EXEC dbms_output.put_line('--- CREATING SP_INDEX_EXISTS --- ');
CREATE OR REPLACE function SP_INDEX_EXISTS (
 index_name     varchar2
) return boolean is
 v_count integer;
begin
  select count(*) into v_count
    from user_indexes
   where index_name = upper(SP_INDEX_EXISTS.index_name);
  if v_count = 0 then
    return false;
  else
    return true;
  end if;
end SP_INDEX_EXISTS;
/

EXEC dbms_output.put_line('--- CREATING SP_PRIMARYKEY_EXISTS --- ');
CREATE OR REPLACE function SP_PRIMARYKEY_EXISTS (
 constraint_name     varchar2
) return boolean is
 v_count integer;
begin
  select count(*) into v_count
    from all_constraints
   where owner = upper('$(DbSchema)')
     and constraint_name = upper(SP_PRIMARYKEY_EXISTS.constraint_name)
     and constraint_type = 'P';
  if v_count = 0 then
    return false;
  else
    return true;
  end if;
end SP_PRIMARYKEY_EXISTS;
/

EXEC dbms_output.put_line('--- CREATING SP_IS_NULLABLE --- ');
CREATE OR REPLACE function SP_IS_NULLABLE (
 table_name     varchar2,
 column_name    varchar2
) return boolean is
 v_count integer;
begin
  select count(*) into v_count
    from all_tab_columns
   where owner = upper('$(DbSchema)')
     and table_name = upper(SP_IS_NULLABLE.table_name)
     and column_name = upper(SP_IS_NULLABLE.column_name)
     AND nullable = 'Y';
  if v_count = 0 then
    return false;
  else
    return true;
  end if;
end SP_IS_NULLABLE;
/

EXEC dbms_output.put_line('--- CREATING SP_PK_CONSTRAINT_EXISTS --- ');
CREATE OR REPLACE function SP_PK_CONSTRAINT_EXISTS (
 table_name     varchar2
) return varchar2 is
 v_pk varchar2(256);
begin
  select initcap(CONSTRAINT_NAME) into v_pk
    from all_constraints
   where owner = upper('$(DbSchema)')
     and table_name = upper(SP_PK_CONSTRAINT_EXISTS.table_name)
     and constraint_type = 'P'
     and ROWNUM = 1;
   return v_pk;
   EXCEPTION
   WHEN NO_DATA_FOUND
   then return 'NOT_FOUND';
end SP_PK_CONSTRAINT_EXISTS;
/

EXEC dbms_output.put_line('--- CREATING SP_INDEX_COLUMNS --- ');
CREATE OR REPLACE function SP_INDEX_COLUMNS (
  index_name varchar2
) return varchar2 is
  vcolumns varchar2(32000);
  CURSOR mycur IS
      SELECT i.table_name TableName 
          ,i.index_name IndexName 
          ,ic.COLUMN_NAME ColumnName
          ,e.COLUMN_EXPRESSION Expression 
        FROM user_indexes i 
        INNER JOIN USER_IND_COLUMNS ic ON i.index_name = ic.index_name 
        LEFT OUTER JOIN user_constraints c ON c.constraint_name = i.index_name 
        LEFT OUTER JOIN USER_IND_EXPRESSIONS e ON e.index_name is not null
            AND e.INDEX_NAME = i.index_name AND e.COLUMN_POSITION = ic.COLUMN_POSITION 
        WHERE (c.CONSTRAINT_TYPE = 'U' OR c.CONSTRAINT_TYPE IS NULL) AND i.generated='N' 
        AND i.index_name = UPPER(SP_INDEX_COLUMNS.index_name)
        ORDER BY i.index_name 
          ,i.table_name
          ,ic.COLUMN_POSITION;
BEGIN
  
  vcolumns := '';

  FOR myval IN mycur
    LOOP
      IF myval.Expression IS NULL THEN 
        vcolumns := vcolumns || myval.ColumnName || '::';
      ELSE
        -- the expresion can have a UPPER() clause, lets remove it
        vcolumns := vcolumns || SUBSTR(myval.Expression, 8, LENGTH(myval.Expression) - 9) || '::';
      END IF;
    END LOOP;
  
  -- Remove last separator
  vcolumns := SUBSTR(vcolumns, 0, LENGTH(vcolumns) - 2);
  
  RETURN UPPER(vcolumns);
  
END SP_INDEX_COLUMNS;
/

PROMPT '***** Prefix scripts end *****';


PROMPT '***** Body scripts start *****';

BEGIN
    dbms_output.put_line('     Step Drop Trigger: civc_invoice_fix_register starting...');
END;
/
BEGIN
  IF NOT SP_TRIGGER_EXISTS ('civc_invoice_fix_register') THEN
       dbms_output.put_line('      Trigger civc_invoice_fix_register already dropped');
  ELSE
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER civc_invoice_fix_register';
    dbms_output.put_line('     Trigger civc_invoice_fix_register dropped');
END;
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Drop Trigger: civc_invoice_fix_register end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Drop Trigger: civc_invoice_xref_fix_register starting...');
END;
/
BEGIN
  IF NOT SP_TRIGGER_EXISTS ('civc_invoice_xref_fix_register') THEN
       dbms_output.put_line('      Trigger civc_invoice_xref_fix_register already dropped');
  ELSE
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER civc_invoice_xref_fix_register';
    dbms_output.put_line('     Trigger civc_invoice_xref_fix_register dropped');
END;
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Drop Trigger: civc_invoice_xref_fix_register end.');
END;
/




PROMPT '***** Body scripts end *****';


-- Keep at end of the script

PROMPT '**************************************';
PROMPT 'Finalizing release version 22.0.0';
PROMPT '**************************************';
/

PROMPT '***************************************************************************';
PROMPT 'Database now un-hybridized to support clients running against the following versions:';
PROMPT '     22.0.0';
PROMPT 'This database is no longer compatible with clients running against legacy versions';
PROMPT 'previously supported while hybridized.  Please ensure that all clients are updated';
PROMPT 'to the appropriate release.';
PROMPT '***************************************************************************';
/
