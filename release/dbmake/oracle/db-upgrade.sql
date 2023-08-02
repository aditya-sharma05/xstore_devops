SET SERVEROUTPUT ON SIZE 100000

SPOOL dbupdate.log;

-- ***************************************************************************
-- This script will upgrade a database from version <source> of the Xstore base schema to version
-- <target>.  If upgrading from a schema version earlier than <source>, multiple upgrade scripts may
-- have to be applied in ascending order by <target>.
--
-- This script should only be run against a database previously created and defined by platform-
-- and version-compatible "create" and "define" scripts.
--
-- For certain supported platforms, this script may be run repeatedly against a target compatible
-- database, including an already upgraded one, without error or data loss.  Please consult the
-- Xstore R&D group for a listing of officially supported platforms for which this convenience is
-- provided.
--
-- Source version:  21.0.x
-- Target version:  22.0.0
-- DB platform:     Oracle 12c
-- ***************************************************************************
-- ***************************************************************************
-- ***************************************************************************

--
-- Variables
--
DEFINE dbDataTableSpace = '$(DbTblspace)_DATA';-- Name of data file tablespace
DEFINE dbIndexTableSpace = '$(DbTblspace)_INDEX';-- Name of index file tablespace 



-- 21.0.x -> 22.0.0
-- ***************************************************************************
-- ***************************************************************************

BEGIN
  dbms_output.put_line('**************************************');
  dbms_output.put_line('* UPGRADE to release 22.0');
  dbms_output.put_line('**************************************');
END;
/

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
    dbms_output.put_line('     Step Add Column: DTX[LegalEntity] Fields{[Field=companyBusinessName]} starting...');
END;
/
BEGIN
  IF SP_COLUMN_EXISTS ('loc_legal_entity','company_business_name') THEN
       dbms_output.put_line('      Column loc_legal_entity.company_business_name already exists');
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE loc_legal_entity ADD company_business_name VARCHAR2(254 char)';
    dbms_output.put_line('     Column loc_legal_entity.company_business_name created');
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Add Column: DTX[LegalEntity] Fields{[Field=companyBusinessName]} end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Add Column: DTX[RetailLocationTaxMapping] Fields{[Field=externalSystem]} starting...');
END;
/
BEGIN
  IF SP_COLUMN_EXISTS ('tax_rtl_loc_tax_mapping','external_system') THEN
       dbms_output.put_line('      Column tax_rtl_loc_tax_mapping.external_system already exists');
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE tax_rtl_loc_tax_mapping ADD external_system VARCHAR2(60 char)';
    dbms_output.put_line('     Column tax_rtl_loc_tax_mapping.external_system created');
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Add Column: DTX[RetailLocationTaxMapping] Fields{[Field=externalSystem]} end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Add Table: DTX[SequenceJournal] starting...');
END;
/
BEGIN
  IF SP_TABLE_EXISTS ('COM_SEQUENCE_JOURNAL') THEN
       dbms_output.put_line('      Table com_sequence_journal already exists');
  ELSE
    EXECUTE IMMEDIATE 'CREATE TABLE com_sequence_journal(
organization_id NUMBER(10, 0),
rtl_loc_id NUMBER(10, 0),
wkstn_id NUMBER(19, 0),
sequence_id VARCHAR2(255 char),
sequence_mode VARCHAR2(30 char) DEFAULT ''ACTIVE'',
sequence_value VARCHAR2(60 char),
sequence_timestamp TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char)
)
TABLESPACE &dbDataTableSpace.
';
        dbms_output.put_line('      Table com_sequence_journal created');
    EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON com_sequence_journal TO POSUSERS,DBAUSERS';
  END IF;
END;
/

BEGIN
  IF SP_TABLE_EXISTS ('COM_SEQUENCE_JOURNAL_P') THEN
       dbms_output.put_line('      Table COM_SEQUENCE_JOURNAL_P already exists');
  ELSE
    CREATE_PROPERTY_TABLE('com_sequence_journal');
    dbms_output.put_line('     Table com_sequence_journal_P created');
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Add Table: DTX[SequenceJournal] end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Add Table: DTX[MerchHierarchyLevel] starting...');
END;
/
BEGIN
  IF SP_TABLE_EXISTS ('ITM_MERCH_HIERARCHY_LEVELS') THEN
       dbms_output.put_line('      Table itm_merch_hierarchy_levels already exists');
  ELSE
    EXECUTE IMMEDIATE 'CREATE TABLE itm_merch_hierarchy_levels(
organization_id NUMBER(10, 0) NOT NULL,
level_id NUMBER(10, 0) NOT NULL,
level_code VARCHAR2(30 char),
description VARCHAR2(150 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itmmerchhierarchylevels PRIMARY KEY (organization_id, level_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
';
        dbms_output.put_line('      Table itm_merch_hierarchy_levels created');
    EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON itm_merch_hierarchy_levels TO POSUSERS,DBAUSERS';
  END IF;
END;
/

BEGIN
  IF SP_TABLE_EXISTS ('ITM_MERCH_HIERARCHY_LEVELS_P') THEN
       dbms_output.put_line('      Table ITM_MERCH_HIERARCHY_LEVELS_P already exists');
  ELSE
    CREATE_PROPERTY_TABLE('itm_merch_hierarchy_levels');
    dbms_output.put_line('     Table itm_merch_hierarchy_levels_P created');
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Add Table: DTX[MerchHierarchyLevel] end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Add Table: DTX[ServiceResponseLog] starting...');
END;
/
BEGIN
  IF SP_TABLE_EXISTS ('CTL_SERVICE_RESPONSE_LOG') THEN
       dbms_output.put_line('      Table ctl_service_response_log already exists');
  ELSE
    EXECUTE IMMEDIATE 'CREATE TABLE ctl_service_response_log(
organization_id NUMBER(10, 0) NOT NULL,
system_id VARCHAR2(25 char) NOT NULL,
message_id VARCHAR2(255 char) NOT NULL,
message_count NUMBER(10, 0),
reference_id VARCHAR2(255 char),
error CLOB,
detail CLOB,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ctl_service_response_log PRIMARY KEY (organization_id, system_id, message_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
';
        dbms_output.put_line('      Table ctl_service_response_log created');
    EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_service_response_log TO POSUSERS,DBAUSERS';
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Add Table: DTX[ServiceResponseLog] end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Sets the correct workstation id when the invoice is issued on a different workstation than the transaction one starting...');
END;
/
UPDATE civc_invoice_xref t0
SET wkstn_id = (SELECT t1.wkstn_id
FROM trn_trans t1
INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
      FROM civc_invoice t2
      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = 'RETAIL_SALE' AND t2.gross_amt = t3.total OR t3.trans_typcode = 'DEFERRED_INVOICE')  AND t2.create_date between t3.create_date - (1/24/60/60) AND t3.create_date + (1/24/60/60)
      WHERE t3.organization_id is null) t4
ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = 'DEFERRED_INVOICE' AND t1.create_date between t4.create_date - (1/24/60/60) AND t4.create_date + (1/24/60/60) 
WHERE t0.organization_id = t4.organization_id AND t0.rtl_loc_id = t4.rtl_loc_id AND t0.business_year = t4.business_year AND t0.wkstn_id = t4.wkstn_id AND t0.sequence_nbr = t4.sequence_nbr)
WHERE EXISTS (SELECT 1
FROM trn_trans t1
INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
      FROM civc_invoice t2
      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = 'RETAIL_SALE' AND t2.gross_amt = t3.total OR t3.trans_typcode = 'DEFERRED_INVOICE') AND t2.create_date between t3.create_date - (1/24/60/60) AND t3.create_date + (1/24/60/60)
      WHERE t3.organization_id is null) t4
ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = 'DEFERRED_INVOICE' AND t1.create_date between t4.create_date - (1/24/60/60) AND t4.create_date + (1/24/60/60) 
WHERE t0.organization_id = t4.organization_id AND t0.rtl_loc_id = t4.rtl_loc_id AND t0.business_year = t4.business_year AND t0.wkstn_id = t4.wkstn_id AND t0.sequence_nbr = t4.sequence_nbr);
/

UPDATE civc_invoice t0
SET wkstn_id = (SELECT t1.wkstn_id
FROM trn_trans t1
INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
      FROM civc_invoice t2
      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = 'RETAIL_SALE' AND t2.gross_amt = t3.total OR t3.trans_typcode = 'DEFERRED_INVOICE') AND t2.create_date between t3.create_date - (1/24/60/60) AND t3.create_date + (1/24/60/60)
      WHERE t3.organization_id is null) t4
ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = 'DEFERRED_INVOICE' AND t1.create_date between t4.create_date - (1/24/60/60) AND t4.create_date + (1/24/60/60) 
WHERE t0.organization_id = t4.organization_id AND t0.rtl_loc_id = t4.rtl_loc_id AND t0.business_year = t4.business_year AND t0.wkstn_id = t4.wkstn_id AND t0.sequence_nbr = t4.sequence_nbr)
WHERE EXISTS (SELECT 1
FROM trn_trans t1
INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
      FROM civc_invoice t2
      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = 'RETAIL_SALE' AND t2.gross_amt = t3.total OR t3.trans_typcode = 'DEFERRED_INVOICE') AND t2.create_date between t3.create_date - (1/24/60/60) AND t3.create_date + (1/24/60/60)
      WHERE t3.organization_id is null) t4
ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = 'DEFERRED_INVOICE' AND t1.create_date between t4.create_date - (1/24/60/60) AND t4.create_date + (1/24/60/60) 
WHERE t0.organization_id = t4.organization_id AND t0.rtl_loc_id = t4.rtl_loc_id AND t0.business_year = t4.business_year AND t0.wkstn_id = t4.wkstn_id AND t0.sequence_nbr = t4.sequence_nbr);
/
BEGIN
    dbms_output.put_line('     Step Sets the correct workstation id when the invoice is issued on a different workstation than the transaction one end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Fixing the error introduced in V19 with the conversion of the invoice reports starting...');
END;
/
BEGIN
    UPDATE trn_report_data t0
    SET report_id = (SELECT t2.invoice_type
    FROM trn_report_data t1
    INNER JOIN civc_invoice t2 ON t1.organization_id = t2.organization_id AND t1.rtl_loc_id = t2.rtl_loc_id AND t1.business_date = t2.business_date AND t1.wkstn_id = t2.wkstn_id AND t1.trans_seq = t2.invoice_trans_seq
    WHERE t0.organization_id = t1.organization_id AND t0.rtl_loc_id = t1.rtl_loc_id AND t0.business_date = t1.business_date AND t0.wkstn_id = t1.wkstn_id AND t0.trans_seq = t1.trans_seq
    AND t0.report_id = 'INVOICE' AND t2.invoice_type = 'CREDIT_NOTE')
    WHERE EXISTS (SELECT 1
    FROM trn_report_data t1
    INNER JOIN civc_invoice t2 ON t1.organization_id = t2.organization_id AND t1.rtl_loc_id = t2.rtl_loc_id AND t1.business_date = t2.business_date AND t1.wkstn_id = t2.wkstn_id AND t1.trans_seq = t2.invoice_trans_seq
    WHERE t0.organization_id = t1.organization_id AND t0.rtl_loc_id = t1.rtl_loc_id AND t0.business_date = t1.business_date AND t0.wkstn_id = t1.wkstn_id AND t0.trans_seq = t1.trans_seq
    AND t0.report_id = 'INVOICE' AND t2.invoice_type = 'CREDIT_NOTE');
    dbms_output.put_line(CONCAT('Error previously introduced with the conversion of the report fixed: ', SQL%rowcount));
END;
/
BEGIN
    dbms_output.put_line('     Step Fixing the error introduced in V19 with the conversion of the invoice reports end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Add Table: DTX[TemporaryTransactionStorage] starting...');
END;
/
BEGIN
  IF SP_TABLE_EXISTS ('TRN_TEMP_TRANS') THEN
       dbms_output.put_line('      Table trn_temp_trans already exists');
  ELSE
    EXECUTE IMMEDIATE 'CREATE TABLE trn_temp_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
status_code VARCHAR2(30 char),
tran_data BLOB,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_temp_trans PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
';
        dbms_output.put_line('      Table trn_temp_trans created');
    EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON trn_temp_trans TO POSUSERS,DBAUSERS';
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Add Table: DTX[TemporaryTransactionStorage] end.');
END;
/



BEGIN
    dbms_output.put_line('     Step If trn_temp_trans.tran_data is a clob, drop it and add as a blob. starting...');
END;
/
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM ALL_TAB_COLS
    WHERE OWNER = UPPER('$(DbSchema)') AND TABLE_NAME = 'TRN_TEMP_TRANS' AND COLUMN_NAME='TRAN_DATA' AND DATA_TYPE='CLOB';

    IF li_rowcnt = 1 THEN
        EXECUTE IMMEDIATE 'TRUNCATE TABLE trn_temp_trans';
        DBMS_OUTPUT.PUT_LINE('      trn_temp_trans.tran_data truncated');
        EXECUTE IMMEDIATE 'ALTER TABLE trn_temp_trans DROP COLUMN tran_data';
        DBMS_OUTPUT.PUT_LINE('     trn_temp_trans.tran_data clob dropped');
        EXECUTE IMMEDIATE 'ALTER TABLE trn_temp_trans ADD tran_data blob';
        DBMS_OUTPUT.PUT_LINE('     trn_temp_trans.tran_data blob added');
    END IF;
END;
/
BEGIN
    dbms_output.put_line('     Step If trn_temp_trans.tran_data is a clob, drop it and add as a blob. end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Add Index: DTX[DatabaseTranslation] Index[IDX_COM_TRANSLATIONS_ORG_KEY] starting...');
END;
/
DECLARE pk_name varchar2(256) := '';
BEGIN
  IF SP_INDEX_EXISTS ('IDX_COM_TRANSLATIONS_ORG_KEY') THEN
    IF SP_INDEX_COLUMNS ('IDX_COM_TRANSLATIONS_ORG_KEY')='ORGANIZATION_ID::TRANSLATION_KEY' THEN
      dbms_output.put_line('     Index IDX_COM_TRANSLATIONS_ORG_KEY already defined correctly');
    ELSE
  pk_name := SP_PK_CONSTRAINT_EXISTS('com_translations');
  IF pk_name = 'NOT_FOUND'  THEN
      dbms_output.put_line('     PK com_translations is missing');
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE com_translations DROP CONSTRAINT ' || pk_name || '';
    dbms_output.put_line('     PK com_translations dropped');
  END IF;

  IF NOT SP_INDEX_EXISTS ('IDX_COM_TRANSLATIONS_ORG_KEY') THEN
      dbms_output.put_line('     Index IDX_COM_TRANSLATIONS_ORG_KEY is missing');
  ELSE
    EXECUTE IMMEDIATE 'DROP INDEX IDX_COM_TRANSLATIONS_ORG_KEY';
    dbms_output.put_line('     Index IDX_COM_TRANSLATIONS_ORG_KEY dropped');
  END IF;

  pk_name := SP_PK_CONSTRAINT_EXISTS('com_translations');
  IF pk_name <> 'NOT_FOUND'  THEN
      dbms_output.put_line('     PK com_translations already exists');
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE com_translations ADD CONSTRAINT pk_com_translations PRIMARY KEY (organization_id, locale, translation_key) USING INDEX TABLESPACE &dbIndexTableSpace.';
    dbms_output.put_line('     PK pk_com_translations created');
  END IF;

    EXECUTE IMMEDIATE 'CREATE INDEX IDX_COM_TRANSLATIONS_ORG_KEY ON com_translations(organization_id, translation_key)
        TABLESPACE &dbIndexTableSpace.';
    dbms_output.put_line('     Index IDX_COM_TRANSLATIONS_ORG_KEY created');
  END IF;

  ELSE

  pk_name := SP_PK_CONSTRAINT_EXISTS('com_translations');
  IF pk_name <> 'NOT_FOUND'  THEN
      dbms_output.put_line('     PK com_translations already exists');
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE com_translations ADD CONSTRAINT pk_com_translations PRIMARY KEY (organization_id, locale, translation_key) USING INDEX TABLESPACE &dbIndexTableSpace.';
    dbms_output.put_line('     PK pk_com_translations created');
  END IF;

    EXECUTE IMMEDIATE 'CREATE INDEX IDX_COM_TRANSLATIONS_ORG_KEY ON com_translations(organization_id, translation_key)
        TABLESPACE &dbIndexTableSpace.';
    dbms_output.put_line('     Index IDX_COM_TRANSLATIONS_ORG_KEY created');
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Add Index: DTX[DatabaseTranslation] Index[IDX_COM_TRANSLATIONS_ORG_KEY] end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Add Table: DTX[TokenSigningData] starting...');
END;
/
BEGIN
  IF SP_TABLE_EXISTS ('SEC_TOKEN_SIGNING_DATA') THEN
       dbms_output.put_line('      Table sec_token_signing_data already exists');
  ELSE
    EXECUTE IMMEDIATE 'CREATE TABLE sec_token_signing_data(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
effective_datetime TIMESTAMP(6) NOT NULL,
expiration_datetime TIMESTAMP(6) NOT NULL,
key_id VARCHAR2(36 char) NOT NULL,
inactive_flag NUMBER(1, 0),
key_algorithm VARCHAR2(10 char) NOT NULL,
signature_algorithm VARCHAR2(10 char) NOT NULL,
private_key_format VARCHAR2(10 char) NOT NULL,
encrypted_private_key CLOB NOT NULL,
public_key_format VARCHAR2(10 char) NOT NULL,
public_key CLOB NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_sec_token_signing_data PRIMARY KEY (organization_id, rtl_loc_id, effective_datetime) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
';
        dbms_output.put_line('      Table sec_token_signing_data created');
    EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON sec_token_signing_data TO POSUSERS,DBAUSERS';
  END IF;
END;
/

DECLARE pk_name varchar2(256) := '';
BEGIN
  IF SP_INDEX_EXISTS ('IDX_TOKEN_SIGNING_DATA_ID') THEN
    IF SP_INDEX_COLUMNS ('IDX_TOKEN_SIGNING_DATA_ID')='ORGANIZATION_ID::KEY_ID' THEN
      dbms_output.put_line('     Index IDX_TOKEN_SIGNING_DATA_ID already defined correctly');
    ELSE
  pk_name := SP_PK_CONSTRAINT_EXISTS('sec_token_signing_data');
  IF pk_name = 'NOT_FOUND'  THEN
      dbms_output.put_line('     PK sec_token_signing_data is missing');
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE sec_token_signing_data DROP CONSTRAINT ' || pk_name || '';
    dbms_output.put_line('     PK sec_token_signing_data dropped');
  END IF;

  IF NOT SP_INDEX_EXISTS ('IDX_TOKEN_SIGNING_DATA_ID') THEN
      dbms_output.put_line('     Index IDX_TOKEN_SIGNING_DATA_ID is missing');
  ELSE
    EXECUTE IMMEDIATE 'DROP INDEX IDX_TOKEN_SIGNING_DATA_ID';
    dbms_output.put_line('     Index IDX_TOKEN_SIGNING_DATA_ID dropped');
  END IF;

  pk_name := SP_PK_CONSTRAINT_EXISTS('sec_token_signing_data');
  IF pk_name <> 'NOT_FOUND'  THEN
      dbms_output.put_line('     PK sec_token_signing_data already exists');
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE sec_token_signing_data ADD CONSTRAINT pk_sec_token_signing_data PRIMARY KEY (organization_id, rtl_loc_id, effective_datetime) USING INDEX TABLESPACE &dbIndexTableSpace.';
    dbms_output.put_line('     PK pk_sec_token_signing_data created');
  END IF;

    EXECUTE IMMEDIATE 'CREATE INDEX IDX_TOKEN_SIGNING_DATA_ID ON sec_token_signing_data(organization_id, UPPER(key_id))
        TABLESPACE &dbIndexTableSpace.';
    dbms_output.put_line('     Index IDX_TOKEN_SIGNING_DATA_ID created');
  END IF;

  ELSE

  pk_name := SP_PK_CONSTRAINT_EXISTS('sec_token_signing_data');
  IF pk_name <> 'NOT_FOUND'  THEN
      dbms_output.put_line('     PK sec_token_signing_data already exists');
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE sec_token_signing_data ADD CONSTRAINT pk_sec_token_signing_data PRIMARY KEY (organization_id, rtl_loc_id, effective_datetime) USING INDEX TABLESPACE &dbIndexTableSpace.';
    dbms_output.put_line('     PK pk_sec_token_signing_data created');
  END IF;

    EXECUTE IMMEDIATE 'CREATE INDEX IDX_TOKEN_SIGNING_DATA_ID ON sec_token_signing_data(organization_id, UPPER(key_id))
        TABLESPACE &dbIndexTableSpace.';
    dbms_output.put_line('     Index IDX_TOKEN_SIGNING_DATA_ID created');
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Add Table: DTX[TokenSigningData] end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Add Column: DTX[TenderLineItem] Fields{[Field=tenderDescription]} starting...');
END;
/
BEGIN
  IF SP_COLUMN_EXISTS ('ttr_tndr_lineitm','tndr_description') THEN
       dbms_output.put_line('      Column ttr_tndr_lineitm.tndr_description already exists');
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE ttr_tndr_lineitm ADD tndr_description VARCHAR2(254 char)';
    dbms_output.put_line('     Column ttr_tndr_lineitm.tndr_description created');
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Add Column: DTX[TenderLineItem] Fields{[Field=tenderDescription]} end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Add Table: DTX[GroupRole] starting...');
END;
/
BEGIN
  IF SP_TABLE_EXISTS ('SEC_GROUP_ROLES') THEN
       dbms_output.put_line('      Table sec_group_roles already exists');
  ELSE
    EXECUTE IMMEDIATE 'CREATE TABLE sec_group_roles(
organization_id NUMBER(10, 0) NOT NULL,
group_id VARCHAR2(60 char) NOT NULL,
role VARCHAR2(50 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_sec_group_roles PRIMARY KEY (organization_id, group_id, role) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
';
        dbms_output.put_line('      Table sec_group_roles created');
    EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON sec_group_roles TO POSUSERS,DBAUSERS';
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Add Table: DTX[GroupRole] end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Alter Column: DTX[UserRole] Fields{[Field=roleCode]} starting...');
END;
/
BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE sec_user_role MODIFY role_code VARCHAR2(50 char) DEFAULT (null)';
    dbms_output.put_line('     Column sec_user_role.role_code modify');
END;
/
BEGIN
  IF NOT SP_IS_NULLABLE ('sec_user_role','role_code') THEN
      dbms_output.put_line('     Column sec_user_role.role_code already not nullable');
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE sec_user_role MODIFY role_code NOT NULL';
    dbms_output.put_line('     Column sec_user_role.role_code modify');
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Alter Column: DTX[UserRole] Fields{[Field=roleCode]} end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Drop Primary Key: DTX[ReceiptLookup] starting...');
END;
/
DECLARE pk_name varchar2(256) := SP_PK_CONSTRAINT_EXISTS('trn_receipt_lookup');
BEGIN
  IF pk_name = 'NOT_FOUND'  THEN
      dbms_output.put_line('     PK trn_receipt_lookup is missing');
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE trn_receipt_lookup DROP CONSTRAINT ' || pk_name || '';
    dbms_output.put_line('     PK trn_receipt_lookup dropped');
  END IF;
END;
/

DECLARE pk_name varchar2(256) := SP_PK_CONSTRAINT_EXISTS('trn_receipt_lookup_P');
BEGIN
  IF pk_name = 'NOT_FOUND'  THEN
      dbms_output.put_line('     PK trn_receipt_lookup_P is missing');
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE trn_receipt_lookup_P DROP CONSTRAINT ' || pk_name || '';
    dbms_output.put_line('     PK trn_receipt_lookup_P dropped');
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Drop Primary Key: DTX[ReceiptLookup] end.');
END;
/



BEGIN
    dbms_output.put_line('     Step Add Primary Key: DTX[ReceiptLookup] starting...');
END;
/
DECLARE pk_name varchar2(256) := SP_PK_CONSTRAINT_EXISTS('trn_receipt_lookup');
BEGIN
  IF pk_name <> 'NOT_FOUND'  THEN
      dbms_output.put_line('     PK trn_receipt_lookup already exists');
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE trn_receipt_lookup ADD CONSTRAINT pk_trn_receipt_lookup PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq, receipt_id) USING INDEX TABLESPACE &dbIndexTableSpace.';
    dbms_output.put_line('     PK pk_trn_receipt_lookup created');
  END IF;
END;
/

DECLARE pk_name varchar2(256) := SP_PK_CONSTRAINT_EXISTS('trn_receipt_lookup_P');
BEGIN
  IF pk_name <> 'NOT_FOUND'  THEN
      dbms_output.put_line('     PK trn_receipt_lookup_P already exists');
  ELSE
    EXECUTE IMMEDIATE 'ALTER TABLE trn_receipt_lookup_P ADD CONSTRAINT pk_trn_receipt_lookup_P PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq, receipt_id, property_code) USING INDEX TABLESPACE &dbIndexTableSpace.';
    dbms_output.put_line('     PK pk_trn_receipt_lookup_P created');
  END IF;
END;
/

BEGIN
    dbms_output.put_line('     Step Add Primary Key: DTX[ReceiptLookup] end.');
END;
/



BEGIN
    dbms_output.put_line('     Step ORACLE: Fix to avoid unique constraint exception starting...');
END;
/
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
-- ... .....        Initial Version
-- PGH  02/23/10    Removed the currencyid paramerer, then joining the loc_rtl_loc table to get the default
--                  currencyid for the location.  If the default is not set, defaulting to 'USD'. 
-- BCW  06/21/12    Updated per Emily Tan's instructions.
-- BCW  12/06/13    Replaced the sale cursor by writing the transaction line item directly into the rpt_sale_line table.
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING PROCEDURE SP_FLASH');

CREATE OR REPLACE PROCEDURE sp_flash 
  (argOrganizationId    IN NUMBER, 
   argRetailLocationId  IN NUMBER, 
   argBusinessDate      IN DATE, 
   argWrkstnId          IN NUMBER, 
   argTransSeq          IN NUMBER) 
AUTHID CURRENT_USER 
IS

myerror exception;
myreturn exception;

-- Arguments
pvOrganizationId        NUMBER(10);
pvRetailLocationId      NUMBER(10); 
pvBusinessDate          DATE;
pvWrkstnId              NUMBER(20,0);
pvTransSeq              NUMBER(20,0);

-- Quantities
vActualQuantity         NUMBER (11,2);
vGrossQuantity          NUMBER (11,2);
vQuantity               NUMBER (11,2);
vTotQuantity            NUMBER (11,2);

-- Amounts
vNetAmount              NUMBER (17,6);
vGrossAmount            NUMBER (17,6);
vTotGrossAmt            NUMBER (17,6);
vTotNetAmt              NUMBER (17,6);
vDiscountAmt            NUMBER (17,6);
vOverrideAmt            NUMBER (17,6);
vPaidAmt                NUMBER (17,6);
vTenderAmt              NUMBER (17,6);
vForeign_amt            NUMBER (17,6);
vLayawayPrice           NUMBER(17,6);
vUnitPrice              NUMBER (17,6);

-- Non Physical Items
vNonPhys                VARCHAR2(30 char);
vNonPhysSaleType        VARCHAR2(30 char);
vNonPhysType            VARCHAR2(30 char);
vNonPhysPrice           NUMBER (17,6);
vNonPhysQuantity        NUMBER (11,2);

-- Status codes
vTransStatcode          VARCHAR2(30 char);
vTransTypcode           VARCHAR2(30 char);
vSaleLineItmTypcode     VARCHAR2(30 char);
vTndrStatcode           VARCHAR2(60 char);
vLineitemStatcode       VARCHAR2(30 char);

-- others
vTransTimeStamp         TIMESTAMP;
vTransDate              TIMESTAMP;
vTransCount             NUMBER(10);
vTndrCount              NUMBER(10);
vPostVoidFlag           NUMBER(1);
vReturnFlag             NUMBER(1);
vTaxTotal               NUMBER (17,6);
vPaid                   VARCHAR2(30 char);
vLineEnum               VARCHAR2(150 char);
vTndrId                 VARCHAR2(60 char);
vItemId                 VARCHAR2(60 char);
vRtransLineItmSeq       NUMBER(10);
vDepartmentId           VARCHAR2(90 char);
vTndridProp             VARCHAR2(60 char);
vCurrencyId             VARCHAR2(3 char);
vTndrTypCode            VARCHAR2(30 char);

vSerialNbr              VARCHAR2(60 char);
vPriceModAmt            NUMBER(17,6);
vPriceModReascode       VARCHAR2(60 char);
vNonPhysExcludeFlag     NUMBER(1);
vCustPartyId            VARCHAR2(60 char);
vCustLastName           VARCHAR2(90 char);
vCustFirstName          VARCHAR2(90 char);
vItemDesc               VARCHAR2(254 char);
vBeginTimeInt           NUMBER(10);

-- counts
vRowCnt                 NUMBER(10);
vCntTrans               NUMBER(10);
vCntTndrCtl             NUMBER(10);
vCntPostVoid            NUMBER(10);
vCntRevTrans            NUMBER(10);
vCntNonPhysItm          NUMBER(10);
vCntNonPhys             NUMBER(10);
vCntCust                NUMBER(10);
vCntItem                NUMBER(10);
vCntParty               NUMBER(10);

-- cursors

CURSOR tenderCursor IS 
    SELECT t.amt, t.foreign_amt, t.tndr_id, t.tndr_statcode, tr.string_value, tnd.tndr_typcode 
        FROM TTR_TNDR_LINEITM t 
        inner join TRL_RTRANS_LINEITM r ON t.organization_id=r.organization_id
                                       AND t.rtl_loc_id=r.rtl_loc_id
                                       AND t.wkstn_id=r.wkstn_id
                                       AND t.trans_seq=r.trans_seq
                                       AND t.business_date=r.business_date
                                       AND t.rtrans_lineitm_seq=r.rtrans_lineitm_seq
        inner join TND_TNDR tnd ON t.organization_id=tnd.organization_id
                                       AND t.tndr_id=tnd.tndr_id                                   
    left outer join trl_rtrans_lineitm_p tr on tr.organization_id=r.organization_id
                    and tr.rtl_loc_id=r.rtl_loc_id
                    and tr.wkstn_id=r.wkstn_id
                    and tr.trans_seq=r.trans_seq
                    and tr.business_date=r.business_date
                    and tr.rtrans_lineitm_seq=r.rtrans_lineitm_seq
                    and lower(property_code) = 'tender_id'
        WHERE t.organization_id = pvOrganizationId
          AND t.rtl_loc_id = pvRetailLocationId
          AND t.wkstn_id = pvWrkstnId
          AND t.trans_seq = pvTransSeq
          AND t.business_date = pvBusinessDate
          AND r.void_flag = 0
          AND t.tndr_id <> 'ACCOUNT_CREDIT';

CURSOR postVoidTenderCursor IS 
    SELECT t.amt, t.foreign_amt, t.tndr_id, t.tndr_statcode, tr.string_value 
        FROM TTR_TNDR_LINEITM t 
        inner join TRL_RTRANS_LINEITM r ON t.organization_id=r.organization_id
                                       AND t.rtl_loc_id=r.rtl_loc_id
                                       AND t.wkstn_id=r.wkstn_id
                                       AND t.trans_seq=r.trans_seq
                                       AND t.business_date=r.business_date
                                       AND t.rtrans_lineitm_seq=r.rtrans_lineitm_seq
    left outer join trl_rtrans_lineitm_p tr on tr.organization_id=r.organization_id
                    and tr.rtl_loc_id=r.rtl_loc_id
                    and tr.wkstn_id=r.wkstn_id
                    and tr.trans_seq=r.trans_seq
                    and tr.business_date=r.business_date
                    and tr.rtrans_lineitm_seq=r.rtrans_lineitm_seq
                    and lower(property_code) = 'tender_id'
        WHERE t.organization_id = pvOrganizationId
          AND t.rtl_loc_id = pvRetailLocationId
          AND t.wkstn_id = pvWrkstnId
          AND t.trans_seq = pvTransSeq
          AND t.business_date = pvBusinessDate
          AND r.void_flag = 0
      AND t.tndr_id <> 'ACCOUNT_CREDIT';

CURSOR saleCursor IS
       select rsl.item_id,
       sale_lineitm_typcode,
       actual_quantity,
       unit_price,
       case vPostVoidFlag when 1 then -1 else 1 end * coalesce(gross_amt,0),
       case when return_flag=vPostVoidFlag then 1 else -1 end * coalesce(gross_quantity,0),
       merch_level_1,
       case vPostVoidFlag when 1 then -1 else 1 end * coalesce(net_amt,0),
       case when return_flag=vPostVoidFlag then 1 else -1 end * coalesce(quantity,0),
     return_flag 
       from rpt_sale_line rsl
     left join itm_non_phys_item inp on rsl.item_id=inp.item_id and rsl.organization_id=inp.organization_id
       WHERE rsl.organization_id = pvOrganizationId
          AND rtl_loc_id = pvRetailLocationId
          AND wkstn_id = pvWrkstnId
          AND business_date = pvBusinessDate
          AND trans_seq = pvTransSeq
      and QUANTITY <> 0
      and sale_lineitm_typcode not in ('ONHOLD','WORK_ORDER')
      and coalesce(exclude_from_net_sales_flag,0)=0;

-- Declarations end 

BEGIN
    -- initializations of args
    pvOrganizationId      := argOrganizationId;
    pvRetailLocationId    := argRetailLocationId;
    pvWrkstnId            := argWrkstnId;
    pvBusinessDate        := argBusinessDate;
    pvTransSeq            := argTransSeq;

    BEGIN
    SELECT tt.trans_statcode,
           tt.trans_typcode, 
           tt.begin_datetime, 
           tt.trans_date,
           tt.taxtotal, 
           tt.post_void_flag, 
           tt.begin_time_int,
           coalesce(t.currency_id, rl.currency_id)
        INTO vTransStatcode, 
             vTransTypcode, 
             vTransTimeStamp, 
             vTransDate,
             vTaxTotal, 
             vPostVoidFlag, 
             vBeginTimeInt,
             vCurrencyID
        FROM TRN_TRANS tt  
            LEFT JOIN loc_rtl_loc rl on tt.organization_id = rl.organization_id and tt.rtl_loc_id = rl.rtl_loc_id
      LEFT JOIN (select max(currency_id) currency_id,ttl.organization_id,ttl.rtl_loc_id,ttl.wkstn_id,ttl.business_date,ttl.trans_seq
      from ttr_tndr_lineitm ttl
      inner join tnd_tndr tnd on ttl.organization_id=tnd.organization_id and ttl.tndr_id=tnd.tndr_id
      group by ttl.organization_id,ttl.rtl_loc_id,ttl.wkstn_id,ttl.business_date,ttl.trans_seq) t ON
      tt.organization_id = t.organization_id
          AND tt.rtl_loc_id = t.rtl_loc_id
          AND tt.wkstn_id = t.wkstn_id
          AND tt.business_date = t.business_date
          AND tt.trans_seq = t.trans_seq
        WHERE tt.organization_id = pvOrganizationId
          AND tt.rtl_loc_id = pvRetailLocationId
          AND tt.wkstn_id = pvWrkstnId
          AND tt.business_date = pvBusinessDate
          AND tt.trans_seq = pvTransSeq;
    EXCEPTION
        WHEN no_data_found THEN
        NULL;
    END;
    
    vCntTrans := SQL%ROWCOUNT;
    
    IF vCntTrans = 1 THEN 
    
    -- so update the column on trn trans
        UPDATE TRN_TRANS SET flash_sales_flag = 1
            WHERE organization_id = pvOrganizationId
            AND rtl_loc_id = pvRetailLocationId
            AND wkstn_id = pvWrkstnId
            AND trans_seq = pvTransSeq
            AND business_date = pvBusinessDate;
    ELSE
        -- /* Invalid transaction */
        raise myerror;
        
    END IF;

    vTransCount := 1; -- /* initializing the transaction count */

  select count(*) into vCntTrans from rpt_sale_line
    WHERE organization_id = pvOrganizationId
    AND rtl_loc_id = pvRetailLocationId
    AND wkstn_id = pvWrkstnId
    AND trans_seq = pvTransSeq
    AND business_date = pvBusinessDate;

  IF vCntTrans = 0 AND vPostVoidFlag = 1 THEN
    insert into rpt_sale_line
    (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq,
    quantity, actual_quantity, gross_quantity, unit_price, net_amt, gross_amt, item_id, 
    item_desc, merch_level_1, serial_nbr, return_flag, override_amt, trans_timestamp, trans_date,
    discount_amt, cust_party_id, last_name, first_name, trans_statcode, sale_lineitm_typcode, begin_time_int, exclude_from_net_sales_flag)
    select tsl.organization_id, tsl.rtl_loc_id, tsl.business_date, tsl.wkstn_id, tsl.trans_seq, tsl.rtrans_lineitm_seq,
    tsl.net_quantity, tsl.quantity, tsl.gross_quantity, tsl.unit_price,
    -- For VAT taxed items there are rounding problems by which the usage of the tsl.net_amt could create problems.
    -- So, we are calculating it using the tax amount which could have more decimals and because that it is more accurate
    case when vat_amt is null then tsl.net_amt else tsl.gross_amt-tsl.vat_amt-coalesce(d.discount_amt,0) end, 
    tsl.gross_amt, tsl.item_id,
    i.DESCRIPTION, coalesce(tsl.merch_level_1,i.MERCH_LEVEL_1,'DEFAULT'), tsl.serial_nbr, tsl.return_flag, coalesce(o.override_amt,0), vTransTimeStamp, vTransDate,
    coalesce(d.discount_amt,0), tr.cust_party_id, cust.last_name, cust.first_name, 'VOID', tsl.sale_lineitm_typcode, vBeginTimeInt, tsl.exclude_from_net_sales_flag
    from trl_sale_lineitm tsl
    inner join trl_rtrans_lineitm r
    on tsl.organization_id=r.organization_id
    and tsl.rtl_loc_id=r.rtl_loc_id
    and tsl.wkstn_id=r.wkstn_id
    and tsl.trans_seq=r.trans_seq
    and tsl.business_date=r.business_date
    and tsl.rtrans_lineitm_seq=r.rtrans_lineitm_seq
    and r.rtrans_lineitm_typcode = 'ITEM'
    left join xom_order_mod xom
    on tsl.organization_id=xom.organization_id
    and tsl.rtl_loc_id=xom.rtl_loc_id
    and tsl.wkstn_id=xom.wkstn_id
    and tsl.trans_seq=xom.trans_seq
    and tsl.business_date=xom.business_date
    and tsl.rtrans_lineitm_seq=xom.rtrans_lineitm_seq
    left join xom_order_line_detail xold
    on xom.organization_id=xold.organization_id
    and xom.order_id=xold.order_id
    and xom.detail_seq=xold.detail_seq
    and xom.detail_line_number=xold.detail_line_number
    left join itm_item i
    on tsl.organization_id=i.ORGANIZATION_ID
    and tsl.item_id=i.ITEM_ID
    left join (select * from (select extended_amt override_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
            FROM trl_rtl_price_mod
            WHERE void_flag = 0 and rtl_price_mod_reascode='PRICE_OVERRIDE' order by organization_id, rtl_loc_id, business_date, wkstn_id, rtrans_lineitm_seq, trans_seq, rtl_price_mod_seq_nbr desc) where rownum =1) o
    on tsl.organization_id = o.organization_id 
      AND tsl.rtl_loc_id = o.rtl_loc_id
      AND tsl.business_date = o.business_date 
      AND tsl.wkstn_id = o.wkstn_id 
      AND tsl.trans_seq = o.trans_seq
      AND tsl.rtrans_lineitm_seq = o.rtrans_lineitm_seq
    left join (select sum(extended_amt) discount_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
      FROM trl_rtl_price_mod
      WHERE void_flag = 0 and rtl_price_mod_reascode in ('LINE_ITEM_DISCOUNT', 'TRANSACTION_DISCOUNT', 'GROUP_DISCOUNT', 'NEW_PRICE_RULE', 'DEAL', 'ENTITLEMENT')
      group by organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq) d
    on tsl.organization_id = d.organization_id 
      AND tsl.rtl_loc_id = d.rtl_loc_id
      AND tsl.business_date = d.business_date 
      AND tsl.wkstn_id = d.wkstn_id 
      AND tsl.trans_seq = d.trans_seq
      AND tsl.rtrans_lineitm_seq = d.rtrans_lineitm_seq
    left join trl_rtrans tr
    on tsl.organization_id = tr.organization_id 
      AND tsl.rtl_loc_id = tr.rtl_loc_id
      AND tsl.business_date = tr.business_date 
      AND tsl.wkstn_id = tr.wkstn_id 
      AND tsl.trans_seq = tr.trans_seq
    left join crm_party cust
    on tsl.organization_id = cust.organization_id 
      AND tr.cust_party_id = cust.party_id
    where tsl.organization_id = pvOrganizationId
    and tsl.rtl_loc_id = pvRetailLocationId
    and tsl.wkstn_id = pvWrkstnId
    and tsl.business_date = pvBusinessDate
    and tsl.trans_seq = pvTransSeq
    and r.void_flag=0
    and ((tsl.SALE_LINEITM_TYPCODE <> 'ORDER'and (xom.detail_type IS NULL OR xold.status_code = 'FULFILLED') )
    or (tsl.SALE_LINEITM_TYPCODE = 'ORDER' and xom.detail_type in ('FEE', 'PAYMENT') ));
    raise myreturn;
  END IF;

    -- collect transaction data
    IF ABS(vTaxTotal) > 0 AND vTransTypcode <> 'POST_VOID' AND vPostVoidFlag = 0 AND vTransStatcode = 'COMPLETE' THEN
      
        sp_ins_upd_flash_sales (pvOrganizationId, 
                                pvRetailLocationId, 
                                vTransDate,
                                pvWrkstnId, 
                                'TOTALTAX', 
                                1, 
                                vTaxTotal, 
                                vCurrencyId);
      
    END IF;

    IF vTransTypcode = 'TENDER_CONTROL' AND vPostVoidFlag = 0 THEN    -- process for paid in paid out 
    
        BEGIN
        SELECT  typcode, amt INTO vPaid, vPaidAmt 
            FROM TSN_TNDR_CONTROL_TRANS 
            WHERE typcode LIKE 'PAID%'
              AND organization_id = pvOrganizationId
              AND rtl_loc_id = pvRetailLocationId
              AND wkstn_id = pvWrkstnId
              AND trans_seq = pvTransSeq
              AND business_date = pvBusinessDate;
           EXCEPTION
        WHEN no_data_found THEN
            NULL;
        END;


        vCntTndrCtl := SQL%ROWCOUNT;
    
        IF vCntTndrCtl = 1 THEN   
            
                IF vTransStatcode = 'COMPLETE' THEN
                        -- it is paid in or paid out
                    IF vPaid = 'PAID_IN' OR vPaid = 'PAIDIN' THEN
                        vLineEnum := 'paidin';
                    ELSE
                        vLineEnum := 'paidout';
                    END IF; 
                        -- update flash sales                 
                        sp_ins_upd_flash_sales (pvOrganizationId, 
                                               pvRetailLocationId, 
                                               vTransDate,
                                               pvWrkstnId, 
                                               vLineEnum, 
                                               1, 
                                               vPaidAmt, 
                                               vCurrencyId);
                END IF;
        END IF;
    END IF;
  
  -- collect tenders  data
  IF vPostVoidFlag = 0 AND vTransTypcode <> 'POST_VOID' THEN
  BEGIN
    OPEN tenderCursor;
    LOOP
        FETCH tenderCursor INTO vTenderAmt, vForeign_amt, vTndrid, vTndrStatcode, vTndridProp, vTndrTypCode; 
        EXIT WHEN tenderCursor%NOTFOUND;
  
        IF vTndrTypCode='VOUCHER' OR vTndrStatcode <> 'Change' THEN
            vTndrCount := 1;-- only for original tenders
        ELSE 
            vTndrCount := 0;
        END IF;

        if vTndridProp IS NOT NULL THEN
           vTndrid := vTndridProp;
    end if;

       IF vLineEnum = 'paidout' THEN
            vTenderAmt := vTenderAmt * -1;
            vForeign_amt := vForeign_amt * -1;
        END IF;

        -- update flash
        IF vTransStatcode = 'COMPLETE' THEN
            sp_ins_upd_flash_sales (pvOrganizationId, 
                                    pvRetailLocationId, 
                                    vTransDate, 
                                    pvWrkstnId, 
                                    vTndrid, 
                                    vTndrCount, 
                                    vTenderAmt, 
                                    vCurrencyId);
        END IF;

        IF vTenderAmt > 0 AND vTransStatcode = 'COMPLETE' THEN
            sp_ins_upd_flash_sales (pvOrganizationId, 
                                    pvRetailLocationId, 
                                    vTransDate, 
                                    pvWrkstnId,
                                    'TendersTakenIn', 
                                    1, 
                                    vTenderAmt, 
                                    vCurrencyId);
        ELSE
            sp_ins_upd_flash_sales (pvOrganizationId, 
                                    pvRetailLocationId, 
                                    vTransDate, 
                                    pvWrkstnId, 
                                    'TendersRefunded', 
                                    1, 
                                    vTenderAmt, 
                                    vCurrencyId);
        END IF;
    END LOOP;
    CLOSE tenderCursor;
  EXCEPTION
    WHEN OTHERS THEN CLOSE tenderCursor;
  END;
  END IF;
  
  -- collect post void info
  IF vTransTypcode = 'POST_VOID' OR vPostVoidFlag = 1 THEN
      vTransCount := -1; /* reversing the count */
      IF vPostVoidFlag = 0 THEN
        vPostVoidFlag := 1;
      
            /* NOTE: From now on the parameter value carries the original post voided
                information rather than the current transaction information in 
                case of post void trans type. This will apply for sales data 
                processing.
            */
            BEGIN
            SELECT voided_org_id, voided_rtl_store_id, voided_wkstn_id, voided_business_date, voided_trans_id 
              INTO pvOrganizationId, pvRetailLocationId, pvWrkstnId, pvBusinessDate, pvTransSeq
              FROM TRN_POST_VOID_TRANS 
              WHERE organization_id = pvOrganizationId
                AND rtl_loc_id = pvRetailLocationId
                AND wkstn_id = pvWrkstnId
                AND business_date = pvBusinessDate
                AND trans_seq = pvTransSeq;
            EXCEPTION
                WHEN no_data_found THEN
                NULL;
            END;

            vCntPostVoid := SQL%ROWCOUNT;

            IF vCntPostVoid = 0 THEN      
              
                raise myerror; -- don't know the original post voided record
            END IF;

      select count(*) into vCntPostVoid from rpt_sale_line
      WHERE organization_id = pvOrganizationId
      AND rtl_loc_id = pvRetailLocationId
      AND wkstn_id = pvWrkstnId
      AND trans_seq = pvTransSeq
      AND business_date = pvBusinessDate
      AND trans_statcode = 'VOID';

      IF vCntPostVoid > 0 THEN
                raise myreturn; -- record already exists
      END IF;
    END IF;
    -- updating for postvoid
     UPDATE rpt_sale_line
       SET trans_statcode='VOID'
       WHERE organization_id = pvOrganizationId
         AND rtl_loc_id = pvRetailLocationId
         AND wkstn_id = pvWrkstnId
         AND business_date = pvBusinessDate
         AND trans_seq = pvTransSeq; 
        
      BEGIN
      SELECT typcode, amt INTO vPaid, vPaidAmt
        FROM TSN_TNDR_CONTROL_TRANS 
        WHERE typcode LIKE 'PAID%'
          AND organization_id = pvOrganizationId
          AND rtl_loc_id = pvRetailLocationId
          AND wkstn_id = pvWrkstnId
          AND trans_seq = pvTransSeq
          AND business_date = pvBusinessDate;
      EXCEPTION WHEN no_data_found THEN
          NULL;
      END;


      IF SQL%FOUND AND vTransStatcode = 'COMPLETE' THEN
        -- it is paid in or paid out
        IF vPaid = 'PAID_IN' OR vPaid = 'PAIDIN' THEN
            vLineEnum := 'paidin';
        ELSE
            vLineEnum := 'paidout';
        END IF;
        vPaidAmt := vPaidAmt * -1 ;

        -- update flash sales                 
        sp_ins_upd_flash_sales (pvOrganizationId, 
                                pvRetailLocationId, 
                                vTransDate,
                                pvWrkstnId, 
                                vLineEnum, 
                                -1, 
                                vPaidAmt, 
                                vCurrencyId);
      END IF;
    
        BEGIN
        SELECT taxtotal INTO vTaxTotal
          FROM TRN_TRANS 
          WHERE organization_id = pvOrganizationId
            AND rtl_loc_id = pvRetailLocationId
            AND wkstn_id = pvWrkstnId
            AND business_date = pvBusinessDate
            AND trans_seq = pvTransSeq;
        EXCEPTION WHEN no_data_found THEN
            NULL;
        END;
        
        vCntRevTrans := SQL%ROWCOUNT;
        
        IF vCntRevTrans = 1 THEN    
            IF ABS(vTaxTotal) > 0 AND vTransStatcode = 'COMPLETE' THEN
                vTaxTotal := vTaxTotal * -1 ;
                sp_ins_upd_flash_sales (pvOrganizationId,
                                        pvRetailLocationId,
                                        vTransDate,
                                        pvWrkstnId,
                                        'TOTALTAX',
                                        -1,
                                        vTaxTotal, 
                                        vCurrencyId);
            END IF;
        END IF;

        -- reverse tenders
    BEGIN
        OPEN postVoidTenderCursor;
        
        LOOP
            FETCH postVoidTenderCursor INTO vTenderAmt, vForeign_amt, vTndrid, vTndrStatcode, vTndridProp;
            EXIT WHEN postVoidTenderCursor%NOTFOUND;
          
            IF vTndrStatcode <> 'Change' THEN
              vTndrCount := -1 ; -- only for original tenders
            ELSE 
              vTndrCount := 0 ;
            END IF;
          
      if vTndridProp IS NOT NULL THEN
         vTndrid := vTndridProp;
      end if;

            -- update flash
            vTenderAmt := vTenderAmt * -1;

            IF vTransStatcode = 'COMPLETE' THEN
                sp_ins_upd_flash_sales (pvOrganizationId, 
                                        pvRetailLocationId, 
                                        vTransDate, 
                                        pvWrkstnId, 
                                        vTndrid, 
                                        vTndrCount, 
                                        vTenderAmt, 
                                        vCurrencyId);
            END IF;
            
            IF vTenderAmt < 0 AND vTransStatcode = 'COMPLETE' THEN
                sp_ins_upd_flash_sales (pvOrganizationId, 
                                        pvRetailLocationId, 
                                        vTransDate, 
                                        pvWrkstnId,
                                        'TendersTakenIn',
                                        -1, 
                                        vTenderAmt, 
                                        vCurrencyId);
            ELSE
                sp_ins_upd_flash_sales (pvOrganizationId, 
                                        pvRetailLocationId, 
                                        vTransDate, 
                                        pvWrkstnId,
                                        'TendersRefunded',
                                        -1, 
                                        vTenderAmt, 
                                        vCurrencyId);
            END IF;
        END LOOP;
        
        CLOSE postVoidTenderCursor;
    EXCEPTION
      WHEN OTHERS THEN CLOSE postVoidTenderCursor;
  END;
  END IF;
  
  -- collect sales data
          

IF vPostVoidFlag = 0 and vTransTypcode <> 'POST_VOID' THEN -- dont do it for rpt sale line
        -- sale item insert
         insert into rpt_sale_line
        (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq,
        quantity, actual_quantity, gross_quantity, unit_price, net_amt, gross_amt, item_id, 
        item_desc, merch_level_1, serial_nbr, return_flag, override_amt, trans_timestamp, trans_date,
        discount_amt, cust_party_id, last_name, first_name, trans_statcode, sale_lineitm_typcode, begin_time_int, exclude_from_net_sales_flag)
        select tsl.organization_id, tsl.rtl_loc_id, tsl.business_date, tsl.wkstn_id, tsl.trans_seq, tsl.rtrans_lineitm_seq,
        tsl.net_quantity, tsl.quantity, tsl.gross_quantity, tsl.unit_price,
        -- For VAT taxed items there are rounding problems by which the usage of the tsl.net_amt could create problems.
        -- So, we are calculating it using the tax amount which could have more decimals and because that it is more accurate
        case when vat_amt is null then tsl.net_amt else tsl.gross_amt-tsl.vat_amt-coalesce(d.discount_amt,0) end,
        tsl.gross_amt, tsl.item_id,
        i.DESCRIPTION, coalesce(tsl.merch_level_1,i.MERCH_LEVEL_1,'DEFAULT'), tsl.serial_nbr, tsl.return_flag, coalesce(o.override_amt,0), vTransTimeStamp, vTransDate,
        coalesce(d.discount_amt,0), tr.cust_party_id, cust.last_name, cust.first_name, vTransStatcode, tsl.sale_lineitm_typcode, vBeginTimeInt, tsl.exclude_from_net_sales_flag
        from trl_sale_lineitm tsl
        inner join trl_rtrans_lineitm r
        on tsl.organization_id=r.organization_id
        and tsl.rtl_loc_id=r.rtl_loc_id
        and tsl.wkstn_id=r.wkstn_id
        and tsl.trans_seq=r.trans_seq
        and tsl.business_date=r.business_date
        and tsl.rtrans_lineitm_seq=r.rtrans_lineitm_seq
        and r.rtrans_lineitm_typcode = 'ITEM'
        left join xom_order_mod xom
            on tsl.organization_id=xom.organization_id
            and tsl.rtl_loc_id=xom.rtl_loc_id
            and tsl.wkstn_id=xom.wkstn_id
            and tsl.trans_seq=xom.trans_seq
            and tsl.business_date=xom.business_date
            and tsl.rtrans_lineitm_seq=xom.rtrans_lineitm_seq
        left join xom_order_line_detail xold
            on xom.organization_id=xold.organization_id
            and xom.order_id=xold.order_id
            and xom.detail_seq=xold.detail_seq
            and xom.detail_line_number=xold.detail_line_number
            left join itm_item i
        on tsl.organization_id=i.ORGANIZATION_ID
        and tsl.item_id=i.ITEM_ID
        left join (select * from (select extended_amt override_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
            FROM trl_rtl_price_mod
            WHERE void_flag = 0 and rtl_price_mod_reascode='PRICE_OVERRIDE' 
              and organization_id = pvOrganizationId
              and rtl_loc_id = pvRetailLocationId
              and wkstn_id = pvWrkstnId
              and business_date = pvBusinessDate
              and trans_seq = pvTransSeq 
              order by organization_id, rtl_loc_id, business_date, wkstn_id, rtrans_lineitm_seq, trans_seq, rtl_price_mod_seq_nbr desc) where rownum =1) o
        on tsl.organization_id = o.organization_id 
            AND tsl.rtl_loc_id = o.rtl_loc_id
            AND tsl.business_date = o.business_date 
            AND tsl.wkstn_id = o.wkstn_id 
            AND tsl.trans_seq = o.trans_seq
            AND tsl.rtrans_lineitm_seq = o.rtrans_lineitm_seq
        left join (select sum(extended_amt) discount_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
            FROM trl_rtl_price_mod
            WHERE void_flag = 0 and rtl_price_mod_reascode in ('LINE_ITEM_DISCOUNT', 'TRANSACTION_DISCOUNT', 'GROUP_DISCOUNT', 'NEW_PRICE_RULE', 'DEAL', 'ENTITLEMENT')
            group by organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq) d
        on tsl.organization_id = d.organization_id 
            AND tsl.rtl_loc_id = d.rtl_loc_id
            AND tsl.business_date = d.business_date 
            AND tsl.wkstn_id = d.wkstn_id 
            AND tsl.trans_seq = d.trans_seq
            AND tsl.rtrans_lineitm_seq = d.rtrans_lineitm_seq
        left join trl_rtrans tr
        on tsl.organization_id = tr.organization_id 
            AND tsl.rtl_loc_id = tr.rtl_loc_id
            AND tsl.business_date = tr.business_date 
            AND tsl.wkstn_id = tr.wkstn_id 
            AND tsl.trans_seq = tr.trans_seq
        left join crm_party cust
        on tsl.organization_id = cust.organization_id 
            AND tr.cust_party_id = cust.party_id
        where tsl.organization_id = pvOrganizationId
        and tsl.rtl_loc_id = pvRetailLocationId
        and tsl.wkstn_id = pvWrkstnId
        and tsl.business_date = pvBusinessDate
        and tsl.trans_seq = pvTransSeq
        and r.void_flag=0
        and ((tsl.SALE_LINEITM_TYPCODE <> 'ORDER'and (xom.detail_type IS NULL OR xold.status_code = 'FULFILLED') )
             or (tsl.SALE_LINEITM_TYPCODE = 'ORDER' and xom.detail_type in ('FEE', 'PAYMENT') ));

END IF;
    
        IF vTransStatcode = 'COMPLETE' THEN -- process only completed transaction for flash sales tables
        BEGIN
       select sum(case vPostVoidFlag when 0 then -1 else 1 end * coalesce(quantity,0)),sum(case vPostVoidFlag when 1 then -1 else 1 end * coalesce(net_amt,0))
        INTO vQuantity,vNetAmount
        from rpt_sale_line rsl
    left join itm_non_phys_item inp on rsl.item_id=inp.item_id and rsl.organization_id=inp.organization_id
        where rsl.organization_id = pvOrganizationId
            and rtl_loc_id = pvRetailLocationId
            and wkstn_id = pvWrkstnId
            and business_date = pvBusinessDate
            and trans_seq= pvTransSeq
            and return_flag=1
      and coalesce(exclude_from_net_sales_flag,0)=0;
        EXCEPTION WHEN no_data_found THEN
          NULL;
        END;
        
            IF ABS(vNetAmount) > 0 OR ABS(vQuantity) > 0 THEN
                -- populate now to flash tables
                -- returns
                sp_ins_upd_flash_sales(pvOrganizationId, 
                                       pvRetailLocationId, 
                                       vTransDate, 
                                       pvWrkstnId, 
                                       'RETURNS', 
                                       vQuantity, 
                                       vNetAmount, 
                                       vCurrencyId);
            END IF;
            
        select sum(case when return_flag=vPostVoidFlag then 1 else -1 end * coalesce(gross_quantity,0)),
        sum(case when return_flag=vPostVoidFlag then 1 else -1 end * coalesce(quantity,0)),
        sum(case vPostVoidFlag when 1 then -1 else 1 end * coalesce(gross_amt,0)),
        sum(case vPostVoidFlag when 1 then -1 else 1 end * coalesce(net_amt,0)),
        sum(case vPostVoidFlag when 1 then 1 else -1 end * coalesce(override_amt,0)),
        sum(case vPostVoidFlag when 1 then 1 else -1 end * coalesce(discount_amt,0))
        into vGrossQuantity,vQuantity,vGrossAmount,vNetAmount,vOverrideAmt,vDiscountAmt
        from rpt_sale_line rsl
    left join itm_non_phys_item inp on rsl.item_id=inp.item_id and rsl.organization_id=inp.organization_id
        where rsl.organization_id = pvOrganizationId
            and rtl_loc_id = pvRetailLocationId
            and wkstn_id = pvWrkstnId
            and business_date = pvBusinessDate
            and trans_seq= pvTransSeq
      and QUANTITY <> 0
      and sale_lineitm_typcode not in ('ONHOLD','WORK_ORDER')
      and coalesce(exclude_from_net_sales_flag,0)=0;
      
      -- For VAT taxed items there are rounding problems by which the usage of the SUM(net_amt) could create problems
      -- So we decided to set it as simple difference between the gross amount and the discount, which results in the expected value for both SALES and VAT without rounding issues
      -- We excluded the possibility to round also the tax because several reasons:
      -- 1) It will be possible that the final result is not accurate if both values have 5 as exceeding decimal
      -- 2) The value of the tax is rounded by specific legal requirements, and must match with what specified on the fiscal receipts
      -- 3) The number of decimals used for the tax amount in the database is less (6) than the one used in the calculator (10); 
      -- anyway, this last one is the most accurate, so we cannot rely on the value on the database which is at line level (rpt_sale_line) and could be affected by several roundings
      vNetAmount := vGrossAmount + vDiscountAmt - vTaxTotal;
      
            -- Gross sales
            IF ABS(vGrossAmount) > 0 THEN
                sp_ins_upd_flash_sales(pvOrganizationId,
                                       pvRetailLocationId,
                                       vTransDate, 
                                       pvWrkstnId, 
                                       'GROSSSALES', 
                                       vGrossQuantity, 
                                       vGrossAmount, 
                                       vCurrencyId);
            END IF;
      
            -- Net Sales update
            IF ABS(vNetAmount) > 0 THEN
                sp_ins_upd_flash_sales(pvOrganizationId,
                                       pvRetailLocationId,
                                       vTransDate, 
                                       pvWrkstnId, 
                                       'NETSALES', 
                                       vQuantity, 
                                       vNetAmount, 
                                       vCurrencyId);
            END IF;
        
            -- Discounts
            IF ABS(vOverrideAmt) > 0 THEN
                sp_ins_upd_flash_sales(pvOrganizationId,
                                       pvRetailLocationId,
                                       vTransDate, 
                                       pvWrkstnId, 
                                       'OVERRIDES', 
                                       vQuantity, 
                                       vOverrideAmt, 
                                       vCurrencyId);
            END IF; 
  
            -- Discounts  
            IF ABS(vDiscountAmt) > 0 THEN 
                sp_ins_upd_flash_sales(pvOrganizationId,
                                       pvRetailLocationId,
                                       vTransDate,
                                       pvWrkstnId,
                                       'DISCOUNTS',
                                       vQuantity, 
                                       vDiscountAmt, 
                                       vCurrencyId);
            END IF;
      
   
        -- Hourly sales updates (add for all the line items in the transaction)
            vTotQuantity := COALESCE(vTotQuantity,0) + vQuantity;
            vTotNetAmt := COALESCE(vTotNetAmt,0) + vNetAmount;
            vTotGrossAmt := COALESCE(vTotGrossAmt,0) + vGrossAmount;
    
  BEGIN
    OPEN saleCursor;
      
    LOOP  
        FETCH saleCursor INTO vItemId, 
                              vSaleLineitmTypcode, 
                              vActualQuantity,
                              vUnitPrice, 
                              vGrossAmount, 
                              vGrossQuantity, 
                              vDepartmentId, 
                              vNetAmount, 
                              vQuantity,
                vReturnFlag;
    
        EXIT WHEN saleCursor%NOTFOUND;
      
            BEGIN
            SELECT non_phys_item_typcode INTO vNonPhysType
              FROM ITM_NON_PHYS_ITEM 
              WHERE item_id = vItemId 
                AND organization_id = pvOrganizationId  ;
            EXCEPTION WHEN no_data_found THEN
                NULL;
            END;
      
            vCntNonPhysItm := SQL%ROWCOUNT;
            
            IF vCntNonPhysItm = 1 THEN  
                -- check for layaway or sp. order payment / deposit
                IF vPostVoidFlag <> vReturnFlag THEN 
                    vNonPhysPrice := vUnitPrice * -1;
                    vNonPhysQuantity := vActualQuantity * -1;
                ELSE
                    vNonPhysPrice := vUnitPrice;
                    vNonPhysQuantity := vActualQuantity;
                END IF;
      
                IF vNonPhysType = 'LAYAWAY_DEPOSIT' THEN 
                    vNonPhys := 'LayawayDeposits';
                ELSIF vNonPhysType = 'LAYAWAY_PAYMENT' THEN
                    vNonPhys := 'LayawayPayments';
                ELSIF vNonPhysType = 'SP_ORDER_DEPOSIT' THEN
                    vNonPhys := 'SpOrderDeposits';
                ELSIF vNonPhysType = 'SP_ORDER_PAYMENT' THEN
                    vNonPhys := 'SpOrderPayments';
                ELSIF vNonPhysType = 'PRESALE_DEPOSIT' THEN
                    vNonPhys := 'PresaleDeposits';
                ELSIF vNonPhysType = 'PRESALE_PAYMENT' THEN
                    vNonPhys := 'PresalePayments';
                ELSIF vNonPhysType = 'ONHOLD_DEPOSIT' THEN
                    vNonPhys := 'OnholdDeposits';
                ELSIF vNonPhysType = 'ONHOLD_PAYMENT' THEN
                    vNonPhys := 'OnholdPayments';
                ELSIF vNonPhysType = 'LOCALORDER_DEPOSIT' THEN
                    vNonPhys := 'LocalInventoryOrderDeposits';
                ELSIF vNonPhysType = 'LOCALORDER_PAYMENT' THEN
                    vNonPhys := 'LocalInventoryOrderPayments';
                ELSE 
                    vNonPhys := 'NonMerchandise';
                    vNonPhysPrice := vGrossAmount;
                    vNonPhysQuantity := vGrossQuantity;
                END IF; 
                -- update flash sales for non physical payments / deposits
                sp_ins_upd_flash_sales (pvOrganizationId,
                                        pvRetailLocationId,
                                        vTransDate,
                                        pvWrkstnId,
                                        vNonPhys,
                                        vNonPhysQuantity, 
                                        vNonphysPrice, 
                                        vCurrencyId);
            ELSE
                vNonPhys := ''; -- reset 
            END IF;
    
            -- process layaways, special orders, presales, onholds, and local inventory orders (not sales)
            IF vSaleLineitmTypcode = 'LAYAWAY' OR vSaleLineitmTypcode = 'SPECIAL_ORDER' 
                or vSaleLineitmTypcode = 'PRESALE' or vSaleLineitmTypcode = 'ONHOLD' or vSaleLineitmTypcode = 'LOCALORDER' THEN
                IF (NOT (vNonPhys = 'LayawayDeposits' 
                      OR vNonPhys = 'LayawayPayments' 
                      OR vNonPhys = 'SpOrderDeposits' 
                      OR vNonPhys = 'SpOrderPayments'
                      OR vNonPhys = 'OnholdDeposits' 
                      OR vNonPhys = 'OnholdPayments'
                      OR vNonPhys = 'LocalInventoryOrderDeposits' 
                      OR vNonPhys = 'LocalInventoryOrderPayments'
                      OR vNonPhys = 'PresaleDeposits'
                      OR vNonPhys = 'PresalePayments')) 
                    AND ((vLineitemStatcode IS NULL) OR (vLineitemStatcode <> 'CANCEL')) THEN
                    
                    vNonPhysSaleType := 'SpOrderItems';
                  
                    IF vSaleLineitmTypcode = 'LAYAWAY' THEN
                        vNonPhysSaleType := 'LayawayItems';
                    ELSIF vSaleLineitmTypcode = 'PRESALE' THEN
                        vNonPhysSaleType := 'PresaleItems';
                    ELSIF vSaleLineitmTypcode = 'ONHOLD' THEN
                        vNonPhysSaleType := 'OnholdItems';
                    ELSIF vSaleLineitmTypcode = 'LOCALORDER' THEN
                        vNonPhysSaleType := 'LocalInventoryOrderItems';
                    END IF;
                  
                    -- update flash sales for layaway items
                    vLayawayPrice := vUnitPrice * COALESCE(vActualQuantity,0);
                    sp_ins_upd_flash_sales (pvOrganizationId,
                                            pvRetailLocationId,
                                            vTransDate,
                                            pvWrkstnId,
                                            vNonPhys,
                                            vActualQuantity, 
                                            vLayawayPrice, 
                                            vCurrencyId);
                END IF;
            END IF;
            -- end flash sales update
            -- department sales
            sp_ins_upd_merchlvl1_sales(pvOrganizationId, 
                                  pvRetailLocationId, 
                                  vTransDate, 
                                  pvWrkstnId, 
                                  vDepartmentId, 
                                  vQuantity, 
                                  vNetAmount, 
                                  vGrossAmount, 
                                  vCurrencyId);
    END LOOP;
    CLOSE saleCursor;
  EXCEPTION
    WHEN OTHERS THEN CLOSE saleCursor;
  END;
    END IF; 
  
  
    -- update hourly sales
    Sp_Ins_Upd_Hourly_Sales(pvOrganizationId, 
                            pvRetailLocationId, 
                            vTransDate, 
                            pvWrkstnId, 
                            vTransTimeStamp, 
                            vTotquantity, 
                            vTotNetAmt, 
                            vTotGrossAmt, 
                            vTransCount, 
                            vCurrencyId);
  
    COMMIT;
  
    EXCEPTION
        --WHEN NO_DATA_FOUND THEN
        --    vRowCnt := 0;            
        WHEN myerror THEN
            rollback;
        WHEN myreturn THEN
            commit;
        WHEN others THEN
            DBMS_OUTPUT.PUT_LINE('ERROR NUM: ' || to_char(sqlcode));
            DBMS_OUTPUT.PUT_LINE('ERROR TXT: ' || SQLERRM);
            rollback;
--    END;
END sp_flash;
/

GRANT EXECUTE ON sp_flash TO posusers,dbausers;
 
BEGIN
    dbms_output.put_line('     Step ORACLE: Fix to avoid unique constraint exception end.');
END;
/




PROMPT '***** Body scripts end *****';


-- Keep at end of the script

PROMPT '**************************************';
PROMPT 'Finalizing UPGRADE release 22.0';
PROMPT '**************************************';
/

-- LEAVE BLANK LINE BELOW
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING RPT_TRL_SALE_LINEITM_VIEW');

CREATE OR REPLACE VIEW rpt_trl_sale_lineitm_view
(ORGANIZATION_ID, RTL_LOC_ID, WKSTN_ID, TRANS_SEQ, RTRANS_LINEITM_SEQ, BUSINESS_DATE, BEGIN_DATETIME, END_DATETIME, TRANS_STATCODE, TRANS_TYPCODE, SESSION_ID, OPERATOR_PARTY_ID, CUST_PARTY_ID, ITEM_ID, DEPARTMENT_ID, QUANTITY, UNIT_PRICE, EXTENDED_AMT, VAT_AMT, RETURN_FLAG, NET_AMT, GROSS_AMT, SERIAL_NBR, SALE_LINEITM_TYPCODE, TAX_GROUP_ID, ORIGINAL_RTL_LOC_ID, ORIGINAL_WKSTN_ID, ORIGINAL_BUSINESS_DATE, ORIGINAL_TRANS_SEQ, ORIGINAL_RTRANS_LINEITM_SEQ, RETURN_REASCODE, RETURN_COMMENT, RETURN_TYPCODE, VOID_FLAG, VOID_LINEITM_REASCODE, BASE_EXTENDED_PRICE, RPT_BASE_UNIT_PRICE, EXCLUDE_FROM_NET_SALES_FLAG) AS
SELECT 
TRN.organization_id,
TRN.rtl_loc_id ,
TRN.wkstn_id ,
TRN.trans_seq ,
TSL.rtrans_lineitm_seq ,
TRN.business_date,
TRN.begin_datetime,
TRN.end_datetime,
TRN.trans_statcode,
TRN.trans_typcode,
TRN.session_id,
TRN.operator_party_id,
TRT.cust_party_id,
TSL.item_id,
TSL.merch_level_1,
TSL.quantity,
TSL.unit_price,
TSL.extended_amt,
TSL.vat_amt,
TSL.return_flag,
TSL.net_amt,
TSL.gross_amt,
TSL.serial_nbr,
TSL.sale_lineitm_typcode,
TSL.tax_group_id,
TSL.original_rtl_loc_id,
TSL.original_wkstn_id,
TSL.original_business_date,
TSL.original_trans_seq,
TSL.original_rtrans_lineitm_seq,
TSL.return_reascode,
TSL.return_comment,
TSL.return_typcode,
TRL.void_flag,
TRL.void_lineitm_reascode,
TSL.base_extended_price,
TSL.rpt_base_unit_price,
TSL.exclude_from_net_sales_flag
FROM  
trn_trans TRN, 
trl_sale_lineitm TSL, 
trl_rtrans_lineitm TRL, 
trl_rtrans TRT
WHERE
TRN.organization_id = TSL.organization_id AND
TRN.rtl_loc_id = TSL.rtl_loc_id AND
TRN.wkstn_id = TSL.wkstn_id AND
TRN.business_date = TSL.business_date AND
TRN.trans_seq = TSL.trans_seq AND
TSL.organization_id = TRL.organization_id AND
TSL.rtl_loc_id = TRL.rtl_loc_id AND
TSL.wkstn_id = TRL.wkstn_id AND
TSL.business_date = TRL.business_date AND
TSL.trans_seq = TRL.trans_seq AND
TSL.rtrans_lineitm_seq = TRL.rtrans_lineitm_seq AND
TSL.organization_id = TRT.organization_id AND
TSL.rtl_loc_id = TRT.rtl_loc_id AND
TSL.wkstn_id = TRT.wkstn_id AND
TSL.business_date = TRT.business_date AND
TSL.trans_seq = TRT.trans_seq AND
TRN.trans_statcode ='COMPLETE'
;
/

GRANT SELECT ON rpt_trl_sale_lineitm_view TO posusers,dbausers
;

--
-- VIEW: Test_Connection 
--
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING Test_Connection');

CREATE OR REPLACE VIEW Test_Connection(result)
AS
SELECT 1  from dual;

GRANT SELECT ON Test_Connection TO posusers,dbausers;



EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING RPT_TRL_STOCK_MOVEMENT_VIEW');

CREATE OR REPLACE VIEW RPT_TRL_STOCK_MOVEMENT_VIEW
AS
SELECT organization_id, rtl_loc_id, business_date, item_id, quantity, adjustment_flag
FROM
((SELECT tsl.organization_id as organization_id, tsl.rtl_loc_id as rtl_loc_id, tsl.business_date as business_date, tsl.item_id as item_id,
	quantity, case when return_flag = 0 then 1 else 0 end as adjustment_flag
	FROM rpt_trl_sale_lineitm_view tsl
	WHERE trans_seq NOT IN
          (SELECT voided_trans_id FROM trn_post_void_trans pvt
           WHERE pvt.organization_id = tsl.organization_id
           AND pvt.rtl_loc_id = tsl.rtl_loc_id
           AND pvt.wkstn_id = tsl.wkstn_id)
	AND sale_lineitm_typcode = 'SALE'
	AND tsl.void_flag = 0) 
UNION ALL
(SELECT inv_journal.organization_id, inv_journal.rtl_loc_id, inv_journal.business_date, inv_journal.inventory_item_id,
     quantity, case when action_code IN ('RECEIVING', 'INVENTORY_ADJUSTMENT', 'CYCLE_COUNT_ADJUSTMENT') then 0 else 1 end as adjustment_flag
FROM inv_inventory_journal inv_journal
WHERE action_code IN ('RECEIVING', 'SHIPPING', 'INVENTORY_ADJUSTMENT', 'CYCLE_COUNT_ADJUSTMENT')
      AND (source_bucket_id='ON_HAND' OR dest_bucket_id='ON_HAND')));
/

GRANT SELECT ON RPT_TRL_STOCK_MOVEMENT_VIEW TO posusers,dbausers
;

-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : DATEADD
-- Description       : 
-- Version           : 19.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....         Initial Version
-- 
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION DATEADD');

CREATE OR REPLACE FUNCTION DATEADD (as_DateFMT      varchar2,
                                        ai_interval    integer,
                                        as_Date        timestamp) RETURN TIMESTAMP
AUTHID CURRENT_USER 
IS
    ld_NewDate      timestamp;
    id_Date         timestamp;
   
BEGIN
    
    id_Date := as_Date;
   
    CASE UPPER(as_DateFMT)
        WHEN 'DAY' THEN
            ld_NewDate := id_Date + ai_interval;
        WHEN 'MONTH' THEN
            ld_NewDate := ADD_MONTHS(id_Date, ai_interval);
        WHEN 'YEAR' THEN
            ld_NewDate := ADD_MONTHS(id_Date, (ai_interval * 12));
        else
            ld_NewDate := NULL;
    END CASE;
    
    RETURN ld_NewDate;
END DATEADD;
/

GRANT EXECUTE ON DATEADD TO posusers,dbausers;
 
-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : datepart
-- Description       : 
-- Version           : 19.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....         Initial Version
-- 
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION DATEPART');

CREATE OR REPLACE FUNCTION datepart (as_DateFMT     varchar2,
                                        ad_Date         timestamp) RETURN INTEGER
AUTHID CURRENT_USER 
IS
    li_DatePart     integer;
    
BEGIN
    
    
    CASE UPPER(as_DateFMT)
        WHEN 'DD' THEN
            li_DatePart := to_number(to_char(ad_Date, 'DD'));
        WHEN 'DW' THEN
            li_DatePart := to_number(to_char(ad_Date, 'D'));
        WHEN 'DY' THEN
            li_DatePart := to_number(to_char(ad_Date, 'DDD'));
        else
            li_DatePart := NULL;
    END CASE;
    
    RETURN li_DatePart;
END datepart;
/

GRANT EXECUTE ON datepart TO posusers,dbausers;
 
-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : DAY
-- Description       : 
-- Version           : 16.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....         Initial Version
-- 
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('DAY');

CREATE OR REPLACE FUNCTION DAY (ad_Date timestamp)
 RETURN INTEGER
AUTHID CURRENT_USER 
IS
    li_day integer;
BEGIN
    li_day := to_number(to_char(ad_Date, 'DD'));
    RETURN li_day;
END DAY;
/

GRANT EXECUTE ON DAY TO posusers;
GRANT EXECUTE ON DAY TO dbausers;

 
-- 
-- FUNCTION: fn_getsessionid 
--
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION FN_GETSESSIONID');

CREATE OR REPLACE FUNCTION FN_GETSESSIONID (orgId NUMBER, rtlLocId NUMBER, wkstnId NUMBER) RETURN NUMBER 
AUTHID CURRENT_USER 
IS
  v_sessionId NUMBER(10,0);
BEGIN
  SELECT Max(session_id)
    INTO v_sessionId 
    FROM tsn_session_wkstn 
    WHERE organization_id = orgId AND
          rtl_loc_id = rtlLocId AND
          wkstn_id = wkstnId AND
          attached_flag = '1';
 
  RETURN v_sessionId;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 0;
    WHEN OTHERS THEN RETURN 0;
END fn_getSessionId;
/
GRANT EXECUTE ON fn_getsessionid TO posusers,dbausers;
 
-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : GETDATE
-- Description       : 
-- Version           : 19.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....         Initial Version
-- 
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION GETDATE');

CREATE OR REPLACE FUNCTION GETDATE 
 RETURN TIMESTAMP
AUTHID CURRENT_USER 
IS
BEGIN
    RETURN SYSDATE;
END GETDATE;
/

GRANT EXECUTE ON GETDATE TO posusers,dbausers;
 

-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : GETUTCDATE
-- Description       : 
-- Version           : 19.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....         Initial Version
-- 
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION GETUTCDATE');

CREATE OR REPLACE FUNCTION GETUTCDATE 
 RETURN TIMESTAMP
AUTHID CURRENT_USER 
IS
BEGIN
    RETURN SYS_EXTRACT_UTC(SYSTIMESTAMP);
END GETUTCDATE;
/

GRANT EXECUTE ON GETUTCDATE TO posusers,dbausers;
 

-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : MONTH
-- Description       : 
-- Version           : 16.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....         Initial Version
-- 
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('MONTH');

CREATE OR REPLACE FUNCTION MONTH (ad_Date timestamp)
 RETURN INTEGER
AUTHID CURRENT_USER 
IS
    li_month integer;
BEGIN
    li_month := to_number(to_char(ad_Date, 'MM'));
    RETURN li_month;
END MONTH;
/

GRANT EXECUTE ON MONTH TO posusers;
GRANT EXECUTE ON MONTH TO dbausers;

 
-- 
-- PROCEDURE: SP_INS_UPD_HOURLY_SALES 
--
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING PROCEDURE sp_ins_upd_hourly_sales');

CREATE OR REPLACE PROCEDURE     sp_ins_upd_hourly_sales (
argOrganizationId IN NUMBER /*oragnization id*/,
argRtlLocId IN NUMBER /*retail location or store number*/,
argBusinessDate IN DATE /*business date*/,
argWkstnId IN NUMBER /*register*/,
argHour IN TIMESTAMP /*flash sales classification*/,
argQty IN NUMBER /*quantity*/,
argNetAmt IN NUMBER /*net amount*/,
argGrossAmt IN NUMBER /*gross amount*/,
argTransCount IN NUMBER /*transcation count*/,
argCurrencyId IN VARCHAR2
)
AUTHID CURRENT_USER 
IS
vcount int;
BEGIN 
select decode(instr(DBMS_UTILITY.format_call_stack,'SP_FLASH'),0,0,1) into vcount from dual;
 if vcount>0 then
  UPDATE rpt_sales_by_hour
     SET qty = coalesce(qty, 0) + coalesce(argQty, 0),
         trans_count = coalesce(trans_count, 0) + coalesce(argTransCount, 0),
         net_sales = coalesce(net_sales, 0) + coalesce(argNetAmt, 0),
         gross_sales = coalesce(gross_sales, 0) + coalesce(argGrossAmt, 0),
         update_date = SYS_EXTRACT_UTC(SYSTIMESTAMP),
         update_user_id = user
   WHERE organization_id = argOrganizationId
     AND rtl_loc_id = argRtlLocId
     AND wkstn_id = argWkstnId
     AND business_date = argBusinessDate
     AND hour = extract (HOUR FROM argHour);

  IF sql%notfound THEN
    INSERT INTO rpt_sales_by_hour
      (organization_id, rtl_loc_id, wkstn_id, hour, qty, trans_count,
      net_sales, business_date, gross_sales, currency_id, create_date, create_user_id)
    VALUES (argOrganizationId, argRtlLocId, argWkstnId, extract (HOUR FROM argHour), argQty, 
      argTransCount, argNetAmt, argBusinessDate, argGrossAmt, argCurrencyId, SYS_EXTRACT_UTC(SYSTIMESTAMP), user);
  END IF;
 else
  raise_application_error( -20001, 'Cannot be run directly.' );
 end if;
END;
/

GRANT EXECUTE ON SP_INS_UPD_HOURLY_SALES TO posusers,dbausers;


-- 
-- PROCEDURE: SP_INS_UPD_MERCHLVL1_SALES 
--
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING PROCEDURE sp_ins_upd_merchlvl1_sales');

CREATE OR REPLACE PROCEDURE     sp_ins_upd_merchlvl1_sales (
argOrganizationId IN NUMBER /*organization id*/,
argRtlLocId IN NUMBER /*retail location or store number*/,
argBusinessDate IN DATE /*business date*/,
argWkstnId IN NUMBER /*register*/,
argDeptId IN VARCHAR2 /*flash sales classification*/,
argQty IN NUMBER /*quantity*/,
argNetAmt IN NUMBER /*net amount*/,
argGrossAmt IN NUMBER /*gross amount*/,
argCurrencyId IN VARCHAR2
)
AUTHID CURRENT_USER 
IS
vcount int;
BEGIN
select decode(instr(DBMS_UTILITY.format_call_stack,'SP_FLASH'),0,0,1) into vcount from dual;
 if vcount>0 then
  UPDATE rpt_merchlvl1_sales
     SET line_count = coalesce(line_count, 0) + argQty,
         line_amt = coalesce(line_amt, 0) + argNetAmt,
         gross_amt = gross_amt + argGrossAmt,
         update_date = SYS_EXTRACT_UTC(SYSTIMESTAMP),
         update_user_id = user
   WHERE organization_id = argOrganizationId
     AND rtl_loc_id = argRtlLocId
     AND wkstn_id = argWkstnId
     AND business_date = argBusinessDate
     AND merch_level_1 = argDeptId;

  IF sql%notfound THEN
    INSERT INTO rpt_merchlvl1_sales (organization_id, rtl_loc_id, wkstn_id, merch_level_1, line_count, 
      line_amt, business_date, gross_amt, currency_id, create_date, create_user_id)
    VALUES (argOrganizationId, argRtlLocId, argWkstnId, argDeptId, argQty, 
      argNetAmt, argBusinessDate, argGrossAmt, argCurrencyId, SYS_EXTRACT_UTC(SYSTIMESTAMP), user);
  END IF;
 else
  raise_application_error( -20001, 'Cannot be run directly.' );
 end if;
END;
/

GRANT EXECUTE ON SP_INS_UPD_MERCHLVL1_SALES TO posusers,dbausers;


-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : SP_REPLACE_ORG_ID
-- Description       : 
-- Version           : 19.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....         Initial Version
-- PGH 09/22/10     Added a commit after each table is updated. 
-- BCW 09/18/15     Changed owner to the current schema.
-- BCW 09/24/15     Changed argNewOrgId from varchar2 to number.
-------------------------------------------------------------------------------------------------------------------

EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION sp_replace_org_id');

CREATE OR REPLACE FUNCTION sp_replace_org_id
  (argNewOrgId IN number)
RETURN INTEGER
AUTHID CURRENT_USER 
IS
  v_sqlStmt varchar(500);
  v_tabName varchar(60);
  
  CURSOR rtlcur IS 
    SELECT col.table_name 
      FROM all_tab_columns col, all_tables tab
      WHERE tab.owner = upper('$(DbSchema)') AND 
            col.owner = upper('$(DbSchema)') AND 
            col.table_name = tab.table_name AND 
            col.column_name = 'ORGANIZATION_ID'
      ORDER BY col.table_name;
      
BEGIN

  DBMS_OUTPUT.ENABLE (buffer_size => NULL);
  DBMS_OUTPUT.PUT_LINE ('Starting sp_replace_org_id...');
  
  OPEN rtlcur;
  LOOP
    --DBMS_OUTPUT.PUT_LINE ('Starting Loop');

    FETCH rtlcur INTO v_tabName;
        EXIT WHEN rtlcur%NOTFOUND;
    
    v_sqlStmt := 'update $(DbSchema).'||v_tabName||' set organization_id = '||argNewOrgId;
    dbms_output.put_line (v_sqlstmt);
    
    IF v_sqlStmt IS NOT NULL THEN
      EXECUTE IMMEDIATE v_sqlStmt;
      
    END IF;
    
    COMMIT;
    
  END LOOP;
  CLOSE rtlcur;
  
  DBMS_OUTPUT.PUT_LINE ('Ending sp_replace_org_id...');
  
  RETURN 0;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error:');
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
        DBMS_OUTPUT.PUT_LINE ('Ending sp_replace_org_id...');
        CLOSE rtlcur;
        RETURN -1;
END;
/

GRANT EXECUTE ON SP_REPLACE_ORG_ID TO posusers,dbausers;

 
-------------------------------------------------------------------------------------------------------------
--
-- Procedure         : SP_TRUNCATE_TABLE
-- Description       : truncates data from a table
-- Version           : 16.0
-------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                               --
-------------------------------------------------------------------------------------------------------------
-- WHO              DATE              DESCRIPTION                                                          --
-------------------------------------------------------------------------------------------------------------
-- Nuwan Wijekoon 02/07/2019         Initial Version
-- 
-------------------------------------------------------------------------------------------------------------

EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING PROCEDURE SP_TRUNCATE_TABLE');

CREATE OR REPLACE PROCEDURE SP_TRUNCATE_TABLE(argTableName IN VARCHAR2)
AS
vPrepStatement VARCHAR2(4000);
BEGIN
  vPrepStatement := 'TRUNCATE TABLE ' || argTableName;
  EXECUTE IMMEDIATE vPrepStatement;
END;
/

GRANT EXECUTE ON SP_TRUNCATE_TABLE TO posusers;
GRANT EXECUTE ON SP_TRUNCATE_TABLE TO dbausers;
-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : YEAR
-- Description       : 
-- Version           : 16.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....         Initial Version
-- 
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('YEAR');

CREATE OR REPLACE FUNCTION YEAR (ad_Date timestamp)
 RETURN INTEGER
AUTHID CURRENT_USER 
IS
    li_year integer;
BEGIN
    li_year := to_number(to_char(ad_Date, 'YYYY'));
    RETURN li_year;
END YEAR;
/

GRANT EXECUTE ON YEAR TO posusers;
GRANT EXECUTE ON YEAR TO dbausers;

 
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION fn_NLS_LOWER'); 
CREATE OR REPLACE FUNCTION fn_NLS_LOWER (argString varchar) RETURN VARCHAR 
AUTHID CURRENT_USER 
IS
BEGIN
   
   RETURN NLS_LOWER(argString);
END fn_NLS_LOWER;
/

GRANT EXECUTE ON fn_NLS_LOWER TO posusers,dbausers;
 
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION fn_NLS_UPPER'); 
CREATE OR REPLACE FUNCTION fn_NLS_UPPER (argString varchar) RETURN VARCHAR 
AUTHID CURRENT_USER 
IS
BEGIN
   
   RETURN NLS_UPPER(argString);
END fn_NLS_UPPER;
/

GRANT EXECUTE ON fn_NLS_UPPER TO posusers,dbausers;
 
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION fn_ParseDate'); 
CREATE OR REPLACE FUNCTION fn_ParseDate (argDateString varchar) RETURN DATE 
AUTHID CURRENT_USER 
IS
BEGIN
   
   RETURN to_date(argDateString,'YYYY-MM-DD HH24:MI:SS');
END fn_ParseDate;
/

GRANT EXECUTE ON fn_ParseDate TO posusers,dbausers;

create or replace function
fn_compressedblob2clob(src_blob BLOB) 
return CLOB
is
  dest_clob CLOB;
  raw_blob BLOB;
  dest_offset integer := 1;
  src_offset integer := 1;
  csid integer := NLS_CHARSET_ID('al32utf8');
  lang_context integer := 0;
  warning integer := 0;
begin
  raw_blob := UTL_COMPRESS.LZ_UNCOMPRESS(src_blob);
  DBMS_LOB.CreateTemporary(lob_loc=>dest_clob, CACHE=>true);
  DBMS_LOB.ConvertToClob(dest_clob, raw_blob, length(raw_blob), dest_offset, src_offset, csid, lang_context, warning);
  DBMS_LOB.FreeTemporary(raw_blob);
  return(dest_clob);
end fn_compressedblob2clob;
/
GRANT EXECUTE ON fn_compressedblob2clob TO posusers,dbausers;
create or replace type split_tbl as table of number(10,0);
 /

EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION fn_integerListToTable'); 
 create or replace function fn_integerListToTable
 (
     p_list varchar2,
     p_del varchar2 := ','
 ) return split_tbl pipelined
AUTHID CURRENT_USER 
 is
     l_idx    pls_integer;
     l_list    varchar2(32767):= p_list;
 --AA
--     l_value    varchar2(32767);
     
  begin
     loop
         l_idx :=instr(l_list,p_del);
         if l_idx > 0 then
             pipe row(substr(l_list,1,l_idx-1));
             l_list:= substr(l_list,l_idx+length(p_del));

         else
             pipe row(l_list);
             exit;
         end if;
     end loop;
     return;
 end fn_integerListToTable;
 /

GRANT EXECUTE ON split_tbl TO posusers,dbausers;
GRANT EXECUTE ON fn_integerListToTable TO posusers,dbausers;

 
create or replace type var_tbl as table of varchar2(4000 char);
 /

EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION fn_nodesInHierarchy'); 
CREATE OR REPLACE function fn_nodesInHierarchy 
(
    v_orgId number, 
    v_orgCode VARCHAR2, 
    v_orgValue VARCHAR2
) return  var_tbl
AUTHID CURRENT_USER 
 as
 testtab var_tbl := var_tbl();
BEGIN
FOR rc IN
(select org_code || ':' || org_value as node from
    (SELECT org_code, org_value
    FROM loc_org_hierarchy
    WHERE organization_id = v_orgId
    START WITH org_code =v_orgCode AND org_value = v_orgValue
    CONNECT BY PRIOR parent_code = org_code AND PRIOR parent_value = org_value))
  LOOP
    testtab.EXTEND;
    testtab (testtab.COUNT) := rc.node;
  END LOOP;
  return testtab;
  END fn_nodesInHierarchy;
  /

GRANT EXECUTE ON var_tbl TO posusers,dbausers;
GRANT EXECUTE ON fn_nodesInHierarchy TO posusers,dbausers;

 
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION fn_storesInHierarchy'); 
CREATE OR REPLACE function fn_storesInHierarchy 
(
    v_orgId number, 
    v_orgCode VARCHAR2, 
    v_orgValue VARCHAR2
) return  split_tbl
AUTHID CURRENT_USER 
 as
 testtab split_tbl := split_tbl();
BEGIN
FOR rc IN
(select cast(org_value as number) org_value from
    (SELECT organization_id, org_code, org_value
    FROM loc_org_hierarchy
    WHERE organization_id = v_orgId
START WITH org_code =v_orgCode AND org_value = v_orgValue
CONNECT BY PRIOR org_code = parent_code AND PRIOR org_value = parent_value)
  WHERE org_code = 'STORE')
  LOOP
    testtab.EXTEND;
    testtab (testtab.COUNT) := rc.org_value;
  END LOOP;
  return testtab;
  END fn_storesInHierarchy;
  /

GRANT EXECUTE ON fn_storesInHierarchy TO posusers,dbausers;

 
/* 
 * PROCEDURE: sp_conv_to_unicode 
 */

-- =============================================
-- Author:        Brett C. White
-- Create date: 2/14/12
-- Description:    Converts all char2, varchar2, and clob fields into nchar2, nvarchar2, and nclob.
-- =============================================
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING PROCEDURE sp_conv_to_unicode');
CREATE OR REPLACE PROCEDURE sp_conv_to_unicode 
AUTHID CURRENT_USER 
IS
    v_csql varchar2(255);
    v_ttable varchar2(40);
    v_tcolumn varchar2(40);
    v_old varchar2(40);
BEGIN

  DECLARE CURSOR column_list is
    select 'ALTER TABLE ' || COL.table_name || ' MODIFY "' || column_name || '" N' || data_type
    || '(' || cast(data_length as varchar2(4)) || ')'
    from all_tab_columns COL
    inner join all_tables t on t.TABLE_NAME=COL.TABLE_NAME
    where DATA_TYPE in ('VARCHAR2','CHAR2')
  order by COL.table_name;

  BEGIN
  open column_list;
  LOOP
    FETCH column_list INTO v_csql;
    EXIT WHEN column_list%NOTFOUND;

        BEGIN
        EXECUTE IMMEDIATE v_csql;
 --       dbms_output.put_line(v_csql);
            EXCEPTION
            WHEN OTHERS THEN
            dbms_output.put_line(v_csql || ' failed');
        END;
  END LOOP;
  close column_list;
    END;

    DECLARE CURSOR text_list is
   select COL.table_name,col.COLUMN_NAME
  from all_tab_columns COL
  inner join all_tables t on t.TABLE_NAME=COL.TABLE_NAME
  where DATA_TYPE in ('CLOB')
  order by COL.table_name;

  begin
  open text_list;
    LOOP
      FETCH text_list INTO v_ttable,v_tcolumn;
        EXIT WHEN text_list%NOTFOUND;
    
    v_old := 'old_column';
  
    dbms_output.put_line('ALTER TABLE ' || v_ttable || ' RENAME COLUMN ' || v_tcolumn || ' TO ' || v_old);
    EXECUTE IMMEDIATE 'ALTER TABLE ' || v_ttable || ' RENAME COLUMN ' || v_tcolumn || ' TO ' || v_old;
    
    dbms_output.put_line('ALTER TABLE ' || v_ttable || ' ADD ' || v_tcolumn || ' NCLOB');
    EXECUTE IMMEDIATE 'ALTER TABLE ' || v_ttable || ' ADD ' || v_tcolumn || ' NCLOB';
    
    dbms_output.put_line('update ' || v_ttable || ' SET ' || v_tcolumn || ' = ' || v_old);
    EXECUTE IMMEDIATE 'update ' || v_ttable || ' SET ' || v_tcolumn || ' = ' || v_old;

    dbms_output.put_line('ALTER TABLE ' || v_ttable || ' DROP COLUMN ' || v_old);
    EXECUTE IMMEDIATE 'ALTER TABLE ' || v_ttable || ' DROP COLUMN ' || v_old;
  end LOOP;
  close text_list;
  EXCEPTION
    WHEN OTHERS THEN CLOSE text_list;
  end;
  dbms_output.put_line('PLEASE UPDATE THE STORED PROCEDURES MANUALLY!!!');
END;
/

GRANT EXECUTE ON sp_conv_to_unicode TO dbausers;

 
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING PROCEDURE sp_fifo_detail');

CREATE OR REPLACE PROCEDURE sp_fifo_detail
   (merch_level_1_param    in varchar2, 
    merch_level_2_param    in varchar2, 
    merch_level_3_param    in varchar2, 
    merch_level_4_param    in varchar2,
    item_id_param          in varchar2,
    style_id_param         in varchar2,
    rtl_loc_id_param       in varchar2, 
    organization_id_param  in int,
    user_name_param        in varchar2,
    stock_val_date_param   in DATE)
AUTHID CURRENT_USER 
 IS

            organization_id         int;
            organization_id_a       int;
            item_id                 VARCHAR2(60);
            item_id_a               VARCHAR2(60);
            description             VARCHAR2(254);
            description_a           VARCHAR2(254);
            style_id                VARCHAR2(60);
            style_id_a              VARCHAR2(254);
            style_desc              VARCHAR2(254);
            style_desc_a            VARCHAR2(254);
            rtl_loc_id              int;
            rtl_loc_id_a            int;
            store_name              VARCHAR2(254);
            store_name_a            VARCHAR2(254);
            invctl_document_id      VARCHAR2(30);
            invctl_document_id_a    VARCHAR2(30);
            invctl_document_nbr     int;
            invctl_document_nbr_a   int;
            create_date_timestamp   DATE;
            create_date_timestamp_a DATE;
            unit_count              DECIMAL(14,4);
            unit_count_a            DECIMAL(14,4);
            current_unit_count      DECIMAL(14,4);
            unit_cost               DECIMAL(17,6);
            unit_cost_a             DECIMAL(17,6);
            unitCount               DECIMAL(14,4);
            unitCount_a             DECIMAL(14,4);

            vcomment                VARCHAR2(254);

            current_item_id         VARCHAR2(60);
            current_rtl_loc_id      int;
            pending_unitCount       DECIMAL(14,4);
            
            vinsert                 number(4,0);
            
  
  CURSOR tableCur IS 
      SELECT MAX(sla.organization_id), MAX(COALESCE(sla.unitcount,0)) + MAX(COALESCE(ts.quantity, 0)) AS quantity, 
                  sla.item_id, MAX(i.description), MAX(style.item_id), MAX(style.description), 
              l.rtl_loc_id, MAX(l.store_name), doc.invctl_document_id, doc.invctl_document_line_nbr,
                  doc.create_date, MAX(COALESCE(doc.unit_count,0)), MAX(COALESCE(doc.unit_cost,0))
      FROM loc_rtl_loc l, (select column_value from table(fn_integerListToTable(rtl_loc_id_param))) fn, 
      (SELECT organization_id, item_id, COALESCE(SUM(unitcount),0) AS unitcount 
        FROM inv_stock_ledger_acct, (select column_value from table(fn_integerListToTable(rtl_loc_id_param))) fn
        WHERE fn.column_value = rtl_loc_id 
                AND bucket_id = 'ON_HAND'
        GROUP BY organization_id, item_id) sla
        LEFT OUTER JOIN
            (SELECT itm_mov.organization_id, itm_mov.rtl_loc_id, itm_mov.item_id, 
                  SUM(COALESCE(quantity,0) * CASE WHEN adjustment_flag = 1 THEN 1 ELSE -1 END) AS quantity
           FROM rpt_trl_stock_movement_view itm_mov
           WHERE to_char(business_date) > to_char(stock_val_date_param)
           GROUP BY itm_mov.organization_id, itm_mov.rtl_loc_id, itm_mov.item_id) ts
           ON sla.organization_id = ts.organization_id
              AND sla.item_id = ts.item_id
            LEFT OUTER JOIN (
                  SELECT id.organization_id, idl.inventory_item_id, idl.rtl_loc_id , id.invctl_document_id, 
                        idl.invctl_document_line_nbr, idl.create_date, COALESCE(idl.unit_count,0) AS unit_count, COALESCE(idl.unit_cost,0) AS unit_cost
                  FROM inv_invctl_document_lineitm idl, (select column_value from table(fn_integerListToTable(rtl_loc_id_param))) fn, inv_invctl_document id
                  WHERE idl.organization_id = id.organization_id AND idl.rtl_loc_id = id.rtl_loc_id AND 
                        idl.document_typcode = id.document_typcode AND idl.invctl_document_id = id.invctl_document_id AND 
                        idl.unit_count IS NOT NULL AND idl.unit_cost IS NOT NULL AND idl.create_date IS NOT NULL AND
                        id.document_subtypcode = 'ASN'
                        AND id.status_code IN ('CLOSED', 'OPEN', 'IN_PROCESS')
                        AND to_date(idl.create_date,'MM/DD/YYYY') <= to_date(stock_val_date_param,'MM/DD/YYYY')
                        AND fn.column_value = idl.rtl_loc_id 
                        AND idl.organization_id = organization_id_param
            ) doc
            ON sla.organization_id = doc.organization_id AND 
               sla.item_id = doc.inventory_item_id
            INNER JOIN itm_item i
            ON sla.item_id = i.item_id AND
               sla.organization_id = i.organization_id
            LEFT OUTER JOIN itm_item style
            ON i.parent_item_id = style.item_id AND
               i.organization_id = style.organization_id
      WHERE merch_level_1_param in (i.merch_level_1,'%') AND merch_level_2_param in (i.merch_level_2,'%') AND 
            merch_level_3_param IN (i.merch_level_3,'%') AND merch_level_4_param IN (i.merch_level_4,'%') AND
            item_id_param IN (i.item_id,'%') AND style_id_param IN (i.parent_item_id,'%') AND
            sla.organization_id = l.organization_id AND 
            fn.column_value = l.rtl_loc_id AND 
            doc.rtl_loc_id = l.rtl_loc_id AND 
            COALESCE(sla.unitcount,0) + COALESCE(ts.quantity, 0) > 0
      GROUP BY style.item_id, sla.item_id, doc.invctl_document_id, l.rtl_loc_id, doc.invctl_document_line_nbr, doc.create_date
      ORDER BY sla.item_id,doc.create_date DESC;

BEGIN      
  EXECUTE IMMEDIATE 'DELETE FROM rpt_fifo_detail WHERE user_name = ''' || user_name_param || '''';
    vcomment := '';
    current_item_id := '';
    pending_unitCount := 0;
    vinsert := 0;
    OPEN tableCur;
    FETCH tableCur INTO organization_id, unitcount, item_id, description, style_id, style_desc, rtl_loc_id, store_name, invctl_document_id, invctl_document_nbr, create_date_timestamp, unit_count, unit_cost;
    LOOP
    EXIT WHEN tableCur%NOTFOUND;
        IF current_item_id <> item_id THEN
            current_item_id := item_id;
            pending_unitCount := unitcount;
        END IF;
     IF pending_unitCount > 0 Then
              IF pending_unitCount < unit_count Then
                  current_unit_count := pending_unitCount;
                  pending_unitCount := 0;
              ELSE
                  current_unit_count := unit_count ;
                  pending_unitCount := pending_unitCount - unit_count;
              END IF;
              vinsert := 1;
        ELSIF pending_unitCount < 0 Then
                 vinsert := 1;
        ELSE 
            vinsert := 0;
        END IF;

              organization_id_a := organization_id;
              unitcount_a := unitcount;
              item_id_a := item_id;
              description_a := description;
              style_id_a := style_id;
              style_desc_a := style_desc;
              rtl_loc_id_a := rtl_loc_id;
              store_name_a := store_name;
              invctl_document_id_a := invctl_document_id;
              invctl_document_nbr_a := invctl_document_nbr;
              create_date_timestamp_a := create_date_timestamp;
              unit_count_a := unit_count;
              unit_cost_a := unit_cost;

        FETCH tableCur INTO organization_id, unitcount, item_id, description, style_id, style_desc, rtl_loc_id, store_name, invctl_document_id, invctl_document_nbr, create_date_timestamp, unit_count, unit_cost;
     IF (pending_unitCount >= 0 OR tableCur%NOTFOUND  OR item_id <> item_id_a) AND vinsert = 1 then
             vcomment := '';
              IF (item_id_a <> item_id AND pending_unitCount > 0) OR tableCur%NOTFOUND then
                  IF pending_unitCount > 0 Then
                        vcomment := '_rptLackDocStockVal';
                  END IF;
              END IF;

      IF pending_unitCount < 0 Then
         invctl_document_id_a := '_rptNoAvailDocStockVal';
         unit_cost_a := null;
         unit_count_a := null;
         current_unit_count := null;
         create_date_timestamp_a := null;
         vcomment := '_rptLackDocStockVal';
      END IF;

              INSERT INTO rpt_fifo_detail (organization_id, rtl_loc_id, item_id, invctl_doc_id, user_name, invctl_doc_create_date, description, store_name, 
                     unit_count, current_unit_count, unit_cost, unit_count_a, current_cost, "comment", pending_count, style_id, style_desc, invctl_doc_line_nbr)
              VALUES(organization_id_a, rtl_loc_id_a, item_id_a, invctl_document_id_a, user_name_param, create_date_timestamp_a, description_a, store_name_a,
           unit_count_a, current_unit_count, unit_cost_a, unitcount_a, current_unit_count * unit_cost_a, vcomment, pending_unitCount, style_id_a, style_desc_a, invctl_document_nbr_a);
           END IF;
    END LOOP;
    CLOSE tableCur;
  EXCEPTION
    WHEN OTHERS THEN CLOSE tableCur;
END sp_fifo_detail;
/


GRANT EXECUTE ON sp_fifo_detail TO posusers,dbausers;
-- 
-- PROCEDURE: sp_fifo_summary 
--
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING procedure SP_FIFO_SUMMARY');

CREATE OR REPLACE PROCEDURE sp_fifo_summary
   (merch_level_1_param     in varchar2, 
    merch_level_2_param     in varchar2, 
    merch_level_3_param     in varchar2, 
    merch_level_4_param     in varchar2,
    item_id_param           in varchar2,
    style_id_param          in varchar2,
    rtl_loc_id_param        in varchar2, 
    organization_id_param   in int,
    user_name_param         in varchar2,
    stock_val_date_param    in DATE)
AUTHID CURRENT_USER 
 IS

            organization_id         int;
            item_id                 VARCHAR2(60);
            description             VARCHAR2(254);
            style_id                VARCHAR2(60);
            style_desc              VARCHAR2(254);
            rtl_loc_id              int;
            store_name              VARCHAR2(254);
            unit_count              DECIMAL(14,4);
            unit_cost               DECIMAL(17,6);
            vcomment                VARCHAR2(254);
  
  CURSOR tableCur IS 
      SELECT MAX(sla.organization_id), MAX(COALESCE(sla.unitcount,0)) + MAX(COALESCE(ts.quantity, 0)) AS quantity, sla.item_id, MAX(i.description), style.item_id, MAX(style.description), sla.rtl_loc_id, MAX(l.store_name),
      MAX(COALESCE(fifo_detail.unit_cost,0)), MAX(fifo_detail."comment")
      FROM loc_rtl_loc l, (select column_value from table(fn_integerListToTable(rtl_loc_id_param))) fn, inv_stock_ledger_acct sla
            LEFT OUTER JOIN
            (SELECT itm_mov.organization_id, itm_mov.rtl_loc_id, itm_mov.item_id, 
                    SUM(COALESCE(quantity,0) * CASE WHEN adjustment_flag = 1 THEN 1 ELSE -1 END) AS quantity
             FROM rpt_trl_stock_movement_view itm_mov
             WHERE to_char(business_date) > to_char(stock_val_date_param) 
             GROUP BY itm_mov.organization_id, itm_mov.rtl_loc_id, itm_mov.item_id) ts
             ON sla.organization_id = ts.organization_id
                AND sla.rtl_loc_id = ts.rtl_loc_id
                AND sla.item_id = ts.item_id
            LEFT OUTER JOIN (
                  SELECT organization_id, item_id, SUM(current_cost)/SUM(current_unit_count) as unit_cost, MAX("comment") as "comment"
                  FROM rpt_fifo_detail
               GROUP BY organization_id, item_id ) fifo_detail
             ON sla.organization_id = fifo_detail.organization_id AND 
                 sla.item_id = fifo_detail.item_id
             INNER JOIN itm_item i
              ON sla.item_id = i.item_id AND
                 sla.organization_id = i.organization_id
               LEFT OUTER JOIN itm_item style
              ON i.parent_item_id = style.item_id AND 
                 i.organization_id = style.organization_id
             WHERE merch_level_1_param in (i.merch_level_1,'%') AND merch_level_2_param in (i.merch_level_2,'%') AND 
                 merch_level_3_param IN (i.merch_level_3,'%') AND merch_level_4_param IN (i.merch_level_4,'%') AND
                 item_id_param IN (i.item_id,'%') AND style_id_param IN (i.parent_item_id,'%') AND
            fn.column_value = sla.rtl_loc_id AND
            sla.organization_id = l.organization_id AND 
            sla.rtl_loc_id = l.rtl_loc_id AND
            sla.bucket_id = 'ON_HAND' AND
            COALESCE(sla.unitcount,0) + COALESCE(ts.quantity, 0) <> 0
      GROUP BY sla.rtl_loc_id, style.item_id, sla.item_id
      ORDER BY sla.rtl_loc_id, sla.item_id DESC;

BEGIN      
    sp_fifo_detail (merch_level_1_param, merch_level_2_param, merch_level_3_param, merch_level_4_param, item_id_param, style_id_param, rtl_loc_id_param, organization_id_param, user_name_param, stock_val_date_param);
    EXECUTE IMMEDIATE 'DELETE FROM rpt_fifo WHERE user_name = ''' || user_name_param || '''';
    OPEN tableCur;
    LOOP
    FETCH tableCur INTO organization_id, unit_count, item_id, description, style_id, style_desc, rtl_loc_id, store_name, unit_cost, vcomment;
    EXIT WHEN tableCur%NOTFOUND;
      IF unit_cost=0 then
        unit_count :=0;
      END IF;
       INSERT INTO rpt_fifo (organization_id, rtl_loc_id, store_name, item_id, user_name, description,  
           style_id, style_desc, unit_count, unit_cost, "comment")
       VALUES(organization_id, rtl_loc_id, store_name, item_id, user_name_param, description, 
           style_id, style_desc, unit_count, unit_cost, vcomment); 
    END LOOP;
    CLOSE tableCur;
    EXCEPTION
        WHEN OTHERS THEN CLOSE tableCur;
END sp_fifo_summary;
/

GRANT EXECUTE ON sp_fifo_summary TO posusers,dbausers;
 
 

-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : sp_ins_upd_flash_sales
-- Description       : Loads data into the Report tables which are then used by the flash reports.
-- Version           : 19.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....      Initial Version
-- 
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING PROCEDURE sp_ins_upd_flash_sales');

CREATE OR REPLACE PROCEDURE sp_ins_upd_flash_sales (
argOrganizationId   IN NUMBER   /*organization id*/,
argRtlLocId         IN NUMBER   /*retail location or store number*/,
argBusinessDate     IN DATE     /*business date*/,
argWkstnId          IN NUMBER   /*register*/,
argLineEnum         IN VARCHAR2 /*flash sales classification*/,
argQty              IN NUMBER   /*quantity*/,
argNetAmt           IN NUMBER   /*net amount*/,
argCurrencyId       IN VARCHAR2
)
AUTHID CURRENT_USER 
IS
vcount int;
BEGIN
select decode(instr(DBMS_UTILITY.format_call_stack,'SP_FLASH'),0,0,1) into vcount from dual;
 if vcount>0 then
  UPDATE rpt_flash_sales
     SET line_count = COALESCE(line_count, 0) + argQty,
         line_amt = COALESCE(line_amt, 0) + argNetAmt,
         update_date = SYS_EXTRACT_UTC(SYSTIMESTAMP),
         update_user_id = USER
   WHERE organization_id = argOrganizationId
     AND rtl_loc_id = argRtlLocId
     AND wkstn_id = argWkstnId
     AND business_date = argBusinessDate
     AND line_enum = argLineEnum;

  IF SQL%NOTFOUND THEN
    INSERT INTO rpt_flash_sales (organization_id,
                                 rtl_loc_id,
                                 wkstn_id, 
                                 line_enum, 
                                 line_count,
                                 line_amt, 
                                 foreign_amt, 
                                 currency_id, 
                                 business_date, 
                                 create_date, 
                                 create_user_id)
    VALUES (argOrganizationId, 
            argRtlLocId, 
            argWkstnId, 
            argLineEnum, 
            argQty, 
            argNetAmt, 
            0, 
            argCurrencyId, 
            argBusinessDate, 
            SYS_EXTRACT_UTC(SYSTIMESTAMP), 
            USER);
  END IF;
 else
  raise_application_error( -20001, 'Cannot be run directly.' );
 end if;
END;
/

GRANT EXECUTE ON sp_ins_upd_flash_sales TO posusers,dbausers;


EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION sp_next_sequence_value');
CREATE OR REPLACE FUNCTION sp_next_sequence_value (
  argOrganizationId      number,
  argRetailLocationId    number,
  argWorkstationId       number,
  argSequenceId          varchar2,
  argSequenceMode        varchar2,
  argIncrement           number,
  argIncrementalValue    number,
  argMaximumValue        number,
  argInitialValue        number)
return number
AUTHID CURRENT_USER 
IS
    vCurrentSequence number(10,0);
    vNextSequence number(10,0);
  BEGIN 
  LOCK TABLE com_sequence IN EXCLUSIVE MODE;
    
    SELECT t.sequence_nbr INTO vCurrentSequence
        FROM com_sequence t 
        WHERE t.organization_id = argOrganizationId
        AND t.rtl_loc_id = argRetailLocationId
        AND t.wkstn_id = argWorkstationId
        AND t.sequence_id = argSequenceId
        AND t.sequence_mode = argSequenceMode;
        
      vNextSequence := vCurrentSequence + argIncrementalValue;
      IF(vNextSequence > argMaximumValue)  then
        vNextSequence := argInitialValue + argIncrementalValue;
      end if;  
        -- handle initial value -1
      IF (argIncrement = '1')  then
        UPDATE com_sequence
        SET sequence_nbr = vNextSequence
        WHERE organization_id = argOrganizationId
        AND rtl_loc_id = argRetailLocationId
        AND wkstn_id = argWorkstationId
        AND sequence_id = argSequenceId
        AND sequence_mode = argSequenceMode;
      END if;
      return vNextSequence;
    exception
      when NO_DATA_FOUND 
      then 
      begin
      IF (argIncrement = '1')  then
        vNextSequence := argInitialValue + argIncrementalValue;
      ELSE
        vNextSequence := argInitialValue;
      END if;   
      INSERT INTO com_sequence (organization_id, rtl_loc_id, wkstn_id, sequence_id, sequence_mode, sequence_nbr) 
      VALUES (argOrganizationId, argRetailLocationId, argWorkstationId, argSequenceId, argSequenceMode, vNextSequence);
      return vNextSequence;
      end;
END sp_next_sequence_value;
/

GRANT EXECUTE ON sp_next_sequence_value TO posusers,dbausers;


EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING PROCEDURE sp_set_sequence_value');
CREATE OR REPLACE PROCEDURE sp_set_sequence_value(
  argOrganizationId      number,
  argRetailLocationId    number,
  argWorkstationId       number,
  argSequenceId          varchar2,
  argSequenceMode        varchar2,
  argSequenceValue       number)
AUTHID CURRENT_USER 
IS
BEGIN
  LOCK TABLE com_sequence IN EXCLUSIVE MODE;
  
    UPDATE com_sequence 
        SET sequence_nbr = argSequenceValue
        WHERE organization_id = argOrganizationId
        AND rtl_loc_id = argRetailLocationId
        AND wkstn_id = argWorkstationId
        AND sequence_id = argSequenceId    
        And sequence_mode = argSequenceMode;
END sp_set_sequence_value;
/

GRANT EXECUTE ON sp_set_sequence_value TO posusers,dbausers;

EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING PROCEDURE sp_tables_inmemory');
CREATE OR REPLACE PROCEDURE sp_tables_inmemory 
    (venable varchar2) -- Yes = enables in-memory in all tables.  No = disables in-memory in all tables.
AUTHID CURRENT_USER 
AS
vcount int;
CURSOR mycur IS 
  select table_name,owner from all_tables
  where owner=upper('$(DbSchema)')
  order by table_name asc;

BEGIN
    FOR myval IN mycur
    LOOP
    IF substr(upper(venable),1,1) in ('1','T','Y','E') or upper(venable)='ON' THEN
      EXECUTE IMMEDIATE 'alter table ' || myval.owner || '.' || myval.table_name || ' inmemory MEMCOMPRESS FOR QUERY HIGH';
    ELSE
      EXECUTE IMMEDIATE 'alter table ' || myval.owner || '.' || myval.table_name || ' no inmemory';
    END IF;
    END LOOP;
    IF substr(upper(venable),1,1) in ('1','T','Y','E') or upper(venable)='ON' THEN
            dbms_output.put_line('In-Memory option has been enabled on all tables.
Please run the following line to enable the In-Memory option on all new tables.
ALTER TABLESPACE &dbDataTableSpace. DEFAULT INMEMORY MEMCOMPRESS FOR QUERY HIGH;');
    ELSE
        dbms_output.put_line('In-Memory option has been disabled on all tables.
Please run the following line to disable the In-Memory option on all new tables.
ALTER TABLESPACE &dbDataTableSpace. DEFAULT NO INMEMORY;');
    END IF;
END;
/

GRANT EXECUTE ON sp_tables_inmemory TO dbausers;

-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : SP_WRITE_DBMS_OUTPUT_TO_FILE
-- Description       : 
-- Version           : 19.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....         Initial Version
-------------------------------------------------------------------------------------------------------------------

EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING PROCEDURE sp_write_dbms_output_to_file');

create or replace PROCEDURE sp_write_dbms_output_to_file(logname varchar) AS
   l_line VARCHAR2(255);
   l_done NUMBER;
   l_file utl_file.file_type;
   ext NUMBER;
BEGIN
   ext := INSTR(logname,'.', 1);
   if ext = 0 then
    l_file := utl_file.fopen('EXP_DIR', logname || '.log', 'A');
   else
    l_file := utl_file.fopen('EXP_DIR', logname, 'A');
   end if;
   LOOP
      dbms_output.get_line(l_line, l_done);
      EXIT WHEN l_done = 1;
      utl_file.put_line(l_file, substr(to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS,FF'),1,23) || ' ' || l_line);
   END LOOP;
   utl_file.fflush(l_file);
   utl_file.fclose(l_file);
END sp_write_dbms_output_to_file;
/

GRANT EXECUTE ON sp_write_dbms_output_to_file TO posusers,dbausers;

 
-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : SP_EXPORT_DATABASE
-- Description       : This procedure is called on the local database to export all of the XStore objects.
-- Version           : 19.0
--
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... ..........         Initial Version
-- PGH 11/04/10     Converted to a function, so a return code can be sent back to Data Server.
-- BCW 09/11/15     Added reuse file to ADD_FILE.  This ability was added in 11g.
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION SP_EXPORT_DATABASE');

CREATE OR REPLACE FUNCTION SP_EXPORT_DATABASE 
(  
    argExportPath          varchar2,                   -- Import Directory Name
    argBackupDataFile      varchar2,                   -- Dump File Name
    argOutputFile          varchar2,                   -- Log File Name
    argSourceOwner         varchar2                    -- Source Owner User Name
)
RETURN INTEGER
IS

-- Varaibles for the Datapump section
h1                      NUMBER;         -- Data Pump job handle
job_state               VARCHAR2(30);   -- To keep track of job state
ind                     NUMBER;         -- loop index
le                      ku$_LogEntry;   -- WIP and error messages
js                      ku$_JobStatus;  -- job status from get_status
jd                      ku$_JobDesc;    -- job description from get_status
sts                     ku$_Status;     -- status object returned by
rowcnt                  NUMBER; 

BEGIN
    --Enable Server Output
    DBMS_OUTPUT.ENABLE (buffer_size => NULL);
    DBMS_OUTPUT.PUT_LINE (user || ' is starting SP_EXPORT_DATABASE.');
    sp_write_dbms_output_to_file('SP_EXPORT_DATABASE');

    --
    -- Checks to see if the Data Pump work table exists and drops it.
    --
    select count(*)
        into rowcnt
        from all_tables
        where table_name = 'XSTORE_EXPORT';
          
    IF rowcnt > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE XSTORE_EXPORT';
    END IF;

    --
    -- Create a schema level export for the DTV objects
    --
    h1 := DBMS_DATAPUMP.OPEN('EXPORT', 'SCHEMA', NULL, 'XSTORE_EXPORT', 'LATEST');
    DBMS_DATAPUMP.METADATA_FILTER(h1, 'SCHEMA_EXPR', 'IN ('''|| argSourceOwner ||''')');

    DBMS_DATAPUMP.METADATA_FILTER(h1,'NAME_EXPR','!=''SP_IMPORT_DATABASE''', 'FUNCTION');
    DBMS_DATAPUMP.METADATA_FILTER(h1,'NAME_EXPR','!=''SP_WRITE_DBMS_OUTPUT_TO_FILE''', 'PROCEDURE');
    DBMS_DATAPUMP.METADATA_FILTER(h1, 'EXCLUDE_PATH_EXPR', 'IN (''STATISTICS'')');
    DBMS_DATAPUMP.SET_PARAMETER(h1, 'METRICS', 1);

    --
    -- Adds the data and log files
    --
    DBMS_DATAPUMP.ADD_FILE(h1, argBackupDataFile, argExportPath, NULL, DBMS_DATAPUMP.KU$_FILE_TYPE_DUMP_FILE, 1);
    DBMS_DATAPUMP.ADD_FILE(h1, argOutputFile, argExportPath, NULL, DBMS_DATAPUMP.KU$_FILE_TYPE_LOG_FILE, 1);
    
    --
    -- Start the job. An exception will be generated if something is not set up
    -- properly.
    --
    DBMS_DATAPUMP.START_JOB(h1);

    --
    -- Waits until the job as completed
    --
    DBMS_DATAPUMP.WAIT_FOR_JOB (h1, job_state);

    dbms_output.put_line('Job has completed');
    dbms_output.put_line('Final job state = ' || job_state);

    dbms_datapump.detach(h1);
    
    DBMS_OUTPUT.PUT_LINE ('Ending SP_EXPORT_DATABASE...');
    sp_write_dbms_output_to_file('SP_EXPORT_DATABASE');
    DBMS_OUTPUT.DISABLE ();
    RETURN 0;
    
EXCEPTION
    WHEN OTHERS THEN
    BEGIN
        dbms_datapump.get_status(h1, 
                                    dbms_datapump.ku$_status_job_error, 
                                    -1, 
                                    job_state, 
                                    sts);
        js := sts.job_status;
        le := sts.error;
        IF le IS NOT NULL THEN
          ind := le.FIRST;
          WHILE ind IS NOT NULL LOOP
            dbms_output.put_line(le(ind).LogText);
            ind := le.NEXT(ind);
          END LOOP;
        END IF;
    
        DBMS_DATAPUMP.STOP_JOB (h1, -1, 0, 0);
        dbms_datapump.detach(h1);

        DBMS_OUTPUT.PUT_LINE ('Ending SP_EXPORT_DATABASE...');
        sp_write_dbms_output_to_file('SP_EXPORT_DATABASE');
        DBMS_OUTPUT.DISABLE ();
       return -1;
    END;
END;
/

GRANT EXECUTE ON SP_EXPORT_DATABASE TO dbausers;


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
-- ... .....        Initial Version
-- PGH  02/23/10    Removed the currencyid paramerer, then joining the loc_rtl_loc table to get the default
--                  currencyid for the location.  If the default is not set, defaulting to 'USD'. 
-- BCW  06/21/12    Updated per Emily Tan's instructions.
-- BCW  12/06/13    Replaced the sale cursor by writing the transaction line item directly into the rpt_sale_line table.
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING PROCEDURE SP_FLASH');

CREATE OR REPLACE PROCEDURE sp_flash 
  (argOrganizationId    IN NUMBER, 
   argRetailLocationId  IN NUMBER, 
   argBusinessDate      IN DATE, 
   argWrkstnId          IN NUMBER, 
   argTransSeq          IN NUMBER) 
AUTHID CURRENT_USER 
IS

myerror exception;
myreturn exception;

-- Arguments
pvOrganizationId        NUMBER(10);
pvRetailLocationId      NUMBER(10); 
pvBusinessDate          DATE;
pvWrkstnId              NUMBER(20,0);
pvTransSeq              NUMBER(20,0);

-- Quantities
vActualQuantity         NUMBER (11,2);
vGrossQuantity          NUMBER (11,2);
vQuantity               NUMBER (11,2);
vTotQuantity            NUMBER (11,2);

-- Amounts
vNetAmount              NUMBER (17,6);
vGrossAmount            NUMBER (17,6);
vTotGrossAmt            NUMBER (17,6);
vTotNetAmt              NUMBER (17,6);
vDiscountAmt            NUMBER (17,6);
vOverrideAmt            NUMBER (17,6);
vPaidAmt                NUMBER (17,6);
vTenderAmt              NUMBER (17,6);
vForeign_amt            NUMBER (17,6);
vLayawayPrice           NUMBER(17,6);
vUnitPrice              NUMBER (17,6);

-- Non Physical Items
vNonPhys                VARCHAR2(30 char);
vNonPhysSaleType        VARCHAR2(30 char);
vNonPhysType            VARCHAR2(30 char);
vNonPhysPrice           NUMBER (17,6);
vNonPhysQuantity        NUMBER (11,2);

-- Status codes
vTransStatcode          VARCHAR2(30 char);
vTransTypcode           VARCHAR2(30 char);
vSaleLineItmTypcode     VARCHAR2(30 char);
vTndrStatcode           VARCHAR2(60 char);
vLineitemStatcode       VARCHAR2(30 char);

-- others
vTransTimeStamp         TIMESTAMP;
vTransDate              TIMESTAMP;
vTransCount             NUMBER(10);
vTndrCount              NUMBER(10);
vPostVoidFlag           NUMBER(1);
vReturnFlag             NUMBER(1);
vTaxTotal               NUMBER (17,6);
vPaid                   VARCHAR2(30 char);
vLineEnum               VARCHAR2(150 char);
vTndrId                 VARCHAR2(60 char);
vItemId                 VARCHAR2(60 char);
vRtransLineItmSeq       NUMBER(10);
vDepartmentId           VARCHAR2(90 char);
vTndridProp             VARCHAR2(60 char);
vCurrencyId             VARCHAR2(3 char);
vTndrTypCode            VARCHAR2(30 char);

vSerialNbr              VARCHAR2(60 char);
vPriceModAmt            NUMBER(17,6);
vPriceModReascode       VARCHAR2(60 char);
vNonPhysExcludeFlag     NUMBER(1);
vCustPartyId            VARCHAR2(60 char);
vCustLastName           VARCHAR2(90 char);
vCustFirstName          VARCHAR2(90 char);
vItemDesc               VARCHAR2(254 char);
vBeginTimeInt           NUMBER(10);

-- counts
vRowCnt                 NUMBER(10);
vCntTrans               NUMBER(10);
vCntTndrCtl             NUMBER(10);
vCntPostVoid            NUMBER(10);
vCntRevTrans            NUMBER(10);
vCntNonPhysItm          NUMBER(10);
vCntNonPhys             NUMBER(10);
vCntCust                NUMBER(10);
vCntItem                NUMBER(10);
vCntParty               NUMBER(10);

-- cursors

CURSOR tenderCursor IS 
    SELECT t.amt, t.foreign_amt, t.tndr_id, t.tndr_statcode, tr.string_value, tnd.tndr_typcode 
        FROM TTR_TNDR_LINEITM t 
        inner join TRL_RTRANS_LINEITM r ON t.organization_id=r.organization_id
                                       AND t.rtl_loc_id=r.rtl_loc_id
                                       AND t.wkstn_id=r.wkstn_id
                                       AND t.trans_seq=r.trans_seq
                                       AND t.business_date=r.business_date
                                       AND t.rtrans_lineitm_seq=r.rtrans_lineitm_seq
        inner join TND_TNDR tnd ON t.organization_id=tnd.organization_id
                                       AND t.tndr_id=tnd.tndr_id                                   
    left outer join trl_rtrans_lineitm_p tr on tr.organization_id=r.organization_id
                    and tr.rtl_loc_id=r.rtl_loc_id
                    and tr.wkstn_id=r.wkstn_id
                    and tr.trans_seq=r.trans_seq
                    and tr.business_date=r.business_date
                    and tr.rtrans_lineitm_seq=r.rtrans_lineitm_seq
                    and lower(property_code) = 'tender_id'
        WHERE t.organization_id = pvOrganizationId
          AND t.rtl_loc_id = pvRetailLocationId
          AND t.wkstn_id = pvWrkstnId
          AND t.trans_seq = pvTransSeq
          AND t.business_date = pvBusinessDate
          AND r.void_flag = 0
          AND t.tndr_id <> 'ACCOUNT_CREDIT';

CURSOR postVoidTenderCursor IS 
    SELECT t.amt, t.foreign_amt, t.tndr_id, t.tndr_statcode, tr.string_value 
        FROM TTR_TNDR_LINEITM t 
        inner join TRL_RTRANS_LINEITM r ON t.organization_id=r.organization_id
                                       AND t.rtl_loc_id=r.rtl_loc_id
                                       AND t.wkstn_id=r.wkstn_id
                                       AND t.trans_seq=r.trans_seq
                                       AND t.business_date=r.business_date
                                       AND t.rtrans_lineitm_seq=r.rtrans_lineitm_seq
    left outer join trl_rtrans_lineitm_p tr on tr.organization_id=r.organization_id
                    and tr.rtl_loc_id=r.rtl_loc_id
                    and tr.wkstn_id=r.wkstn_id
                    and tr.trans_seq=r.trans_seq
                    and tr.business_date=r.business_date
                    and tr.rtrans_lineitm_seq=r.rtrans_lineitm_seq
                    and lower(property_code) = 'tender_id'
        WHERE t.organization_id = pvOrganizationId
          AND t.rtl_loc_id = pvRetailLocationId
          AND t.wkstn_id = pvWrkstnId
          AND t.trans_seq = pvTransSeq
          AND t.business_date = pvBusinessDate
          AND r.void_flag = 0
      AND t.tndr_id <> 'ACCOUNT_CREDIT';

CURSOR saleCursor IS
       select rsl.item_id,
       sale_lineitm_typcode,
       actual_quantity,
       unit_price,
       case vPostVoidFlag when 1 then -1 else 1 end * coalesce(gross_amt,0),
       case when return_flag=vPostVoidFlag then 1 else -1 end * coalesce(gross_quantity,0),
       merch_level_1,
       case vPostVoidFlag when 1 then -1 else 1 end * coalesce(net_amt,0),
       case when return_flag=vPostVoidFlag then 1 else -1 end * coalesce(quantity,0),
     return_flag 
       from rpt_sale_line rsl
     left join itm_non_phys_item inp on rsl.item_id=inp.item_id and rsl.organization_id=inp.organization_id
       WHERE rsl.organization_id = pvOrganizationId
          AND rtl_loc_id = pvRetailLocationId
          AND wkstn_id = pvWrkstnId
          AND business_date = pvBusinessDate
          AND trans_seq = pvTransSeq
      and QUANTITY <> 0
      and sale_lineitm_typcode not in ('ONHOLD','WORK_ORDER')
      and coalesce(exclude_from_net_sales_flag,0)=0;

-- Declarations end 

BEGIN
    -- initializations of args
    pvOrganizationId      := argOrganizationId;
    pvRetailLocationId    := argRetailLocationId;
    pvWrkstnId            := argWrkstnId;
    pvBusinessDate        := argBusinessDate;
    pvTransSeq            := argTransSeq;

    BEGIN
    SELECT tt.trans_statcode,
           tt.trans_typcode, 
           tt.begin_datetime, 
           tt.trans_date,
           tt.taxtotal, 
           tt.post_void_flag, 
           tt.begin_time_int,
           coalesce(t.currency_id, rl.currency_id)
        INTO vTransStatcode, 
             vTransTypcode, 
             vTransTimeStamp, 
             vTransDate,
             vTaxTotal, 
             vPostVoidFlag, 
             vBeginTimeInt,
             vCurrencyID
        FROM TRN_TRANS tt  
            LEFT JOIN loc_rtl_loc rl on tt.organization_id = rl.organization_id and tt.rtl_loc_id = rl.rtl_loc_id
      LEFT JOIN (select max(currency_id) currency_id,ttl.organization_id,ttl.rtl_loc_id,ttl.wkstn_id,ttl.business_date,ttl.trans_seq
      from ttr_tndr_lineitm ttl
      inner join tnd_tndr tnd on ttl.organization_id=tnd.organization_id and ttl.tndr_id=tnd.tndr_id
      group by ttl.organization_id,ttl.rtl_loc_id,ttl.wkstn_id,ttl.business_date,ttl.trans_seq) t ON
      tt.organization_id = t.organization_id
          AND tt.rtl_loc_id = t.rtl_loc_id
          AND tt.wkstn_id = t.wkstn_id
          AND tt.business_date = t.business_date
          AND tt.trans_seq = t.trans_seq
        WHERE tt.organization_id = pvOrganizationId
          AND tt.rtl_loc_id = pvRetailLocationId
          AND tt.wkstn_id = pvWrkstnId
          AND tt.business_date = pvBusinessDate
          AND tt.trans_seq = pvTransSeq;
    EXCEPTION
        WHEN no_data_found THEN
        NULL;
    END;
    
    vCntTrans := SQL%ROWCOUNT;
    
    IF vCntTrans = 1 THEN 
    
    -- so update the column on trn trans
        UPDATE TRN_TRANS SET flash_sales_flag = 1
            WHERE organization_id = pvOrganizationId
            AND rtl_loc_id = pvRetailLocationId
            AND wkstn_id = pvWrkstnId
            AND trans_seq = pvTransSeq
            AND business_date = pvBusinessDate;
    ELSE
        -- /* Invalid transaction */
        raise myerror;
        
    END IF;

    vTransCount := 1; -- /* initializing the transaction count */

  select count(*) into vCntTrans from rpt_sale_line
    WHERE organization_id = pvOrganizationId
    AND rtl_loc_id = pvRetailLocationId
    AND wkstn_id = pvWrkstnId
    AND trans_seq = pvTransSeq
    AND business_date = pvBusinessDate;

  IF vCntTrans = 0 AND vPostVoidFlag = 1 THEN
    insert into rpt_sale_line
    (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq,
    quantity, actual_quantity, gross_quantity, unit_price, net_amt, gross_amt, item_id, 
    item_desc, merch_level_1, serial_nbr, return_flag, override_amt, trans_timestamp, trans_date,
    discount_amt, cust_party_id, last_name, first_name, trans_statcode, sale_lineitm_typcode, begin_time_int, exclude_from_net_sales_flag)
    select tsl.organization_id, tsl.rtl_loc_id, tsl.business_date, tsl.wkstn_id, tsl.trans_seq, tsl.rtrans_lineitm_seq,
    tsl.net_quantity, tsl.quantity, tsl.gross_quantity, tsl.unit_price,
    -- For VAT taxed items there are rounding problems by which the usage of the tsl.net_amt could create problems.
    -- So, we are calculating it using the tax amount which could have more decimals and because that it is more accurate
    case when vat_amt is null then tsl.net_amt else tsl.gross_amt-tsl.vat_amt-coalesce(d.discount_amt,0) end, 
    tsl.gross_amt, tsl.item_id,
    i.DESCRIPTION, coalesce(tsl.merch_level_1,i.MERCH_LEVEL_1,'DEFAULT'), tsl.serial_nbr, tsl.return_flag, coalesce(o.override_amt,0), vTransTimeStamp, vTransDate,
    coalesce(d.discount_amt,0), tr.cust_party_id, cust.last_name, cust.first_name, 'VOID', tsl.sale_lineitm_typcode, vBeginTimeInt, tsl.exclude_from_net_sales_flag
    from trl_sale_lineitm tsl
    inner join trl_rtrans_lineitm r
    on tsl.organization_id=r.organization_id
    and tsl.rtl_loc_id=r.rtl_loc_id
    and tsl.wkstn_id=r.wkstn_id
    and tsl.trans_seq=r.trans_seq
    and tsl.business_date=r.business_date
    and tsl.rtrans_lineitm_seq=r.rtrans_lineitm_seq
    and r.rtrans_lineitm_typcode = 'ITEM'
    left join xom_order_mod xom
    on tsl.organization_id=xom.organization_id
    and tsl.rtl_loc_id=xom.rtl_loc_id
    and tsl.wkstn_id=xom.wkstn_id
    and tsl.trans_seq=xom.trans_seq
    and tsl.business_date=xom.business_date
    and tsl.rtrans_lineitm_seq=xom.rtrans_lineitm_seq
    left join xom_order_line_detail xold
    on xom.organization_id=xold.organization_id
    and xom.order_id=xold.order_id
    and xom.detail_seq=xold.detail_seq
    and xom.detail_line_number=xold.detail_line_number
    left join itm_item i
    on tsl.organization_id=i.ORGANIZATION_ID
    and tsl.item_id=i.ITEM_ID
    left join (select * from (select extended_amt override_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
            FROM trl_rtl_price_mod
            WHERE void_flag = 0 and rtl_price_mod_reascode='PRICE_OVERRIDE' order by organization_id, rtl_loc_id, business_date, wkstn_id, rtrans_lineitm_seq, trans_seq, rtl_price_mod_seq_nbr desc) where rownum =1) o
    on tsl.organization_id = o.organization_id 
      AND tsl.rtl_loc_id = o.rtl_loc_id
      AND tsl.business_date = o.business_date 
      AND tsl.wkstn_id = o.wkstn_id 
      AND tsl.trans_seq = o.trans_seq
      AND tsl.rtrans_lineitm_seq = o.rtrans_lineitm_seq
    left join (select sum(extended_amt) discount_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
      FROM trl_rtl_price_mod
      WHERE void_flag = 0 and rtl_price_mod_reascode in ('LINE_ITEM_DISCOUNT', 'TRANSACTION_DISCOUNT', 'GROUP_DISCOUNT', 'NEW_PRICE_RULE', 'DEAL', 'ENTITLEMENT')
      group by organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq) d
    on tsl.organization_id = d.organization_id 
      AND tsl.rtl_loc_id = d.rtl_loc_id
      AND tsl.business_date = d.business_date 
      AND tsl.wkstn_id = d.wkstn_id 
      AND tsl.trans_seq = d.trans_seq
      AND tsl.rtrans_lineitm_seq = d.rtrans_lineitm_seq
    left join trl_rtrans tr
    on tsl.organization_id = tr.organization_id 
      AND tsl.rtl_loc_id = tr.rtl_loc_id
      AND tsl.business_date = tr.business_date 
      AND tsl.wkstn_id = tr.wkstn_id 
      AND tsl.trans_seq = tr.trans_seq
    left join crm_party cust
    on tsl.organization_id = cust.organization_id 
      AND tr.cust_party_id = cust.party_id
    where tsl.organization_id = pvOrganizationId
    and tsl.rtl_loc_id = pvRetailLocationId
    and tsl.wkstn_id = pvWrkstnId
    and tsl.business_date = pvBusinessDate
    and tsl.trans_seq = pvTransSeq
    and r.void_flag=0
    and ((tsl.SALE_LINEITM_TYPCODE <> 'ORDER'and (xom.detail_type IS NULL OR xold.status_code = 'FULFILLED') )
    or (tsl.SALE_LINEITM_TYPCODE = 'ORDER' and xom.detail_type in ('FEE', 'PAYMENT') ));
    raise myreturn;
  END IF;

    -- collect transaction data
    IF ABS(vTaxTotal) > 0 AND vTransTypcode <> 'POST_VOID' AND vPostVoidFlag = 0 AND vTransStatcode = 'COMPLETE' THEN
      
        sp_ins_upd_flash_sales (pvOrganizationId, 
                                pvRetailLocationId, 
                                vTransDate,
                                pvWrkstnId, 
                                'TOTALTAX', 
                                1, 
                                vTaxTotal, 
                                vCurrencyId);
      
    END IF;

    IF vTransTypcode = 'TENDER_CONTROL' AND vPostVoidFlag = 0 THEN    -- process for paid in paid out 
    
        BEGIN
        SELECT  typcode, amt INTO vPaid, vPaidAmt 
            FROM TSN_TNDR_CONTROL_TRANS 
            WHERE typcode LIKE 'PAID%'
              AND organization_id = pvOrganizationId
              AND rtl_loc_id = pvRetailLocationId
              AND wkstn_id = pvWrkstnId
              AND trans_seq = pvTransSeq
              AND business_date = pvBusinessDate;
           EXCEPTION
        WHEN no_data_found THEN
            NULL;
        END;


        vCntTndrCtl := SQL%ROWCOUNT;
    
        IF vCntTndrCtl = 1 THEN   
            
                IF vTransStatcode = 'COMPLETE' THEN
                        -- it is paid in or paid out
                    IF vPaid = 'PAID_IN' OR vPaid = 'PAIDIN' THEN
                        vLineEnum := 'paidin';
                    ELSE
                        vLineEnum := 'paidout';
                    END IF; 
                        -- update flash sales                 
                        sp_ins_upd_flash_sales (pvOrganizationId, 
                                               pvRetailLocationId, 
                                               vTransDate,
                                               pvWrkstnId, 
                                               vLineEnum, 
                                               1, 
                                               vPaidAmt, 
                                               vCurrencyId);
                END IF;
        END IF;
    END IF;
  
  -- collect tenders  data
  IF vPostVoidFlag = 0 AND vTransTypcode <> 'POST_VOID' THEN
  BEGIN
    OPEN tenderCursor;
    LOOP
        FETCH tenderCursor INTO vTenderAmt, vForeign_amt, vTndrid, vTndrStatcode, vTndridProp, vTndrTypCode; 
        EXIT WHEN tenderCursor%NOTFOUND;
  
        IF vTndrTypCode='VOUCHER' OR vTndrStatcode <> 'Change' THEN
            vTndrCount := 1;-- only for original tenders
        ELSE 
            vTndrCount := 0;
        END IF;

        if vTndridProp IS NOT NULL THEN
           vTndrid := vTndridProp;
    end if;

       IF vLineEnum = 'paidout' THEN
            vTenderAmt := vTenderAmt * -1;
            vForeign_amt := vForeign_amt * -1;
        END IF;

        -- update flash
        IF vTransStatcode = 'COMPLETE' THEN
            sp_ins_upd_flash_sales (pvOrganizationId, 
                                    pvRetailLocationId, 
                                    vTransDate, 
                                    pvWrkstnId, 
                                    vTndrid, 
                                    vTndrCount, 
                                    vTenderAmt, 
                                    vCurrencyId);
        END IF;

        IF vTenderAmt > 0 AND vTransStatcode = 'COMPLETE' THEN
            sp_ins_upd_flash_sales (pvOrganizationId, 
                                    pvRetailLocationId, 
                                    vTransDate, 
                                    pvWrkstnId,
                                    'TendersTakenIn', 
                                    1, 
                                    vTenderAmt, 
                                    vCurrencyId);
        ELSE
            sp_ins_upd_flash_sales (pvOrganizationId, 
                                    pvRetailLocationId, 
                                    vTransDate, 
                                    pvWrkstnId, 
                                    'TendersRefunded', 
                                    1, 
                                    vTenderAmt, 
                                    vCurrencyId);
        END IF;
    END LOOP;
    CLOSE tenderCursor;
  EXCEPTION
    WHEN OTHERS THEN CLOSE tenderCursor;
  END;
  END IF;
  
  -- collect post void info
  IF vTransTypcode = 'POST_VOID' OR vPostVoidFlag = 1 THEN
      vTransCount := -1; /* reversing the count */
      IF vPostVoidFlag = 0 THEN
        vPostVoidFlag := 1;
      
            /* NOTE: From now on the parameter value carries the original post voided
                information rather than the current transaction information in 
                case of post void trans type. This will apply for sales data 
                processing.
            */
            BEGIN
            SELECT voided_org_id, voided_rtl_store_id, voided_wkstn_id, voided_business_date, voided_trans_id 
              INTO pvOrganizationId, pvRetailLocationId, pvWrkstnId, pvBusinessDate, pvTransSeq
              FROM TRN_POST_VOID_TRANS 
              WHERE organization_id = pvOrganizationId
                AND rtl_loc_id = pvRetailLocationId
                AND wkstn_id = pvWrkstnId
                AND business_date = pvBusinessDate
                AND trans_seq = pvTransSeq;
            EXCEPTION
                WHEN no_data_found THEN
                NULL;
            END;

            vCntPostVoid := SQL%ROWCOUNT;

            IF vCntPostVoid = 0 THEN      
              
                raise myerror; -- don't know the original post voided record
            END IF;

      select count(*) into vCntPostVoid from rpt_sale_line
      WHERE organization_id = pvOrganizationId
      AND rtl_loc_id = pvRetailLocationId
      AND wkstn_id = pvWrkstnId
      AND trans_seq = pvTransSeq
      AND business_date = pvBusinessDate
      AND trans_statcode = 'VOID';

      IF vCntPostVoid > 0 THEN
                raise myreturn; -- record already exists
      END IF;
    END IF;
    -- updating for postvoid
     UPDATE rpt_sale_line
       SET trans_statcode='VOID'
       WHERE organization_id = pvOrganizationId
         AND rtl_loc_id = pvRetailLocationId
         AND wkstn_id = pvWrkstnId
         AND business_date = pvBusinessDate
         AND trans_seq = pvTransSeq; 
        
      BEGIN
      SELECT typcode, amt INTO vPaid, vPaidAmt
        FROM TSN_TNDR_CONTROL_TRANS 
        WHERE typcode LIKE 'PAID%'
          AND organization_id = pvOrganizationId
          AND rtl_loc_id = pvRetailLocationId
          AND wkstn_id = pvWrkstnId
          AND trans_seq = pvTransSeq
          AND business_date = pvBusinessDate;
      EXCEPTION WHEN no_data_found THEN
          NULL;
      END;


      IF SQL%FOUND AND vTransStatcode = 'COMPLETE' THEN
        -- it is paid in or paid out
        IF vPaid = 'PAID_IN' OR vPaid = 'PAIDIN' THEN
            vLineEnum := 'paidin';
        ELSE
            vLineEnum := 'paidout';
        END IF;
        vPaidAmt := vPaidAmt * -1 ;

        -- update flash sales                 
        sp_ins_upd_flash_sales (pvOrganizationId, 
                                pvRetailLocationId, 
                                vTransDate,
                                pvWrkstnId, 
                                vLineEnum, 
                                -1, 
                                vPaidAmt, 
                                vCurrencyId);
      END IF;
    
        BEGIN
        SELECT taxtotal INTO vTaxTotal
          FROM TRN_TRANS 
          WHERE organization_id = pvOrganizationId
            AND rtl_loc_id = pvRetailLocationId
            AND wkstn_id = pvWrkstnId
            AND business_date = pvBusinessDate
            AND trans_seq = pvTransSeq;
        EXCEPTION WHEN no_data_found THEN
            NULL;
        END;
        
        vCntRevTrans := SQL%ROWCOUNT;
        
        IF vCntRevTrans = 1 THEN    
            IF ABS(vTaxTotal) > 0 AND vTransStatcode = 'COMPLETE' THEN
                vTaxTotal := vTaxTotal * -1 ;
                sp_ins_upd_flash_sales (pvOrganizationId,
                                        pvRetailLocationId,
                                        vTransDate,
                                        pvWrkstnId,
                                        'TOTALTAX',
                                        -1,
                                        vTaxTotal, 
                                        vCurrencyId);
            END IF;
        END IF;

        -- reverse tenders
    BEGIN
        OPEN postVoidTenderCursor;
        
        LOOP
            FETCH postVoidTenderCursor INTO vTenderAmt, vForeign_amt, vTndrid, vTndrStatcode, vTndridProp;
            EXIT WHEN postVoidTenderCursor%NOTFOUND;
          
            IF vTndrStatcode <> 'Change' THEN
              vTndrCount := -1 ; -- only for original tenders
            ELSE 
              vTndrCount := 0 ;
            END IF;
          
      if vTndridProp IS NOT NULL THEN
         vTndrid := vTndridProp;
      end if;

            -- update flash
            vTenderAmt := vTenderAmt * -1;

            IF vTransStatcode = 'COMPLETE' THEN
                sp_ins_upd_flash_sales (pvOrganizationId, 
                                        pvRetailLocationId, 
                                        vTransDate, 
                                        pvWrkstnId, 
                                        vTndrid, 
                                        vTndrCount, 
                                        vTenderAmt, 
                                        vCurrencyId);
            END IF;
            
            IF vTenderAmt < 0 AND vTransStatcode = 'COMPLETE' THEN
                sp_ins_upd_flash_sales (pvOrganizationId, 
                                        pvRetailLocationId, 
                                        vTransDate, 
                                        pvWrkstnId,
                                        'TendersTakenIn',
                                        -1, 
                                        vTenderAmt, 
                                        vCurrencyId);
            ELSE
                sp_ins_upd_flash_sales (pvOrganizationId, 
                                        pvRetailLocationId, 
                                        vTransDate, 
                                        pvWrkstnId,
                                        'TendersRefunded',
                                        -1, 
                                        vTenderAmt, 
                                        vCurrencyId);
            END IF;
        END LOOP;
        
        CLOSE postVoidTenderCursor;
    EXCEPTION
      WHEN OTHERS THEN CLOSE postVoidTenderCursor;
  END;
  END IF;
  
  -- collect sales data
          

IF vPostVoidFlag = 0 and vTransTypcode <> 'POST_VOID' THEN -- dont do it for rpt sale line
        -- sale item insert
         insert into rpt_sale_line
        (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq,
        quantity, actual_quantity, gross_quantity, unit_price, net_amt, gross_amt, item_id, 
        item_desc, merch_level_1, serial_nbr, return_flag, override_amt, trans_timestamp, trans_date,
        discount_amt, cust_party_id, last_name, first_name, trans_statcode, sale_lineitm_typcode, begin_time_int, exclude_from_net_sales_flag)
        select tsl.organization_id, tsl.rtl_loc_id, tsl.business_date, tsl.wkstn_id, tsl.trans_seq, tsl.rtrans_lineitm_seq,
        tsl.net_quantity, tsl.quantity, tsl.gross_quantity, tsl.unit_price,
        -- For VAT taxed items there are rounding problems by which the usage of the tsl.net_amt could create problems.
        -- So, we are calculating it using the tax amount which could have more decimals and because that it is more accurate
        case when vat_amt is null then tsl.net_amt else tsl.gross_amt-tsl.vat_amt-coalesce(d.discount_amt,0) end,
        tsl.gross_amt, tsl.item_id,
        i.DESCRIPTION, coalesce(tsl.merch_level_1,i.MERCH_LEVEL_1,'DEFAULT'), tsl.serial_nbr, tsl.return_flag, coalesce(o.override_amt,0), vTransTimeStamp, vTransDate,
        coalesce(d.discount_amt,0), tr.cust_party_id, cust.last_name, cust.first_name, vTransStatcode, tsl.sale_lineitm_typcode, vBeginTimeInt, tsl.exclude_from_net_sales_flag
        from trl_sale_lineitm tsl
        inner join trl_rtrans_lineitm r
        on tsl.organization_id=r.organization_id
        and tsl.rtl_loc_id=r.rtl_loc_id
        and tsl.wkstn_id=r.wkstn_id
        and tsl.trans_seq=r.trans_seq
        and tsl.business_date=r.business_date
        and tsl.rtrans_lineitm_seq=r.rtrans_lineitm_seq
        and r.rtrans_lineitm_typcode = 'ITEM'
        left join xom_order_mod xom
            on tsl.organization_id=xom.organization_id
            and tsl.rtl_loc_id=xom.rtl_loc_id
            and tsl.wkstn_id=xom.wkstn_id
            and tsl.trans_seq=xom.trans_seq
            and tsl.business_date=xom.business_date
            and tsl.rtrans_lineitm_seq=xom.rtrans_lineitm_seq
        left join xom_order_line_detail xold
            on xom.organization_id=xold.organization_id
            and xom.order_id=xold.order_id
            and xom.detail_seq=xold.detail_seq
            and xom.detail_line_number=xold.detail_line_number
            left join itm_item i
        on tsl.organization_id=i.ORGANIZATION_ID
        and tsl.item_id=i.ITEM_ID
        left join (select * from (select extended_amt override_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
            FROM trl_rtl_price_mod
            WHERE void_flag = 0 and rtl_price_mod_reascode='PRICE_OVERRIDE' 
              and organization_id = pvOrganizationId
              and rtl_loc_id = pvRetailLocationId
              and wkstn_id = pvWrkstnId
              and business_date = pvBusinessDate
              and trans_seq = pvTransSeq 
              order by organization_id, rtl_loc_id, business_date, wkstn_id, rtrans_lineitm_seq, trans_seq, rtl_price_mod_seq_nbr desc) where rownum =1) o
        on tsl.organization_id = o.organization_id 
            AND tsl.rtl_loc_id = o.rtl_loc_id
            AND tsl.business_date = o.business_date 
            AND tsl.wkstn_id = o.wkstn_id 
            AND tsl.trans_seq = o.trans_seq
            AND tsl.rtrans_lineitm_seq = o.rtrans_lineitm_seq
        left join (select sum(extended_amt) discount_amt,organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq
            FROM trl_rtl_price_mod
            WHERE void_flag = 0 and rtl_price_mod_reascode in ('LINE_ITEM_DISCOUNT', 'TRANSACTION_DISCOUNT', 'GROUP_DISCOUNT', 'NEW_PRICE_RULE', 'DEAL', 'ENTITLEMENT')
            group by organization_id,rtl_loc_id,business_date,wkstn_id,trans_seq,rtrans_lineitm_seq) d
        on tsl.organization_id = d.organization_id 
            AND tsl.rtl_loc_id = d.rtl_loc_id
            AND tsl.business_date = d.business_date 
            AND tsl.wkstn_id = d.wkstn_id 
            AND tsl.trans_seq = d.trans_seq
            AND tsl.rtrans_lineitm_seq = d.rtrans_lineitm_seq
        left join trl_rtrans tr
        on tsl.organization_id = tr.organization_id 
            AND tsl.rtl_loc_id = tr.rtl_loc_id
            AND tsl.business_date = tr.business_date 
            AND tsl.wkstn_id = tr.wkstn_id 
            AND tsl.trans_seq = tr.trans_seq
        left join crm_party cust
        on tsl.organization_id = cust.organization_id 
            AND tr.cust_party_id = cust.party_id
        where tsl.organization_id = pvOrganizationId
        and tsl.rtl_loc_id = pvRetailLocationId
        and tsl.wkstn_id = pvWrkstnId
        and tsl.business_date = pvBusinessDate
        and tsl.trans_seq = pvTransSeq
        and r.void_flag=0
        and ((tsl.SALE_LINEITM_TYPCODE <> 'ORDER'and (xom.detail_type IS NULL OR xold.status_code = 'FULFILLED') )
             or (tsl.SALE_LINEITM_TYPCODE = 'ORDER' and xom.detail_type in ('FEE', 'PAYMENT') ));

END IF;
    
        IF vTransStatcode = 'COMPLETE' THEN -- process only completed transaction for flash sales tables
        BEGIN
       select sum(case vPostVoidFlag when 0 then -1 else 1 end * coalesce(quantity,0)),sum(case vPostVoidFlag when 1 then -1 else 1 end * coalesce(net_amt,0))
        INTO vQuantity,vNetAmount
        from rpt_sale_line rsl
    left join itm_non_phys_item inp on rsl.item_id=inp.item_id and rsl.organization_id=inp.organization_id
        where rsl.organization_id = pvOrganizationId
            and rtl_loc_id = pvRetailLocationId
            and wkstn_id = pvWrkstnId
            and business_date = pvBusinessDate
            and trans_seq= pvTransSeq
            and return_flag=1
      and coalesce(exclude_from_net_sales_flag,0)=0;
        EXCEPTION WHEN no_data_found THEN
          NULL;
        END;
        
            IF ABS(vNetAmount) > 0 OR ABS(vQuantity) > 0 THEN
                -- populate now to flash tables
                -- returns
                sp_ins_upd_flash_sales(pvOrganizationId, 
                                       pvRetailLocationId, 
                                       vTransDate, 
                                       pvWrkstnId, 
                                       'RETURNS', 
                                       vQuantity, 
                                       vNetAmount, 
                                       vCurrencyId);
            END IF;
            
        select sum(case when return_flag=vPostVoidFlag then 1 else -1 end * coalesce(gross_quantity,0)),
        sum(case when return_flag=vPostVoidFlag then 1 else -1 end * coalesce(quantity,0)),
        sum(case vPostVoidFlag when 1 then -1 else 1 end * coalesce(gross_amt,0)),
        sum(case vPostVoidFlag when 1 then -1 else 1 end * coalesce(net_amt,0)),
        sum(case vPostVoidFlag when 1 then 1 else -1 end * coalesce(override_amt,0)),
        sum(case vPostVoidFlag when 1 then 1 else -1 end * coalesce(discount_amt,0))
        into vGrossQuantity,vQuantity,vGrossAmount,vNetAmount,vOverrideAmt,vDiscountAmt
        from rpt_sale_line rsl
    left join itm_non_phys_item inp on rsl.item_id=inp.item_id and rsl.organization_id=inp.organization_id
        where rsl.organization_id = pvOrganizationId
            and rtl_loc_id = pvRetailLocationId
            and wkstn_id = pvWrkstnId
            and business_date = pvBusinessDate
            and trans_seq= pvTransSeq
      and QUANTITY <> 0
      and sale_lineitm_typcode not in ('ONHOLD','WORK_ORDER')
      and coalesce(exclude_from_net_sales_flag,0)=0;
      
      -- For VAT taxed items there are rounding problems by which the usage of the SUM(net_amt) could create problems
      -- So we decided to set it as simple difference between the gross amount and the discount, which results in the expected value for both SALES and VAT without rounding issues
      -- We excluded the possibility to round also the tax because several reasons:
      -- 1) It will be possible that the final result is not accurate if both values have 5 as exceeding decimal
      -- 2) The value of the tax is rounded by specific legal requirements, and must match with what specified on the fiscal receipts
      -- 3) The number of decimals used for the tax amount in the database is less (6) than the one used in the calculator (10); 
      -- anyway, this last one is the most accurate, so we cannot rely on the value on the database which is at line level (rpt_sale_line) and could be affected by several roundings
      vNetAmount := vGrossAmount + vDiscountAmt - vTaxTotal;
      
            -- Gross sales
            IF ABS(vGrossAmount) > 0 THEN
                sp_ins_upd_flash_sales(pvOrganizationId,
                                       pvRetailLocationId,
                                       vTransDate, 
                                       pvWrkstnId, 
                                       'GROSSSALES', 
                                       vGrossQuantity, 
                                       vGrossAmount, 
                                       vCurrencyId);
            END IF;
      
            -- Net Sales update
            IF ABS(vNetAmount) > 0 THEN
                sp_ins_upd_flash_sales(pvOrganizationId,
                                       pvRetailLocationId,
                                       vTransDate, 
                                       pvWrkstnId, 
                                       'NETSALES', 
                                       vQuantity, 
                                       vNetAmount, 
                                       vCurrencyId);
            END IF;
        
            -- Discounts
            IF ABS(vOverrideAmt) > 0 THEN
                sp_ins_upd_flash_sales(pvOrganizationId,
                                       pvRetailLocationId,
                                       vTransDate, 
                                       pvWrkstnId, 
                                       'OVERRIDES', 
                                       vQuantity, 
                                       vOverrideAmt, 
                                       vCurrencyId);
            END IF; 
  
            -- Discounts  
            IF ABS(vDiscountAmt) > 0 THEN 
                sp_ins_upd_flash_sales(pvOrganizationId,
                                       pvRetailLocationId,
                                       vTransDate,
                                       pvWrkstnId,
                                       'DISCOUNTS',
                                       vQuantity, 
                                       vDiscountAmt, 
                                       vCurrencyId);
            END IF;
      
   
        -- Hourly sales updates (add for all the line items in the transaction)
            vTotQuantity := COALESCE(vTotQuantity,0) + vQuantity;
            vTotNetAmt := COALESCE(vTotNetAmt,0) + vNetAmount;
            vTotGrossAmt := COALESCE(vTotGrossAmt,0) + vGrossAmount;
    
  BEGIN
    OPEN saleCursor;
      
    LOOP  
        FETCH saleCursor INTO vItemId, 
                              vSaleLineitmTypcode, 
                              vActualQuantity,
                              vUnitPrice, 
                              vGrossAmount, 
                              vGrossQuantity, 
                              vDepartmentId, 
                              vNetAmount, 
                              vQuantity,
                vReturnFlag;
    
        EXIT WHEN saleCursor%NOTFOUND;
      
            BEGIN
            SELECT non_phys_item_typcode INTO vNonPhysType
              FROM ITM_NON_PHYS_ITEM 
              WHERE item_id = vItemId 
                AND organization_id = pvOrganizationId  ;
            EXCEPTION WHEN no_data_found THEN
                NULL;
            END;
      
            vCntNonPhysItm := SQL%ROWCOUNT;
            
            IF vCntNonPhysItm = 1 THEN  
                -- check for layaway or sp. order payment / deposit
                IF vPostVoidFlag <> vReturnFlag THEN 
                    vNonPhysPrice := vUnitPrice * -1;
                    vNonPhysQuantity := vActualQuantity * -1;
                ELSE
                    vNonPhysPrice := vUnitPrice;
                    vNonPhysQuantity := vActualQuantity;
                END IF;
      
                IF vNonPhysType = 'LAYAWAY_DEPOSIT' THEN 
                    vNonPhys := 'LayawayDeposits';
                ELSIF vNonPhysType = 'LAYAWAY_PAYMENT' THEN
                    vNonPhys := 'LayawayPayments';
                ELSIF vNonPhysType = 'SP_ORDER_DEPOSIT' THEN
                    vNonPhys := 'SpOrderDeposits';
                ELSIF vNonPhysType = 'SP_ORDER_PAYMENT' THEN
                    vNonPhys := 'SpOrderPayments';
                ELSIF vNonPhysType = 'PRESALE_DEPOSIT' THEN
                    vNonPhys := 'PresaleDeposits';
                ELSIF vNonPhysType = 'PRESALE_PAYMENT' THEN
                    vNonPhys := 'PresalePayments';
                ELSIF vNonPhysType = 'ONHOLD_DEPOSIT' THEN
                    vNonPhys := 'OnholdDeposits';
                ELSIF vNonPhysType = 'ONHOLD_PAYMENT' THEN
                    vNonPhys := 'OnholdPayments';
                ELSIF vNonPhysType = 'LOCALORDER_DEPOSIT' THEN
                    vNonPhys := 'LocalInventoryOrderDeposits';
                ELSIF vNonPhysType = 'LOCALORDER_PAYMENT' THEN
                    vNonPhys := 'LocalInventoryOrderPayments';
                ELSE 
                    vNonPhys := 'NonMerchandise';
                    vNonPhysPrice := vGrossAmount;
                    vNonPhysQuantity := vGrossQuantity;
                END IF; 
                -- update flash sales for non physical payments / deposits
                sp_ins_upd_flash_sales (pvOrganizationId,
                                        pvRetailLocationId,
                                        vTransDate,
                                        pvWrkstnId,
                                        vNonPhys,
                                        vNonPhysQuantity, 
                                        vNonphysPrice, 
                                        vCurrencyId);
            ELSE
                vNonPhys := ''; -- reset 
            END IF;
    
            -- process layaways, special orders, presales, onholds, and local inventory orders (not sales)
            IF vSaleLineitmTypcode = 'LAYAWAY' OR vSaleLineitmTypcode = 'SPECIAL_ORDER' 
                or vSaleLineitmTypcode = 'PRESALE' or vSaleLineitmTypcode = 'ONHOLD' or vSaleLineitmTypcode = 'LOCALORDER' THEN
                IF (NOT (vNonPhys = 'LayawayDeposits' 
                      OR vNonPhys = 'LayawayPayments' 
                      OR vNonPhys = 'SpOrderDeposits' 
                      OR vNonPhys = 'SpOrderPayments'
                      OR vNonPhys = 'OnholdDeposits' 
                      OR vNonPhys = 'OnholdPayments'
                      OR vNonPhys = 'LocalInventoryOrderDeposits' 
                      OR vNonPhys = 'LocalInventoryOrderPayments'
                      OR vNonPhys = 'PresaleDeposits'
                      OR vNonPhys = 'PresalePayments')) 
                    AND ((vLineitemStatcode IS NULL) OR (vLineitemStatcode <> 'CANCEL')) THEN
                    
                    vNonPhysSaleType := 'SpOrderItems';
                  
                    IF vSaleLineitmTypcode = 'LAYAWAY' THEN
                        vNonPhysSaleType := 'LayawayItems';
                    ELSIF vSaleLineitmTypcode = 'PRESALE' THEN
                        vNonPhysSaleType := 'PresaleItems';
                    ELSIF vSaleLineitmTypcode = 'ONHOLD' THEN
                        vNonPhysSaleType := 'OnholdItems';
                    ELSIF vSaleLineitmTypcode = 'LOCALORDER' THEN
                        vNonPhysSaleType := 'LocalInventoryOrderItems';
                    END IF;
                  
                    -- update flash sales for layaway items
                    vLayawayPrice := vUnitPrice * COALESCE(vActualQuantity,0);
                    sp_ins_upd_flash_sales (pvOrganizationId,
                                            pvRetailLocationId,
                                            vTransDate,
                                            pvWrkstnId,
                                            vNonPhys,
                                            vActualQuantity, 
                                            vLayawayPrice, 
                                            vCurrencyId);
                END IF;
            END IF;
            -- end flash sales update
            -- department sales
            sp_ins_upd_merchlvl1_sales(pvOrganizationId, 
                                  pvRetailLocationId, 
                                  vTransDate, 
                                  pvWrkstnId, 
                                  vDepartmentId, 
                                  vQuantity, 
                                  vNetAmount, 
                                  vGrossAmount, 
                                  vCurrencyId);
    END LOOP;
    CLOSE saleCursor;
  EXCEPTION
    WHEN OTHERS THEN CLOSE saleCursor;
  END;
    END IF; 
  
  
    -- update hourly sales
    Sp_Ins_Upd_Hourly_Sales(pvOrganizationId, 
                            pvRetailLocationId, 
                            vTransDate, 
                            pvWrkstnId, 
                            vTransTimeStamp, 
                            vTotquantity, 
                            vTotNetAmt, 
                            vTotGrossAmt, 
                            vTransCount, 
                            vCurrencyId);
  
    COMMIT;
  
    EXCEPTION
        --WHEN NO_DATA_FOUND THEN
        --    vRowCnt := 0;            
        WHEN myerror THEN
            rollback;
        WHEN myreturn THEN
            commit;
        WHEN others THEN
            DBMS_OUTPUT.PUT_LINE('ERROR NUM: ' || to_char(sqlcode));
            DBMS_OUTPUT.PUT_LINE('ERROR TXT: ' || SQLERRM);
            rollback;
--    END;
END sp_flash;
/

GRANT EXECUTE ON sp_flash TO posusers,dbausers;
 
-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : SP_IMPORT_DATABASE
-- Description       : This procedure is called on the local database to import all of the XStore objects onto a
--                      secondary register or for the local training databases.  It procedure will drop all of the 
--                      procedures, triggers, views, sequences and functions owned by the target owner.  If this a 
--                      production database the public synonyms are also dropped.
-- Version           : 19.0
--
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... ..........         Initial Version
-- PGH 03/17/2010   Added the two parameters and logic to drop public synonyms
-- PGH 03/26/2010   Rewritten the procedure to execute the datadump import via SQL calls instead of the command
--                  line utility.  The procedures now does pre, import and post steps.
-- PGH 08/30/2010   Add a line to ignore the ctl_replication_queue, because there are two copies of this table and
--                  the synoym should not be owned by DTV.
-- BCW 09/08/2015   Changed the public synonyms to user synonyms.
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION SP_IMPORT_DATABASE');

CREATE OR REPLACE FUNCTION SP_IMPORT_DATABASE 
(  
    argImportPath              varchar2,                   -- Import Directory Name
    argProd                    varchar2,                   -- Import Type: PRODUCTION / TRAINING
    argBackupDataFile          varchar2,                   -- Dump File Name
    argOutputFile              varchar2,                   -- Log File Name
    argSourceOwner             varchar2,                   -- Source Owner User Name
    argTargetOwner             varchar2,                   -- Target Owner User Name
    argSourceTablespace        varchar2,                   -- Source Data Tablespace Name
    argTargetTablespace        varchar2,                   -- Target Data Tablespace Name
    argSourceIndexTablespace   varchar2,                   -- Source Index Tablespace Name
    argTargetIndexTablespace   varchar2                    -- Target Index Tablespace Name
)
RETURN INTEGER
IS

sqlStmt                 VARCHAR2(512);
ls_object_type          VARCHAR2(30);
ls_object_name          VARCHAR2(128);
err_count               NUMBER := 0;
status_message          VARCHAR2(30);

-- Varaibles for the Datapump section
h1                      NUMBER;         -- Data Pump job handle
job_state               VARCHAR2(30);   -- To keep track of job state
ind                     NUMBER;         -- loop index
le                      ku$_LogEntry;   -- WIP and error messages
js                      ku$_JobStatus;  -- job status from get_status
jd                      ku$_JobDesc;    -- job description from get_status
sts                     ku$_Status;     -- status object returned by 
rowcnt                  NUMBER;


CURSOR OBJECT_LIST (v_owner  VARCHAR2) IS
SELECT object_type, object_name
  FROM all_objects
  WHERE object_type IN ('PROCEDURE', 'TRIGGER', 'VIEW', 'SEQUENCE', 'FUNCTION', 'TABLE', 'TYPE')
    AND object_name != 'SP_IMPORT_DATABASE'
    AND object_name != 'SP_WRITE_DBMS_OUTPUT_TO_FILE'
    AND object_name != 'CTL_REPLICATION_QUEUE'
    AND owner = v_owner;

BEGIN

    -- Enable Server Output
    DBMS_OUTPUT.ENABLE (buffer_size => NULL);
    DBMS_OUTPUT.PUT_LINE (user || ' is starting SP_IMPORT_DATABASE.');
    sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
    
    --
    -- Checks to see if the Data Pump work table exists and drops it.
    --
    select count(*)
        into rowcnt
        from all_tables
        where owner = upper('$(DbSchema)')
          and table_name = 'XSTORE_IMPORT';
          
    IF rowcnt > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE XSTORE_IMPORT';
    END IF;

    -- 
    -- Validate the first parameter is either 'PRODUCTION' OR 'TRAINING', if not raise an error
    --
    IF argProd != 'PRODUCTION' AND argProd != 'TRAINING' THEN
        dbms_output.put_line ('Parameter: argProd - Must be PRODUCTION OR TRAINING');
        Raise_application_error(-20001 , 'Parameter: argProd - Must be PRODUCTION OR TRAINING');
    END IF;

    --
    -- Drops all of the user's objects
    --
    BEGIN
    OPEN OBJECT_LIST (argTargetOwner);
      
    LOOP 
      BEGIN
        FETCH OBJECT_LIST INTO ls_object_type, ls_object_name;
        EXIT WHEN OBJECT_LIST%NOTFOUND;
        
        -- Do not drop the tables, they will be dropped by datapump.
        IF ls_object_type != 'TABLE' THEN
            IF ls_object_type = 'SEQUENCE' AND ls_object_name LIKE '%ISEQ$$%' THEN
              dbms_output.put_line ('FOUND A SYSTEM GENERATED SEQ ' || ls_object_name ||' WILL NOT DROP IT.');
            ELSE
              sqlstmt := 'DROP '|| ls_object_type ||' '|| argTargetOwner || '.' || ls_object_name;
              dbms_output.put_line (sqlstmt);
            END IF;
            IF sqlStmt IS NOT NULL THEN
                  EXECUTE IMMEDIATE sqlStmt;
            END IF;
        END IF;
      EXCEPTION
         WHEN OTHERS THEN
         BEGIN
         DBMS_OUTPUT.PUT_LINE('Error: '|| SQLERRM);
         sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
         err_count := err_count + 1;
         END;
      END;  
    END LOOP;
    CLOSE OBJECT_LIST;
    sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
    EXCEPTION
         WHEN OTHERS THEN
         BEGIN
         CLOSE OBJECT_LIST;
         DBMS_OUTPUT.PUT_LINE('Error: '|| SQLERRM);
         sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
         err_count := err_count + 1;
         END;
    END;  

    --
    -- Import the schema objects using Datapump DBMS package
    -- This is a code block to handel exceptions from Datapump
    --

    BEGIN
            --
        -- Performs a schema level import for the Xstore objects
        --
        h1 := DBMS_DATAPUMP.OPEN('IMPORT','SCHEMA',NULL,'XSTORE_IMPORT','LATEST');
        DBMS_DATAPUMP.METADATA_FILTER(h1, 'SCHEMA_EXPR', 'IN ('''|| argSourceOwner || ''')');

        --
        -- Adds the data and log files
        --
        DBMS_DATAPUMP.ADD_FILE(h1, argBackupDataFile, argImportPath, NULL, DBMS_DATAPUMP.KU$_FILE_TYPE_DUMP_FILE);
        DBMS_DATAPUMP.ADD_FILE(h1, argOutputFile, argImportPath, NULL, DBMS_DATAPUMP.KU$_FILE_TYPE_LOG_FILE);
        
        --
        -- Parameters for the import
        --  1) Do not create user
        --  2) Drop table if they exists
        --  3) Collect metrics as time taken to process object(s)
        --  4) Exclude procedure SP_PREP_FOR_IMPORT
        --  5) If Training, exclude grants
        --  6) Remap Schema
        --  7) Remap Tablespace
        --  8) Inhibit the assignment of the exported OID,a new OID will be assigned.
        --
        --DBMS_DATAPUMP.SET_PARAMETER(h1, 'USER_METADATA', 0);
        DBMS_DATAPUMP.SET_PARAMETER(h1, 'TABLE_EXISTS_ACTION', 'REPLACE');
        DBMS_DATAPUMP.SET_PARAMETER(h1, 'METRICS', 1);
        DBMS_DATAPUMP.METADATA_REMAP(h1, 'REMAP_SCHEMA', argSourceOwner, argTargetOwner);
        DBMS_DATAPUMP.METADATA_FILTER(h1,'NAME_EXPR','!=''SP_IMPORT_DATABASE''', 'FUNCTION');
        DBMS_DATAPUMP.METADATA_FILTER(h1,'NAME_EXPR','!=''SP_WRITE_DBMS_OUTPUT_TO_FILE''', 'PROCEDURE');
        DBMS_DATAPUMP.METADATA_FILTER(h1,'NAME_EXPR','!=''$(DbUser)''', 'USER');
        DBMS_DATAPUMP.METADATA_FILTER(h1,'NAME_EXPR','!=''TRAINING''', 'USER');
        DBMS_DATAPUMP.METADATA_TRANSFORM(h1,'OID',0, 'TYPE');
        IF upper(argProd) = 'TRAINING' THEN
            DBMS_DATAPUMP.METADATA_FILTER(h1, 'EXCLUDE_PATH_EXPR', 'like''%GRANT%''');
        END IF;
        
        DBMS_DATAPUMP.METADATA_REMAP(h1, 'REMAP_TABLESPACE', argSourceTablespace, argTargetTablespace); 
        DBMS_DATAPUMP.METADATA_REMAP(h1, 'REMAP_TABLESPACE', argSourceIndexTablespace, argTargetIndexTablespace); 

        --
        -- Start the job. An exception will be generated if something is not set up
        -- properly.
        --
        dbms_output.put_line('Starting datapump job');
        DBMS_DATAPUMP.START_JOB(h1);

        --
        -- Waits until the job as completed
        --
        DBMS_DATAPUMP.WAIT_FOR_JOB (h1, job_state);

        dbms_output.put_line('Job has completed');
        dbms_output.put_line('Final job state = ' || job_state);

        dbms_datapump.detach(h1);
      sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
      BEGIN
        sqlstmt := 'PURGE RECYCLEBIN';
        EXECUTE IMMEDIATE sqlstmt;
        DBMS_OUTPUT.PUT_LINE(sqlstmt || ' executed');
        sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
      END;
    EXCEPTION
        WHEN OTHERS THEN
        BEGIN
            dbms_datapump.get_status(h1, 
                                        dbms_datapump.ku$_status_job_error, 
                                        -1, 
                                        job_state, 
                                        sts);
            js := sts.job_status;
            le := sts.error;
            IF le IS NOT NULL THEN
              ind := le.FIRST;
              WHILE ind IS NOT NULL LOOP
                dbms_output.put_line(le(ind).LogText);
                ind := le.NEXT(ind);
              END LOOP;
            END IF;
            
            DBMS_DATAPUMP.STOP_JOB (h1, -1, 0, 0);
            dbms_datapump.detach(h1);
        sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
          DBMS_OUTPUT.DISABLE ();
            --Raise_application_error(-20002 , 'Datapump: Data Import Failed');
            return -1;
        END;
    END;  
    
    status_message :=
      CASE err_count
         WHEN 0 THEN 'successfully.'
         ELSE 'with ' || err_count || ' errors.'
      end;
    DBMS_OUTPUT.PUT_LINE (user || ' has executed SP_IMPORT_DATABASE '|| status_message);
    sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
 
    DBMS_OUTPUT.DISABLE ();

    return 0;
EXCEPTION
    WHEN OTHERS THEN
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        err_count := err_count + 1;
        DBMS_OUTPUT.PUT_LINE (user || ' has executed SP_IMPORT_DATABASE with ' || err_count || ' errors.');
        sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
        DBMS_OUTPUT.DISABLE ();
        RETURN -1;
    END;
END;
/

GRANT EXECUTE ON SP_IMPORT_DATABASE TO dbausers;


-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : SP_REPORT
-- Description       : This procedure is to be executed on the XCenter database to populate the flash report tables.
--                      It calls sp_flash for each record in the trn_trans table where the flash_sales_flag is zero
--                      to generate the data.  All of the report / business logic will be kept in sp_flash.
-- Version           : 19.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....         Initial Version
-- PGH 11/03/18   Changed the v_business_date paramter from timestamp(6) to date.
-- 
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING PROCEDURE SP_REPORT');

CREATE OR REPLACE PROCEDURE SP_REPORT (
  job_id      in number default 0,
  firstLoc_id   in number default 0,
  lastLoc_id    in number default 999999999,
  start_date    in DATE default to_date('01/01/1900','mm/dd/yyyy'),
  end_date    in DATE default to_date('12/31/9999','mm/dd/yyyy'),
  batch_count   in number default 9999999999,
  nologging   in number default 0)
AUTHID CURRENT_USER 
IS

  v_organization_id  NUMBER(10);
  v_rtl_loc_id NUMBER(10);
  v_wkstn_id NUMBER(20);
  v_business_date date;       -- Changed the parameter from timestamp(6) to date.
  v_trans_seq NUMBER(10);
  v_starttime DATE;
  v_sql VARCHAR2(4000);

  CURSOR trans IS
   SELECT trn.organization_id, 
          trn.rtl_loc_id, 
          trn.business_date, 
          trn.wkstn_id, 
          trn.trans_seq
   FROM trn_trans trn

   LEFT JOIN tsn_tndr_control_trans tndr
    ON trn.organization_id = tndr.organization_id
    AND trn.rtl_loc_id     = tndr.rtl_loc_id
    AND trn.business_date  = tndr.business_date
    AND trn.wkstn_id       = tndr.wkstn_id
    AND trn.trans_seq      = tndr.trans_seq
    AND trn.flash_sales_flag = 0

   WHERE trn.flash_sales_flag = 0
   AND trn.trans_typcode in ('RETAIL_SALE','POST_VOID','TENDER_CONTROL')
   AND trn.trans_statcode not like 'CANCEL%'
   AND trn.rtl_loc_id between firstLoc_id AND lastLoc_id
   AND trn.business_date between start_date AND end_date
   AND (tndr.typcode IS NULL OR tndr.typcode IN ('PAID_IN', 'PAID_OUT'))
   AND rownum<=batch_count
  ORDER BY trn.business_date, trn.rtl_loc_id, trn.begin_datetime;

BEGIN
    select sysdate into v_starttime from dual;
    if nologging=0 then
       insert into log_sp_report (job_id,loc_id,business_date,job_start,completed,expected)
      select job_id, trn.rtl_loc_id, trn.business_date, v_starttime, 0, COUNT(*)
      FROM trn_trans trn
      
      LEFT JOIN tsn_tndr_control_trans tndr
        ON trn.organization_id = tndr.organization_id
        AND trn.rtl_loc_id     = tndr.rtl_loc_id
        AND trn.business_date  = tndr.business_date
        AND trn.wkstn_id       = tndr.wkstn_id
        AND trn.trans_seq      = tndr.trans_seq
        AND trn.flash_sales_flag = 0
      
      WHERE trn.flash_sales_flag = 0
      AND trn.trans_typcode in ('RETAIL_SALE','POST_VOID','TENDER_CONTROL')
      AND trn.trans_statcode not like 'CANCEL%'
      AND trn.rtl_loc_id between firstLoc_id AND lastLoc_id
      AND trn.business_date between start_date AND end_date
      AND (tndr.typcode IS NULL OR tndr.typcode IN ('PAID_IN', 'PAID_OUT'))
      AND rownum<=batch_count
      group by trn.rtl_loc_id, trn.business_date;
    end if;
    
    OPEN trans;
  
        LOOP
            FETCH trans INTO v_organization_id, 
                             v_rtl_loc_id, 
                             v_business_date, 
                             v_wkstn_id,
                             v_trans_seq;
       
            EXIT WHEN trans%NOTFOUND;

        if nologging=0 then
        update log_sp_report set start_dt = SYSDATE where loc_id = v_rtl_loc_id and business_date=v_business_date and job_start=v_starttime and job_id=job_id and start_dt is null;
      end if;

           sp_flash (v_organization_id, 
                      v_rtl_loc_id, 
                      v_business_date, 
                      v_wkstn_id,
                      v_trans_seq); 

        if nologging=0 then
        update log_sp_report set completed = completed + 1,end_dt = SYSDATE where loc_id = v_rtl_loc_id and business_date=v_business_date and job_start=v_starttime and job_id=job_id;
      end if;
        END LOOP;
    CLOSE trans;
  if nologging=0 then
    update log_sp_report set job_end = SYSDATE where job_start=v_starttime and job_id=job_id;
  end if;
  EXCEPTION
    WHEN OTHERS THEN CLOSE trans;
END SP_REPORT;
/

GRANT EXECUTE ON SP_REPORT TO posusers,dbausers;

-- 
-- TRIGGER: TRG_UPDATE_RETURN 
--

CREATE OR REPLACE TRIGGER TRG_UPDATE_RETURN
AFTER INSERT
ON trl_returned_item_journal
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE
  v_found_trans SMALLINT;
  v_found_lineitm SMALLINT;
BEGIN
  SELECT COUNT(*) INTO v_found_trans 
      FROM trn_trans 
      WHERE organization_id = :NEW.organization_id
      AND rtl_loc_id = :NEW.rtl_loc_id
      AND wkstn_id = :NEW.wkstn_id
      AND business_date = :NEW.business_date
      AND trans_seq = :NEW.trans_seq;
  IF v_found_trans > 0 THEN
     SELECT COUNT(*) INTO v_found_lineitm FROM trl_returned_item_count ric WHERE 
           organization_id = :NEW.organization_id AND
           rtl_loc_id = :NEW.rtl_loc_id AND
           wkstn_id = :NEW.wkstn_id AND
           business_date = :NEW.business_date AND
           trans_seq = :NEW.trans_seq AND
           rtrans_lineitm_seq = :NEW.rtrans_lineitm_seq;
    IF v_found_lineitm < 1 THEN
      INSERT INTO trl_returned_item_count
        (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq,
        rtrans_lineitm_seq, returned_count)
  VALUES(:NEW.organization_id,:NEW.rtl_loc_id,
        :NEW.wkstn_id,:NEW.business_date,:NEW.trans_seq,
        :NEW.rtrans_lineitm_seq,:NEW.returned_count);
    ELSE
      UPDATE trl_returned_item_count 
        SET
          returned_count = returned_count + :NEW.returned_count
        WHERE
          organization_id = :NEW.organization_id AND
          rtl_loc_id = :NEW.rtl_loc_id AND
          wkstn_id = :NEW.wkstn_id AND
          business_date = :NEW.business_date AND
          trans_seq = :NEW.trans_seq AND
          rtrans_lineitm_seq = :NEW.rtrans_lineitm_seq;
    END IF;
  END IF;
END;
/

SET SERVEROUTPUT ON SIZE 10000


-- ***************************************************************************
-- This script will apply after all schema artifacts have been upgraded to a given version.  It is
-- generally useful for performing conversions between legacy and modern representations of affected
-- data sets.
--
-- Source version:  18.0.x
-- Target version:  19.0.0
-- DB platform:     Oracle 12c
-- ***************************************************************************

UNDEFINE dbDataTableSpace;
UNDEFINE dbIndexTableSpace;

-- LEAVE BLANK LINE BELOW

INSERT INTO ctl_version_history (
    organization_id, base_schema_version, customer_schema_version, base_schema_date, 
    create_user_id, create_date, update_user_id, update_date)
  SELECT 
    organization_id, '22.0.0.0.20230127185818', '0.0.0 - 0.0', SYSDATE, 
    'Oracle', SYSDATE, 'Oracle', SYSDATE
    FROM(
      SELECT l.organization_id FROM loc_org_hierarchy l
      UNION ALL
      SELECT c.organization_id FROM ctl_version_history c) t
  GROUP BY organization_id;
COMMIT;

declare
vcnt int;
begin
	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY TRIGGER';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY TRIGGER FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE PUBLIC SYNONYM';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE PUBLIC SYNONYM FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY VIEW';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY VIEW FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY DIRECTORY';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY DIRECTORY FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY SEQUENCE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY SEQUENCE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY PROCEDURE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY PROCEDURE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY TABLE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY TABLE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY JOB';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY JOB FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='DROP ANY TRIGGER';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE DROP ANY TRIGGER FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='DROP PUBLIC SYNONYM';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE DROP PUBLIC SYNONYM FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='DROP ANY VIEW';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE DROP ANY VIEW FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='DROP ANY DIRECTORY';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE DROP ANY DIRECTORY FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='DROP ANY SEQUENCE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE DROP ANY SEQUENCE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='DROP ANY PROCEDURE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE DROP ANY PROCEDURE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='DROP ANY TABLE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE DROP ANY TABLE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_ROLE_PRIVS where GRANTEE=upper('$(DbSchema)') and GRANTED_ROLE='EXP_FULL_DATABASE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE EXP_FULL_DATABASE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='SELECT ANY DICTIONARY';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE SELECT ANY DICTIONARY FROM $(DbSchema)';
	end if;


	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY SYNONYM';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY SYNONYM FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='GRANT ANY PRIVILEGE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'GRANT CREATE TRIGGER TO $(DbSchema)';
		EXECUTE IMMEDIATE 'GRANT CREATE VIEW TO $(DbSchema)';
		EXECUTE IMMEDIATE 'GRANT CREATE SEQUENCE TO $(DbSchema)';
		EXECUTE IMMEDIATE 'GRANT CREATE PROCEDURE TO $(DbSchema)';
		EXECUTE IMMEDIATE 'GRANT CREATE TABLE TO $(DbSchema)';
		EXECUTE IMMEDIATE 'GRANT CREATE TYPE TO $(DbSchema)';
		EXECUTE IMMEDIATE 'GRANT CREATE JOB TO $(DbSchema)';
		EXECUTE IMMEDIATE 'GRANT CREATE SYNONYM TO $(DbUser)';
		EXECUTE IMMEDIATE 'GRANT UNLIMITED TABLESPACE TO $(DbUser)';
		EXECUTE IMMEDIATE 'GRANT UNLIMITED TABLESPACE TO $(DbBackup)';

		EXECUTE IMMEDIATE 'REVOKE GRANT ANY PRIVILEGE FROM $(DbSchema)';
	end if;
end;
/

SPOOL OFF;
