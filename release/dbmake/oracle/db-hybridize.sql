SET SERVEROUTPUT ON SIZE 100000

SPOOL hybridize.log;

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
-- DB platform:     Oracle 12c
-- ***************************************************************************
PROMPT '**************************************';
PROMPT '*****        HYBRIDIZING         *****';
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
    dbms_output.put_line('     Step Sets the correct workstation id when the invoice is issued on a different workstation than the transaction one starting...');
END;
/
BEGIN

  EXECUTE IMMEDIATE 'CREATE OR REPLACE TRIGGER civc_invoice_fix_register
  AFTER INSERT ON civc_invoice
  BEGIN
	UPDATE civc_invoice_xref t0
	SET wkstn_id = (SELECT t1.wkstn_id
	FROM trn_trans t1
	INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
	      FROM civc_invoice t2
	      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = ''RETAIL_SALE'' AND t2.gross_amt = t3.total OR t3.trans_typcode = ''DEFERRED_INVOICE'')  AND t2.create_date between t3.create_date - (1/24/60/60) AND t3.create_date + (1/24/60/60)
	      WHERE t3.organization_id is null) t4
	ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = ''DEFERRED_INVOICE'' AND t1.create_date between t4.create_date - (1/24/60/60) AND t4.create_date + (1/24/60/60) 
	WHERE t0.organization_id = t4.organization_id AND t0.rtl_loc_id = t4.rtl_loc_id AND t0.business_year = t4.business_year AND t0.wkstn_id = t4.wkstn_id AND t0.sequence_nbr = t4.sequence_nbr)
	WHERE EXISTS (SELECT 1
	FROM trn_trans t1
	INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
	      FROM civc_invoice t2
	      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = ''RETAIL_SALE'' AND t2.gross_amt = t3.total OR t3.trans_typcode = ''DEFERRED_INVOICE'') AND t2.create_date between t3.create_date - (1/24/60/60) AND t3.create_date + (1/24/60/60)
	      WHERE t3.organization_id is null) t4
	ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = ''DEFERRED_INVOICE'' AND t1.create_date between t4.create_date - (1/24/60/60) AND t4.create_date + (1/24/60/60) 
	WHERE t0.organization_id = t4.organization_id AND t0.rtl_loc_id = t4.rtl_loc_id AND t0.business_year = t4.business_year AND t0.wkstn_id = t4.wkstn_id AND t0.sequence_nbr = t4.sequence_nbr);
	
	UPDATE civc_invoice t0
	SET wkstn_id = (SELECT t1.wkstn_id
	FROM trn_trans t1
	INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
	      FROM civc_invoice t2
	      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = ''RETAIL_SALE'' AND t2.gross_amt = t3.total OR t3.trans_typcode = ''DEFERRED_INVOICE'') AND t2.create_date between t3.create_date - (1/24/60/60) AND t3.create_date + (1/24/60/60)
	      WHERE t3.organization_id is null) t4
	ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = ''DEFERRED_INVOICE'' AND t1.create_date between t4.create_date - (1/24/60/60) AND t4.create_date + (1/24/60/60) 
	WHERE t0.organization_id = t4.organization_id AND t0.rtl_loc_id = t4.rtl_loc_id AND t0.business_year = t4.business_year AND t0.wkstn_id = t4.wkstn_id AND t0.sequence_nbr = t4.sequence_nbr)
	WHERE EXISTS (SELECT 1
	FROM trn_trans t1
	INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
	      FROM civc_invoice t2
	      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = ''RETAIL_SALE'' AND t2.gross_amt = t3.total OR t3.trans_typcode = ''DEFERRED_INVOICE'') AND t2.create_date between t3.create_date - (1/24/60/60) AND t3.create_date + (1/24/60/60)
	      WHERE t3.organization_id is null) t4
	ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = ''DEFERRED_INVOICE'' AND t1.create_date between t4.create_date - (1/24/60/60) AND t4.create_date + (1/24/60/60) 
	WHERE t0.organization_id = t4.organization_id AND t0.rtl_loc_id = t4.rtl_loc_id AND t0.business_year = t4.business_year AND t0.wkstn_id = t4.wkstn_id AND t0.sequence_nbr = t4.sequence_nbr);

  END;';
  dbms_output.put_line('Trigger civc_invoice_fix_register created');

  EXECUTE IMMEDIATE 'CREATE OR REPLACE TRIGGER civc_invoice_xref_fix_register
  AFTER INSERT ON civc_invoice
  BEGIN
	UPDATE civc_invoice_xref t0
	SET wkstn_id = (SELECT t1.wkstn_id
	FROM trn_trans t1
	INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
	      FROM civc_invoice t2
	      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = ''RETAIL_SALE'' AND t2.gross_amt = t3.total OR t3.trans_typcode = ''DEFERRED_INVOICE'')  AND t2.create_date between t3.create_date - (1/24/60/60) AND t3.create_date + (1/24/60/60)
	      WHERE t3.organization_id is null) t4
	ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = ''DEFERRED_INVOICE'' AND t1.create_date between t4.create_date - (1/24/60/60) AND t4.create_date + (1/24/60/60) 
	WHERE t0.organization_id = t4.organization_id AND t0.rtl_loc_id = t4.rtl_loc_id AND t0.business_year = t4.business_year AND t0.wkstn_id = t4.wkstn_id AND t0.sequence_nbr = t4.sequence_nbr)
	WHERE EXISTS (SELECT 1
	FROM trn_trans t1
	INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
	      FROM civc_invoice t2
	      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = ''RETAIL_SALE'' AND t2.gross_amt = t3.total OR t3.trans_typcode = ''DEFERRED_INVOICE'') AND t2.create_date between t3.create_date - (1/24/60/60) AND t3.create_date + (1/24/60/60)
	      WHERE t3.organization_id is null) t4
	ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = ''DEFERRED_INVOICE'' AND t1.create_date between t4.create_date - (1/24/60/60) AND t4.create_date + (1/24/60/60) 
	WHERE t0.organization_id = t4.organization_id AND t0.rtl_loc_id = t4.rtl_loc_id AND t0.business_year = t4.business_year AND t0.wkstn_id = t4.wkstn_id AND t0.sequence_nbr = t4.sequence_nbr);
	
	UPDATE civc_invoice t0
	SET wkstn_id = (SELECT t1.wkstn_id
	FROM trn_trans t1
	INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
	      FROM civc_invoice t2
	      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = ''RETAIL_SALE'' AND t2.gross_amt = t3.total OR t3.trans_typcode = ''DEFERRED_INVOICE'') AND t2.create_date between t3.create_date - (1/24/60/60) AND t3.create_date + (1/24/60/60)
	      WHERE t3.organization_id is null) t4
	ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = ''DEFERRED_INVOICE'' AND t1.create_date between t4.create_date - (1/24/60/60) AND t4.create_date + (1/24/60/60) 
	WHERE t0.organization_id = t4.organization_id AND t0.rtl_loc_id = t4.rtl_loc_id AND t0.business_year = t4.business_year AND t0.wkstn_id = t4.wkstn_id AND t0.sequence_nbr = t4.sequence_nbr)
	WHERE EXISTS (SELECT 1
	FROM trn_trans t1
	INNER JOIN (SELECT t2.organization_id, t2.rtl_loc_id, t2.business_year, t2.wkstn_id, t2.sequence_nbr, t2.business_date, t2.invoice_trans_seq,  t2.create_date
	      FROM civc_invoice t2
	      LEFT JOIN trn_trans t3 ON t2.organization_id = t3.organization_id AND t2.rtl_loc_id = t3.rtl_loc_id AND t2.business_date = t3.business_date AND t2.wkstn_id = t3.wkstn_id AND t2.invoice_trans_seq = t3.trans_seq AND (t3.trans_typcode = ''RETAIL_SALE'' AND t2.gross_amt = t3.total OR t3.trans_typcode = ''DEFERRED_INVOICE'') AND t2.create_date between t3.create_date - (1/24/60/60) AND t3.create_date + (1/24/60/60)
	      WHERE t3.organization_id is null) t4
	ON t1.organization_id = t4.organization_id AND t1.rtl_loc_id = t4.rtl_loc_id AND t1.business_date = t4.business_date AND t1.wkstn_id <> t4.wkstn_id AND t1.trans_seq = t4.invoice_trans_seq AND t1.trans_typcode = ''DEFERRED_INVOICE'' AND t1.create_date between t4.create_date - (1/24/60/60) AND t4.create_date + (1/24/60/60) 
	WHERE t0.organization_id = t4.organization_id AND t0.rtl_loc_id = t4.rtl_loc_id AND t0.business_year = t4.business_year AND t0.wkstn_id = t4.wkstn_id AND t0.sequence_nbr = t4.sequence_nbr);

  END;';
  dbms_output.put_line('Trigger civc_invoice_xref_fix_register created');
  
END;
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

PROMPT '***************************************************************************';
PROMPT 'Database now hybridized to support clients running against the following versions:';
PROMPT '     21.0.*';
PROMPT '     22.0.0';
PROMPT 'Please run the corresponding un-hybridize script against this database once all';
PROMPT 'clients on earlier supported versions have been updated to the latest supported release.';
PROMPT '***************************************************************************';
/
