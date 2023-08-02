SET SERVEROUTPUT ON SIZE 10000
SET FLUSH OFF;
SET TRIMSPOOL OFF;

SPOOL dbdefine.log;
-- ***************************************************************************
-- This script will handle all post db create statements on an Xstore database compatible with DB 
-- platform <platform> and, where applicable, create/assign the appropriate users, roles, and 
-- platform-specific options for it.
--
-- This script does not define any schematics for the new database.  To identify an Xstore-compatible
-- schema for it, run the "new" script designated for the desired application version.
--
-- Platform:  Oracle 12c
-- ***************************************************************************
--                            CHANGE HISTORY                                                                    
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                    
-------------------------------------------------------------------------------------------------------------------
-- ... .....     Initial Version
-- ST  10/27/06  Created
-- TMS 07/15/11	 Handle all post db create features in db-define.sql by default.
-------------------------------------------------------------------------------------------------------------------
--
-- Variables
--
DEFINE dbDataTableSpace = '$(DbTblspace)_DATA';-- Name of data file tablespace
DEFINE dbIndexTableSpace = '$(DbTblspace)_INDEX';-- Name of index file tablespace 



alter session set current_schema=$(DbSchema);


EXEC dbms_output.put_line('--- CREATING sp_table_exists --- ');
create or replace function sp_table_exists (
  table_name varchar2
) return boolean is
  v_count integer;
begin
  select count(*) into v_count
    from all_tables
   where owner = upper('$(DbSchema)')
     and table_name = upper(sp_table_exists.table_name);
  if v_count = 0 then
    return false;
  else
    return true;
  end if;

end sp_table_exists;
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
    vdatabaseVersion varchar2(10) := dbms_db_version.version || '.' || dbms_db_version.release;
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
   IF ((to_number(vdatabaseVersion) > 12.1 AND LENGTH(vtableName) > 123) OR 
       (to_number(vdatabaseVersion) <= 12.1 AND LENGTH(vtableName) > 25)) THEN
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

EXEC dbms_output.put_line('--- CREATING TABLE cat_acct_note --- ');
CREATE TABLE cat_acct_note(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
note_seq NUMBER(19, 0) NOT NULL,
entry_timestamp TIMESTAMP(6),
entry_party_id NUMBER(19, 0),
note CLOB,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_acct_note PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id, note_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_acct_note TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cat_acct_note');
EXEC dbms_output.put_line('--- CREATING TABLE cat_authorizations --- ');
CREATE TABLE cat_authorizations(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
status_code VARCHAR2(30 char),
status_datetime TIMESTAMP(6),
authorization_type VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_authorizations PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_authorizations TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cat_authorizations');
EXEC dbms_output.put_line('--- CREATING TABLE cat_award_acct --- ');
CREATE TABLE cat_award_acct(
organization_id NUMBER(10, 0) NOT NULL,
cust_card_nbr VARCHAR2(60 char) NOT NULL,
acct_id VARCHAR2(60 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_award_acct PRIMARY KEY (organization_id, cust_card_nbr, acct_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_award_acct TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cat_award_acct');
EXEC dbms_output.put_line('--- CREATING TABLE cat_award_acct_coupon --- ');
CREATE TABLE cat_award_acct_coupon(
organization_id NUMBER(10, 0) NOT NULL,
cust_card_nbr VARCHAR2(60 char) NOT NULL,
acct_id VARCHAR2(60 char) NOT NULL,
coupon_id VARCHAR2(60 char) NOT NULL,
amount NUMBER(17, 6),
expiration_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_award_acct_coupon PRIMARY KEY (organization_id, cust_card_nbr, acct_id, coupon_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_award_acct_coupon TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cat_award_acct_coupon');
EXEC dbms_output.put_line('--- CREATING TABLE cat_charge_acct_history --- ');
CREATE TABLE cat_charge_acct_history(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
history_seq NUMBER(19, 0) NOT NULL,
activity_date TIMESTAMP(6),
activity_enum VARCHAR2(30 char),
amt NUMBER(17, 6),
party_id NUMBER(19, 0),
acct_user_name VARCHAR2(254 char),
business_date TIMESTAMP(6),
trans_seq NUMBER(19, 0),
rtrans_lineitm_seq NUMBER(10, 0),
rtl_loc_id NUMBER(10, 0),
wkstn_id NUMBER(19, 0),
acct_balance NUMBER(17, 6),
acct_user_id VARCHAR2(30 char),
reversed_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_charge_acct_history PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id, history_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_charge_acct_history TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CAT_CHARGE_ACCT_HIST01 --- ');
CREATE INDEX IDX_CAT_CHARGE_ACCT_HIST01 ON cat_charge_acct_history(party_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('cat_charge_acct_history');
EXEC dbms_output.put_line('--- CREATING TABLE cat_charge_acct_invoice --- ');
CREATE TABLE cat_charge_acct_invoice(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
invoice_number VARCHAR2(60 char) NOT NULL,
invoice_balance NUMBER(17, 6) NOT NULL,
original_invoice_balance NUMBER(17, 6),
invoice_date TIMESTAMP(6),
last_activity_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_charge_acct_invoice PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id, invoice_number) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_charge_acct_invoice TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cat_charge_acct_invoice');
EXEC dbms_output.put_line('--- CREATING TABLE cat_charge_acct_users --- ');
CREATE TABLE cat_charge_acct_users(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
acct_user_id VARCHAR2(30 char) NOT NULL,
acct_user_name VARCHAR2(254 char) NOT NULL,
party_id NUMBER(19, 0),
effective_date TIMESTAMP(6),
expiration_date TIMESTAMP(6),
primary_contact_flag NUMBER(1, 0) DEFAULT 0,
acct_user_first_name VARCHAR2(60 char),
acct_user_last_name VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_charge_acct_users PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id, acct_user_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_charge_acct_users TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CAT_CHARGE_ACCT_USERS01 --- ');
CREATE INDEX IDX_CAT_CHARGE_ACCT_USERS01 ON cat_charge_acct_users(party_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('cat_charge_acct_users');
EXEC dbms_output.put_line('--- CREATING TABLE cat_cust_acct --- ');
CREATE TABLE cat_cust_acct(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
acct_balance NUMBER(17, 6),
rtl_loc_id NUMBER(10, 0),
cust_identity_req_flag NUMBER(1, 0) DEFAULT 0,
cust_identity_typcode VARCHAR2(30 char),
party_id NUMBER(19, 0),
acct_po_nbr VARCHAR2(60 char),
dtv_class_name VARCHAR2(254 char),
cust_acct_statcode VARCHAR2(30 char),
last_activity_date TIMESTAMP(6),
acct_setup_date TIMESTAMP(6),
first_name VARCHAR2(254 char),
last_name VARCHAR2(254 char),
telephone VARCHAR2(32 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_cust_acct PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_cust_acct TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_CAT_CUSTACCT_ID --- ');
CREATE INDEX XST_CAT_CUSTACCT_ID ON cat_cust_acct(cust_acct_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_CAT_CUSTACCT_PARTYID --- ');
CREATE INDEX XST_CAT_CUSTACCT_PARTYID ON cat_cust_acct(organization_id, party_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('cat_cust_acct');
EXEC dbms_output.put_line('--- CREATING TABLE cat_cust_acct_card --- ');
CREATE TABLE cat_cust_acct_card(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_card_nbr VARCHAR2(60 char) NOT NULL,
party_id NUMBER(19, 0),
effective_date TIMESTAMP(6),
expr_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_cust_acct_card PRIMARY KEY (organization_id, cust_acct_card_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_cust_acct_card TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cat_cust_acct_card');
EXEC dbms_output.put_line('--- CREATING TABLE cat_cust_acct_journal --- ');
CREATE TABLE cat_cust_acct_journal(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
journal_seq NUMBER(19, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0),
party_id NUMBER(19, 0),
acct_balance NUMBER(17, 6),
cust_identity_typcode VARCHAR2(30 char),
trans_rtl_loc_id NUMBER(10, 0),
trans_wkstn_id NUMBER(19, 0),
trans_business_date TIMESTAMP(6),
trans_trans_seq NUMBER(19, 0),
dtv_class_name VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_cust_acct_journal PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id, journal_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_cust_acct_journal TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CAT_CUST_ACCT_JOURNAL01 --- ');
CREATE INDEX IDX_CAT_CUST_ACCT_JOURNAL01 ON cat_cust_acct_journal(party_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('cat_cust_acct_journal');
EXEC dbms_output.put_line('--- CREATING TABLE cat_cust_acct_plan --- ');
CREATE TABLE cat_cust_acct_plan(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
plan_id VARCHAR2(30 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
plan_description VARCHAR2(255 char),
effective_date TIMESTAMP(6),
expiration_date TIMESTAMP(6),
display_order NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_cust_acct_plan PRIMARY KEY (organization_id, cust_acct_code, plan_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_cust_acct_plan TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CAT_CUST_ACCT_PLAN_ORGNODE --- ');
CREATE INDEX IDX_CAT_CUST_ACCT_PLAN_ORGNODE ON cat_cust_acct_plan(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('cat_cust_acct_plan');
EXEC dbms_output.put_line('--- CREATING TABLE cat_cust_consumer_charge_acct --- ');
CREATE TABLE cat_cust_consumer_charge_acct(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
credit_limit NUMBER(17, 6),
po_req_flag NUMBER(1, 0) DEFAULT 0,
on_hold_flag NUMBER(1, 0) DEFAULT 0,
corporate_account_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_catcustconsumerchargeacct PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_cust_consumer_charge_acct TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE cat_cust_item_acct --- ');
CREATE TABLE cat_cust_item_acct(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
acct_total NUMBER(17, 6),
active_payment_amt NUMBER(17, 6),
total_payment_amt NUMBER(17, 6),
active_acct_total NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_cust_item_acct PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_cust_item_acct TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE cat_cust_item_acct_activity --- ');
CREATE TABLE cat_cust_item_acct_activity(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
cust_item_acct_detail_item_nbr NUMBER(10, 0) NOT NULL,
seq_nbr NUMBER(10, 0) NOT NULL,
activity_datetime TIMESTAMP(6),
item_acct_activity_code VARCHAR2(30 char),
item_acct_lineitm_statcode VARCHAR2(30 char),
rtl_loc_id NUMBER(10, 0),
wkstn_id NUMBER(19, 0),
business_date TIMESTAMP(6),
trans_seq NUMBER(19, 0),
rtrans_lineitm_seq NUMBER(10, 0),
unit_price NUMBER(17, 6),
quantity NUMBER(11, 4),
line_typcode VARCHAR2(30 char),
extended_amt NUMBER(17, 6),
net_amt NUMBER(17, 6),
scheduled_pickup_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_catcustitemacctactivity PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id, cust_item_acct_detail_item_nbr, seq_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_cust_item_acct_activity TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CAT_CUST_ITEM_ACCT_ACTVY01 --- ');
CREATE INDEX IDX_CAT_CUST_ITEM_ACCT_ACTVY01 ON cat_cust_item_acct_activity(organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('cat_cust_item_acct_activity');
EXEC dbms_output.put_line('--- CREATING TABLE cat_cust_item_acct_detail --- ');
CREATE TABLE cat_cust_item_acct_detail(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
cust_item_acct_detail_item_nbr NUMBER(10, 0) NOT NULL,
item_acct_lineitm_statcode VARCHAR2(30 char),
original_item_add_date TIMESTAMP(6),
rtl_loc_id NUMBER(10, 0),
wkstn_id NUMBER(19, 0),
business_date TIMESTAMP(6),
trans_seq NUMBER(19, 0),
rtrans_lineitm_seq NUMBER(10, 0),
line_typcode VARCHAR2(30 char),
extended_amt NUMBER(17, 6),
net_amt NUMBER(17, 6),
unit_price NUMBER(17, 6),
quantity NUMBER(11, 4),
scheduled_pickup_date TIMESTAMP(6),
source_loc_id NUMBER(10, 0),
fullfillment_loc_id NUMBER(10, 0),
delivery_type_id VARCHAR2(20 char),
received_by_cust_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_cust_item_acct_detail PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id, cust_item_acct_detail_item_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_cust_item_acct_detail TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cat_cust_item_acct_detail');
EXEC dbms_output.put_line('--- CREATING TABLE cat_cust_item_acct_journal --- ');
CREATE TABLE cat_cust_item_acct_journal(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
journal_seq NUMBER(19, 0) NOT NULL,
cust_acct_statcode VARCHAR2(30 char),
acct_setup_date TIMESTAMP(6),
last_activity_date TIMESTAMP(6),
acct_total NUMBER(17, 6),
active_payment_amt NUMBER(17, 6),
active_acct_total NUMBER(17, 6),
total_payment_amt NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_catcustitemacctjournal PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id, journal_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_cust_item_acct_journal TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE cat_cust_loyalty_acct --- ');
CREATE TABLE cat_cust_loyalty_acct(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
cust_card_nbr VARCHAR2(60 char) DEFAULT 'UNKNOWN' NOT NULL,
effective_date TIMESTAMP(6),
expiration_date TIMESTAMP(6),
acct_balance NUMBER(17, 6),
escrow_balance NUMBER(17, 6),
bonus_balance NUMBER(17, 6),
loyalty_program_id VARCHAR2(60 char),
loyalty_program_level_id VARCHAR2(60 char),
loyalty_program_name VARCHAR2(60 char),
loyalty_program_level_name VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_cust_loyalty_acct PRIMARY KEY (organization_id, cust_acct_id, cust_card_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_cust_loyalty_acct TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cat_cust_loyalty_acct');
EXEC dbms_output.put_line('--- CREATING TABLE cat_delivery_modifier --- ');
CREATE TABLE cat_delivery_modifier(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
delivery_enum VARCHAR2(30 char),
address1 VARCHAR2(254 char),
address2 VARCHAR2(254 char),
address3 VARCHAR2(254 char),
address4 VARCHAR2(254 char),
city VARCHAR2(254 char),
state VARCHAR2(30 char),
postal_code VARCHAR2(30 char),
country VARCHAR2(2 char),
neighborhood VARCHAR2(254 char),
county VARCHAR2(254 char),
telephone1 VARCHAR2(32 char),
telephone2 VARCHAR2(32 char),
telephone3 VARCHAR2(32 char),
telephone4 VARCHAR2(32 char),
apartment VARCHAR2(30 char),
first_name VARCHAR2(254 char),
middle_name VARCHAR2(254 char),
last_name VARCHAR2(254 char),
shipping_method VARCHAR2(254 char),
tracking_number VARCHAR2(254 char),
extension VARCHAR2(8 char),
delivery_end_time TIMESTAMP(6),
delivery_start_time TIMESTAMP(6),
delivery_date TIMESTAMP(6),
instructions VARCHAR2(254 char),
geo_code VARCHAR2(20 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_delivery_modifier PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_delivery_modifier TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cat_delivery_modifier');
EXEC dbms_output.put_line('--- CREATING TABLE cat_escrow_acct --- ');
CREATE TABLE cat_escrow_acct(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
acct_balance NUMBER(17, 6),
cust_acct_statcode VARCHAR2(30 char),
acct_setup_date TIMESTAMP(6),
last_activity_date TIMESTAMP(6),
party_id NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_escrow_acct PRIMARY KEY (organization_id, cust_acct_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_escrow_acct TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cat_escrow_acct');
EXEC dbms_output.put_line('--- CREATING TABLE cat_escrow_acct_activity --- ');
CREATE TABLE cat_escrow_acct_activity(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
seq_nbr NUMBER(19, 0) NOT NULL,
activity_date TIMESTAMP(6),
activity_enum VARCHAR2(30 char),
amt NUMBER(17, 6),
business_date TIMESTAMP(6),
trans_seq NUMBER(19, 0),
rtl_loc_id NUMBER(10, 0),
wkstn_id NUMBER(19, 0),
source_cust_acct_id VARCHAR2(60 char),
source_cust_acct_code VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_escrow_acct_activity PRIMARY KEY (organization_id, cust_acct_id, seq_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_escrow_acct_activity TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cat_escrow_acct_activity');
EXEC dbms_output.put_line('--- CREATING TABLE cat_payment_schedule --- ');
CREATE TABLE cat_payment_schedule(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
begin_date TIMESTAMP(6),
interval_type_enum VARCHAR2(30 char),
interval_count NUMBER(10, 0),
total_payment_amt NUMBER(17, 6),
payment_count NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cat_payment_schedule PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cat_payment_schedule TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cat_payment_schedule');
EXEC dbms_output.put_line('--- CREATING TABLE cfra_invoice_dup --- ');
CREATE TABLE cfra_invoice_dup(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
reprint_id VARCHAR2(30 char) NOT NULL,
doc_number VARCHAR2(30 char) NOT NULL,
reprint_number NUMBER(10, 0),
operator_code VARCHAR2(30 char),
business_date TIMESTAMP(6),
reprint_date TIMESTAMP(6),
document_type VARCHAR2(30 char),
inv_rtl_loc_id NUMBER(10, 0),
inv_wkstn_id NUMBER(19, 0),
inv_business_year NUMBER(4, 0),
inv_sequence_id VARCHAR2(255 char),
inv_sequence_nbr NUMBER(19, 0),
postponement_flag NUMBER(1, 0) DEFAULT 0,
signature VARCHAR2(1024 char),
signature_source VARCHAR2(1024 char),
signature_version NUMBER(6, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cfra_invoice_dup PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, reprint_id, doc_number) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cfra_invoice_dup TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cfra_invoice_dup');
EXEC dbms_output.put_line('--- CREATING TABLE cfra_rcpt_dup --- ');
CREATE TABLE cfra_rcpt_dup(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
reprint_id VARCHAR2(30 char) NOT NULL,
doc_number VARCHAR2(30 char) NOT NULL,
reprint_number NUMBER(10, 0),
operator_code VARCHAR2(30 char),
amount_lines NUMBER(10, 0),
business_date TIMESTAMP(6),
reprint_date TIMESTAMP(6),
postponement_flag NUMBER(1, 0) DEFAULT 0,
signature VARCHAR2(1024 char),
signature_source VARCHAR2(1024 char),
signature_version NUMBER(6, 0),
trans_rtl_loc_id NUMBER(10, 0),
trans_business_date TIMESTAMP(6),
trans_wkstn_id NUMBER(19, 0),
trans_trans_seq NUMBER(19, 0),
document_type VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cfra_rcpt_dup PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, reprint_id, doc_number) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cfra_rcpt_dup TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cfra_rcpt_dup');
EXEC dbms_output.put_line('--- CREATING TABLE cfra_sales_tax_total --- ');
CREATE TABLE cfra_sales_tax_total(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
fiscal_year NUMBER(4, 0) NOT NULL,
reference_year NUMBER(4, 0) NOT NULL,
reference_month NUMBER(2, 0) NOT NULL,
reference_day NUMBER(2, 0) NOT NULL,
tax_rate NUMBER(6, 0) NOT NULL,
sales_total NUMBER(17, 6),
grand_total NUMBER(17, 6),
sales_only_total NUMBER(17, 6),
returns_only_total NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cfra_sales_tax_total PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, fiscal_year, reference_year, reference_month, reference_day, tax_rate) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cfra_sales_tax_total TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cfra_sales_tax_total');
EXEC dbms_output.put_line('--- CREATING TABLE cfra_sales_total --- ');
CREATE TABLE cfra_sales_total(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
fiscal_year NUMBER(4, 0) NOT NULL,
reference_year NUMBER(4, 0) NOT NULL,
reference_month NUMBER(2, 0) NOT NULL,
reference_day NUMBER(2, 0) NOT NULL,
fiscal_month NUMBER(2, 0),
status_code VARCHAR2(30 char),
sales_total NUMBER(17, 6),
grand_total NUMBER(17, 6),
sales_only_total NUMBER(17, 6),
returns_only_total NUMBER(17, 6),
perpetual_grand_total NUMBER(17, 6),
real_perpetual_grand_total NUMBER(17, 6),
total_timestamp TIMESTAMP(6),
postponement_flag NUMBER(1, 0) DEFAULT 0,
signature VARCHAR2(1024 char),
signature_source VARCHAR2(1024 char),
signature_version NUMBER(6, 0),
totals_file CLOB,
totals_file_sign VARCHAR2(1024 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cfra_sales_total PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, fiscal_year, reference_year, reference_month, reference_day) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cfra_sales_total TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cfra_sales_total');
EXEC dbms_output.put_line('--- CREATING TABLE cfra_sales_trn_tax_total --- ');
CREATE TABLE cfra_sales_trn_tax_total(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
reference_year NUMBER(4, 0) NOT NULL,
reference_month NUMBER(2, 0) NOT NULL,
reference_day NUMBER(2, 0) NOT NULL,
document_number VARCHAR2(30 char) NOT NULL,
tax_rate NUMBER(6, 0) NOT NULL,
sales_only_total NUMBER(17, 6),
returns_only_total NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cfra_sales_trn_tax_total PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, reference_year, reference_month, reference_day, document_number, tax_rate) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cfra_sales_trn_tax_total TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cfra_sales_trn_tax_total');
EXEC dbms_output.put_line('--- CREATING TABLE cfra_sales_trn_total --- ');
CREATE TABLE cfra_sales_trn_total(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
reference_year NUMBER(4, 0) NOT NULL,
reference_month NUMBER(2, 0) NOT NULL,
reference_day NUMBER(2, 0) NOT NULL,
document_number VARCHAR2(30 char) NOT NULL,
sales_only_total NUMBER(17, 6),
returns_only_total NUMBER(17, 6),
daily_sales_total NUMBER(17, 6),
perpetual_grand_total NUMBER(17, 6),
real_perpetual_grand_total NUMBER(17, 6),
trans_rtl_loc_id NUMBER(10, 0),
trans_business_date TIMESTAMP(6),
trans_wkstn_id NUMBER(19, 0),
trans_trans_seq NUMBER(19, 0),
total_timestamp TIMESTAMP(6),
postponement_flag NUMBER(1, 0) DEFAULT 0,
signature VARCHAR2(1024 char),
signature_source VARCHAR2(1024 char),
signature_version NUMBER(6, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cfra_sales_trn_total PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, reference_year, reference_month, reference_day, document_number) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cfra_sales_trn_total TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cfra_sales_trn_total');
EXEC dbms_output.put_line('--- CREATING TABLE cfra_technical_event_log --- ');
CREATE TABLE cfra_technical_event_log(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
prefix VARCHAR2(10 char) NOT NULL,
event_number NUMBER(10, 0) NOT NULL,
unique_id VARCHAR2(32 char),
event_code NUMBER(10, 0),
description VARCHAR2(512 char),
operator_code VARCHAR2(30 char),
event_timestamp TIMESTAMP(6),
informations CLOB,
postponement_flag NUMBER(1, 0) DEFAULT 0,
signature VARCHAR2(1024 char),
signature_source VARCHAR2(4000 char),
signature_version NUMBER(6, 0),
business_date TIMESTAMP(6) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cfra_technical_event_log PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, prefix, event_number) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cfra_technical_event_log TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cfra_technical_event_log');
EXEC dbms_output.put_line('--- CREATING TABLE cger_tse_device --- ');
CREATE TABLE cger_tse_device(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
tse_seq NUMBER(10, 0) NOT NULL,
tse_name VARCHAR2(60 char),
tse_type VARCHAR2(60 char),
tse_config VARCHAR2(4000 char),
tse_admin_puk VARCHAR2(60 char),
tse_admin_pin VARCHAR2(60 char),
tse_time_pin VARCHAR2(60 char),
tse_shared_key VARCHAR2(60 char),
tse_serial_number VARCHAR2(60 char),
tse_public_key VARCHAR2(255 char),
tse_cert_expiry_date TIMESTAMP(6),
tse_certificate VARCHAR2(4000 char),
tse_signature_algo VARCHAR2(60 char),
tse_date_format VARCHAR2(60 char),
tse_pd_encoding VARCHAR2(60 char),
tse_init_status VARCHAR2(60 char),
tse_status VARCHAR2(60 char),
void_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cger_tse_device PRIMARY KEY (organization_id, rtl_loc_id, tse_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cger_tse_device TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cger_tse_device');
EXEC dbms_output.put_line('--- CREATING TABLE cger_tse_device_register --- ');
CREATE TABLE cger_tse_device_register(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
tse_seq NUMBER(10, 0),
void_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cger_tse_device_register PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cger_tse_device_register TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cger_tse_device_register');
EXEC dbms_output.put_line('--- CREATING TABLE civc_invoice --- ');
CREATE TABLE civc_invoice(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
business_year NUMBER(4, 0) NOT NULL,
sequence_id VARCHAR2(255 char) NOT NULL,
sequence_nbr NUMBER(19, 0) NOT NULL,
invoice_type VARCHAR2(32 char) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
void_flag NUMBER(1, 0) DEFAULT 0,
party_id NUMBER(19, 0) NOT NULL,
ext_invoice_id VARCHAR2(60 char),
gross_amt NUMBER(17, 6),
refund_amt NUMBER(17, 6),
invoice_date TIMESTAMP(6),
ext_invoice_barcode VARCHAR2(60 char),
return_flag NUMBER(1, 0) DEFAULT 0,
invoice_prefix VARCHAR2(20 char),
confirm_flag NUMBER(1, 0) DEFAULT 0,
void_pending_flag NUMBER(1, 0) DEFAULT 0,
confirm_sent_flag NUMBER(1, 0) DEFAULT 0,
confirm_result VARCHAR2(255 char),
time_stamp TIMESTAMP(6),
document_number VARCHAR2(60 char),
invoice_trans_seq NUMBER(19, 0),
invoice_data BLOB,
invoice_export_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_civc_invoice PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, business_year, sequence_id, sequence_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON civc_invoice TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('civc_invoice');
EXEC dbms_output.put_line('--- CREATING TABLE civc_invoice_xref --- ');
CREATE TABLE civc_invoice_xref(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
business_year NUMBER(4, 0) NOT NULL,
sequence_id VARCHAR2(255 char) NOT NULL,
sequence_nbr NUMBER(19, 0) NOT NULL,
trans_rtl_loc_id NUMBER(10, 0) NOT NULL,
trans_business_date TIMESTAMP(6) NOT NULL,
trans_wkstn_id NUMBER(19, 0) NOT NULL,
trans_trans_seq NUMBER(19, 0) NOT NULL,
trans_trans_lineitm_seq NUMBER(10, 0) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_civc_invoice_xref PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, business_year, sequence_id, sequence_nbr, trans_rtl_loc_id, trans_business_date, trans_wkstn_id, trans_trans_seq, trans_trans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON civc_invoice_xref TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CIVC_INVOICE_XREF_TRANS --- ');
CREATE INDEX IDX_CIVC_INVOICE_XREF_TRANS ON civc_invoice_xref(organization_id, trans_rtl_loc_id, trans_business_date, trans_wkstn_id, trans_trans_seq, trans_trans_lineitm_seq)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('civc_invoice_xref');
EXEC dbms_output.put_line('--- CREATING TABLE civc_taxfree_country --- ');
CREATE TABLE civc_taxfree_country(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
iso3num_code VARCHAR2(3 char) NOT NULL,
iso2alp_code VARCHAR2(2 char),
name VARCHAR2(150 char),
phone_prefix VARCHAR2(4 char),
passport_code VARCHAR2(10 char),
void_flag NUMBER(1, 0) DEFAULT 0,
blocked_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_civc_taxfree_country PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, iso3num_code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON civc_taxfree_country TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('civc_taxfree_country');
EXEC dbms_output.put_line('--- CREATING TABLE com_address --- ');
CREATE TABLE com_address(
organization_id NUMBER(10, 0) NOT NULL,
address_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
address1 VARCHAR2(254 char),
address2 VARCHAR2(254 char),
address3 VARCHAR2(254 char),
address4 VARCHAR2(254 char),
apartment VARCHAR2(30 char),
city VARCHAR2(254 char),
territory VARCHAR2(254 char),
postal_code VARCHAR2(254 char),
country VARCHAR2(2 char),
neighborhood VARCHAR2(254 char),
county VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_address PRIMARY KEY (organization_id, address_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_address TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_COM_ADDRESS_ORGNODE --- ');
CREATE INDEX IDX_COM_ADDRESS_ORGNODE ON com_address(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('com_address');
EXEC dbms_output.put_line('--- CREATING TABLE com_address_country --- ');
CREATE TABLE com_address_country(
organization_id NUMBER(10, 0) NOT NULL,
country_id VARCHAR2(2 char) NOT NULL,
address_mode VARCHAR2(60 char) DEFAULT 'DEFAULT' NOT NULL,
country_name VARCHAR2(254 char),
max_postal_length NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_address_country PRIMARY KEY (organization_id, country_id, address_mode) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_address_country TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_address_country');
EXEC dbms_output.put_line('--- CREATING TABLE com_address_postalcode --- ');
CREATE TABLE com_address_postalcode(
organization_id NUMBER(10, 0) NOT NULL,
country_id VARCHAR2(2 char) NOT NULL,
postal_code_id VARCHAR2(30 char) NOT NULL,
address_mode VARCHAR2(60 char) DEFAULT 'DEFAULT' NOT NULL,
state_id VARCHAR2(10 char),
city_name VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_address_postalcode PRIMARY KEY (organization_id, country_id, postal_code_id, address_mode) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_address_postalcode TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_address_postalcode');
EXEC dbms_output.put_line('--- CREATING TABLE com_address_state --- ');
CREATE TABLE com_address_state(
organization_id NUMBER(10, 0) NOT NULL,
country_id VARCHAR2(2 char) NOT NULL,
state_id VARCHAR2(10 char) NOT NULL,
address_mode VARCHAR2(60 char) DEFAULT 'DEFAULT' NOT NULL,
state_name VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_address_state PRIMARY KEY (organization_id, country_id, state_id, address_mode) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_address_state TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_address_state');
EXEC dbms_output.put_line('--- CREATING TABLE com_airport --- ');
CREATE TABLE com_airport(
organization_id NUMBER(10, 0) NOT NULL,
airport_code VARCHAR2(3 char) NOT NULL,
airport_name VARCHAR2(254 char) NOT NULL,
country_code VARCHAR2(2 char) NOT NULL,
zone_id VARCHAR2(30 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_airport PRIMARY KEY (organization_id, airport_code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_airport TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_airport');
EXEC dbms_output.put_line('--- CREATING TABLE com_airport_zone --- ');
CREATE TABLE com_airport_zone(
organization_id NUMBER(10, 0) NOT NULL,
zone_id VARCHAR2(30 char) NOT NULL,
description VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_airport_zone PRIMARY KEY (organization_id, zone_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_airport_zone TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_airport_zone');
EXEC dbms_output.put_line('--- CREATING TABLE com_airport_zone_detail --- ');
CREATE TABLE com_airport_zone_detail(
organization_id NUMBER(10, 0) NOT NULL,
zone_id VARCHAR2(30 char) NOT NULL,
destination_zone_id VARCHAR2(30 char) NOT NULL,
tax_calculation_mode VARCHAR2(30 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_airport_zone_detail PRIMARY KEY (organization_id, zone_id, destination_zone_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_airport_zone_detail TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_airport_zone_detail');
EXEC dbms_output.put_line('--- CREATING TABLE com_broadcaster_options --- ');
CREATE TABLE com_broadcaster_options(
organization_id NUMBER(10, 0) NOT NULL,
option_id NUMBER(10, 0) NOT NULL,
translation_key VARCHAR2(150 char) NOT NULL,
default_translation VARCHAR2(255 char),
xpath VARCHAR2(200 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_broadcaster_options PRIMARY KEY (organization_id, option_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_broadcaster_options TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_broadcaster_options');
EXEC dbms_output.put_line('--- CREATING TABLE com_button_grid --- ');
CREATE TABLE com_button_grid(
organization_id NUMBER(10, 0) NOT NULL,
level_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
level_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
grid_id VARCHAR2(50 char) NOT NULL,
row_id NUMBER(10, 0) NOT NULL,
column_id NUMBER(10, 0) NOT NULL,
component_id VARCHAR2(50 char) NOT NULL,
sort_order NUMBER(10, 0) DEFAULT 0 NOT NULL,
child_id VARCHAR2(50 char),
key_name VARCHAR2(50 char),
data VARCHAR2(100 char),
text VARCHAR2(255 char),
text_x NUMBER(10, 0),
text_y NUMBER(10, 0),
image_filename VARCHAR2(512 char),
image_x NUMBER(10, 0),
image_y NUMBER(10, 0),
visibility_rule VARCHAR2(255 char),
height_span NUMBER(10, 0),
width_span NUMBER(10, 0),
background_rgb VARCHAR2(7 char),
foreground_rgb VARCHAR2(7 char),
button_style VARCHAR2(50 char),
action_idx NUMBER(10, 0),
animation_idx NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_button_grid PRIMARY KEY (organization_id, level_code, level_value, grid_id, row_id, column_id, component_id, sort_order) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_button_grid TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_button_grid');
EXEC dbms_output.put_line('--- CREATING TABLE com_code_value --- ');
CREATE TABLE com_code_value(
organization_id NUMBER(10, 0) NOT NULL,
category VARCHAR2(30 char) NOT NULL,
code VARCHAR2(60 char) NOT NULL,
description VARCHAR2(254 char),
sort_order NUMBER(10, 0),
hidden_flag NUMBER(1, 0) DEFAULT 0,
rank NUMBER(10, 0),
image_url VARCHAR2(254 char),
config_element VARCHAR2(200 char) DEFAULT '*' NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_code_value PRIMARY KEY (organization_id, category, code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_code_value TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_code_value');
EXEC dbms_output.put_line('--- CREATING TABLE com_country_return_map --- ');
CREATE TABLE com_country_return_map(
organization_id NUMBER(10, 0) NOT NULL,
purchased_from VARCHAR2(2 char) NOT NULL,
return_to VARCHAR2(2 char) NOT NULL,
disallow_cross_border_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_country_return_map PRIMARY KEY (organization_id, purchased_from, return_to) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_country_return_map TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_country_return_map');
EXEC dbms_output.put_line('--- CREATING TABLE com_external_system_map --- ');
CREATE TABLE com_external_system_map(
system_id VARCHAR2(10 char) NOT NULL,
system_cd VARCHAR2(10 char) NOT NULL,
organization_id NUMBER(10, 0) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_external_system_map PRIMARY KEY (system_id, organization_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_external_system_map TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_external_system_map');
EXEC dbms_output.put_line('--- CREATING TABLE com_flight_info --- ');
CREATE TABLE com_flight_info(
organization_id NUMBER(10, 0) NOT NULL,
scheduled_date_time TIMESTAMP(6) NOT NULL,
origin_airport VARCHAR2(3 char) NOT NULL,
flight_number VARCHAR2(30 char) NOT NULL,
destination_airport VARCHAR2(3 char) NOT NULL,
via_1_airport VARCHAR2(3 char),
via_2_airport VARCHAR2(3 char),
via_3_airport VARCHAR2(3 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_flight_info PRIMARY KEY (organization_id, scheduled_date_time, origin_airport, flight_number) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_flight_info TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_flight_info');
EXEC dbms_output.put_line('--- CREATING TABLE com_measurement --- ');
CREATE TABLE com_measurement(
organization_id NUMBER(10, 0) NOT NULL,
dimension VARCHAR2(30 char) NOT NULL,
code VARCHAR2(10 char) NOT NULL,
name VARCHAR2(254 char) NOT NULL,
symbol VARCHAR2(254 char) NOT NULL,
factor NUMBER(21, 10) NOT NULL,
qty_scale NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_measurement PRIMARY KEY (organization_id, dimension, code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_measurement TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_measurement');
EXEC dbms_output.put_line('--- CREATING TABLE com_reason_code --- ');
CREATE TABLE com_reason_code(
organization_id NUMBER(10, 0) NOT NULL,
reason_typcode VARCHAR2(30 char) NOT NULL,
reason_code VARCHAR2(30 char) NOT NULL,
description VARCHAR2(254 char),
parent_code VARCHAR2(30 char),
gl_acct_nbr VARCHAR2(254 char),
minimum_amt NUMBER(17, 6),
maximum_amt NUMBER(17, 6),
comment_req VARCHAR2(10 char),
cust_msg VARCHAR2(254 char),
inv_action_code VARCHAR2(30 char),
location_id VARCHAR2(60 char),
bucket_id VARCHAR2(60 char),
sort_order NUMBER(10, 0),
hidden_flag NUMBER(1, 0) DEFAULT 0,
config_element VARCHAR2(200 char) DEFAULT '*' NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_reason_code PRIMARY KEY (organization_id, reason_typcode, reason_code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_reason_code TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_reason_code');
EXEC dbms_output.put_line('--- CREATING TABLE com_receipt_text --- ');
CREATE TABLE com_receipt_text(
organization_id NUMBER(10, 0) NOT NULL,
text_code VARCHAR2(30 char) NOT NULL,
text_subcode VARCHAR2(30 char) NOT NULL,
text_seq NUMBER(10, 0) NOT NULL,
config_element VARCHAR2(200 char) DEFAULT '*' NOT NULL,
receipt_text VARCHAR2(4000 char) NOT NULL,
effective_date TIMESTAMP(6),
expiration_date TIMESTAMP(6),
reformat_flag NUMBER(1, 0) DEFAULT 1,
line_format VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_receipt_text PRIMARY KEY (organization_id, text_code, text_subcode, text_seq, config_element) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_receipt_text TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_receipt_text');
EXEC dbms_output.put_line('--- CREATING TABLE com_report_data --- ');
CREATE TABLE com_report_data(
organization_id NUMBER(10, 0) NOT NULL,
owner_type_enum VARCHAR2(30 char) NOT NULL,
owner_id VARCHAR2(60 char) NOT NULL,
report_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
report_data BLOB,
delete_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_report_data PRIMARY KEY (organization_id, owner_type_enum, owner_id, report_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_report_data TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_COM_REPORT_DATA_ORGNODE --- ');
CREATE INDEX IDX_COM_REPORT_DATA_ORGNODE ON com_report_data(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('com_report_data');
EXEC dbms_output.put_line('--- CREATING TABLE com_report_lookup --- ');
CREATE TABLE com_report_lookup(
organization_id NUMBER(10, 0) NOT NULL,
owner_type_enum VARCHAR2(30 char) NOT NULL,
owner_id VARCHAR2(60 char) NOT NULL,
report_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
report_url VARCHAR2(254 char),
description VARCHAR2(254 char),
record_type_enum VARCHAR2(30 char),
record_creation_date TIMESTAMP(6),
record_level_enum VARCHAR2(30 char),
parent_report_id VARCHAR2(60 char),
delete_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_report_lookup PRIMARY KEY (organization_id, owner_type_enum, owner_id, report_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_report_lookup TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_COM_REPORT_LOOKUP_ORGNODE --- ');
CREATE INDEX IDX_COM_REPORT_LOOKUP_ORGNODE ON com_report_lookup(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('com_report_lookup');
EXEC dbms_output.put_line('--- CREATING TABLE com_sequence --- ');
CREATE TABLE com_sequence(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
sequence_id VARCHAR2(255 char) NOT NULL,
sequence_mode VARCHAR2(30 char) DEFAULT 'ACTIVE' NOT NULL,
sequence_nbr NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_sequence PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, sequence_id, sequence_mode) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_sequence TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_sequence');
EXEC dbms_output.put_line('--- CREATING TABLE com_sequence_journal --- ');
CREATE TABLE com_sequence_journal(
organization_id NUMBER(10, 0),
rtl_loc_id NUMBER(10, 0),
wkstn_id NUMBER(19, 0),
sequence_id VARCHAR2(255 char),
sequence_mode VARCHAR2(30 char) DEFAULT 'ACTIVE',
sequence_value VARCHAR2(60 char),
sequence_timestamp TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char)
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_sequence_journal TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_sequence_journal');
EXEC dbms_output.put_line('--- CREATING TABLE com_sequence_part --- ');
CREATE TABLE com_sequence_part(
organization_id NUMBER(10, 0) NOT NULL,
sequence_id VARCHAR2(255 char) NOT NULL,
prefix VARCHAR2(30 char),
suffix VARCHAR2(30 char),
encode_flag NUMBER(1, 0),
check_digit_algo VARCHAR2(30 char),
numeric_flag NUMBER(1, 0),
pad_length NUMBER(10, 0),
pad_character VARCHAR2(2 char),
initial_value NUMBER(10, 0),
max_value NUMBER(10, 0),
value_increment NUMBER(10, 0),
include_store_id NUMBER(1, 0),
store_pad_length NUMBER(10, 0),
include_wkstn_id NUMBER(1, 0),
wkstn_pad_length NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_sequence_part PRIMARY KEY (organization_id, sequence_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_sequence_part TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_sequence_part');
EXEC dbms_output.put_line('--- CREATING TABLE com_shipping_cost --- ');
CREATE TABLE com_shipping_cost(
organization_id NUMBER(10, 0) NOT NULL,
begin_range NUMBER(11, 2) NOT NULL,
end_range NUMBER(11, 2) NOT NULL,
cost NUMBER(17, 6) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
category VARCHAR2(30 char) NOT NULL,
minimum_cost NUMBER(17, 6),
maximum_cost NUMBER(17, 6),
item_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_shipping_cost PRIMARY KEY (organization_id, begin_range, end_range, cost, category) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_shipping_cost TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_COM_SHIPPING_COST_ORGNODE --- ');
CREATE INDEX IDX_COM_SHIPPING_COST_ORGNODE ON com_shipping_cost(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('com_shipping_cost');
EXEC dbms_output.put_line('--- CREATING TABLE com_shipping_fee --- ');
CREATE TABLE com_shipping_fee(
organization_id NUMBER(10, 0) NOT NULL,
rule_name VARCHAR2(30 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
priority NUMBER(10, 0),
ship_item_id VARCHAR2(60 char),
aggregation_type VARCHAR2(30 char),
rule_type VARCHAR2(30 char),
param1 VARCHAR2(30 char),
param2 VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_shipping_fee PRIMARY KEY (organization_id, rule_name) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_shipping_fee TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_COM_SHIPPING_FEE_ORGNODE --- ');
CREATE INDEX IDX_COM_SHIPPING_FEE_ORGNODE ON com_shipping_fee(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('com_shipping_fee');
EXEC dbms_output.put_line('--- CREATING TABLE com_shipping_fee_tier --- ');
CREATE TABLE com_shipping_fee_tier(
organization_id NUMBER(10, 0) NOT NULL,
rule_name VARCHAR2(30 char) NOT NULL,
parent_rule_name VARCHAR2(30 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
priority NUMBER(10, 0),
fee_type VARCHAR2(20 char),
fee_value NUMBER(17, 6),
ship_method VARCHAR2(60 char),
min_price NUMBER(17, 6),
max_price NUMBER(17, 6),
item_id VARCHAR2(60 char),
rule_type VARCHAR2(30 char),
param1 VARCHAR2(30 char),
param2 VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_shipping_fee_tier PRIMARY KEY (organization_id, rule_name, parent_rule_name) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_shipping_fee_tier TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_COM_SHIP_TIER_SHIP_METHOD --- ');
CREATE INDEX XST_COM_SHIP_TIER_SHIP_METHOD ON com_shipping_fee_tier(UPPER(ship_method))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_COMSHIPPINGFEETIERORGNODE --- ');
CREATE INDEX IDX_COMSHIPPINGFEETIERORGNODE ON com_shipping_fee_tier(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('com_shipping_fee_tier');
EXEC dbms_output.put_line('--- CREATING TABLE com_signature --- ');
CREATE TABLE com_signature(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
signature_id VARCHAR2(255 char) NOT NULL,
signature_mode VARCHAR2(30 char) DEFAULT 'ACTIVE' NOT NULL,
signature_string VARCHAR2(1024 char),
signature_source VARCHAR2(4000 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_signature PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, signature_id, signature_mode) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_signature TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('com_signature');
EXEC dbms_output.put_line('--- CREATING TABLE com_trans_prompt_properties --- ');
CREATE TABLE com_trans_prompt_properties(
organization_id NUMBER(10, 0) NOT NULL,
trans_prompt_property_code VARCHAR2(30 char) NOT NULL,
effective_date TIMESTAMP(6) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
expiration_date TIMESTAMP(6),
code_category VARCHAR2(30 char),
prompt_title_key VARCHAR2(60 char),
prompt_msg_key VARCHAR2(60 char),
required_flag NUMBER(1, 0) DEFAULT 0,
sort_order NUMBER(10, 0),
prompt_mthd_code VARCHAR2(30 char),
prompt_edit_pattern VARCHAR2(30 char),
validation_rule_key VARCHAR2(30 char),
transaction_state VARCHAR2(30 char),
prompt_key VARCHAR2(30 char),
chain_key VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_comtranspromptproperties PRIMARY KEY (organization_id, trans_prompt_property_code, effective_date) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_trans_prompt_properties TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDXCOMTRNSPRMPTPRPRTIESORGNODE --- ');
CREATE INDEX IDXCOMTRNSPRMPTPRPRTIESORGNODE ON com_trans_prompt_properties(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('com_trans_prompt_properties');
EXEC dbms_output.put_line('--- CREATING TABLE com_translations --- ');
CREATE TABLE com_translations(
organization_id NUMBER(10, 0) NOT NULL,
locale VARCHAR2(30 char) NOT NULL,
translation_key VARCHAR2(150 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
translation VARCHAR2(4000 char),
external_system VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_com_translations PRIMARY KEY (organization_id, locale, translation_key) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON com_translations TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_COM_TRANSLATIONS_ORGNODE --- ');
CREATE INDEX IDX_COM_TRANSLATIONS_ORGNODE ON com_translations(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_COM_TRANSLATIONS_ORG_KEY --- ');
CREATE INDEX IDX_COM_TRANSLATIONS_ORG_KEY ON com_translations(organization_id, translation_key)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('com_translations');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_address_muni --- ');
CREATE TABLE cpaf_address_muni(
organization_id NUMBER(10, 0) NOT NULL,
municipality_id NUMBER(10, 0) NOT NULL,
uf VARCHAR2(2 char),
name VARCHAR2(72 char),
ibge_code VARCHAR2(7 char),
postal_code_start VARCHAR2(8 char),
postal_code_end VARCHAR2(8 char),
parent_municipality_id NUMBER(10, 0),
loc_in_sit VARCHAR2(1 char),
loc_in_tipo_loc VARCHAR2(1 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_address_muni PRIMARY KEY (organization_id, municipality_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_address_muni TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_address_muni');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_card_network --- ');
CREATE TABLE cpaf_card_network(
organization_id NUMBER(10, 0) NOT NULL,
network_name VARCHAR2(254 char) NOT NULL,
network_id VARCHAR2(30 char),
tax_id VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_card_network PRIMARY KEY (organization_id, network_name) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_card_network TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_card_network');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe --- ');
CREATE TABLE cpaf_nfe(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
environment_id NUMBER(10, 0) NOT NULL,
tp_nf NUMBER(10, 0) NOT NULL,
series_id NUMBER(10, 0) NOT NULL,
nnf NUMBER(10, 0) NOT NULL,
model VARCHAR2(2 char) NOT NULL,
cuf NUMBER(10, 0),
cnf NUMBER(10, 0),
trans_typcode VARCHAR2(30 char),
natop VARCHAR2(60 char),
indpag NUMBER(10, 0),
issue_date TIMESTAMP(6),
sai_ent_datetime TIMESTAMP(6),
cmun_fg VARCHAR2(7 char),
tp_imp NUMBER(10, 0),
tp_emis NUMBER(10, 0),
fin_nfe NUMBER(10, 0),
proc_emi NUMBER(10, 0),
ver_proc VARCHAR2(20 char),
cont_datetime TIMESTAMP(6),
cont_xjust VARCHAR2(255 char),
product_amount NUMBER(17, 6),
service_amount NUMBER(17, 6),
icms_basis NUMBER(17, 6),
icms_amount NUMBER(17, 6),
icms_st_basis NUMBER(17, 6),
icms_st_amount NUMBER(17, 6),
iss_basis NUMBER(17, 6),
iss_amount NUMBER(17, 6),
ii_amount NUMBER(17, 6),
pis_amount NUMBER(17, 6),
cofins_amount NUMBER(17, 6),
iss_pis_amount NUMBER(17, 6),
iss_cofins_amount NUMBER(17, 6),
discount_amount NUMBER(17, 6),
freight_amount NUMBER(17, 6),
insurance_amount NUMBER(17, 6),
other_amount NUMBER(17, 6),
total_amount NUMBER(17, 6),
inf_cpl CLOB,
protocolo VARCHAR2(30 char),
canc_protocolo VARCHAR2(30 char),
chave_nfe VARCHAR2(88 char),
old_chave_nfe VARCHAR2(88 char),
recibo VARCHAR2(30 char),
stat_code VARCHAR2(30 char),
xml CLOB,
dig_val VARCHAR2(30 char),
iss_service_date VARCHAR2(10 char),
fcp_amount NUMBER(17, 6),
fcp_st_amount NUMBER(17, 6),
fcp_st_ret_amount NUMBER(17, 6),
v_troco_amount NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe PRIMARY KEY (organization_id, rtl_loc_id, environment_id, tp_nf, series_id, nnf, model) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_dest --- ');
CREATE TABLE cpaf_nfe_dest(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
environment_id NUMBER(10, 0) NOT NULL,
tp_nf NUMBER(10, 0) NOT NULL,
series_id NUMBER(10, 0) NOT NULL,
nnf NUMBER(10, 0) NOT NULL,
model VARCHAR2(2 char) NOT NULL,
name VARCHAR2(60 char),
federal_tax_id VARCHAR2(20 char),
state_tax_id VARCHAR2(20 char),
street_name VARCHAR2(60 char),
street_num VARCHAR2(60 char),
complemento VARCHAR2(60 char),
neighborhood VARCHAR2(60 char),
city_code VARCHAR2(7 char),
city VARCHAR2(60 char),
state VARCHAR2(30 char),
postal_code VARCHAR2(8 char),
country_code VARCHAR2(4 char),
country_name VARCHAR2(60 char),
telephone VARCHAR2(14 char),
email VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_dest PRIMARY KEY (organization_id, rtl_loc_id, environment_id, tp_nf, series_id, nnf, model) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_dest TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_dest');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_issuer --- ');
CREATE TABLE cpaf_nfe_issuer(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
environment_id NUMBER(10, 0) NOT NULL,
tp_nf NUMBER(10, 0) NOT NULL,
series_id NUMBER(10, 0) NOT NULL,
nnf NUMBER(10, 0) NOT NULL,
model VARCHAR2(2 char) NOT NULL,
name VARCHAR2(60 char),
fantasy_name VARCHAR2(60 char),
federal_tax_id VARCHAR2(20 char),
state_tax_id VARCHAR2(20 char),
city_tax_id VARCHAR2(20 char),
crt VARCHAR2(1 char),
street_name VARCHAR2(60 char),
street_num VARCHAR2(60 char),
complemento VARCHAR2(60 char),
neighborhood VARCHAR2(60 char),
city_code VARCHAR2(7 char),
city VARCHAR2(60 char),
state VARCHAR2(30 char),
postal_code VARCHAR2(8 char),
country_code VARCHAR2(4 char),
country_name VARCHAR2(60 char),
telephone VARCHAR2(14 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_issuer PRIMARY KEY (organization_id, rtl_loc_id, environment_id, tp_nf, series_id, nnf, model) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_issuer TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_issuer');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_item --- ');
CREATE TABLE cpaf_nfe_item(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
environment_id NUMBER(10, 0) NOT NULL,
tp_nf NUMBER(10, 0) NOT NULL,
series_id NUMBER(10, 0) NOT NULL,
nnf NUMBER(10, 0) NOT NULL,
model VARCHAR2(2 char) NOT NULL,
sequence NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char),
item_description VARCHAR2(254 char),
ean VARCHAR2(14 char),
ncm VARCHAR2(8 char),
cest VARCHAR2(18 char),
ex_tipi VARCHAR2(3 char),
quantity NUMBER(11, 4),
unit_of_measure_code VARCHAR2(30 char),
taxable_ean VARCHAR2(14 char),
taxable_unit_of_measure_code VARCHAR2(30 char),
iat VARCHAR2(1 char),
ippt VARCHAR2(1 char),
unit_price NUMBER(17, 6),
extended_amount NUMBER(17, 6),
taxable_quantity NUMBER(11, 4),
unit_taxable_amount NUMBER(17, 6),
freight_amount NUMBER(17, 6),
insurance_amount NUMBER(17, 6),
discount_amount NUMBER(17, 6),
other_amount NUMBER(17, 6),
cfop VARCHAR2(4 char),
inf_ad_prod VARCHAR2(500 char),
icms_cst VARCHAR2(3 char),
icms_basis NUMBER(17, 6),
icms_amount NUMBER(17, 6),
icms_rate NUMBER(5, 2),
icms_st_basis NUMBER(17, 6),
icms_st_amount NUMBER(17, 6),
icms_st_rate NUMBER(5, 2),
red_bc_efet_rate NUMBER(5, 2),
bc_efet_amount NUMBER(17, 6),
icms_efet_rate NUMBER(5, 2),
icms_efet_amount NUMBER(17, 6),
iss_basis NUMBER(17, 6),
iss_amount NUMBER(17, 6),
iss_rate NUMBER(5, 2),
ipi_amount NUMBER(17, 6),
ipi_rate NUMBER(5, 2),
ii_amount NUMBER(17, 6),
pis_basis NUMBER(17, 6),
pis_amount NUMBER(17, 6),
pis_rate NUMBER(17, 6),
cofins_basis NUMBER(17, 6),
cofins_amount NUMBER(17, 6),
cofins_rate NUMBER(17, 6),
tax_situation_code VARCHAR2(6 char),
tax_group_id VARCHAR2(120 char),
log_sequence NUMBER(10, 0),
ref_nfe VARCHAR2(88 char),
iis_city_code VARCHAR2(7 char),
iis_service_code VARCHAR2(5 char),
iis_eligible_indicator VARCHAR2(2 char),
iis_incentive_indicator VARCHAR2(1 char),
st_rate NUMBER(17, 6),
fcp_basis NUMBER(17, 6),
fcp_amount NUMBER(17, 6),
fcp_rate NUMBER(17, 6),
fcp_st_basis NUMBER(17, 6),
fcp_st_amount NUMBER(17, 6),
fcp_st_rate NUMBER(17, 6),
fcp_st_ret_basis NUMBER(17, 6),
fcp_st_ret_amount NUMBER(17, 6),
fcp_st_ret_rate NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_item PRIMARY KEY (organization_id, rtl_loc_id, environment_id, tp_nf, series_id, nnf, model, sequence) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_item TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_item');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_queue --- ');
CREATE TABLE cpaf_nfe_queue(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
queue_seq NUMBER(10, 0) NOT NULL,
environment_id NUMBER(10, 0),
tp_nf NUMBER(10, 0),
series_id NUMBER(10, 0),
nnf NUMBER(10, 0),
cuf NUMBER(10, 0),
cnf NUMBER(10, 0),
usage_type VARCHAR2(30 char),
trans_typcode VARCHAR2(30 char),
natop VARCHAR2(60 char),
indpag NUMBER(10, 0),
model VARCHAR2(2 char),
issue_date TIMESTAMP(6),
sai_ent_datetime TIMESTAMP(6),
cmun_fg VARCHAR2(7 char),
tp_imp NUMBER(10, 0),
tp_emis NUMBER(10, 0),
fin_nfe NUMBER(10, 0),
proc_emi NUMBER(10, 0),
ver_proc VARCHAR2(20 char),
cont_datetime TIMESTAMP(6),
cont_xjust VARCHAR2(255 char),
product_amount NUMBER(17, 6),
service_amount NUMBER(17, 6),
icms_basis NUMBER(17, 6),
icms_amount NUMBER(17, 6),
icms_st_basis NUMBER(17, 6),
icms_st_amount NUMBER(17, 6),
iss_basis NUMBER(17, 6),
iss_amount NUMBER(17, 6),
ii_amount NUMBER(17, 6),
pis_amount NUMBER(17, 6),
cofins_amount NUMBER(17, 6),
iss_pis_amount NUMBER(17, 6),
iss_cofins_amount NUMBER(17, 6),
discount_amount NUMBER(17, 6),
freight_amount NUMBER(17, 6),
insurance_amount NUMBER(17, 6),
other_amount NUMBER(17, 6),
total_amount NUMBER(17, 6),
inf_cpl CLOB,
protocolo VARCHAR2(30 char),
canc_protocolo VARCHAR2(30 char),
chave_nfe VARCHAR2(88 char),
old_chave_nfe VARCHAR2(88 char),
recibo VARCHAR2(30 char),
stat_code VARCHAR2(30 char),
xml CLOB,
response_code VARCHAR2(30 char),
response_text CLOB,
dig_val VARCHAR2(30 char),
iss_service_date VARCHAR2(10 char),
fcp_amount NUMBER(17, 6),
fcp_st_amount NUMBER(17, 6),
fcp_st_ret_amount NUMBER(17, 6),
v_troco_amount NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_queue PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, queue_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_queue TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_queue');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_queue_dest --- ');
CREATE TABLE cpaf_nfe_queue_dest(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
queue_seq NUMBER(10, 0) NOT NULL,
name VARCHAR2(60 char),
federal_tax_id VARCHAR2(20 char),
state_tax_id VARCHAR2(20 char),
street_name VARCHAR2(60 char),
street_num VARCHAR2(60 char),
complemento VARCHAR2(60 char),
neighborhood VARCHAR2(60 char),
city_code VARCHAR2(7 char),
city VARCHAR2(60 char),
state VARCHAR2(30 char),
postal_code VARCHAR2(8 char),
country_code VARCHAR2(4 char),
country_name VARCHAR2(60 char),
telephone VARCHAR2(14 char),
email VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_queue_dest PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, queue_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_queue_dest TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_queue_dest');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_queue_issuer --- ');
CREATE TABLE cpaf_nfe_queue_issuer(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
queue_seq NUMBER(10, 0) NOT NULL,
name VARCHAR2(60 char),
fantasy_name VARCHAR2(60 char),
federal_tax_id VARCHAR2(20 char),
state_tax_id VARCHAR2(20 char),
city_tax_id VARCHAR2(20 char),
crt VARCHAR2(1 char),
street_name VARCHAR2(60 char),
street_num VARCHAR2(60 char),
complemento VARCHAR2(60 char),
neighborhood VARCHAR2(60 char),
city_code VARCHAR2(7 char),
city VARCHAR2(60 char),
state VARCHAR2(30 char),
postal_code VARCHAR2(8 char),
country_code VARCHAR2(4 char),
country_name VARCHAR2(60 char),
telephone VARCHAR2(14 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_queue_issuer PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, queue_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_queue_issuer TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_queue_issuer');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_queue_item --- ');
CREATE TABLE cpaf_nfe_queue_item(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
queue_seq NUMBER(10, 0) NOT NULL,
sequence NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char),
item_description VARCHAR2(254 char),
ean VARCHAR2(14 char),
ncm VARCHAR2(8 char),
cest VARCHAR2(18 char),
ex_tipi VARCHAR2(3 char),
quantity NUMBER(11, 4),
unit_of_measure_code VARCHAR2(30 char),
taxable_ean VARCHAR2(14 char),
taxable_unit_of_measure_code VARCHAR2(30 char),
iat VARCHAR2(1 char),
ippt VARCHAR2(1 char),
unit_price NUMBER(17, 6),
extended_amount NUMBER(17, 6),
taxable_quantity NUMBER(11, 4),
unit_taxable_amount NUMBER(17, 6),
freight_amount NUMBER(17, 6),
insurance_amount NUMBER(17, 6),
discount_amount NUMBER(17, 6),
other_amount NUMBER(17, 6),
cfop VARCHAR2(4 char),
inf_ad_prod VARCHAR2(500 char),
icms_cst VARCHAR2(3 char),
icms_basis NUMBER(17, 6),
icms_amount NUMBER(17, 6),
icms_rate NUMBER(5, 2),
icms_st_basis NUMBER(17, 6),
icms_st_amount NUMBER(17, 6),
icms_st_rate NUMBER(5, 2),
red_bc_efet_rate NUMBER(5, 2),
bc_efet_amount NUMBER(17, 6),
icms_efet_rate NUMBER(5, 2),
icms_efet_amount NUMBER(17, 6),
iss_basis NUMBER(17, 6),
iss_amount NUMBER(17, 6),
iss_rate NUMBER(5, 2),
ipi_amount NUMBER(17, 6),
ipi_rate NUMBER(5, 2),
ii_amount NUMBER(17, 6),
pis_basis NUMBER(17, 6),
pis_amount NUMBER(17, 6),
pis_rate NUMBER(17, 6),
cofins_basis NUMBER(17, 6),
cofins_amount NUMBER(17, 6),
cofins_rate NUMBER(17, 6),
tax_situation_code VARCHAR2(6 char),
tax_group_id VARCHAR2(120 char),
log_sequence NUMBER(10, 0),
ref_nfe VARCHAR2(88 char),
iis_city_code VARCHAR2(7 char),
iis_service_code VARCHAR2(5 char),
iis_eligible_indicator VARCHAR2(2 char),
iis_incentive_indicator VARCHAR2(1 char),
st_rate NUMBER(17, 6),
fcp_basis NUMBER(17, 6),
fcp_amount NUMBER(17, 6),
fcp_rate NUMBER(17, 6),
fcp_st_basis NUMBER(17, 6),
fcp_st_amount NUMBER(17, 6),
fcp_st_rate NUMBER(17, 6),
fcp_st_ret_basis NUMBER(17, 6),
fcp_st_ret_amount NUMBER(17, 6),
fcp_st_ret_rate NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_queue_item PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, queue_seq, sequence) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_queue_item TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_queue_item');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_queue_log --- ');
CREATE TABLE cpaf_nfe_queue_log(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
queue_seq NUMBER(10, 0) NOT NULL,
sequence NUMBER(10, 0) NOT NULL,
stat_code VARCHAR2(30 char),
response_code VARCHAR2(30 char),
response_text CLOB,
source VARCHAR2(255 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_queue_log PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, queue_seq, sequence) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_queue_log TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_queue_log');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_queue_tender --- ');
CREATE TABLE cpaf_nfe_queue_tender(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
queue_seq NUMBER(10, 0) NOT NULL,
sequence NUMBER(10, 0) NOT NULL,
tndr_id VARCHAR2(60 char) NOT NULL,
fiscal_tender_id VARCHAR2(60 char) NOT NULL,
amount NUMBER(17, 6),
card_network_id VARCHAR2(30 char),
card_tax_id VARCHAR2(30 char),
card_auth_number VARCHAR2(254 char),
card_type VARCHAR2(254 char),
card_trace_number VARCHAR2(254 char),
card_integration_mode VARCHAR2(30 char),
card_installments NUMBER(10, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_queue_tender PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, queue_seq, sequence, tndr_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_queue_tender TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_queue_tender');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_queue_trans --- ');
CREATE TABLE cpaf_nfe_queue_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
trans_seq NUMBER(10, 0) NOT NULL,
trans_wkstn_id NUMBER(10, 0) DEFAULT 1 NOT NULL,
queue_seq NUMBER(10, 0) NOT NULL,
inactive_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_queue_trans PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq, trans_wkstn_id, queue_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_queue_trans TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_queue_trans');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_tax_cst --- ');
CREATE TABLE cpaf_nfe_tax_cst(
organization_id NUMBER(10, 0) NOT NULL,
trans_typcode VARCHAR2(30 char) NOT NULL,
tax_loc_id VARCHAR2(60 char) NOT NULL,
tax_group_id VARCHAR2(120 char) NOT NULL,
tax_authority_id VARCHAR2(60 char) NOT NULL,
cst VARCHAR2(2 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_tax_cst PRIMARY KEY (organization_id, trans_typcode, tax_loc_id, tax_group_id, tax_authority_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_tax_cst TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_tax_cst');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_tender --- ');
CREATE TABLE cpaf_nfe_tender(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
environment_id NUMBER(10, 0) NOT NULL,
tp_nf NUMBER(10, 0) NOT NULL,
series_id NUMBER(10, 0) NOT NULL,
nnf NUMBER(10, 0) NOT NULL,
model VARCHAR2(2 char) NOT NULL,
sequence NUMBER(10, 0) NOT NULL,
tndr_id VARCHAR2(60 char) NOT NULL,
fiscal_tender_id VARCHAR2(60 char) NOT NULL,
amount NUMBER(17, 6),
card_network_id VARCHAR2(30 char),
card_tax_id VARCHAR2(30 char),
card_auth_number VARCHAR2(254 char),
card_type VARCHAR2(254 char),
card_trace_number VARCHAR2(254 char),
card_integration_mode VARCHAR2(30 char),
card_installments NUMBER(10, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_tender PRIMARY KEY (organization_id, rtl_loc_id, environment_id, tp_nf, series_id, nnf, model, sequence, tndr_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_tender TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_tender');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_trans --- ');
CREATE TABLE cpaf_nfe_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
environment_id NUMBER(10, 0) NOT NULL,
tp_nf NUMBER(10, 0) NOT NULL,
series_id NUMBER(10, 0) NOT NULL,
nnf NUMBER(10, 0) NOT NULL,
model VARCHAR2(2 char) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
trans_wkstn_id NUMBER(10, 0) DEFAULT 1 NOT NULL,
trans_seq NUMBER(10, 0) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_trans PRIMARY KEY (organization_id, rtl_loc_id, environment_id, tp_nf, series_id, nnf, model, business_date, trans_wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_trans TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_trans');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_trans_tax --- ');
CREATE TABLE cpaf_nfe_trans_tax(
organization_id NUMBER(10, 0) NOT NULL,
trans_typcode VARCHAR2(30 char) NOT NULL,
uf VARCHAR2(2 char) NOT NULL,
dest_uf VARCHAR2(2 char) NOT NULL,
tax_group_id VARCHAR2(120 char) NOT NULL,
new_tax_group_id VARCHAR2(120 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_trans_tax PRIMARY KEY (organization_id, trans_typcode, uf, dest_uf, tax_group_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_trans_tax TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_trans_tax');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_trans_type --- ');
CREATE TABLE cpaf_nfe_trans_type(
organization_id NUMBER(10, 0) NOT NULL,
trans_typcode VARCHAR2(30 char) NOT NULL,
description VARCHAR2(60 char),
notes VARCHAR2(2000 char),
cfop_same_uf VARCHAR2(4 char),
cfop_other_uf VARCHAR2(4 char),
cfop_foreign VARCHAR2(4 char),
fin_nfe NUMBER(10, 0) DEFAULT 0,
display_order NUMBER(10, 0),
comment_req_flag NUMBER(1, 0) DEFAULT 0,
rule_type VARCHAR2(30 char),
disallow_cancel_flag NUMBER(1, 0) DEFAULT 0,
pricing_type VARCHAR2(30 char),
initial_comment VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_trans_type PRIMARY KEY (organization_id, trans_typcode) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_trans_type TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_trans_type');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_nfe_trans_type_use --- ');
CREATE TABLE cpaf_nfe_trans_type_use(
organization_id NUMBER(10, 0) NOT NULL,
trans_typcode VARCHAR2(30 char) NOT NULL,
usage_typcode VARCHAR2(30 char) NOT NULL,
uf VARCHAR2(2 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_nfe_trans_type_use PRIMARY KEY (organization_id, trans_typcode, usage_typcode, uf) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_nfe_trans_type_use TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_nfe_trans_type_use');
EXEC dbms_output.put_line('--- CREATING TABLE cpaf_sat_response --- ');
CREATE TABLE cpaf_sat_response(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
queue_seq NUMBER(10, 0) NOT NULL,
session_id NUMBER(10, 0) NOT NULL,
code_sate VARCHAR2(32 char),
message_sate VARCHAR2(254 char),
code_alert VARCHAR2(32 char),
message_alert VARCHAR2(254 char),
xml_string CLOB,
time_stamp TIMESTAMP(6),
chave VARCHAR2(254 char),
total_amount NUMBER(17, 6),
cpf_cnpj_value VARCHAR2(32 char),
signature_qr_code VARCHAR2(2000 char),
success NUMBER(1, 0),
timeout NUMBER(1, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpaf_sat_response PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, queue_seq, session_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpaf_sat_response TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpaf_sat_response');
EXEC dbms_output.put_line('--- CREATING TABLE cpor_ats --- ');
CREATE TABLE cpor_ats(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
sequence_id VARCHAR2(255 char) NOT NULL,
series VARCHAR2(1 char) NOT NULL,
year NUMBER(19, 0) NOT NULL,
ats VARCHAR2(70 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cpor_ats PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, sequence_id, series, year) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cpor_ats TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cpor_ats');
EXEC dbms_output.put_line('--- CREATING TABLE crm_consent_info --- ');
CREATE TABLE crm_consent_info(
organization_id NUMBER(10, 0) NOT NULL,
effective_date TIMESTAMP(6) NOT NULL,
terms_and_conditions VARCHAR2(4000 char),
consent1_text VARCHAR2(4000 char),
consent2_text VARCHAR2(4000 char),
consent3_text VARCHAR2(4000 char),
consent4_text VARCHAR2(4000 char),
consent5_text VARCHAR2(4000 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_crm_consent_info PRIMARY KEY (organization_id, effective_date) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON crm_consent_info TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('crm_consent_info');
EXEC dbms_output.put_line('--- CREATING TABLE crm_customer_affiliation --- ');
CREATE TABLE crm_customer_affiliation(
organization_id NUMBER(10, 0) NOT NULL,
party_id NUMBER(19, 0) NOT NULL,
cust_group_id VARCHAR2(60 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_crm_customer_affiliation PRIMARY KEY (organization_id, party_id, cust_group_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON crm_customer_affiliation TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('crm_customer_affiliation');
EXEC dbms_output.put_line('--- CREATING TABLE crm_customer_notes --- ');
CREATE TABLE crm_customer_notes(
organization_id NUMBER(10, 0) NOT NULL,
party_id NUMBER(19, 0) NOT NULL,
note_seq NUMBER(19, 0) NOT NULL,
note CLOB,
creator_id VARCHAR2(254 char),
note_timestamp TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_crm_customer_notes PRIMARY KEY (organization_id, party_id, note_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON crm_customer_notes TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('crm_customer_notes');
EXEC dbms_output.put_line('--- CREATING TABLE crm_customer_payment_card --- ');
CREATE TABLE crm_customer_payment_card(
organization_id NUMBER(10, 0) NOT NULL,
party_id NUMBER(19, 0) NOT NULL,
card_token VARCHAR2(254 char) NOT NULL,
card_alias VARCHAR2(254 char),
card_type VARCHAR2(60 char),
card_last_four VARCHAR2(4 char),
expr_date VARCHAR2(64 char),
shopper_ref VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_crm_customer_payment_card PRIMARY KEY (organization_id, party_id, card_token) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON crm_customer_payment_card TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('crm_customer_payment_card');
EXEC dbms_output.put_line('--- CREATING TABLE crm_gift_registry_journal --- ');
CREATE TABLE crm_gift_registry_journal(
organization_id NUMBER(10, 0) NOT NULL,
journal_seq NUMBER(19, 0) NOT NULL,
registry_id NUMBER(19, 0),
action_code VARCHAR2(30 char),
registry_status VARCHAR2(30 char),
trans_rtl_loc_id NUMBER(10, 0),
trans_wkstn_id NUMBER(19, 0),
trans_business_date TIMESTAMP(6),
trans_trans_seq NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_crm_gift_registry_journal PRIMARY KEY (organization_id, journal_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON crm_gift_registry_journal TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CRM_GFT_REGISTRY_JOURNAL01 --- ');
CREATE INDEX IDX_CRM_GFT_REGISTRY_JOURNAL01 ON crm_gift_registry_journal(registry_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('crm_gift_registry_journal');
EXEC dbms_output.put_line('--- CREATING TABLE crm_party --- ');
CREATE TABLE crm_party(
organization_id NUMBER(10, 0) NOT NULL,
party_id NUMBER(19, 0) NOT NULL,
party_typcode VARCHAR2(30 char),
cust_id VARCHAR2(60 char),
employee_id VARCHAR2(60 char),
salutation VARCHAR2(30 char),
first_name VARCHAR2(254 char),
middle_name VARCHAR2(60 char),
last_name VARCHAR2(254 char),
first_name2 VARCHAR2(254 char),
last_name2 VARCHAR2(254 char),
suffix VARCHAR2(30 char),
gender VARCHAR2(30 char),
preferred_locale VARCHAR2(30 char),
birth_date TIMESTAMP(6),
social_security_nbr VARCHAR2(255 char),
national_tax_id VARCHAR2(30 char),
personal_tax_id VARCHAR2(30 char),
prospect_flag NUMBER(1, 0) DEFAULT 0,
rent_flag NUMBER(1, 0) DEFAULT 0,
privacy_card_flag NUMBER(1, 0) DEFAULT 0,
contact_pref VARCHAR2(30 char),
sign_up_rtl_loc_id NUMBER(10, 0),
allegiance_rtl_loc_id NUMBER(10, 0),
anniversary_date TIMESTAMP(6),
organization_typcode VARCHAR2(30 char),
organization_name VARCHAR2(254 char),
commercial_customer_flag NUMBER(1, 0) DEFAULT 0,
picture_uri VARCHAR2(254 char),
void_flag NUMBER(1, 0) DEFAULT 0,
active_flag NUMBER(1, 0) DEFAULT 1 NOT NULL,
email_rcpts_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
save_card_payments_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_crm_party PRIMARY KEY (organization_id, party_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON crm_party TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_CRM_PARTY_CUSTID --- ');
CREATE INDEX XST_CRM_PARTY_CUSTID ON crm_party(UPPER(cust_id), organization_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_CRM_PARTY_NAME_FIRST_LAST --- ');
CREATE INDEX XST_CRM_PARTY_NAME_FIRST_LAST ON crm_party(UPPER(first_name), UPPER(last_name))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_CRM_PARTY_NAME_LAST --- ');
CREATE INDEX XST_CRM_PARTY_NAME_LAST ON crm_party(UPPER(last_name))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_CRM_PARTY_NAME_LAST_FIRST --- ');
CREATE INDEX XST_CRM_PARTY_NAME_LAST_FIRST ON crm_party(UPPER(last_name), UPPER(first_name))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('crm_party');
EXEC dbms_output.put_line('--- CREATING TABLE crm_party_cross_reference --- ');
CREATE TABLE crm_party_cross_reference(
organization_id NUMBER(10, 0) NOT NULL,
parent_party_id NUMBER(19, 0) NOT NULL,
child_party_id NUMBER(19, 0) NOT NULL,
party_relationship_typcode VARCHAR2(30 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_crm_party_cross_reference PRIMARY KEY (organization_id, parent_party_id, child_party_id, party_relationship_typcode) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON crm_party_cross_reference TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CRM_PARTY_XREF01 --- ');
CREATE INDEX IDX_CRM_PARTY_XREF01 ON crm_party_cross_reference(child_party_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('crm_party_cross_reference');
EXEC dbms_output.put_line('--- CREATING TABLE crm_party_email --- ');
CREATE TABLE crm_party_email(
organization_id NUMBER(10, 0) NOT NULL,
party_id NUMBER(19, 0) NOT NULL,
email_sequence NUMBER(10, 0) NOT NULL,
email_address VARCHAR2(254 char),
email_type VARCHAR2(20 char),
email_format VARCHAR2(20 char),
contact_flag NUMBER(1, 0) DEFAULT 0,
primary_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_crm_party_email PRIMARY KEY (organization_id, party_id, email_sequence) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON crm_party_email TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_CRM_PARTY_EMAIL01 --- ');
CREATE INDEX XST_CRM_PARTY_EMAIL01 ON crm_party_email(UPPER(email_address))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('crm_party_email');
EXEC dbms_output.put_line('--- CREATING TABLE crm_party_id_xref --- ');
CREATE TABLE crm_party_id_xref(
organization_id NUMBER(10, 0) NOT NULL,
party_id NUMBER(19, 0) NOT NULL,
alternate_id_owner VARCHAR2(30 char) NOT NULL,
alternate_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_crm_party_id_xref PRIMARY KEY (organization_id, party_id, alternate_id_owner) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON crm_party_id_xref TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CRM_PARTY_ID_XREF01 --- ');
CREATE INDEX IDX_CRM_PARTY_ID_XREF01 ON crm_party_id_xref(alternate_id_owner, UPPER(alternate_id))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('crm_party_id_xref');
EXEC dbms_output.put_line('--- CREATING TABLE crm_party_locale_information --- ');
CREATE TABLE crm_party_locale_information(
organization_id NUMBER(10, 0) NOT NULL,
party_id NUMBER(19, 0) NOT NULL,
party_locale_seq NUMBER(10, 0) NOT NULL,
address1 VARCHAR2(254 char),
address2 VARCHAR2(254 char),
address3 VARCHAR2(254 char),
address4 VARCHAR2(254 char),
apartment VARCHAR2(30 char),
city VARCHAR2(254 char),
state VARCHAR2(30 char),
postal_code VARCHAR2(30 char),
country VARCHAR2(2 char),
neighborhood VARCHAR2(254 char),
county VARCHAR2(254 char),
contact_flag NUMBER(1, 0) DEFAULT 0,
primary_flag NUMBER(1, 0) DEFAULT 0,
address_type VARCHAR2(20 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_crmpartylocaleinformation PRIMARY KEY (organization_id, party_id, party_locale_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON crm_party_locale_information TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_CRM_PARTYLOCALE_CITY --- ');
CREATE INDEX XST_CRM_PARTYLOCALE_CITY ON crm_party_locale_information(UPPER(city))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_CRM_PARTYLOCALE_POSTAL --- ');
CREATE INDEX XST_CRM_PARTYLOCALE_POSTAL ON crm_party_locale_information(UPPER(postal_code))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_CRM_PARTYLOCALE_STATE --- ');
CREATE INDEX XST_CRM_PARTYLOCALE_STATE ON crm_party_locale_information(UPPER(state))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('crm_party_locale_information');
EXEC dbms_output.put_line('--- CREATING TABLE crm_party_telephone --- ');
CREATE TABLE crm_party_telephone(
organization_id NUMBER(10, 0) NOT NULL,
party_id NUMBER(19, 0) NOT NULL,
telephone_type VARCHAR2(20 char) NOT NULL,
telephone_number VARCHAR2(32 char),
contact_type VARCHAR2(20 char),
contact_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
primary_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_crm_party_telephone PRIMARY KEY (organization_id, party_id, telephone_type) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON crm_party_telephone TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_CRM_PARTY_TELEPHONE --- ');
CREATE INDEX XST_CRM_PARTY_TELEPHONE ON crm_party_telephone(UPPER(telephone_number))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('crm_party_telephone');
EXEC dbms_output.put_line('--- CREATING TABLE crpt_daily_detail --- ');
CREATE TABLE crpt_daily_detail(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
ref_wkstn_id NUMBER(19, 0) NOT NULL,
record_type VARCHAR2(30 char) NOT NULL,
sequence NUMBER(10, 0) NOT NULL,
count01 NUMBER(19, 0),
count02 NUMBER(19, 0),
txt01 VARCHAR2(2000 char),
txt02 VARCHAR2(2000 char),
txt03 VARCHAR2(2000 char),
txt04 VARCHAR2(2000 char),
txt05 VARCHAR2(2000 char),
txt06 VARCHAR2(2000 char),
num01 NUMBER(17, 6),
num02 NUMBER(17, 6),
num03 NUMBER(17, 6),
num04 NUMBER(17, 6),
num05 NUMBER(17, 6),
num06 NUMBER(17, 6),
num07 NUMBER(17, 6),
num08 NUMBER(17, 6),
num09 NUMBER(17, 6),
num10 NUMBER(17, 6),
num11 NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_crpt_daily_detail PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq, ref_wkstn_id, record_type, sequence) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON crpt_daily_detail TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('crpt_daily_detail');
EXEC dbms_output.put_line('--- CREATING TABLE crpt_daily_header --- ');
CREATE TABLE crpt_daily_header(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
dailyreport_id NUMBER(19, 0) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_crpt_daily_header PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON crpt_daily_header TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('crpt_daily_header');
EXEC dbms_output.put_line('--- CREATING TABLE ctl_app_version --- ');
CREATE TABLE ctl_app_version(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
seq NUMBER(10, 0) NOT NULL,
app_id VARCHAR2(255 char),
version_number VARCHAR2(255 char),
version_priority VARCHAR2(255 char),
effective_date TIMESTAMP(6),
update_url VARCHAR2(255 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ctl_app_version PRIMARY KEY (organization_id, rtl_loc_id, seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_app_version TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE ctl_cheetah_device_access --- ');
CREATE TABLE ctl_cheetah_device_access(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
token VARCHAR2(256 char) NOT NULL,
status VARCHAR2(256 char) NOT NULL,
secret_hash VARCHAR2(256 char),
secret_exp_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ctl_cheetah_device_access PRIMARY KEY (organization_id, rtl_loc_id, token) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_cheetah_device_access TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('ctl_cheetah_device_access');
EXEC dbms_output.put_line('--- CREATING TABLE ctl_dataloader_failure --- ');
CREATE TABLE ctl_dataloader_failure(
organization_id NUMBER(10, 0) NOT NULL,
file_name VARCHAR2(254 char) NOT NULL,
run_timestamp NUMBER(19, 0) NOT NULL,
failure_seq NUMBER(10, 0) NOT NULL,
failure_message VARCHAR2(4000 char) NOT NULL,
failed_data VARCHAR2(4000 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ctl_dataloader_failure PRIMARY KEY (organization_id, file_name, run_timestamp, failure_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_dataloader_failure TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE ctl_dataloader_summary --- ');
CREATE TABLE ctl_dataloader_summary(
organization_id NUMBER(10, 0) NOT NULL,
file_name VARCHAR2(254 char) NOT NULL,
run_timestamp NUMBER(19, 0) NOT NULL,
success_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
successful_rows NUMBER(10, 0),
failed_rows NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ctl_dataloader_summary PRIMARY KEY (organization_id, file_name, run_timestamp) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_dataloader_summary TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE ctl_device_config --- ');
CREATE TABLE ctl_device_config(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
hardware_family_type VARCHAR2(100 char) NOT NULL,
hardware_use VARCHAR2(100 char) NOT NULL,
description VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ctl_device_config PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, hardware_family_type, hardware_use) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_device_config TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('ctl_device_config');
EXEC dbms_output.put_line('--- CREATING TABLE ctl_device_fiscal_info --- ');
CREATE TABLE ctl_device_fiscal_info(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
hardware_family_type VARCHAR2(100 char) NOT NULL,
hardware_use VARCHAR2(100 char) NOT NULL,
device_id VARCHAR2(100 char),
status VARCHAR2(255 char),
fiscal_session_number VARCHAR2(100 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ctl_device_fiscal_info PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, hardware_family_type, hardware_use) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_device_fiscal_info TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('ctl_device_fiscal_info');
EXEC dbms_output.put_line('--- CREATING TABLE ctl_device_information --- ');
CREATE TABLE ctl_device_information(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
dev_seq NUMBER(10, 0) NOT NULL,
device_name VARCHAR2(255 char),
device_type VARCHAR2(255 char),
model VARCHAR2(255 char),
serial_number VARCHAR2(255 char),
firmware VARCHAR2(255 char),
firmware_date TIMESTAMP(6),
asset_status VARCHAR2(255 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ctl_device_information PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, dev_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_device_information TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE ctl_device_registration --- ');
CREATE TABLE ctl_device_registration(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
ip_address VARCHAR2(30 char),
date_timestamp TIMESTAMP(6),
business_date TIMESTAMP(6),
xstore_version VARCHAR2(40 char),
env_version VARCHAR2(40 char),
active_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
config_version VARCHAR2(40 char),
machine_name VARCHAR2(255 char),
mac_address VARCHAR2(20 char),
primary_register_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ctl_device_registration PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_device_registration TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('ctl_device_registration');
EXEC dbms_output.put_line('--- CREATING TABLE ctl_event_log --- ');
CREATE TABLE ctl_event_log(
organization_id NUMBER(10, 0),
rtl_loc_id NUMBER(10, 0),
wkstn_id NUMBER(19, 0),
business_date TIMESTAMP(6),
operator_party_id NUMBER(19, 0),
log_level VARCHAR2(20 char),
log_timestamp TIMESTAMP(6) NOT NULL,
source VARCHAR2(254 char),
thread_name VARCHAR2(254 char),
critical_to_deliver NUMBER(1, 0) DEFAULT 0,
logger_category VARCHAR2(254 char),
log_message CLOB NOT NULL,
arrival_timestamp TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char)
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_event_log TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CTL_EVENT_LOG01 --- ');
CREATE INDEX IDX_CTL_EVENT_LOG01 ON ctl_event_log(log_timestamp)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CTL_EVENT_LOG_CREATE_DATE --- ');
CREATE INDEX IDX_CTL_EVENT_LOG_CREATE_DATE ON ctl_event_log(create_date)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CTL_EVENT_LOG02 --- ');
CREATE INDEX IDX_CTL_EVENT_LOG02 ON ctl_event_log(arrival_timestamp, organization_id, UPPER(logger_category), create_date)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING TABLE ctl_ip_cashdrawer_device --- ');
CREATE TABLE ctl_ip_cashdrawer_device(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
cash_drawer_id VARCHAR2(60 char) NOT NULL,
drawer_status VARCHAR2(40 char),
product_name VARCHAR2(80 char),
description VARCHAR2(80 char),
serial_number VARCHAR2(40 char),
ip_address VARCHAR2(16 char),
tcp_port NUMBER(10, 0),
mac_address VARCHAR2(20 char),
subnet_mask VARCHAR2(16 char),
gateway VARCHAR2(16 char),
dns_hostname VARCHAR2(16 char),
dhcp_flag NUMBER(1, 0) DEFAULT 0,
firmware_version VARCHAR2(20 char),
kup VARCHAR2(1024 char),
kup_update_date TIMESTAMP(6),
beep_on_open_flag NUMBER(1, 0) DEFAULT 0,
beep_long_open_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ctl_ip_cashdrawer_device PRIMARY KEY (organization_id, rtl_loc_id, cash_drawer_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_ip_cashdrawer_device TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('ctl_ip_cashdrawer_device');
EXEC dbms_output.put_line('--- CREATING TABLE ctl_log_trickle --- ');
CREATE TABLE ctl_log_trickle(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
log_trickle_id VARCHAR2(60 char) NOT NULL,
log_type VARCHAR2(60 char),
log_data CLOB,
posted_flag NUMBER(1, 0) DEFAULT 0,
log_generated_datetime TIMESTAMP(6),
log_posted_datetime TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ctl_log_trickle PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, log_trickle_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_log_trickle TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE ctl_mobile_server --- ');
CREATE TABLE ctl_mobile_server(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
hostname VARCHAR2(254 char) NOT NULL,
port NUMBER(19, 0) NOT NULL,
alias VARCHAR2(254 char) NOT NULL,
wkstn_range_start NUMBER(10, 0),
wkstn_range_end NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ctl_mobile_server PRIMARY KEY (organization_id, rtl_loc_id, hostname, port) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_mobile_server TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('ctl_mobile_server');
EXEC dbms_output.put_line('--- CREATING TABLE ctl_offline_pos_transaction --- ');
CREATE TABLE ctl_offline_pos_transaction(
organization_id NUMBER(10, 0) NOT NULL,
uuid VARCHAR2(36 char) NOT NULL,
rtl_loc_id NUMBER(10, 0),
wkstn_id NUMBER(19, 0),
timestamp_end TIMESTAMP(6),
cust_email VARCHAR2(254 char),
sale_items_count NUMBER(10, 0),
trans_total NUMBER(17, 6),
serialized_data BLOB NOT NULL,
processed_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ctlofflinepostransaction PRIMARY KEY (organization_id, uuid) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_offline_pos_transaction TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('ctl_offline_pos_transaction');
EXEC dbms_output.put_line('--- CREATING TABLE ctl_service_response_log --- ');
CREATE TABLE ctl_service_response_log(
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
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_service_response_log TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE ctl_version_history --- ');
CREATE TABLE ctl_version_history(
organization_id NUMBER(10, 0) NOT NULL,
seq NUMBER(19, 0) GENERATED BY DEFAULT ON NULL AS IDENTITY,
base_schema_version VARCHAR2(30 char) NOT NULL,
customer_schema_version VARCHAR2(30 char) NOT NULL,
customer VARCHAR2(30 char),
base_schema_date TIMESTAMP(6),
customer_schema_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ctl_version_history PRIMARY KEY (organization_id, seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ctl_version_history TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('ctl_version_history');
EXEC dbms_output.put_line('--- CREATING TABLE cwo_category_service_loc --- ');
CREATE TABLE cwo_category_service_loc(
organization_id NUMBER(10, 0) NOT NULL,
category_id VARCHAR2(60 char) NOT NULL,
service_loc_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
lead_time_qty NUMBER(11, 4),
lead_time_unit_enum VARCHAR2(30 char),
create_shipment_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cwo_category_service_loc PRIMARY KEY (organization_id, category_id, service_loc_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cwo_category_service_loc TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CWO_CAT_SERVCE_LOC_ORGNODE --- ');
CREATE INDEX IDX_CWO_CAT_SERVCE_LOC_ORGNODE ON cwo_category_service_loc(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('cwo_category_service_loc');
EXEC dbms_output.put_line('--- CREATING TABLE cwo_invoice --- ');
CREATE TABLE cwo_invoice(
organization_id NUMBER(10, 0) NOT NULL,
service_loc_id VARCHAR2(60 char) NOT NULL,
invoice_number VARCHAR2(60 char) NOT NULL,
invoice_date TIMESTAMP(6),
amount_due NUMBER(17, 6),
notes VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cwo_invoice PRIMARY KEY (organization_id, service_loc_id, invoice_number) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cwo_invoice TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cwo_invoice');
EXEC dbms_output.put_line('--- CREATING TABLE cwo_invoice_gl --- ');
CREATE TABLE cwo_invoice_gl(
organization_id NUMBER(10, 0) NOT NULL,
gl_account_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
description VARCHAR2(254 char),
no_cost_with_warranty_flag NUMBER(1, 0) DEFAULT 0,
no_cost_without_warranty_flag NUMBER(1, 0) DEFAULT 0,
sort_order NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cwo_invoice_gl PRIMARY KEY (organization_id, gl_account_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cwo_invoice_gl TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CWO_INVOICE_GL_ORGNODE --- ');
CREATE INDEX IDX_CWO_INVOICE_GL_ORGNODE ON cwo_invoice_gl(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('cwo_invoice_gl');
EXEC dbms_output.put_line('--- CREATING TABLE cwo_invoice_lineitm --- ');
CREATE TABLE cwo_invoice_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
service_loc_id VARCHAR2(60 char) NOT NULL,
invoice_number VARCHAR2(60 char) NOT NULL,
invoice_lineitm_seq NUMBER(10, 0) NOT NULL,
lineitm_typcode VARCHAR2(30 char),
amt NUMBER(17, 6),
gl_account VARCHAR2(60 char),
cust_acct_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cwo_invoice_lineitm PRIMARY KEY (organization_id, service_loc_id, invoice_number, invoice_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cwo_invoice_lineitm TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cwo_invoice_lineitm');
EXEC dbms_output.put_line('--- CREATING TABLE cwo_price_code --- ');
CREATE TABLE cwo_price_code(
organization_id NUMBER(10, 0) NOT NULL,
price_code VARCHAR2(30 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
description VARCHAR2(254 char),
sort_order NUMBER(10, 0),
prompt_for_warranty_nbr_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cwo_price_code PRIMARY KEY (organization_id, price_code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cwo_price_code TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CWO_PRICE_CODE_ORGNODE --- ');
CREATE INDEX IDX_CWO_PRICE_CODE_ORGNODE ON cwo_price_code(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('cwo_price_code');
EXEC dbms_output.put_line('--- CREATING TABLE cwo_service_loc --- ');
CREATE TABLE cwo_service_loc(
organization_id NUMBER(10, 0) NOT NULL,
service_loc_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
description VARCHAR2(254 char),
party_id NUMBER(19, 0),
address_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cwo_service_loc PRIMARY KEY (organization_id, service_loc_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cwo_service_loc TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CWO_SERVICE_LOC_ORGNODE --- ');
CREATE INDEX IDX_CWO_SERVICE_LOC_ORGNODE ON cwo_service_loc(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('cwo_service_loc');
EXEC dbms_output.put_line('--- CREATING TABLE cwo_task --- ');
CREATE TABLE cwo_task(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
category_id VARCHAR2(60 char),
price_type_enum VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cwo_task PRIMARY KEY (organization_id, item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cwo_task TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE cwo_work_item --- ');
CREATE TABLE cwo_work_item(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
work_item_seq NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char),
description VARCHAR2(254 char),
value_amt NUMBER(17, 6),
warranty_number VARCHAR2(254 char),
work_item_serial_nbr VARCHAR2(254 char),
void_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cwo_work_item PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id, work_item_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cwo_work_item TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('cwo_work_item');
EXEC dbms_output.put_line('--- CREATING TABLE cwo_work_order_acct --- ');
CREATE TABLE cwo_work_order_acct(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
service_loc_id VARCHAR2(60 char) NOT NULL,
category_id VARCHAR2(60 char) NOT NULL,
total_value NUMBER(17, 6),
estimated_completion_date TIMESTAMP(6),
approved_work_amt NUMBER(17, 6),
approved_work_date TIMESTAMP(6),
priority_code VARCHAR2(30 char),
price_code VARCHAR2(30 char),
contact_method_code VARCHAR2(30 char),
last_cust_notice TIMESTAMP(6),
cost NUMBER(17, 6),
invoice_number VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cwo_work_order_acct PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cwo_work_order_acct TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE cwo_work_order_acct_journal --- ');
CREATE TABLE cwo_work_order_acct_journal(
organization_id NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
journal_seq NUMBER(19, 0) NOT NULL,
total_value NUMBER(17, 6),
estimated_completion_date TIMESTAMP(6),
approved_work_amt NUMBER(17, 6),
approved_work_date TIMESTAMP(6),
priority_code VARCHAR2(30 char),
price_code VARCHAR2(30 char),
category_id VARCHAR2(60 char),
contact_method VARCHAR2(30 char),
last_cust_notice TIMESTAMP(6),
service_loc_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cwoworkorderacctjournal PRIMARY KEY (organization_id, cust_acct_code, cust_acct_id, journal_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cwo_work_order_acct_journal TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE cwo_work_order_category --- ');
CREATE TABLE cwo_work_order_category(
organization_id NUMBER(10, 0) NOT NULL,
category_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
sort_order NUMBER(10, 0),
description VARCHAR2(254 char),
prompt_for_price_code_flag NUMBER(1, 0) DEFAULT 0,
max_item_count NUMBER(11, 4),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cwo_work_order_category PRIMARY KEY (organization_id, category_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cwo_work_order_category TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CWO_WORK_ORDER_CAT_ORGNODE --- ');
CREATE INDEX IDX_CWO_WORK_ORDER_CAT_ORGNODE ON cwo_work_order_category(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('cwo_work_order_category');
EXEC dbms_output.put_line('--- CREATING TABLE cwo_work_order_line_item --- ');
CREATE TABLE cwo_work_order_line_item(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
price_status_enum VARCHAR2(30 char),
instructions VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cwo_work_order_line_item PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cwo_work_order_line_item TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE cwo_work_order_pricing --- ');
CREATE TABLE cwo_work_order_pricing(
organization_id NUMBER(10, 0) NOT NULL,
price_code VARCHAR2(30 char) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
price NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_cwo_work_order_pricing PRIMARY KEY (organization_id, price_code, item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON cwo_work_order_pricing TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_CWOWORKORDERPRICINGORGNODE --- ');
CREATE INDEX IDX_CWOWORKORDERPRICINGORGNODE ON cwo_work_order_pricing(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('cwo_work_order_pricing');
EXEC dbms_output.put_line('--- CREATING TABLE doc_document --- ');
CREATE TABLE doc_document(
organization_id NUMBER(10, 0) NOT NULL,
document_type VARCHAR2(30 char) NOT NULL,
series_id VARCHAR2(60 char) NOT NULL,
document_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
document_status VARCHAR2(30 char),
issue_date TIMESTAMP(6),
effective_date TIMESTAMP(6),
expiration_date TIMESTAMP(6),
amount NUMBER(17, 6),
percentage NUMBER(17, 6),
max_amount NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_doc_document PRIMARY KEY (organization_id, document_type, series_id, document_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON doc_document TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_DOC_DOCUMENT_ORGNODE --- ');
CREATE INDEX IDX_DOC_DOCUMENT_ORGNODE ON doc_document(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('doc_document');
EXEC dbms_output.put_line('--- CREATING TABLE doc_document_def_properties --- ');
CREATE TABLE doc_document_def_properties(
organization_id NUMBER(10, 0) NOT NULL,
document_type VARCHAR2(30 char) NOT NULL,
series_id VARCHAR2(60 char) NOT NULL,
doc_seq_nbr NUMBER(10, 0) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
property_code VARCHAR2(30 char),
type VARCHAR2(30 char),
string_value VARCHAR2(254 char),
date_value TIMESTAMP(6),
decimal_value NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_docdocumentdefproperties PRIMARY KEY (organization_id, document_type, series_id, doc_seq_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON doc_document_def_properties TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_DOCDOCUMENTDEFPROPORGNODE --- ');
CREATE INDEX IDX_DOCDOCUMENTDEFPROPORGNODE ON doc_document_def_properties(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('doc_document_def_properties');
EXEC dbms_output.put_line('--- CREATING TABLE doc_document_definition --- ');
CREATE TABLE doc_document_definition(
organization_id NUMBER(10, 0) NOT NULL,
series_id VARCHAR2(60 char) NOT NULL,
document_type VARCHAR2(30 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
start_issue_date TIMESTAMP(6),
end_issue_date TIMESTAMP(6),
start_redeem_date TIMESTAMP(6),
end_redeem_date TIMESTAMP(6),
receipt_type VARCHAR2(30 char),
segment_type VARCHAR2(30 char),
text_code_value VARCHAR2(30 char),
file_name VARCHAR2(254 char),
vendor_id VARCHAR2(60 char),
description VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_doc_document_definition PRIMARY KEY (organization_id, series_id, document_type) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON doc_document_definition TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_DOC_DOCUMENT_DEF_ORGNODE --- ');
CREATE INDEX IDX_DOC_DOCUMENT_DEF_ORGNODE ON doc_document_definition(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('doc_document_definition');
EXEC dbms_output.put_line('--- CREATING TABLE doc_document_lineitm --- ');
CREATE TABLE doc_document_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
document_id VARCHAR2(60 char),
document_type VARCHAR2(30 char),
series_id VARCHAR2(60 char),
activity_code VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_doc_document_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON doc_document_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE dsc_coupon_xref --- ');
CREATE TABLE dsc_coupon_xref(
organization_id NUMBER(10, 0) NOT NULL,
coupon_serial_nbr VARCHAR2(254 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
discount_code VARCHAR2(60 char),
tndr_id VARCHAR2(60 char),
coupon_type VARCHAR2(60 char),
serialized_flag NUMBER(1, 0) DEFAULT 0,
effective_date TIMESTAMP(6),
expiration_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_dsc_coupon_xref PRIMARY KEY (organization_id, coupon_serial_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON dsc_coupon_xref TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_DSC_COUPON_XREF_ORGNODE --- ');
CREATE INDEX IDX_DSC_COUPON_XREF_ORGNODE ON dsc_coupon_xref(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('dsc_coupon_xref');
EXEC dbms_output.put_line('--- CREATING TABLE dsc_disc_type_eligibility --- ');
CREATE TABLE dsc_disc_type_eligibility(
organization_id NUMBER(10, 0) NOT NULL,
discount_code VARCHAR2(60 char) NOT NULL,
sale_lineitm_typcode VARCHAR2(30 char) NOT NULL,
config_element VARCHAR2(200 char) DEFAULT '*' NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_dsc_disc_type_eligibility PRIMARY KEY (organization_id, discount_code, sale_lineitm_typcode) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON dsc_disc_type_eligibility TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('dsc_disc_type_eligibility');
EXEC dbms_output.put_line('--- CREATING TABLE dsc_discount --- ');
CREATE TABLE dsc_discount(
organization_id NUMBER(10, 0) NOT NULL,
discount_code VARCHAR2(60 char) NOT NULL,
effective_datetime TIMESTAMP(6) NOT NULL,
expr_datetime TIMESTAMP(6),
typcode VARCHAR2(30 char),
app_mthd_code VARCHAR2(30 char) NOT NULL,
percentage NUMBER(6, 4),
description VARCHAR2(254 char),
calculation_mthd_code VARCHAR2(30 char) NOT NULL,
prompt VARCHAR2(254 char),
sound VARCHAR2(254 char),
max_trans_count NUMBER(10, 0),
exclusive_discount_flag NUMBER(1, 0) DEFAULT 0,
privilege_type VARCHAR2(60 char),
discount NUMBER(17, 6),
dtv_class_name VARCHAR2(254 char),
min_eligible_price NUMBER(17, 6),
serialized_discount_flag NUMBER(1, 0) DEFAULT 0,
taxability_code VARCHAR2(30 char),
max_discount NUMBER(17, 6),
sort_order NUMBER(10, 0),
disallow_change_flag NUMBER(1, 0) DEFAULT 0,
max_amount NUMBER(17, 6),
max_percentage NUMBER(17, 6),
config_element VARCHAR2(200 char) DEFAULT '*' NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_dsc_discount PRIMARY KEY (organization_id, discount_code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON dsc_discount TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('dsc_discount');
EXEC dbms_output.put_line('--- CREATING TABLE dsc_discount_compatibility --- ');
CREATE TABLE dsc_discount_compatibility(
organization_id NUMBER(10, 0) NOT NULL,
primary_discount_code VARCHAR2(60 char) NOT NULL,
compatible_discount_code VARCHAR2(60 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_dscdiscountcompatibility PRIMARY KEY (organization_id, primary_discount_code, compatible_discount_code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON dsc_discount_compatibility TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('dsc_discount_compatibility');
EXEC dbms_output.put_line('--- CREATING TABLE dsc_discount_group_mapping --- ');
CREATE TABLE dsc_discount_group_mapping(
organization_id NUMBER(10, 0) NOT NULL,
cust_group_id VARCHAR2(60 char) NOT NULL,
discount_code VARCHAR2(60 char) NOT NULL,
config_element VARCHAR2(200 char) DEFAULT '*' NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_dscdiscountgroupmapping PRIMARY KEY (organization_id, cust_group_id, discount_code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON dsc_discount_group_mapping TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('dsc_discount_group_mapping');
EXEC dbms_output.put_line('--- CREATING TABLE dsc_discount_item_exclusions --- ');
CREATE TABLE dsc_discount_item_exclusions(
organization_id NUMBER(10, 0) NOT NULL,
discount_code VARCHAR2(60 char) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_dscdiscountitemexclusions PRIMARY KEY (organization_id, discount_code, item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON dsc_discount_item_exclusions TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('dsc_discount_item_exclusions');
EXEC dbms_output.put_line('--- CREATING TABLE dsc_discount_item_inclusions --- ');
CREATE TABLE dsc_discount_item_inclusions(
organization_id NUMBER(10, 0) NOT NULL,
discount_code VARCHAR2(60 char) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_dscdiscountiteminclusions PRIMARY KEY (organization_id, discount_code, item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON dsc_discount_item_inclusions TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('dsc_discount_item_inclusions');
EXEC dbms_output.put_line('--- CREATING TABLE egt_room --- ');
CREATE TABLE egt_room(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
room_lineitm_seq NUMBER(10, 0) NOT NULL,
room_id VARCHAR2(254 char),
assign_datetime TIMESTAMP(6),
release_datetime TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_egt_room PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, room_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON egt_room TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE egt_trans --- ');
CREATE TABLE egt_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
cust_party_id NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_egt_trans PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON egt_trans TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE egt_trans_lineitm --- ');
CREATE TABLE egt_trans_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
item_id_entry_mthd_code VARCHAR2(30 char),
item_id VARCHAR2(60 char),
unit_price NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_egt_trans_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON egt_trans_lineitm TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('egt_trans_lineitm');
EXEC dbms_output.put_line('--- CREATING TABLE hrs_employee --- ');
CREATE TABLE hrs_employee(
organization_id NUMBER(10, 0) NOT NULL,
employee_id VARCHAR2(60 char) NOT NULL,
party_id NUMBER(19, 0),
login_id VARCHAR2(60 char),
sick_days_used NUMBER(11, 2),
hire_date TIMESTAMP(6),
active_date TIMESTAMP(6),
terminated_date TIMESTAMP(6),
job_title VARCHAR2(254 char),
base_pay NUMBER(17, 6),
add_date TIMESTAMP(6),
marital_status VARCHAR2(30 char),
spouse_name VARCHAR2(254 char),
emergency_contact_name VARCHAR2(254 char),
emergency_contact_phone VARCHAR2(32 char),
last_review_date TIMESTAMP(6),
next_review_date TIMESTAMP(6),
additional_withholdings NUMBER(17, 6),
vacation_days NUMBER(11, 2),
vacation_days_used NUMBER(11, 2),
sick_days NUMBER(11, 2),
personal_days NUMBER(11, 2),
personal_days_used NUMBER(11, 2),
clock_in_not_req_flag NUMBER(1, 0) DEFAULT 0,
employee_pay_status VARCHAR2(30 char),
employee_role_code VARCHAR2(30 char),
employee_statcode VARCHAR2(30 char),
clocked_in_flag NUMBER(1, 0) DEFAULT 0,
work_code VARCHAR2(30 char),
group_membership CLOB,
primary_group VARCHAR2(60 char),
department_id VARCHAR2(60 char),
employee_typcode VARCHAR2(30 char),
training_status_enum VARCHAR2(30 char),
locked_out_flag NUMBER(1, 0) DEFAULT 0,
locked_out_timestamp TIMESTAMP(6),
overtime_eligible_flag NUMBER(1, 0) DEFAULT 0,
employee_group_id VARCHAR2(60 char),
employee_work_status VARCHAR2(30 char),
keyed_offline_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_hrs_employee PRIMARY KEY (organization_id, employee_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON hrs_employee TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_HRS_EMPLOYEE_PARTYID --- ');
CREATE INDEX XST_HRS_EMPLOYEE_PARTYID ON hrs_employee(party_id, organization_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('hrs_employee');
EXEC dbms_output.put_line('--- CREATING TABLE hrs_employee_answers --- ');
CREATE TABLE hrs_employee_answers(
organization_id NUMBER(10, 0) NOT NULL,
employee_id VARCHAR2(60 char) NOT NULL,
challenge_code VARCHAR2(60 char) NOT NULL,
challenge_answer VARCHAR2(4000 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_hrs_employee_answers PRIMARY KEY (organization_id, employee_id, challenge_code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON hrs_employee_answers TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('hrs_employee_answers');
EXEC dbms_output.put_line('--- CREATING TABLE hrs_employee_fingerprint --- ');
CREATE TABLE hrs_employee_fingerprint(
organization_id NUMBER(10, 0) NOT NULL,
employee_id VARCHAR2(60 char) NOT NULL,
fingerprint_seq NUMBER(10, 0) NOT NULL,
fingerprint_storage CLOB,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_hrs_employee_fingerprint PRIMARY KEY (organization_id, employee_id, fingerprint_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON hrs_employee_fingerprint TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('hrs_employee_fingerprint');
EXEC dbms_output.put_line('--- CREATING TABLE hrs_employee_message --- ');
CREATE TABLE hrs_employee_message(
organization_id NUMBER(10, 0) NOT NULL,
message_id NUMBER(19, 0) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
start_date TIMESTAMP(6),
end_date TIMESTAMP(6),
priority VARCHAR2(20 char),
content CLOB,
store_created_flag NUMBER(1, 0) DEFAULT 0,
wkstn_specific_flag NUMBER(1, 0) DEFAULT 0,
wkstn_id NUMBER(19, 0),
void_flag NUMBER(1, 0) DEFAULT 0,
message_url VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_hrs_employee_message PRIMARY KEY (organization_id, message_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON hrs_employee_message TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_HRS_EMPLOYEE_MSG_ORGNODE --- ');
CREATE INDEX IDX_HRS_EMPLOYEE_MSG_ORGNODE ON hrs_employee_message(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('hrs_employee_message');
EXEC dbms_output.put_line('--- CREATING TABLE hrs_employee_notes --- ');
CREATE TABLE hrs_employee_notes(
organization_id NUMBER(10, 0) NOT NULL,
employee_id VARCHAR2(60 char) NOT NULL,
note_seq NUMBER(19, 0) NOT NULL,
note CLOB,
creator_party_id NUMBER(19, 0),
note_timestamp TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_hrs_employee_notes PRIMARY KEY (organization_id, employee_id, note_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON hrs_employee_notes TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('hrs_employee_notes');
EXEC dbms_output.put_line('--- CREATING TABLE hrs_employee_password --- ');
CREATE TABLE hrs_employee_password(
organization_id NUMBER(10, 0) NOT NULL,
employee_id VARCHAR2(60 char) NOT NULL,
password_seq NUMBER(19, 0) DEFAULT 0 NOT NULL,
password VARCHAR2(254 char),
effective_date TIMESTAMP(6) NOT NULL,
temp_password_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
current_password_flag NUMBER(1, 0) DEFAULT 1 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_hrs_employee_password PRIMARY KEY (organization_id, employee_id, password_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON hrs_employee_password TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('hrs_employee_password');
EXEC dbms_output.put_line('--- CREATING TABLE hrs_employee_store --- ');
CREATE TABLE hrs_employee_store(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
employee_id VARCHAR2(60 char) NOT NULL,
employee_store_seq NUMBER(10, 0) NOT NULL,
begin_date TIMESTAMP(6),
end_date TIMESTAMP(6),
temp_assignment_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_hrs_employee_store PRIMARY KEY (organization_id, rtl_loc_id, employee_id, employee_store_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON hrs_employee_store TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('hrs_employee_store');
EXEC dbms_output.put_line('--- CREATING TABLE hrs_employee_task --- ');
CREATE TABLE hrs_employee_task(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
task_id NUMBER(19, 0) NOT NULL,
start_date TIMESTAMP(6),
end_date TIMESTAMP(6),
complete_date TIMESTAMP(6),
typcode VARCHAR2(60 char),
visibility VARCHAR2(30 char),
assignment_id VARCHAR2(60 char),
store_created_flag NUMBER(1, 0) DEFAULT 0,
title VARCHAR2(255 char),
description CLOB,
priority VARCHAR2(20 char),
status_code VARCHAR2(30 char),
void_flag NUMBER(1, 0) DEFAULT 0,
party_id NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_hrs_employee_task PRIMARY KEY (organization_id, rtl_loc_id, task_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON hrs_employee_task TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('hrs_employee_task');
EXEC dbms_output.put_line('--- CREATING TABLE hrs_employee_task_notes --- ');
CREATE TABLE hrs_employee_task_notes(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
task_id NUMBER(19, 0) NOT NULL,
note_seq NUMBER(19, 0) NOT NULL,
note CLOB,
creator_party_id NUMBER(19, 0),
note_timestamp TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_hrs_employee_task_notes PRIMARY KEY (organization_id, rtl_loc_id, task_id, note_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON hrs_employee_task_notes TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('hrs_employee_task_notes');
EXEC dbms_output.put_line('--- CREATING TABLE hrs_work_codes --- ');
CREATE TABLE hrs_work_codes(
organization_id NUMBER(10, 0) NOT NULL,
work_code VARCHAR2(30 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
description VARCHAR2(254 char),
sort_order NUMBER(10, 0),
privilege VARCHAR2(60 char),
selling_flag NUMBER(1, 0) DEFAULT 0,
payroll_category VARCHAR2(30 char),
min_clock_in_duration NUMBER(10, 0),
min_clock_out_duration NUMBER(10, 0),
hidden_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_hrs_work_codes PRIMARY KEY (organization_id, work_code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON hrs_work_codes TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_HRS_WORK_CODES_ORGNODE --- ');
CREATE INDEX IDX_HRS_WORK_CODES_ORGNODE ON hrs_work_codes(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('hrs_work_codes');
EXEC dbms_output.put_line('--- CREATING TABLE inv_bucket --- ');
CREATE TABLE inv_bucket(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
bucket_id VARCHAR2(60 char) NOT NULL,
name VARCHAR2(254 char),
function_code VARCHAR2(30 char),
adjustment_action VARCHAR2(30 char),
default_location_id VARCHAR2(60 char),
system_bucket_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_bucket PRIMARY KEY (organization_id, rtl_loc_id, bucket_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_bucket TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_bucket');
EXEC dbms_output.put_line('--- CREATING TABLE inv_carton --- ');
CREATE TABLE inv_carton(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
document_typcode VARCHAR2(30 char) NOT NULL,
invctl_document_id VARCHAR2(60 char) NOT NULL,
carton_id VARCHAR2(60 char) NOT NULL,
carton_statcode VARCHAR2(30 char),
record_creation_type VARCHAR2(30 char),
control_number VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_carton PRIMARY KEY (organization_id, rtl_loc_id, document_typcode, invctl_document_id, carton_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_carton TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_carton');
EXEC dbms_output.put_line('--- CREATING TABLE inv_count --- ');
CREATE TABLE inv_count(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
inv_count_id VARCHAR2(60 char) NOT NULL,
inv_location_id VARCHAR2(60 char),
inv_count_typcode VARCHAR2(60 char) NOT NULL,
begin_date TIMESTAMP(6),
end_date TIMESTAMP(6),
count_status VARCHAR2(60 char),
store_created_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
void_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
description VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_count PRIMARY KEY (organization_id, rtl_loc_id, inv_count_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_count TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_count');
EXEC dbms_output.put_line('--- CREATING TABLE inv_count_bucket --- ');
CREATE TABLE inv_count_bucket(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
inv_count_id VARCHAR2(60 char) NOT NULL,
inv_bucket_id VARCHAR2(60 char) NOT NULL,
count_cycle NUMBER(10, 0),
bucket_status VARCHAR2(60 char),
inv_bucket_name VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_count_bucket PRIMARY KEY (organization_id, rtl_loc_id, inv_count_id, inv_bucket_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_count_bucket TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_count_bucket');
EXEC dbms_output.put_line('--- CREATING TABLE inv_count_mismatch --- ');
CREATE TABLE inv_count_mismatch(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
inv_count_id VARCHAR2(60 char) NOT NULL,
count_sheet_nbr NUMBER(10, 0) NOT NULL,
inv_location_id VARCHAR2(60 char) NOT NULL,
inv_bucket_id VARCHAR2(60 char) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
snapshot_date TIMESTAMP(6),
stock_qty NUMBER(14, 4),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_count_mismatch PRIMARY KEY (organization_id, rtl_loc_id, inv_count_id, count_sheet_nbr, inv_location_id, inv_bucket_id, item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_count_mismatch TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE inv_count_section --- ');
CREATE TABLE inv_count_section(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
inv_location_id VARCHAR2(60 char) NOT NULL,
inv_bucket_id VARCHAR2(60 char) NOT NULL,
section_id VARCHAR2(60 char) NOT NULL,
sort_order NUMBER(10, 0),
inv_bucket_name VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_count_section PRIMARY KEY (organization_id, rtl_loc_id, inv_location_id, inv_bucket_id, section_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_count_section TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_count_section');
EXEC dbms_output.put_line('--- CREATING TABLE inv_count_section_detail --- ');
CREATE TABLE inv_count_section_detail(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
inv_location_id VARCHAR2(60 char) NOT NULL,
inv_bucket_id VARCHAR2(60 char) NOT NULL,
section_id VARCHAR2(60 char) NOT NULL,
section_detail_nbr NUMBER(10, 0) NOT NULL,
merch_hierarchy_level VARCHAR2(60 char),
merch_hierarchy_id VARCHAR2(60 char),
description VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_count_section_detail PRIMARY KEY (organization_id, rtl_loc_id, inv_location_id, inv_bucket_id, section_id, section_detail_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_count_section_detail TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_count_section_detail');
EXEC dbms_output.put_line('--- CREATING TABLE inv_count_sheet --- ');
CREATE TABLE inv_count_sheet(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
inv_count_id VARCHAR2(60 char) NOT NULL,
count_sheet_nbr NUMBER(10, 0) NOT NULL,
inv_bucket_id VARCHAR2(60 char),
section_nbr NUMBER(10, 0),
section_id VARCHAR2(60 char),
count_cycle NUMBER(10, 0),
sheet_status VARCHAR2(60 char),
checked_out_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
inv_bucket_name VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_count_sheet PRIMARY KEY (organization_id, rtl_loc_id, inv_count_id, count_sheet_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_count_sheet TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_count_sheet');
EXEC dbms_output.put_line('--- CREATING TABLE inv_count_sheet_lineitm --- ');
CREATE TABLE inv_count_sheet_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
inv_count_id VARCHAR2(60 char) NOT NULL,
count_sheet_nbr NUMBER(10, 0) NOT NULL,
lineitm_nbr NUMBER(10, 0) NOT NULL,
inv_bucket_id VARCHAR2(60 char),
page_nbr NUMBER(10, 0),
item_id VARCHAR2(60 char),
alternate_id VARCHAR2(60 char),
description VARCHAR2(200 char),
quantity NUMBER(14, 4),
count_cycle NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_count_sheet_lineitm PRIMARY KEY (organization_id, rtl_loc_id, inv_count_id, count_sheet_nbr, lineitm_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_count_sheet_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_INV_COUNT_SHEET_LINEITM01 --- ');
CREATE INDEX IDX_INV_COUNT_SHEET_LINEITM01 ON inv_count_sheet_lineitm(inv_count_id, UPPER(inv_bucket_id), UPPER(item_id), UPPER(alternate_id), UPPER(description))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('inv_count_sheet_lineitm');
EXEC dbms_output.put_line('--- CREATING TABLE inv_count_snapshot --- ');
CREATE TABLE inv_count_snapshot(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
inv_count_id VARCHAR2(60 char) NOT NULL,
inv_location_id VARCHAR2(60 char) NOT NULL,
inv_bucket_id VARCHAR2(60 char) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
snapshot_date TIMESTAMP(6),
quantity NUMBER(14, 4),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_count_snapshot PRIMARY KEY (organization_id, rtl_loc_id, inv_count_id, inv_location_id, inv_bucket_id, item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_count_snapshot TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_count_snapshot');
EXEC dbms_output.put_line('--- CREATING TABLE inv_cst_item_yearend --- ');
CREATE TABLE inv_cst_item_yearend(
organization_id NUMBER(10, 0) NOT NULL,
fiscal_year NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
wac_qty_rcvd NUMBER(14, 4),
wac_value_rcvd NUMBER(17, 6),
pwac_qty_onhand_endofyear NUMBER(14, 4),
pwac_value_onhand_endofyear NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_cst_item_yearend PRIMARY KEY (organization_id, fiscal_year, rtl_loc_id, item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_cst_item_yearend TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_INV_CST_ITEM_YEAREND_01 --- ');
CREATE INDEX IDX_INV_CST_ITEM_YEAREND_01 ON inv_cst_item_yearend(fiscal_year)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_INV_CST_ITEM_YEAREND_02 --- ');
CREATE INDEX IDX_INV_CST_ITEM_YEAREND_02 ON inv_cst_item_yearend(rtl_loc_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('inv_cst_item_yearend');
EXEC dbms_output.put_line('--- CREATING TABLE inv_document_lineitm_note --- ');
CREATE TABLE inv_document_lineitm_note(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
document_typcode VARCHAR2(30 char) NOT NULL,
invctl_document_id VARCHAR2(60 char) NOT NULL,
invctl_document_line_nbr NUMBER(10, 0) NOT NULL,
note_id NUMBER(19, 0) NOT NULL,
note_timestamp TIMESTAMP(6),
note_type VARCHAR2(60 char),
note_text CLOB,
record_creation_type VARCHAR2(60 char),
creator_party_id NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_document_lineitm_note PRIMARY KEY (organization_id, rtl_loc_id, document_typcode, invctl_document_id, invctl_document_line_nbr, note_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_document_lineitm_note TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_document_lineitm_note');
EXEC dbms_output.put_line('--- CREATING TABLE inv_document_notes --- ');
CREATE TABLE inv_document_notes(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
document_typcode VARCHAR2(30 char) NOT NULL,
invctl_document_id VARCHAR2(60 char) NOT NULL,
note_id NUMBER(19, 0) NOT NULL,
note_timestamp TIMESTAMP(6),
note_text CLOB,
creator_party_id NUMBER(19, 0),
note_type VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_document_notes PRIMARY KEY (organization_id, rtl_loc_id, document_typcode, invctl_document_id, note_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_document_notes TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_document_notes');
EXEC dbms_output.put_line('--- CREATING TABLE inv_invctl_doc_lineserial --- ');
CREATE TABLE inv_invctl_doc_lineserial(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
document_typcode VARCHAR2(30 char) NOT NULL,
invctl_document_id VARCHAR2(60 char) NOT NULL,
invctl_document_line_nbr NUMBER(10, 0) NOT NULL,
serial_line_nbr NUMBER(10, 0) NOT NULL,
serial_nbr VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_invctl_doc_lineserial PRIMARY KEY (organization_id, rtl_loc_id, document_typcode, invctl_document_id, invctl_document_line_nbr, serial_line_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_invctl_doc_lineserial TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_invctl_doc_lineserial');
EXEC dbms_output.put_line('--- CREATING TABLE inv_invctl_document --- ');
CREATE TABLE inv_invctl_document(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
document_typcode VARCHAR2(30 char) NOT NULL,
invctl_document_id VARCHAR2(60 char) NOT NULL,
create_date_timestamp TIMESTAMP(6),
complete_date_timestamp TIMESTAMP(6),
status_code VARCHAR2(30 char),
originator_id VARCHAR2(60 char),
document_subtypcode VARCHAR2(30 char),
originator_name VARCHAR2(254 char),
last_activity_date TIMESTAMP(6),
po_ref_nbr VARCHAR2(254 char),
record_creation_type VARCHAR2(30 char),
description VARCHAR2(254 char),
control_number VARCHAR2(254 char),
originator_address_id VARCHAR2(60 char),
submit_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_invctl_document PRIMARY KEY (organization_id, rtl_loc_id, document_typcode, invctl_document_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_invctl_document TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_invctl_document');
EXEC dbms_output.put_line('--- CREATING TABLE inv_invctl_document_lineitm --- ');
CREATE TABLE inv_invctl_document_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
invctl_document_id VARCHAR2(60 char) NOT NULL,
document_typcode VARCHAR2(30 char) NOT NULL,
invctl_document_line_nbr NUMBER(10, 0) NOT NULL,
carton_id VARCHAR2(60 char),
inventory_item_id VARCHAR2(60 char),
lineitm_typcode VARCHAR2(30 char),
unit_count NUMBER(14, 4),
lineitm_rtl_loc_id NUMBER(10, 0),
lineitm_wkstn_id NUMBER(19, 0),
lineitm_business_date TIMESTAMP(6),
lineitm_trans_seq NUMBER(19, 0),
lineitm_rtrans_lineitm_seq NUMBER(10, 0),
status_code VARCHAR2(30 char),
original_loc_id VARCHAR2(60 char),
original_bucket_id VARCHAR2(60 char),
expected_count NUMBER(14, 4),
posted_count NUMBER(14, 4),
record_creation_type VARCHAR2(30 char),
entered_item_id VARCHAR2(60 char),
entered_item_description VARCHAR2(254 char),
serial_number VARCHAR2(254 char),
retail NUMBER(17, 6),
model_nbr VARCHAR2(254 char),
control_number VARCHAR2(254 char),
shipping_weight NUMBER(12, 3),
unit_cost NUMBER(17, 6),
posted_cost NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_invinvctldocumentlineitm PRIMARY KEY (organization_id, rtl_loc_id, invctl_document_id, document_typcode, invctl_document_line_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_invctl_document_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_INV_INVCTL_DOC_LINEITM01 --- ');
CREATE INDEX IDX_INV_INVCTL_DOC_LINEITM01 ON inv_invctl_document_lineitm(organization_id, lineitm_rtl_loc_id, lineitm_business_date, lineitm_wkstn_id, lineitm_trans_seq, lineitm_rtrans_lineitm_seq)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('inv_invctl_document_lineitm');
EXEC dbms_output.put_line('--- CREATING TABLE inv_invctl_document_xref --- ');
CREATE TABLE inv_invctl_document_xref(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
invctl_document_id VARCHAR2(60 char) NOT NULL,
document_typcode VARCHAR2(30 char) NOT NULL,
invctl_document_line_nbr NUMBER(10, 0) NOT NULL,
cross_ref_organization_id NUMBER(10, 0),
cross_ref_document_id VARCHAR2(60 char),
cross_ref_line_number NUMBER(10, 0),
cross_ref_document_typcode VARCHAR2(30 char),
cross_ref_rtl_loc_id NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_invctl_document_xref PRIMARY KEY (organization_id, rtl_loc_id, invctl_document_id, document_typcode, invctl_document_line_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_invctl_document_xref TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_invctl_document_xref');
EXEC dbms_output.put_line('--- CREATING TABLE inv_invctl_trans --- ');
CREATE TABLE inv_invctl_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
document_typcode VARCHAR2(30 char),
document_date TIMESTAMP(6),
old_status_code VARCHAR2(30 char),
new_status_code VARCHAR2(30 char),
invctl_document_id VARCHAR2(60 char),
invctl_document_rtl_loc_id NUMBER(10, 0),
invctl_trans_reascode VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_invctl_trans PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_invctl_trans TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE inv_invctl_trans_detail --- ');
CREATE TABLE inv_invctl_trans_detail(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
invctl_trans_seq NUMBER(19, 0) NOT NULL,
invctl_document_rtl_loc_id NUMBER(10, 0),
invctl_document_id VARCHAR2(60 char),
document_typcode VARCHAR2(30 char),
invctl_document_line_nbr NUMBER(10, 0),
item_id VARCHAR2(60 char),
action_code VARCHAR2(30 char),
previous_unit_count NUMBER(14, 4),
new_unit_count NUMBER(14, 4),
old_status_code VARCHAR2(30 char),
new_status_code VARCHAR2(30 char),
previous_posted_count NUMBER(14, 4),
new_posted_count NUMBER(14, 4),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_invctl_trans_detail PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, invctl_trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_invctl_trans_detail TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_invctl_trans_detail');
EXEC dbms_output.put_line('--- CREATING TABLE inv_inventory_journal --- ');
CREATE TABLE inv_inventory_journal(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
trans_lineitm_seq NUMBER(10, 0) NOT NULL,
journal_seq NUMBER(19, 0) NOT NULL,
inventory_item_id VARCHAR2(60 char),
item_serial_nbr VARCHAR2(254 char),
action_code VARCHAR2(30 char),
quantity NUMBER(11, 4),
source_location_id VARCHAR2(60 char),
source_bucket_id VARCHAR2(60 char),
dest_location_id VARCHAR2(60 char),
dest_bucket_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_inventory_journal PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, trans_lineitm_seq, journal_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_inventory_journal TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_inventory_journal');
EXEC dbms_output.put_line('--- CREATING TABLE inv_inventory_loc_mod --- ');
CREATE TABLE inv_inventory_loc_mod(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
document_typcode VARCHAR2(30 char) NOT NULL,
document_id VARCHAR2(60 char) NOT NULL,
document_line_nbr NUMBER(10, 0) NOT NULL,
mod_seq NUMBER(10, 0) NOT NULL,
serial_nbr VARCHAR2(254 char),
source_location_id VARCHAR2(60 char),
source_bucket_id VARCHAR2(60 char),
dest_location_id VARCHAR2(60 char),
dest_bucket_id VARCHAR2(60 char),
quantity NUMBER(11, 4),
action_code VARCHAR2(30 char),
item_id VARCHAR2(60 char),
cost NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_inventory_loc_mod PRIMARY KEY (organization_id, rtl_loc_id, document_typcode, document_id, document_line_nbr, mod_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_inventory_loc_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_inventory_loc_mod');
EXEC dbms_output.put_line('--- CREATING TABLE inv_item_acct_mod --- ');
CREATE TABLE inv_item_acct_mod(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
document_typcode VARCHAR2(30 char) NOT NULL,
invctl_document_id VARCHAR2(60 char) NOT NULL,
invctl_document_line_nbr NUMBER(10, 0) NOT NULL,
cust_acct_code VARCHAR2(30 char) NOT NULL,
cust_acct_id VARCHAR2(60 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_item_acct_mod PRIMARY KEY (organization_id, rtl_loc_id, document_typcode, invctl_document_id, invctl_document_line_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_item_acct_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_item_acct_mod');
EXEC dbms_output.put_line('--- CREATING TABLE inv_location --- ');
CREATE TABLE inv_location(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
inv_location_id VARCHAR2(60 char) NOT NULL,
name VARCHAR2(254 char),
active_flag NUMBER(1, 0) DEFAULT 0,
system_location_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_location PRIMARY KEY (organization_id, rtl_loc_id, inv_location_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_location TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_location');
EXEC dbms_output.put_line('--- CREATING TABLE inv_location_availability --- ');
CREATE TABLE inv_location_availability(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
location_id VARCHAR2(60 char) NOT NULL,
availability_code VARCHAR2(30 char) NOT NULL,
privilege_type VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_location_availability PRIMARY KEY (organization_id, rtl_loc_id, location_id, availability_code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_location_availability TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_location_availability');
EXEC dbms_output.put_line('--- CREATING TABLE inv_location_bucket --- ');
CREATE TABLE inv_location_bucket(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
location_id VARCHAR2(60 char) NOT NULL,
bucket_id VARCHAR2(60 char) NOT NULL,
tracking_method VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_location_bucket PRIMARY KEY (organization_id, rtl_loc_id, location_id, bucket_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_location_bucket TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_location_bucket');
EXEC dbms_output.put_line('--- CREATING TABLE inv_movement_pending --- ');
CREATE TABLE inv_movement_pending(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
trans_lineitm_seq NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char),
serial_nbr VARCHAR2(254 char),
action_code VARCHAR2(30 char),
quantity NUMBER(11, 4),
reconciled_flag NUMBER(1, 0) DEFAULT 0,
void_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_movement_pending PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, trans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_movement_pending TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_movement_pending');
EXEC dbms_output.put_line('--- CREATING TABLE inv_movement_pending_detail --- ');
CREATE TABLE inv_movement_pending_detail(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
trans_lineitm_seq NUMBER(10, 0) NOT NULL,
pending_seq NUMBER(10, 0) NOT NULL,
serial_nbr VARCHAR2(254 char),
quantity NUMBER(11, 4),
source_location_id VARCHAR2(60 char),
source_bucket_id VARCHAR2(60 char),
dest_location_id VARCHAR2(60 char),
dest_bucket_id VARCHAR2(60 char),
action_code VARCHAR2(30 char),
void_flag NUMBER(1, 0) DEFAULT 0,
item_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_invmovementpendingdetail PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, trans_lineitm_seq, pending_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_movement_pending_detail TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_movement_pending_detail');
EXEC dbms_output.put_line('--- CREATING TABLE inv_mptrans_lineitm --- ');
CREATE TABLE inv_mptrans_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
trans_lineitm_seq NUMBER(10, 0) NOT NULL,
original_rtl_loc_id NUMBER(10, 0),
original_wkstn_id NUMBER(19, 0),
original_business_date TIMESTAMP(6),
original_trans_seq NUMBER(19, 0),
original_trans_lineitm_seq NUMBER(10, 0),
quantity_reconciled NUMBER(11, 4),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_mptrans_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, trans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_mptrans_lineitm TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_mptrans_lineitm');
EXEC dbms_output.put_line('--- CREATING TABLE inv_rep_document_lineitm --- ');
CREATE TABLE inv_rep_document_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
invctl_document_id VARCHAR2(60 char) NOT NULL,
document_typcode VARCHAR2(30 char) NOT NULL,
invctl_document_line_nbr NUMBER(10, 0) NOT NULL,
suggested_order_qty NUMBER(11, 4),
order_quantity NUMBER(11, 4),
confirmed_quantity NUMBER(11, 4),
confirmation_date TIMESTAMP(6),
confirmation_number VARCHAR2(60 char),
ship_via VARCHAR2(254 char),
shipped_quantity NUMBER(11, 4),
shipped_date TIMESTAMP(6),
received_quantity NUMBER(11, 4),
received_date TIMESTAMP(6),
source_type VARCHAR2(60 char),
source_id VARCHAR2(60 char),
source_name VARCHAR2(254 char),
parent_document_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_rep_document_lineitm PRIMARY KEY (organization_id, rtl_loc_id, invctl_document_id, document_typcode, invctl_document_line_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_rep_document_lineitm TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_rep_document_lineitm');
EXEC dbms_output.put_line('--- CREATING TABLE inv_serialized_stock_ledger --- ');
CREATE TABLE inv_serialized_stock_ledger(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
inv_location_id VARCHAR2(60 char) NOT NULL,
bucket_id VARCHAR2(60 char) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
serial_nbr VARCHAR2(200 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_invserializedstockledger PRIMARY KEY (organization_id, rtl_loc_id, inv_location_id, bucket_id, item_id, serial_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_serialized_stock_ledger TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_serialized_stock_ledger');
EXEC dbms_output.put_line('--- CREATING TABLE inv_shipment --- ');
CREATE TABLE inv_shipment(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
document_typcode VARCHAR2(30 char) NOT NULL,
invctl_document_id VARCHAR2(60 char) NOT NULL,
shipment_seq NUMBER(10, 0) NOT NULL,
expected_delivery_date TIMESTAMP(6),
actual_delivery_date TIMESTAMP(6),
expected_ship_date TIMESTAMP(6),
destination_party_id NUMBER(19, 0),
shipping_carrier VARCHAR2(254 char),
actual_ship_date TIMESTAMP(6),
tracking_nbr VARCHAR2(254 char),
shipment_statcode VARCHAR2(30 char),
record_creation_type VARCHAR2(30 char),
destination_rtl_loc_id NUMBER(10, 0),
destination_name VARCHAR2(254 char),
shipping_method VARCHAR2(254 char),
shipping_label VARCHAR2(4000 char),
destination_type VARCHAR2(30 char),
destination_service_loc_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_shipment PRIMARY KEY (organization_id, rtl_loc_id, document_typcode, invctl_document_id, shipment_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_shipment TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_shipment');
EXEC dbms_output.put_line('--- CREATING TABLE inv_shipment_address --- ');
CREATE TABLE inv_shipment_address(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
document_typcode VARCHAR2(30 char) NOT NULL,
invctl_document_id VARCHAR2(60 char) NOT NULL,
shipment_seq NUMBER(10, 0) NOT NULL,
address1 VARCHAR2(254 char),
address2 VARCHAR2(254 char),
address3 VARCHAR2(254 char),
address4 VARCHAR2(254 char),
apartment VARCHAR2(30 char),
city VARCHAR2(254 char),
state VARCHAR2(30 char),
postal_code VARCHAR2(30 char),
country VARCHAR2(2 char),
neighborhood VARCHAR2(254 char),
county VARCHAR2(254 char),
telephone1 VARCHAR2(32 char),
telephone2 VARCHAR2(32 char),
telephone3 VARCHAR2(32 char),
telephone4 VARCHAR2(32 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_shipment_address PRIMARY KEY (organization_id, rtl_loc_id, document_typcode, invctl_document_id, shipment_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_shipment_address TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_shipment_address');
EXEC dbms_output.put_line('--- CREATING TABLE inv_shipment_lines --- ');
CREATE TABLE inv_shipment_lines(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
document_typcode VARCHAR2(30 char) NOT NULL,
invctl_document_id VARCHAR2(60 char) NOT NULL,
shipment_seq NUMBER(10, 0) NOT NULL,
lineitm_seq NUMBER(10, 0) NOT NULL,
invctl_document_line_nbr NUMBER(10, 0) NOT NULL,
ship_qty NUMBER(11, 4),
carton_id VARCHAR2(60 char),
status_code VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_shipment_lines PRIMARY KEY (organization_id, rtl_loc_id, document_typcode, invctl_document_id, shipment_seq, lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_shipment_lines TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_shipment_lines');
EXEC dbms_output.put_line('--- CREATING TABLE inv_shipper --- ');
CREATE TABLE inv_shipper(
organization_id NUMBER(10, 0) NOT NULL,
shipper_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
shipper_desc VARCHAR2(254 char),
display_order NUMBER(10, 0),
tracking_number_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_shipper PRIMARY KEY (organization_id, shipper_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_shipper TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_INV_SHIPPER_ORGNODE --- ');
CREATE INDEX IDX_INV_SHIPPER_ORGNODE ON inv_shipper(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('inv_shipper');
EXEC dbms_output.put_line('--- CREATING TABLE inv_shipper_method --- ');
CREATE TABLE inv_shipper_method(
organization_id NUMBER(10, 0) NOT NULL,
shipper_method_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
shipper_method_desc VARCHAR2(254 char),
shipper_id VARCHAR2(60 char),
domestic_service_code VARCHAR2(60 char),
intl_service_code VARCHAR2(60 char),
display_order NUMBER(10, 0),
priority NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_shipper_method PRIMARY KEY (organization_id, shipper_method_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_shipper_method TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_INV_SHIPPER_METHOD_ORGNODE --- ');
CREATE INDEX IDX_INV_SHIPPER_METHOD_ORGNODE ON inv_shipper_method(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('inv_shipper_method');
EXEC dbms_output.put_line('--- CREATING TABLE inv_stock_fiscal_year --- ');
CREATE TABLE inv_stock_fiscal_year(
organization_id NUMBER(10, 0) NOT NULL,
fiscal_year NUMBER(10, 0) NOT NULL,
start_date TIMESTAMP(6),
end_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_stock_fiscal_year PRIMARY KEY (organization_id, fiscal_year) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_stock_fiscal_year TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_stock_fiscal_year');
EXEC dbms_output.put_line('--- CREATING TABLE inv_stock_ledger_acct --- ');
CREATE TABLE inv_stock_ledger_acct(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
inv_location_id VARCHAR2(60 char) NOT NULL,
bucket_id VARCHAR2(60 char) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
unitcount NUMBER(14, 4),
inventory_value NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_stock_ledger_acct PRIMARY KEY (organization_id, rtl_loc_id, inv_location_id, bucket_id, item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_stock_ledger_acct TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_INV_STOCK_LEDGER_ACCT01 --- ');
CREATE INDEX IDX_INV_STOCK_LEDGER_ACCT01 ON inv_stock_ledger_acct(organization_id, bucket_id, item_id, rtl_loc_id, unitcount)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('inv_stock_ledger_acct');
EXEC dbms_output.put_line('--- CREATING TABLE inv_sum_count_trans_dtl --- ');
CREATE TABLE inv_sum_count_trans_dtl(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
trans_line_seq NUMBER(10, 0) NOT NULL,
location_id VARCHAR2(60 char),
bucket_id VARCHAR2(60 char),
system_count NUMBER(14, 4),
declared_count NUMBER(14, 4),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_sum_count_trans_dtl PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, trans_line_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_sum_count_trans_dtl TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_sum_count_trans_dtl');
EXEC dbms_output.put_line('--- CREATING TABLE inv_valid_destinations --- ');
CREATE TABLE inv_valid_destinations(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
document_typcode VARCHAR2(30 char) NOT NULL,
document_subtypcode VARCHAR2(30 char) NOT NULL,
destination_type_enum VARCHAR2(30 char) NOT NULL,
destination_id VARCHAR2(60 char) NOT NULL,
description VARCHAR2(254 char),
sort_order NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_inv_valid_destinations PRIMARY KEY (organization_id, rtl_loc_id, document_typcode, document_subtypcode, destination_type_enum, destination_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON inv_valid_destinations TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('inv_valid_destinations');
EXEC dbms_output.put_line('--- CREATING TABLE itm_attached_items --- ');
CREATE TABLE itm_attached_items(
organization_id NUMBER(10, 0) NOT NULL,
sold_item_id VARCHAR2(60 char) NOT NULL,
attached_item_id VARCHAR2(60 char) NOT NULL,
level_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
level_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
begin_datetime TIMESTAMP(6),
end_datetime TIMESTAMP(6),
prompt_to_add_flag NUMBER(1, 0) DEFAULT 0,
prompt_to_add_msg_key VARCHAR2(254 char),
quantity_to_add NUMBER(11, 4),
lineitm_assoc_typcode VARCHAR2(30 char),
prompt_for_return_flag NUMBER(1, 0) DEFAULT 0,
prompt_for_return_msg_key VARCHAR2(254 char),
external_id VARCHAR2(60 char),
external_system VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_attached_items PRIMARY KEY (organization_id, sold_item_id, attached_item_id, level_code, level_value) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_attached_items TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('itm_attached_items');
EXEC dbms_output.put_line('--- CREATING TABLE itm_item --- ');
CREATE TABLE itm_item(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
name VARCHAR2(254 char),
description VARCHAR2(254 char),
merch_level_1 VARCHAR2(60 char) DEFAULT 'DEFAULT',
merch_level_2 VARCHAR2(60 char),
merch_level_3 VARCHAR2(60 char),
merch_level_4 VARCHAR2(60 char),
list_price NUMBER(17, 6),
measure_req_flag NUMBER(1, 0) DEFAULT 0,
item_lvlcode VARCHAR2(30 char),
parent_item_id VARCHAR2(60 char),
not_inventoried_flag NUMBER(1, 0) DEFAULT 0,
serialized_item_flag NUMBER(1, 0) DEFAULT 0,
item_typcode VARCHAR2(30 char),
dtv_class_name VARCHAR2(254 char),
dimension_system VARCHAR2(60 char),
disallow_matrix_display_flag NUMBER(1, 0) DEFAULT 0,
item_matrix_color VARCHAR2(20 char),
dimension1 VARCHAR2(60 char),
dimension2 VARCHAR2(60 char),
dimension3 VARCHAR2(60 char),
external_system VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_item PRIMARY KEY (organization_id, item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_item TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_ITM_ITEM_MRCHLVL1 --- ');
CREATE INDEX XST_ITM_ITEM_MRCHLVL1 ON itm_item(organization_id, UPPER(merch_level_1))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_ITM_ITEM_MRCHLVL2 --- ');
CREATE INDEX XST_ITM_ITEM_MRCHLVL2 ON itm_item(organization_id, UPPER(merch_level_2))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_ITM_ITEM_MRCHLVL3 --- ');
CREATE INDEX XST_ITM_ITEM_MRCHLVL3 ON itm_item(organization_id, UPPER(merch_level_3))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_ITM_ITEM_MRCHLVL4 --- ');
CREATE INDEX XST_ITM_ITEM_MRCHLVL4 ON itm_item(organization_id, UPPER(merch_level_4))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_ITM_ITEM_DESCRIPTION --- ');
CREATE INDEX XST_ITM_ITEM_DESCRIPTION ON itm_item(organization_id, UPPER(description))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_ITM_ITEM_ID_PARENTID --- ');
CREATE INDEX XST_ITM_ITEM_ID_PARENTID ON itm_item(organization_id, UPPER(parent_item_id), item_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_ITM_ITEM_TYPCODE --- ');
CREATE INDEX XST_ITM_ITEM_TYPCODE ON itm_item(organization_id, UPPER(item_typcode))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_ITEM02 --- ');
CREATE INDEX IDX_ITM_ITEM02 ON itm_item(item_id, UPPER(item_typcode), UPPER(merch_level_1), organization_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_ITEM_ORGNODE --- ');
CREATE INDEX IDX_ITM_ITEM_ORGNODE ON itm_item(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_item');
EXEC dbms_output.put_line('--- CREATING TABLE itm_item_cross_reference --- ');
CREATE TABLE itm_item_cross_reference(
organization_id NUMBER(10, 0) NOT NULL,
manufacturer_upc VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
item_id VARCHAR2(60 char),
manufacturer VARCHAR2(254 char),
primary_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_item_cross_reference PRIMARY KEY (organization_id, manufacturer_upc) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_item_cross_reference TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_ITM_XREF_ITEMID --- ');
CREATE INDEX XST_ITM_XREF_ITEMID ON itm_item_cross_reference(organization_id, UPPER(item_id))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_ITM_XREF_UPC_ITEMID --- ');
CREATE INDEX XST_ITM_XREF_UPC_ITEMID ON itm_item_cross_reference(manufacturer_upc, UPPER(item_id), organization_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_ITEM_XREFERENCEORGNODE --- ');
CREATE INDEX IDX_ITM_ITEM_XREFERENCEORGNODE ON itm_item_cross_reference(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_item_cross_reference');
EXEC dbms_output.put_line('--- CREATING TABLE itm_item_deal_prop --- ');
CREATE TABLE itm_item_deal_prop(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
itm_deal_property_code VARCHAR2(30 char) NOT NULL,
effective_date TIMESTAMP(6) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
expiration_date TIMESTAMP(6),
type VARCHAR2(30 char),
string_value VARCHAR2(254 char),
date_value TIMESTAMP(6),
decimal_value NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_item_deal_prop PRIMARY KEY (organization_id, item_id, itm_deal_property_code, effective_date) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_item_deal_prop TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_ITM_ITEMPROPS_ITEMID --- ');
CREATE INDEX XST_ITM_ITEMPROPS_ITEMID ON itm_item_deal_prop(organization_id, item_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_ITEM_PROP_ORGNODE --- ');
CREATE INDEX IDX_ITM_ITEM_PROP_ORGNODE ON itm_item_deal_prop(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_item_deal_prop');
EXEC dbms_output.put_line('--- CREATING TABLE itm_item_dimension_type --- ');
CREATE TABLE itm_item_dimension_type(
organization_id NUMBER(10, 0) NOT NULL,
dimension_system VARCHAR2(60 char) NOT NULL,
dimension VARCHAR2(30 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
seq NUMBER(10, 0),
sort_order NUMBER(10, 0),
description VARCHAR2(254 char),
prompt_msg VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_item_dimension_type PRIMARY KEY (organization_id, dimension_system, dimension) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_item_dimension_type TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_ITEM_DIM_TYPE_ORGNODE --- ');
CREATE INDEX IDX_ITM_ITEM_DIM_TYPE_ORGNODE ON itm_item_dimension_type(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_item_dimension_type');
EXEC dbms_output.put_line('--- CREATING TABLE itm_item_dimension_value --- ');
CREATE TABLE itm_item_dimension_value(
organization_id NUMBER(10, 0) NOT NULL,
dimension_system VARCHAR2(60 char) NOT NULL,
dimension VARCHAR2(30 char) NOT NULL,
value VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
sort_order NUMBER(10, 0),
description VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_item_dimension_value PRIMARY KEY (organization_id, dimension_system, dimension, value) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_item_dimension_value TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_ITEM_DIM_VALUE_ORGNODE --- ');
CREATE INDEX IDX_ITM_ITEM_DIM_VALUE_ORGNODE ON itm_item_dimension_value(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_item_dimension_value');
EXEC dbms_output.put_line('--- CREATING TABLE itm_item_images --- ');
CREATE TABLE itm_item_images(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
feature_id VARCHAR2(60 char) DEFAULT 'DEFAULT' NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
image_url VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_item_images PRIMARY KEY (organization_id, item_id, feature_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_item_images TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('itm_item_images');
EXEC dbms_output.put_line('--- CREATING TABLE itm_item_label_batch --- ');
CREATE TABLE itm_item_label_batch(
organization_id NUMBER(10, 0) NOT NULL,
batch_name VARCHAR2(30 char) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
stock_label VARCHAR2(20 char) NOT NULL,
rtl_loc_id NUMBER(10, 0) DEFAULT 0 NOT NULL,
count NUMBER(10, 0) NOT NULL,
overriden_price NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_item_label_batch PRIMARY KEY (organization_id, batch_name, item_id, stock_label, rtl_loc_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_item_label_batch TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('itm_item_label_batch');
EXEC dbms_output.put_line('--- CREATING TABLE itm_item_label_properties --- ');
CREATE TABLE itm_item_label_properties(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
stock_label VARCHAR2(30 char),
logo_url VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_item_label_properties PRIMARY KEY (organization_id, item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_item_label_properties TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_ITEM_LABL_PROP_ORGNODE --- ');
CREATE INDEX IDX_ITM_ITEM_LABL_PROP_ORGNODE ON itm_item_label_properties(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_item_label_properties');
EXEC dbms_output.put_line('--- CREATING TABLE itm_item_msg --- ');
CREATE TABLE itm_item_msg(
organization_id NUMBER(10, 0) NOT NULL,
msg_id VARCHAR2(60 char) NOT NULL,
effective_datetime TIMESTAMP(6) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
expr_datetime TIMESTAMP(6),
msg_key VARCHAR2(254 char) NOT NULL,
title_key VARCHAR2(254 char),
content_type VARCHAR2(30 char),
contents BLOB,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_item_msg PRIMARY KEY (organization_id, msg_id, effective_datetime) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_item_msg TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_ITEM_MSG_ORGNODE --- ');
CREATE INDEX IDX_ITM_ITEM_MSG_ORGNODE ON itm_item_msg(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_item_msg');
EXEC dbms_output.put_line('--- CREATING TABLE itm_item_msg_cross_reference --- ');
CREATE TABLE itm_item_msg_cross_reference(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
msg_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itmitemmsgcrossreference PRIMARY KEY (organization_id, item_id, msg_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_item_msg_cross_reference TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_ITEM_MSG_XREF_ORGNODE --- ');
CREATE INDEX IDX_ITM_ITEM_MSG_XREF_ORGNODE ON itm_item_msg_cross_reference(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_item_msg_cross_reference');
EXEC dbms_output.put_line('--- CREATING TABLE itm_item_msg_types --- ');
CREATE TABLE itm_item_msg_types(
organization_id NUMBER(10, 0) NOT NULL,
msg_id VARCHAR2(60 char) NOT NULL,
sale_lineitm_typcode VARCHAR2(30 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_item_msg_types PRIMARY KEY (organization_id, msg_id, sale_lineitm_typcode) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_item_msg_types TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_ITEM_MSG_TYPES_ORGNODE --- ');
CREATE INDEX IDX_ITM_ITEM_MSG_TYPES_ORGNODE ON itm_item_msg_types(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_item_msg_types');
EXEC dbms_output.put_line('--- CREATING TABLE itm_item_options --- ');
CREATE TABLE itm_item_options(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
level_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
level_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
unit_cost NUMBER(17, 6),
curr_sale_price NUMBER(17, 6),
unit_of_measure_code VARCHAR2(30 char),
compare_at_price NUMBER(17, 6),
min_sale_unit_count NUMBER(11, 4),
max_sale_unit_count NUMBER(11, 4),
item_availability_code VARCHAR2(30 char),
disallow_discounts_flag NUMBER(1, 0) DEFAULT 0,
prompt_for_quantity_flag NUMBER(1, 0) DEFAULT 0,
prompt_for_price_flag NUMBER(1, 0) DEFAULT 0,
prompt_for_description_flag NUMBER(1, 0) DEFAULT 0,
force_quantity_of_one_flag NUMBER(1, 0) DEFAULT 0,
not_returnable_flag NUMBER(1, 0) DEFAULT 0,
no_giveaways_flag NUMBER(1, 0) DEFAULT 0,
attached_items_flag NUMBER(1, 0) DEFAULT 0,
substitute_available_flag NUMBER(1, 0) DEFAULT 0,
tax_group_id VARCHAR2(60 char),
messages_flag NUMBER(1, 0) DEFAULT 0,
vendor VARCHAR2(256 char),
season_code VARCHAR2(30 char),
part_number VARCHAR2(254 char),
qty_scale NUMBER(10, 0),
restocking_fee NUMBER(17, 6),
special_order_lead_days NUMBER(10, 0),
apply_restocking_fee_flag NUMBER(1, 0) DEFAULT 0,
disallow_send_sale_flag NUMBER(1, 0) DEFAULT 0,
disallow_price_change_flag NUMBER(1, 0) DEFAULT 0,
disallow_layaway_flag NUMBER(1, 0) DEFAULT 0,
disallow_special_order_flag NUMBER(1, 0) DEFAULT 0,
disallow_self_checkout_flag NUMBER(1, 0) DEFAULT 0,
disallow_work_order_flag NUMBER(1, 0) DEFAULT 0,
disallow_commission_flag NUMBER(1, 0) DEFAULT 0,
warranty_flag NUMBER(1, 0) DEFAULT 0,
generic_item_flag NUMBER(1, 0) DEFAULT 0,
initial_sale_qty NUMBER(11, 4),
disposition_code VARCHAR2(30 char),
foodstamp_eligible_flag NUMBER(1, 0) DEFAULT 0,
stock_status VARCHAR2(60 char),
prompt_for_customer VARCHAR2(30 char),
shipping_weight NUMBER(12, 3),
disallow_order_flag NUMBER(1, 0) DEFAULT 0,
disallow_deals_flag NUMBER(1, 0) DEFAULT 0,
pack_size NUMBER(11, 4),
default_source_type VARCHAR2(60 char),
default_source_id VARCHAR2(60 char),
disallow_rain_check NUMBER(1, 0) DEFAULT 0,
selling_group_id VARCHAR2(60 char),
fiscal_item_id VARCHAR2(254 char),
fiscal_item_description VARCHAR2(254 char),
exclude_from_net_sales_flag NUMBER(1, 0) DEFAULT 0,
external_system VARCHAR2(60 char),
tare_value NUMBER(11, 4),
tare_unit_of_measure_code VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_item_options PRIMARY KEY (organization_id, item_id, level_code, level_value) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_item_options TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_ITEM_OPTIONS --- ');
CREATE INDEX IDX_ITM_ITEM_OPTIONS ON itm_item_options(organization_id, item_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_item_options');
EXEC dbms_output.put_line('--- CREATING TABLE itm_item_prices --- ');
CREATE TABLE itm_item_prices(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
level_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
level_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
itm_price_property_code VARCHAR2(60 char) NOT NULL,
effective_date TIMESTAMP(6) NOT NULL,
expiration_date TIMESTAMP(6),
price NUMBER(17, 6) NOT NULL,
price_qty NUMBER(11, 4) DEFAULT 1 NOT NULL,
external_id VARCHAR2(60 char),
external_system VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_item_prices PRIMARY KEY (organization_id, item_id, level_code, level_value, itm_price_property_code, effective_date, price_qty) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_item_prices TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_ITM_ITEMPRICES_EXPR --- ');
CREATE INDEX XST_ITM_ITEMPRICES_EXPR ON itm_item_prices(expiration_date)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_item_prices');
EXEC dbms_output.put_line('--- CREATING TABLE itm_item_prompt_properties --- ');
CREATE TABLE itm_item_prompt_properties(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
itm_prompt_property_code VARCHAR2(30 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
code_group VARCHAR2(30 char),
prompt_title_key VARCHAR2(60 char),
prompt_msg_key VARCHAR2(60 char),
required_flag NUMBER(1, 0) DEFAULT 0,
sort_order NUMBER(10, 0),
prompt_mthd_code VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itmitempromptproperties PRIMARY KEY (organization_id, item_id, itm_prompt_property_code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_item_prompt_properties TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_ITM_PRMPT_PROP_ORGNODE --- ');
CREATE INDEX IDX_ITM_ITM_PRMPT_PROP_ORGNODE ON itm_item_prompt_properties(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_item_prompt_properties');
EXEC dbms_output.put_line('--- CREATING TABLE itm_kit_component --- ');
CREATE TABLE itm_kit_component(
organization_id NUMBER(10, 0) NOT NULL,
kit_item_id VARCHAR2(60 char) NOT NULL,
component_item_id VARCHAR2(60 char) NOT NULL,
seq_nbr NUMBER(10, 0) DEFAULT 1 NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
display_order NUMBER(10, 0),
quantity_per_kit NUMBER(10, 0) DEFAULT 1,
begin_datetime TIMESTAMP(6),
end_datetime TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_kit_component PRIMARY KEY (organization_id, kit_item_id, component_item_id, seq_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_kit_component TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_KIT_COMPONENT_ORGNODE --- ');
CREATE INDEX IDX_ITM_KIT_COMPONENT_ORGNODE ON itm_kit_component(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_kit_component');
EXEC dbms_output.put_line('--- CREATING TABLE itm_matrix_sort_order --- ');
CREATE TABLE itm_matrix_sort_order(
organization_id NUMBER(10, 0) NOT NULL,
matrix_sort_type VARCHAR2(60 char) NOT NULL,
matrix_sort_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
sort_order NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_matrix_sort_order PRIMARY KEY (organization_id, matrix_sort_type, matrix_sort_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_matrix_sort_order TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_MATRIX_SORTORD_ORGNODE --- ');
CREATE INDEX IDX_ITM_MATRIX_SORTORD_ORGNODE ON itm_matrix_sort_order(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_matrix_sort_order');
EXEC dbms_output.put_line('--- CREATING TABLE itm_merch_hierarchy --- ');
CREATE TABLE itm_merch_hierarchy(
organization_id NUMBER(10, 0) NOT NULL,
hierarchy_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
parent_id VARCHAR2(60 char),
level_code VARCHAR2(30 char),
description VARCHAR2(254 char),
sort_order NUMBER(10, 0),
hidden_flag NUMBER(1, 0) DEFAULT 0,
disallow_matrix_display_flag NUMBER(1, 0) DEFAULT 0,
item_matrix_color VARCHAR2(20 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_merch_hierarchy PRIMARY KEY (organization_id, hierarchy_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_merch_hierarchy TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_MERCH_HIRARCHY_ORGNODE --- ');
CREATE INDEX IDX_ITM_MERCH_HIRARCHY_ORGNODE ON itm_merch_hierarchy(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_merch_hierarchy');
EXEC dbms_output.put_line('--- CREATING TABLE itm_merch_hierarchy_levels --- ');
CREATE TABLE itm_merch_hierarchy_levels(
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
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_merch_hierarchy_levels TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('itm_merch_hierarchy_levels');
EXEC dbms_output.put_line('--- CREATING TABLE itm_non_phys_item --- ');
CREATE TABLE itm_non_phys_item(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
display_order NUMBER(10, 0),
non_phys_item_typcode VARCHAR2(30 char),
non_phys_item_subtype VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_non_phys_item PRIMARY KEY (organization_id, item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_non_phys_item TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE itm_quick_items --- ');
CREATE TABLE itm_quick_items(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
parent_id VARCHAR2(60 char),
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
image_url VARCHAR2(254 char),
sort_order NUMBER(10, 0),
description VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_quick_items PRIMARY KEY (organization_id, item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_quick_items TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('itm_quick_items');
EXEC dbms_output.put_line('--- CREATING TABLE itm_refund_schedule --- ');
CREATE TABLE itm_refund_schedule(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
effective_date TIMESTAMP(6) NOT NULL,
expiration_date TIMESTAMP(6),
max_full_refund_time NUMBER(10, 0),
min_no_refund_time NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_refund_schedule PRIMARY KEY (organization_id, item_id, effective_date) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_refund_schedule TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_REFND_SCHEDULE_ORGNODE --- ');
CREATE INDEX IDX_ITM_REFND_SCHEDULE_ORGNODE ON itm_refund_schedule(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_refund_schedule');
EXEC dbms_output.put_line('--- CREATING TABLE itm_restrict_gs1 --- ');
CREATE TABLE itm_restrict_gs1(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
field_id VARCHAR2(10 char) NOT NULL,
ai_type VARCHAR2(30 char) NOT NULL,
start_value VARCHAR2(50 char) NOT NULL,
end_value VARCHAR2(50 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_restrict_gs1 PRIMARY KEY (organization_id, item_id, field_id, start_value) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_restrict_gs1 TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_RESTRICT_GS1 --- ');
CREATE INDEX IDX_ITM_RESTRICT_GS1 ON itm_restrict_gs1(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_restrict_gs1');
EXEC dbms_output.put_line('--- CREATING TABLE itm_restriction --- ');
CREATE TABLE itm_restriction(
organization_id NUMBER(10, 0) NOT NULL,
restriction_id VARCHAR2(30 char) NOT NULL,
restriction_description VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_restriction PRIMARY KEY (organization_id, restriction_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_restriction TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('itm_restriction');
EXEC dbms_output.put_line('--- CREATING TABLE itm_restriction_calendar --- ');
CREATE TABLE itm_restriction_calendar(
organization_id NUMBER(10, 0) NOT NULL,
restriction_id VARCHAR2(30 char) NOT NULL,
restriction_typecode VARCHAR2(60 char) NOT NULL,
day_code VARCHAR2(3 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
start_time TIMESTAMP(6),
end_time TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_restriction_calendar PRIMARY KEY (organization_id, restriction_id, restriction_typecode, day_code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_restriction_calendar TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_RESTRICT_CAL_ORGNODE --- ');
CREATE INDEX IDX_ITM_RESTRICT_CAL_ORGNODE ON itm_restriction_calendar(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_restriction_calendar');
EXEC dbms_output.put_line('--- CREATING TABLE itm_restriction_mapping --- ');
CREATE TABLE itm_restriction_mapping(
organization_id NUMBER(10, 0) NOT NULL,
restriction_id VARCHAR2(30 char) NOT NULL,
merch_hierarchy_level VARCHAR2(60 char) NOT NULL,
merch_hierarchy_id VARCHAR2(60 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_restriction_mapping PRIMARY KEY (organization_id, restriction_id, merch_hierarchy_level, merch_hierarchy_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_restriction_mapping TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('itm_restriction_mapping');
EXEC dbms_output.put_line('--- CREATING TABLE itm_restriction_type --- ');
CREATE TABLE itm_restriction_type(
organization_id NUMBER(10, 0) NOT NULL,
restriction_id VARCHAR2(30 char) NOT NULL,
restriction_typecode VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
effective_date TIMESTAMP(6),
expiration_date TIMESTAMP(6),
value_type VARCHAR2(30 char),
boolean_value NUMBER(1, 0),
date_value TIMESTAMP(6),
decimal_value NUMBER(17, 6),
string_value VARCHAR2(254 char),
exclude_returns_flag NUMBER(1, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_restriction_type PRIMARY KEY (organization_id, restriction_id, restriction_typecode) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_restriction_type TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_RESTRICT_TYPE_ORGNODE --- ');
CREATE INDEX IDX_ITM_RESTRICT_TYPE_ORGNODE ON itm_restriction_type(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_restriction_type');
EXEC dbms_output.put_line('--- CREATING TABLE itm_substitute_items --- ');
CREATE TABLE itm_substitute_items(
organization_id NUMBER(10, 0) NOT NULL,
primary_item_id VARCHAR2(60 char) NOT NULL,
substitute_item_id VARCHAR2(60 char) NOT NULL,
level_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
level_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
begin_datetime TIMESTAMP(6),
end_datetime TIMESTAMP(6),
external_id VARCHAR2(60 char),
external_system VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_substitute_items PRIMARY KEY (organization_id, primary_item_id, substitute_item_id, level_code, level_value) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_substitute_items TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_SUB_ITEMS_ORGNODE --- ');
CREATE INDEX IDX_ITM_SUB_ITEMS_ORGNODE ON itm_substitute_items(level_code, level_value)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_substitute_items');
EXEC dbms_output.put_line('--- CREATING TABLE itm_vendor --- ');
CREATE TABLE itm_vendor(
organization_id NUMBER(10, 0) NOT NULL,
vendor_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
name VARCHAR2(254 char),
buyer VARCHAR2(254 char),
address_id VARCHAR2(60 char),
telephone VARCHAR2(32 char),
contact_telephone VARCHAR2(32 char),
typcode VARCHAR2(30 char),
contact VARCHAR2(254 char),
fax VARCHAR2(32 char),
status VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_vendor PRIMARY KEY (organization_id, vendor_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_vendor TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_VENDOR_ORGNODE --- ');
CREATE INDEX IDX_ITM_VENDOR_ORGNODE ON itm_vendor(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_vendor');
EXEC dbms_output.put_line('--- CREATING TABLE itm_warranty --- ');
CREATE TABLE itm_warranty(
organization_id NUMBER(10, 0) NOT NULL,
warranty_typcode VARCHAR2(60 char) NOT NULL,
warranty_nbr VARCHAR2(30 char) NOT NULL,
warranty_plan_id VARCHAR2(60 char),
warranty_issue_date TIMESTAMP(6),
warranty_expiration_date TIMESTAMP(6),
status_code VARCHAR2(30 char),
purchase_price NUMBER(17, 6),
cust_id VARCHAR2(60 char),
party_id NUMBER(19, 0),
certificate_nbr VARCHAR2(60 char),
certificate_company_name VARCHAR2(254 char),
warranty_item_id VARCHAR2(60 char),
warranty_line_business_date TIMESTAMP(6),
warranty_line_rtl_loc_id NUMBER(10, 0),
warranty_line_wkstn_id NUMBER(19, 0),
warranty_line_trans_seq NUMBER(19, 0),
warranty_rtrans_lineitm_seq NUMBER(10, 0),
covered_item_id VARCHAR2(60 char),
covered_line_business_date TIMESTAMP(6),
covered_line_rtl_loc_id NUMBER(10, 0),
covered_line_wkstn_id NUMBER(19, 0),
covered_line_trans_seq NUMBER(19, 0),
covered_rtrans_lineitm_seq NUMBER(10, 0),
covered_item_purchase_date TIMESTAMP(6),
covered_item_purchase_price NUMBER(17, 6),
covered_item_purchase_location VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_warranty PRIMARY KEY (organization_id, warranty_typcode, warranty_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_warranty TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_WARRANTY01 --- ');
CREATE INDEX IDX_ITM_WARRANTY01 ON itm_warranty(party_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_warranty');
EXEC dbms_output.put_line('--- CREATING TABLE itm_warranty_item --- ');
CREATE TABLE itm_warranty_item(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
pricing_mthd_code VARCHAR2(60 char),
warranty_price_amt NUMBER(17, 6),
warranty_price_percentage NUMBER(6, 4),
warranty_min_price_amt NUMBER(17, 6),
expiration_days NUMBER(10, 0),
service_days NUMBER(10, 0),
renewable_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_warranty_item PRIMARY KEY (organization_id, item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_warranty_item TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE itm_warranty_item_price --- ');
CREATE TABLE itm_warranty_item_price(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
warranty_price_seq NUMBER(10, 0) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
min_item_price_amt NUMBER(17, 6),
max_item_price_amt NUMBER(17, 6),
price_amt NUMBER(17, 6),
price_percentage NUMBER(6, 4),
min_price_amt NUMBER(17, 6),
ref_item_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_warranty_item_price PRIMARY KEY (organization_id, item_id, warranty_price_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_warranty_item_price TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDXITMWARRANTYITEMPRICEORGNODE --- ');
CREATE INDEX IDXITMWARRANTYITEMPRICEORGNODE ON itm_warranty_item_price(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_warranty_item_price');
EXEC dbms_output.put_line('--- CREATING TABLE itm_warranty_item_xref --- ');
CREATE TABLE itm_warranty_item_xref(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
warranty_typcode VARCHAR2(60 char) NOT NULL,
warranty_item_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
sort_order NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_warranty_item_xref PRIMARY KEY (organization_id, item_id, warranty_typcode, warranty_item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_warranty_item_xref TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDXITMWARRANTYITEMXREFORGNODE --- ');
CREATE INDEX IDXITMWARRANTYITEMXREFORGNODE ON itm_warranty_item_xref(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_warranty_item_xref');
EXEC dbms_output.put_line('--- CREATING TABLE itm_warranty_journal --- ');
CREATE TABLE itm_warranty_journal(
organization_id NUMBER(10, 0) NOT NULL,
warranty_typcode VARCHAR2(60 char) NOT NULL,
warranty_nbr VARCHAR2(30 char) NOT NULL,
journal_seq NUMBER(19, 0) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
trans_business_date TIMESTAMP(6),
trans_rtl_loc_id NUMBER(10, 0),
trans_wkstn_id NUMBER(19, 0),
trans_trans_seq NUMBER(19, 0),
warranty_plan_id VARCHAR2(60 char),
warranty_issue_date TIMESTAMP(6),
warranty_expiration_date TIMESTAMP(6),
status_code VARCHAR2(30 char),
purchase_price NUMBER(17, 6),
cust_id VARCHAR2(60 char),
party_id NUMBER(19, 0),
certificate_nbr VARCHAR2(60 char),
certificate_company_name VARCHAR2(254 char),
warranty_item_id VARCHAR2(60 char),
warranty_line_business_date TIMESTAMP(6),
warranty_line_rtl_loc_id NUMBER(10, 0),
warranty_line_wkstn_id NUMBER(19, 0),
warranty_line_trans_seq NUMBER(19, 0),
warranty_rtrans_lineitm_seq NUMBER(10, 0),
covered_item_id VARCHAR2(60 char),
covered_line_business_date TIMESTAMP(6),
covered_line_rtl_loc_id NUMBER(10, 0),
covered_line_wkstn_id NUMBER(19, 0),
covered_line_trans_seq NUMBER(19, 0),
covered_rtrans_lineitm_seq NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_itm_warranty_journal PRIMARY KEY (organization_id, warranty_typcode, warranty_nbr, journal_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON itm_warranty_journal TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_ITM_WARRANTY_JOURNAL01 --- ');
CREATE INDEX IDX_ITM_WARRANTY_JOURNAL01 ON itm_warranty_journal(party_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDXITMWARRANTYJOURNALORGNODE --- ');
CREATE INDEX IDXITMWARRANTYJOURNALORGNODE ON itm_warranty_journal(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('itm_warranty_journal');
EXEC dbms_output.put_line('--- CREATING TABLE loc_close_dates --- ');
CREATE TABLE loc_close_dates(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
close_date TIMESTAMP(6) NOT NULL,
reason_code VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_loc_close_dates PRIMARY KEY (organization_id, rtl_loc_id, close_date) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON loc_close_dates TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('loc_close_dates');
EXEC dbms_output.put_line('--- CREATING TABLE loc_closing_message --- ');
CREATE TABLE loc_closing_message(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
closing_message VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_loc_closing_message PRIMARY KEY (organization_id, rtl_loc_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON loc_closing_message TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('loc_closing_message');
EXEC dbms_output.put_line('--- CREATING TABLE loc_cycle_question_answers --- ');
CREATE TABLE loc_cycle_question_answers(
organization_id NUMBER(10, 0) NOT NULL,
question_id VARCHAR2(60 char) NOT NULL,
answer_id VARCHAR2(60 char) NOT NULL,
answer_timestamp TIMESTAMP(6) NOT NULL,
rtl_loc_id NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_loccyclequestionanswers PRIMARY KEY (organization_id, question_id, answer_id, answer_timestamp) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON loc_cycle_question_answers TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('loc_cycle_question_answers');
EXEC dbms_output.put_line('--- CREATING TABLE loc_cycle_question_choices --- ');
CREATE TABLE loc_cycle_question_choices(
organization_id NUMBER(10, 0) NOT NULL,
question_id VARCHAR2(60 char) NOT NULL,
answer_id VARCHAR2(60 char) NOT NULL,
answer_text_key CLOB,
sort_order NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_loccyclequestionchoices PRIMARY KEY (organization_id, question_id, answer_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON loc_cycle_question_choices TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('loc_cycle_question_choices');
EXEC dbms_output.put_line('--- CREATING TABLE loc_cycle_questions --- ');
CREATE TABLE loc_cycle_questions(
organization_id NUMBER(10, 0) NOT NULL,
question_id VARCHAR2(60 char) NOT NULL,
question_text_key VARCHAR2(254 char),
sort_order NUMBER(10, 0),
effective_datetime TIMESTAMP(6),
expiration_datetime TIMESTAMP(6),
rtl_loc_id NUMBER(10, 0) DEFAULT 0,
corporate_message_flag NUMBER(1, 0) DEFAULT 0,
question_typcode VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_loc_cycle_questions PRIMARY KEY (organization_id, question_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON loc_cycle_questions TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('loc_cycle_questions');
EXEC dbms_output.put_line('--- CREATING TABLE loc_legal_entity --- ');
CREATE TABLE loc_legal_entity(
organization_id NUMBER(10, 0) NOT NULL,
legal_entity_id VARCHAR2(30 char) NOT NULL,
description VARCHAR2(254 char),
address1 VARCHAR2(254 char),
address2 VARCHAR2(254 char),
address3 VARCHAR2(254 char),
address4 VARCHAR2(254 char),
city VARCHAR2(254 char),
state VARCHAR2(30 char),
district VARCHAR2(30 char),
area VARCHAR2(30 char),
postal_code VARCHAR2(30 char),
country VARCHAR2(2 char),
neighborhood VARCHAR2(254 char),
county VARCHAR2(254 char),
apartment VARCHAR2(30 char),
email_addr VARCHAR2(254 char),
tax_id VARCHAR2(30 char),
fiscal_code VARCHAR2(30 char),
taxation_regime VARCHAR2(30 char),
legal_employer_id VARCHAR2(30 char),
activity_code VARCHAR2(30 char),
tax_office_code VARCHAR2(30 char),
statistical_code VARCHAR2(30 char),
legal_form VARCHAR2(60 char),
social_capital VARCHAR2(60 char),
companies_register_number VARCHAR2(30 char),
fax_number VARCHAR2(32 char),
phone_number VARCHAR2(32 char),
web_site VARCHAR2(254 char),
establishment_code VARCHAR2(30 char),
registration_city VARCHAR2(254 char),
activity_description VARCHAR2(254 char),
company_business_name VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_loc_legal_entity PRIMARY KEY (organization_id, legal_entity_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON loc_legal_entity TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('loc_legal_entity');
EXEC dbms_output.put_line('--- CREATING TABLE loc_org_hierarchy --- ');
CREATE TABLE loc_org_hierarchy(
organization_id NUMBER(10, 0) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
parent_code VARCHAR2(30 char),
parent_value VARCHAR2(60 char),
description VARCHAR2(254 char),
level_mgr VARCHAR2(254 char),
level_order NUMBER(10, 0),
sort_order NUMBER(10, 0),
inactive_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_loc_org_hierarchy PRIMARY KEY (organization_id, org_code, org_value) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON loc_org_hierarchy TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_LOC_ORGHIER_LVLMGR --- ');
CREATE INDEX XST_LOC_ORGHIER_LVLMGR ON loc_org_hierarchy(UPPER(level_mgr))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_LOC_ORGHIER_LVLORDER --- ');
CREATE INDEX XST_LOC_ORGHIER_LVLORDER ON loc_org_hierarchy(level_order)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_LOC_ORGHIER_PARENT --- ');
CREATE INDEX XST_LOC_ORGHIER_PARENT ON loc_org_hierarchy(UPPER(parent_code), UPPER(parent_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_LOC_ORGHIER_SORTORDER --- ');
CREATE INDEX XST_LOC_ORGHIER_SORTORDER ON loc_org_hierarchy(sort_order)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('loc_org_hierarchy');
EXEC dbms_output.put_line('--- CREATING TABLE loc_pricing_hierarchy --- ');
CREATE TABLE loc_pricing_hierarchy(
organization_id NUMBER(10, 0) NOT NULL,
level_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
level_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
parent_code VARCHAR2(30 char),
parent_value VARCHAR2(60 char),
description VARCHAR2(254 char),
level_order NUMBER(10, 0),
sort_order NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_loc_pricing_hierarchy PRIMARY KEY (organization_id, level_code, level_value) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON loc_pricing_hierarchy TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_LOC_PRICEHIER_LVLORDER --- ');
CREATE INDEX XST_LOC_PRICEHIER_LVLORDER ON loc_pricing_hierarchy(level_order)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_LOC_PRICEHIER_PARENT --- ');
CREATE INDEX XST_LOC_PRICEHIER_PARENT ON loc_pricing_hierarchy(UPPER(parent_code), UPPER(parent_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX XST_LOC_PRICEHIER_SORTORDER --- ');
CREATE INDEX XST_LOC_PRICEHIER_SORTORDER ON loc_pricing_hierarchy(sort_order)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('loc_pricing_hierarchy');
EXEC dbms_output.put_line('--- CREATING TABLE loc_rtl_loc --- ');
CREATE TABLE loc_rtl_loc(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
store_name VARCHAR2(254 char),
address1 VARCHAR2(254 char),
address2 VARCHAR2(254 char),
address3 VARCHAR2(254 char),
address4 VARCHAR2(254 char),
city VARCHAR2(254 char),
state VARCHAR2(30 char),
district VARCHAR2(30 char),
area VARCHAR2(30 char),
postal_code VARCHAR2(30 char),
country VARCHAR2(2 char),
neighborhood VARCHAR2(254 char),
county VARCHAR2(254 char),
locale VARCHAR2(30 char) NOT NULL,
currency_id VARCHAR2(3 char),
latitude NUMBER(17, 6),
longitude NUMBER(17, 6),
telephone1 VARCHAR2(32 char),
telephone2 VARCHAR2(32 char),
telephone3 VARCHAR2(32 char),
telephone4 VARCHAR2(32 char),
description VARCHAR2(254 char),
store_nbr VARCHAR2(254 char),
apartment VARCHAR2(30 char),
store_manager VARCHAR2(254 char),
email_addr VARCHAR2(254 char),
default_tax_percentage NUMBER(8, 6),
location_type VARCHAR2(60 char),
delivery_available_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
pickup_available_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
transfer_available_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
geo_code VARCHAR2(20 char),
uez_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
alternate_store_nbr VARCHAR2(254 char),
use_till_accountability_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
deposit_bank_name VARCHAR2(254 char),
deposit_bank_account_number VARCHAR2(30 char),
airport_code VARCHAR2(3 char),
legal_entity_id VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_loc_rtl_loc PRIMARY KEY (organization_id, rtl_loc_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON loc_rtl_loc TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('loc_rtl_loc');
EXEC dbms_output.put_line('--- CREATING TABLE loc_state_journal --- ');
CREATE TABLE loc_state_journal(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
status_typcode VARCHAR2(30 char) NOT NULL,
state_journal_id VARCHAR2(60 char) NOT NULL,
time_stamp TIMESTAMP(6) NOT NULL,
date_value TIMESTAMP(6),
string_value VARCHAR2(30 char),
decimal_value NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_loc_state_journal PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, status_typcode, state_journal_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON loc_state_journal TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_LOC_STATEJOURNAL_TIME --- ');
CREATE INDEX XST_LOC_STATEJOURNAL_TIME ON loc_state_journal(time_stamp)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('loc_state_journal');
EXEC dbms_output.put_line('--- CREATING TABLE loc_temp_store_request --- ');
CREATE TABLE loc_temp_store_request(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
request_id NUMBER(19, 0) NOT NULL,
request_type VARCHAR2(30 char),
store_created_flag NUMBER(1, 0),
description VARCHAR2(254 char),
start_date_str VARCHAR2(8 char) NOT NULL,
end_date_str VARCHAR2(8 char),
active_date_str VARCHAR2(8 char),
assigned_server_host VARCHAR2(254 char),
assigned_server_port NUMBER(10, 0),
status VARCHAR2(30 char) NOT NULL,
approve_reject_notes VARCHAR2(254 char),
use_store_tax_loc_flag NUMBER(1, 0) DEFAULT 1 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_loc_temp_store_request PRIMARY KEY (organization_id, rtl_loc_id, request_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON loc_temp_store_request TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('loc_temp_store_request');
EXEC dbms_output.put_line('--- CREATING TABLE loc_wkstn --- ');
CREATE TABLE loc_wkstn(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_loc_wkstn PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON loc_wkstn TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('loc_wkstn');
EXEC dbms_output.put_line('--- CREATING TABLE loc_wkstn_config_data --- ');
CREATE TABLE loc_wkstn_config_data(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
field_name VARCHAR2(100 char) NOT NULL,
create_timestamp TIMESTAMP(6) NOT NULL,
field_value VARCHAR2(1024 char),
link_column VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char)
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON loc_wkstn_config_data TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_LOC_WKSTN_CONFIG_DATA01 --- ');
CREATE INDEX IDX_LOC_WKSTN_CONFIG_DATA01 ON loc_wkstn_config_data(organization_id, rtl_loc_id, wkstn_id, UPPER(field_name), create_timestamp)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING TABLE log_sp_report --- ');
CREATE TABLE log_sp_report(
job_id NUMBER(10, 0) NOT NULL,
loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
start_dt TIMESTAMP(6),
end_dt TIMESTAMP(6),
completed NUMBER(10, 0),
expected NUMBER(10, 0),
job_start TIMESTAMP(6) NOT NULL,
job_end TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_log_sp_report PRIMARY KEY (job_id, loc_id, business_date, job_start) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON log_sp_report TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE prc_deal --- ');
CREATE TABLE prc_deal(
organization_id NUMBER(10, 0) NOT NULL,
deal_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
description VARCHAR2(128 char),
consumable NUMBER(1, 0) DEFAULT 0,
act_deferred NUMBER(1, 0) DEFAULT 0,
effective_date TIMESTAMP(6),
end_date TIMESTAMP(6),
start_time TIMESTAMP(6),
end_time TIMESTAMP(6),
generosity_cap NUMBER(17, 6),
iteration_cap NUMBER(10, 0),
priority_nudge NUMBER(10, 0),
subtotal_min NUMBER(17, 6),
subtotal_max NUMBER(17, 6),
trans_deal_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
trwide_action VARCHAR2(30 char),
trwide_amount NUMBER(17, 6),
taxability_code VARCHAR2(30 char),
promotion_id VARCHAR2(60 char),
higher_nonaction_amt_flag NUMBER(1, 0) DEFAULT 0,
exclude_price_override_flag NUMBER(1, 0) DEFAULT 0,
exclude_discounted_flag NUMBER(1, 0) DEFAULT 0,
targeted_flag NUMBER(1, 0) DEFAULT 0,
week_sched_flag NUMBER(1, 0),
sort_order NUMBER(10, 0) DEFAULT 0 NOT NULL,
type VARCHAR2(60 char),
group_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_prc_deal PRIMARY KEY (organization_id, deal_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON prc_deal TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_PRC_DEAL_ORGNODE --- ');
CREATE INDEX IDX_PRC_DEAL_ORGNODE ON prc_deal(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('prc_deal');
EXEC dbms_output.put_line('--- CREATING TABLE prc_deal_cust_groups --- ');
CREATE TABLE prc_deal_cust_groups(
organization_id NUMBER(10, 0) NOT NULL,
deal_id VARCHAR2(60 char) NOT NULL,
cust_group_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_prc_deal_cust_groups PRIMARY KEY (organization_id, deal_id, cust_group_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON prc_deal_cust_groups TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_PRC_DEAL_CUSTGROUPSORGNODE --- ');
CREATE INDEX IDX_PRC_DEAL_CUSTGROUPSORGNODE ON prc_deal_cust_groups(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('prc_deal_cust_groups');
EXEC dbms_output.put_line('--- CREATING TABLE prc_deal_document_xref --- ');
CREATE TABLE prc_deal_document_xref(
organization_id NUMBER(10, 0) NOT NULL,
deal_id VARCHAR2(60 char) NOT NULL,
series_id VARCHAR2(60 char) NOT NULL,
document_type VARCHAR2(30 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_prc_deal_document_xref PRIMARY KEY (organization_id, deal_id, series_id, document_type) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON prc_deal_document_xref TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_PRC_DEAL_DOC_XREF_ORGNODE --- ');
CREATE INDEX IDX_PRC_DEAL_DOC_XREF_ORGNODE ON prc_deal_document_xref(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('prc_deal_document_xref');
EXEC dbms_output.put_line('--- CREATING TABLE prc_deal_field_test --- ');
CREATE TABLE prc_deal_field_test(
organization_id NUMBER(10, 0) NOT NULL,
deal_id VARCHAR2(60 char) NOT NULL,
item_ordinal NUMBER(10, 0) NOT NULL,
item_condition_group NUMBER(10, 0) NOT NULL,
item_condition_seq NUMBER(10, 0) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
item_field VARCHAR2(60 char) NOT NULL,
match_rule VARCHAR2(20 char) NOT NULL,
value1 VARCHAR2(128 char) NOT NULL,
value2 VARCHAR2(128 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_prc_deal_field_test PRIMARY KEY (organization_id, deal_id, item_ordinal, item_condition_group, item_condition_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON prc_deal_field_test TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_PRC_DEAL_FIELD_TST_ORGNODE --- ');
CREATE INDEX IDX_PRC_DEAL_FIELD_TST_ORGNODE ON prc_deal_field_test(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('prc_deal_field_test');
EXEC dbms_output.put_line('--- CREATING TABLE prc_deal_item --- ');
CREATE TABLE prc_deal_item(
organization_id NUMBER(10, 0) NOT NULL,
deal_id VARCHAR2(60 char) NOT NULL,
item_ordinal NUMBER(10, 0) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
consumable NUMBER(1, 0),
qty_min NUMBER(17, 4),
qty_max NUMBER(17, 4),
min_item_total NUMBER(17, 6),
deal_action VARCHAR2(30 char),
action_arg NUMBER(17, 6),
action_arg_qty NUMBER(17, 4),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_prc_deal_item PRIMARY KEY (organization_id, deal_id, item_ordinal) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON prc_deal_item TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_PRC_DEAL_ITEM_ORGNODE --- ');
CREATE INDEX IDX_PRC_DEAL_ITEM_ORGNODE ON prc_deal_item(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('prc_deal_item');
EXEC dbms_output.put_line('--- CREATING TABLE prc_deal_loc --- ');
CREATE TABLE prc_deal_loc(
organization_id NUMBER(10, 0) NOT NULL,
deal_id VARCHAR2(60 char) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_prc_deal_loc PRIMARY KEY (organization_id, deal_id, rtl_loc_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON prc_deal_loc TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('prc_deal_loc');
EXEC dbms_output.put_line('--- CREATING TABLE prc_deal_trig --- ');
CREATE TABLE prc_deal_trig(
organization_id NUMBER(10, 0) NOT NULL,
deal_id VARCHAR2(60 char) NOT NULL,
deal_trigger VARCHAR2(128 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_prc_deal_trig PRIMARY KEY (organization_id, deal_id, deal_trigger) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON prc_deal_trig TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_PRC_DEAL_TRIG_ORGNODE --- ');
CREATE INDEX IDX_PRC_DEAL_TRIG_ORGNODE ON prc_deal_trig(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('prc_deal_trig');
EXEC dbms_output.put_line('--- CREATING TABLE prc_deal_week --- ');
CREATE TABLE prc_deal_week(
organization_id NUMBER(10, 0) NOT NULL,
deal_id VARCHAR2(60 char) NOT NULL,
day_code VARCHAR2(3 char) NOT NULL,
start_time TIMESTAMP(6) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
end_time TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_prc_deal_week PRIMARY KEY (organization_id, deal_id, day_code, start_time) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON prc_deal_week TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_PRC_DEAL_WEEK_ORGNODE --- ');
CREATE INDEX IDX_PRC_DEAL_WEEK_ORGNODE ON prc_deal_week(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('prc_deal_week');
EXEC dbms_output.put_line('--- CREATING TABLE rms_diff_group_detail --- ');
CREATE TABLE rms_diff_group_detail(
organization_id NUMBER(10, 0) NOT NULL,
diff_group_id VARCHAR2(10 char) NOT NULL,
diff_id VARCHAR2(10 char) NOT NULL,
display_seq NUMBER(4, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_rms_diff_group_detail PRIMARY KEY (organization_id, diff_group_id, diff_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON rms_diff_group_detail TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE rms_diff_group_head --- ');
CREATE TABLE rms_diff_group_head(
organization_id NUMBER(10, 0) NOT NULL,
diff_group_id VARCHAR2(10 char) NOT NULL,
diff_type VARCHAR2(6 char) NOT NULL,
diff_group_desc VARCHAR2(120 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_rms_diff_group_head PRIMARY KEY (organization_id, diff_group_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON rms_diff_group_head TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE rms_diff_ids --- ');
CREATE TABLE rms_diff_ids(
organization_id NUMBER(10, 0) NOT NULL,
diff_id VARCHAR2(10 char) NOT NULL,
diff_desc VARCHAR2(120 char),
diff_type VARCHAR2(6 char) NOT NULL,
diff_type_desc VARCHAR2(120 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_rms_diff_ids PRIMARY KEY (organization_id, diff_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON rms_diff_ids TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE rms_related_item_head --- ');
CREATE TABLE rms_related_item_head(
organization_id NUMBER(10, 0) NOT NULL,
relationship_id NUMBER(19, 0) NOT NULL,
item VARCHAR2(25 char) NOT NULL,
location VARCHAR2(10 char) NOT NULL,
relationship_name VARCHAR2(255 char) NOT NULL,
relationship_type VARCHAR2(6 char) NOT NULL,
mandatory_ind VARCHAR2(1 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_rms_related_item_head PRIMARY KEY (organization_id, relationship_id, location) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON rms_related_item_head TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE rpt_fifo --- ');
CREATE TABLE rpt_fifo(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
description VARCHAR2(254 char),
style_id VARCHAR2(60 char),
style_desc VARCHAR2(254 char),
rtl_loc_id NUMBER(10, 0) NOT NULL,
store_name VARCHAR2(254 char),
unit_count NUMBER(14, 4),
unit_cost NUMBER(17, 6),
user_name VARCHAR2(30 char) NOT NULL,
"comment" VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_rpt_fifo PRIMARY KEY (organization_id, item_id, rtl_loc_id, user_name) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON rpt_fifo TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE rpt_fifo_detail --- ');
CREATE TABLE rpt_fifo_detail(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
description VARCHAR2(254 char),
style_id VARCHAR2(60 char),
style_desc VARCHAR2(254 char),
rtl_loc_id NUMBER(10, 0) NOT NULL,
store_name VARCHAR2(254 char),
invctl_doc_id VARCHAR2(60 char) NOT NULL,
invctl_doc_line_nbr NUMBER(10, 0) NOT NULL,
user_name VARCHAR2(30 char) NOT NULL,
invctl_doc_create_date TIMESTAMP(6),
unit_count NUMBER(14, 4),
current_unit_count NUMBER(14, 4),
unit_cost NUMBER(17, 6),
unit_count_a NUMBER(14, 4),
current_cost NUMBER(17, 6),
"comment" VARCHAR2(254 char),
pending_count NUMBER(14, 4),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_rpt_fifo_detail PRIMARY KEY (organization_id, item_id, rtl_loc_id, invctl_doc_id, invctl_doc_line_nbr, user_name) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON rpt_fifo_detail TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE rpt_flash_sales --- ');
CREATE TABLE rpt_flash_sales(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
line_enum VARCHAR2(30 char) NOT NULL,
line_count NUMBER(11, 4),
line_amt NUMBER(17, 6),
foreign_amt NUMBER(17, 6),
currency_id VARCHAR2(3 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_rpt_flash_sales PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, line_enum) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON rpt_flash_sales TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE rpt_flash_sales_goal --- ');
CREATE TABLE rpt_flash_sales_goal(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
sales_goal NUMBER(17, 6),
sales_last_year NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_rpt_flash_sales_goal PRIMARY KEY (organization_id, rtl_loc_id, business_date) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON rpt_flash_sales_goal TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE rpt_item_price --- ');
CREATE TABLE rpt_item_price(
organization_id NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char) NOT NULL,
regular_price NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_rpt_item_price PRIMARY KEY (organization_id, item_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON rpt_item_price TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE rpt_merchlvl1_sales --- ');
CREATE TABLE rpt_merchlvl1_sales(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
merch_level_1 VARCHAR2(60 char) NOT NULL,
line_count NUMBER(11, 4),
line_amt NUMBER(17, 6),
gross_amt NUMBER(17, 6),
currency_id VARCHAR2(3 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_rpt_merchlvl1_sales PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, merch_level_1) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON rpt_merchlvl1_sales TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE rpt_organizer --- ');
CREATE TABLE rpt_organizer(
organization_id NUMBER(10, 0) NOT NULL,
report_name VARCHAR2(100 char) NOT NULL,
report_group VARCHAR2(100 char) NOT NULL,
report_element VARCHAR2(200 char) NOT NULL,
report_order NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_rpt_organizer PRIMARY KEY (organization_id, report_name, report_group, report_element) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON rpt_organizer TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('rpt_organizer');
EXEC dbms_output.put_line('--- CREATING TABLE rpt_sale_line --- ');
CREATE TABLE rpt_sale_line(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
quantity NUMBER(11, 4),
actual_quantity NUMBER(11, 4),
gross_quantity NUMBER(11, 4),
unit_price NUMBER(17, 6),
net_amt NUMBER(17, 6),
gross_amt NUMBER(17, 6),
currency_id VARCHAR2(3 char),
item_id VARCHAR2(60 char),
item_desc VARCHAR2(254 char),
merch_level_1 VARCHAR2(60 char),
serial_nbr VARCHAR2(60 char),
return_flag NUMBER(1, 0) DEFAULT 0,
override_amt NUMBER(17, 6),
trans_timestamp TIMESTAMP(6),
discount_amt NUMBER(17, 6),
cust_party_id NUMBER(19, 0),
last_name VARCHAR2(254 char),
first_name VARCHAR2(254 char),
trans_statcode VARCHAR2(60 char),
sale_lineitm_typcode VARCHAR2(60 char),
begin_time_int NUMBER(10, 0),
regular_base_price NUMBER(17, 6),
exclude_from_net_sales_flag NUMBER(1, 0) DEFAULT 0,
trans_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_rpt_sale_line PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON rpt_sale_line TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_RPT_SALE_LINE01 --- ');
CREATE INDEX IDX_RPT_SALE_LINE01 ON rpt_sale_line(trans_seq, business_date, rtl_loc_id, wkstn_id, organization_id, rtrans_lineitm_seq)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_RPT_SALE_LINE02 --- ');
CREATE INDEX IDX_RPT_SALE_LINE02 ON rpt_sale_line(cust_party_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_RPT_SALE_LINE03 --- ');
CREATE INDEX IDX_RPT_SALE_LINE03 ON rpt_sale_line(organization_id, UPPER(trans_statcode), business_date, rtl_loc_id, wkstn_id, trans_seq, rtrans_lineitm_seq, quantity, net_amt)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_RPT_SALE_LINE04 --- ');
CREATE INDEX IDX_RPT_SALE_LINE04 ON rpt_sale_line(trans_date)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING TABLE rpt_sales_by_hour --- ');
CREATE TABLE rpt_sales_by_hour(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
hour NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
trans_count NUMBER(10, 0),
qty NUMBER(11, 4),
net_sales NUMBER(17, 6),
gross_sales NUMBER(17, 6),
currency_id VARCHAR2(3 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_rpt_sales_by_hour PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, hour, business_date) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON rpt_sales_by_hour TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE sch_emp_time_off --- ');
CREATE TABLE sch_emp_time_off(
organization_id NUMBER(10, 0) NOT NULL,
employee_id VARCHAR2(60 char) NOT NULL,
time_off_seq NUMBER(19, 0) NOT NULL,
start_datetime TIMESTAMP(6),
end_datetime TIMESTAMP(6),
reason_code VARCHAR2(30 char),
void_flag NUMBER(1, 0) DEFAULT 0,
time_off_typcode VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_sch_emp_time_off PRIMARY KEY (organization_id, employee_id, time_off_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sch_emp_time_off TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('sch_emp_time_off');
EXEC dbms_output.put_line('--- CREATING TABLE sch_schedule --- ');
CREATE TABLE sch_schedule(
organization_id NUMBER(10, 0) NOT NULL,
employee_id VARCHAR2(60 char) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
schedule_seq NUMBER(19, 0) NOT NULL,
work_code VARCHAR2(30 char),
start_time TIMESTAMP(6),
end_time TIMESTAMP(6),
void_flag NUMBER(1, 0) DEFAULT 0,
break_duration NUMBER(19, 0),
schedule_duration NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_sch_schedule PRIMARY KEY (organization_id, employee_id, business_date, schedule_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sch_schedule TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('sch_schedule');
EXEC dbms_output.put_line('--- CREATING TABLE sch_shift --- ');
CREATE TABLE sch_shift(
organization_id NUMBER(10, 0) NOT NULL,
shift_id NUMBER(19, 0) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
name VARCHAR2(60 char),
description VARCHAR2(254 char),
work_code VARCHAR2(30 char),
start_time TIMESTAMP(6),
end_time TIMESTAMP(6),
void_flag NUMBER(1, 0) DEFAULT 0,
break_duration NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_sch_shift PRIMARY KEY (organization_id, shift_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sch_shift TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_SCH_SHIFT_ORGNODE --- ');
CREATE INDEX IDX_SCH_SHIFT_ORGNODE ON sch_shift(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('sch_shift');
EXEC dbms_output.put_line('--- CREATING TABLE sec_access_types --- ');
CREATE TABLE sec_access_types(
organization_id NUMBER(10, 0) NOT NULL,
secured_object_id VARCHAR2(30 char) NOT NULL,
access_typcode VARCHAR2(30 char) NOT NULL,
group_membership CLOB NOT NULL,
no_access_settings VARCHAR2(30 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_sec_access_types PRIMARY KEY (organization_id, secured_object_id, access_typcode) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sec_access_types TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('sec_access_types');
EXEC dbms_output.put_line('--- CREATING TABLE sec_acl --- ');
CREATE TABLE sec_acl(
organization_id NUMBER(10, 0) NOT NULL,
secured_object_id VARCHAR2(30 char) NOT NULL,
authentication_req_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_sec_acl PRIMARY KEY (organization_id, secured_object_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sec_acl TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('sec_acl');
EXEC dbms_output.put_line('--- CREATING TABLE sec_activity_log --- ');
CREATE TABLE sec_activity_log(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
business_date TIMESTAMP(6),
trans_seq NUMBER(19, 0),
activity_typcode VARCHAR2(30 char) NOT NULL,
success_flag NUMBER(1, 0),
employee_id VARCHAR2(60 char),
overriding_employee_id VARCHAR2(60 char),
privilege_type VARCHAR2(255 char),
system_datetime TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char)
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sec_activity_log TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE sec_group_roles --- ');
CREATE TABLE sec_group_roles(
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
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sec_group_roles TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE sec_groups --- ');
CREATE TABLE sec_groups(
organization_id NUMBER(10, 0) NOT NULL,
group_id VARCHAR2(60 char) NOT NULL,
description VARCHAR2(254 char),
bitmap_position NUMBER(10, 0) NOT NULL,
group_rank NUMBER(10, 0),
config_element VARCHAR2(200 char) DEFAULT '*' NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_sec_groups PRIMARY KEY (organization_id, group_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sec_groups TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('sec_groups');
EXEC dbms_output.put_line('--- CREATING TABLE sec_password --- ');
CREATE TABLE sec_password(
organization_id NUMBER(10, 0) NOT NULL,
password_id NUMBER(10, 0) NOT NULL,
password VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_sec_password PRIMARY KEY (organization_id, password_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sec_password TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE sec_privilege --- ');
CREATE TABLE sec_privilege(
organization_id NUMBER(10, 0) NOT NULL,
privilege_type VARCHAR2(60 char) NOT NULL,
authentication_req NUMBER(1, 0) DEFAULT 0,
description VARCHAR2(254 char),
overridable_flag NUMBER(1, 0) DEFAULT 0,
group_membership CLOB NOT NULL,
second_prompt_settings VARCHAR2(30 char),
second_prompt_req_diff_emp NUMBER(1, 0) DEFAULT 0 NOT NULL,
second_prompt_group_membership CLOB,
config_element VARCHAR2(200 char) DEFAULT '*' NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_sec_privilege PRIMARY KEY (organization_id, privilege_type) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sec_privilege TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('sec_privilege');
EXEC dbms_output.put_line('--- CREATING TABLE sec_service_credentials --- ');
CREATE TABLE sec_service_credentials(
organization_id NUMBER(10, 0) NOT NULL,
service_id VARCHAR2(60 char) NOT NULL,
effective_date TIMESTAMP(6) NOT NULL,
expiration_date TIMESTAMP(6),
user_name VARCHAR2(1024 char) NOT NULL,
password VARCHAR2(1024 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_sec_service_credentials PRIMARY KEY (organization_id, service_id, effective_date) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sec_service_credentials TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('sec_service_credentials');
EXEC dbms_output.put_line('--- CREATING TABLE sec_token_signing_data --- ');
CREATE TABLE sec_token_signing_data(
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
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sec_token_signing_data TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TOKEN_SIGNING_DATA_ID --- ');
CREATE INDEX IDX_TOKEN_SIGNING_DATA_ID ON sec_token_signing_data(organization_id, UPPER(key_id))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING TABLE sec_user_password --- ');
CREATE TABLE sec_user_password(
organization_id NUMBER(10, 0) NOT NULL,
username VARCHAR2(50 char) NOT NULL,
password_seq NUMBER(19, 0) NOT NULL,
password VARCHAR2(254 char) NOT NULL,
effective_date TIMESTAMP(6) NOT NULL,
failed_attempts NUMBER(10, 0) DEFAULT 0 NOT NULL,
locked_out_timestamp TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_sec_user_password PRIMARY KEY (organization_id, username, password_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sec_user_password TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('sec_user_password');
EXEC dbms_output.put_line('--- CREATING TABLE sec_user_role --- ');
CREATE TABLE sec_user_role(
organization_id NUMBER(10, 0) NOT NULL,
user_role_id NUMBER(10, 0) NOT NULL,
username VARCHAR2(50 char) NOT NULL,
role_code VARCHAR2(50 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_sec_user_role PRIMARY KEY (organization_id, user_role_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sec_user_role TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('sec_user_role');
EXEC dbms_output.put_line('--- CREATING TABLE sls_sales_goal --- ');
CREATE TABLE sls_sales_goal(
organization_id NUMBER(10, 0) NOT NULL,
sales_goal_id VARCHAR2(60 char) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
sales_goal_value NUMBER(17, 6) NOT NULL,
effective_date TIMESTAMP(6) NOT NULL,
end_date TIMESTAMP(6) NOT NULL,
description VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_sls_sales_goal PRIMARY KEY (organization_id, sales_goal_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON sls_sales_goal TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_SLS_SALES_GOAL_ORGNODE --- ');
CREATE INDEX IDX_SLS_SALES_GOAL_ORGNODE ON sls_sales_goal(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('sls_sales_goal');
EXEC dbms_output.put_line('--- CREATING TABLE tax_postal_code_mapping --- ');
CREATE TABLE tax_postal_code_mapping(
organization_id NUMBER(10, 0) NOT NULL,
postal_code VARCHAR2(100 char) NOT NULL,
city VARCHAR2(254 char) NOT NULL,
tax_loc_id VARCHAR2(60 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tax_postal_code_mapping PRIMARY KEY (organization_id, postal_code, city, tax_loc_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tax_postal_code_mapping TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tax_postal_code_mapping');
EXEC dbms_output.put_line('--- CREATING TABLE tax_rtl_loc_tax_mapping --- ');
CREATE TABLE tax_rtl_loc_tax_mapping(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
tax_loc_id VARCHAR2(60 char),
external_system VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tax_rtl_loc_tax_mapping PRIMARY KEY (organization_id, rtl_loc_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tax_rtl_loc_tax_mapping TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tax_rtl_loc_tax_mapping');
EXEC dbms_output.put_line('--- CREATING TABLE tax_tax_authority --- ');
CREATE TABLE tax_tax_authority(
organization_id NUMBER(10, 0) NOT NULL,
tax_authority_id VARCHAR2(60 char) NOT NULL,
name VARCHAR2(254 char),
rounding_code VARCHAR2(30 char),
rounding_digits_quantity NUMBER(10, 0),
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
external_system VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tax_tax_authority PRIMARY KEY (organization_id, tax_authority_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tax_tax_authority TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TAX_TAX_AUTHORITY_ORGNODE --- ');
CREATE INDEX IDX_TAX_TAX_AUTHORITY_ORGNODE ON tax_tax_authority(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('tax_tax_authority');
EXEC dbms_output.put_line('--- CREATING TABLE tax_tax_bracket --- ');
CREATE TABLE tax_tax_bracket(
organization_id NUMBER(10, 0) NOT NULL,
tax_bracket_id VARCHAR2(60 char) NOT NULL,
tax_bracket_seq_nbr NUMBER(10, 0) NOT NULL,
org_code VARCHAR2(30 char) DEFAULT '*',
org_value VARCHAR2(60 char) DEFAULT '*',
tax_breakpoint NUMBER(17, 6),
tax_amount NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tax_tax_bracket PRIMARY KEY (organization_id, tax_bracket_id, tax_bracket_seq_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tax_tax_bracket TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TAX_TAX_BRACKET_ORGNODE --- ');
CREATE INDEX IDX_TAX_TAX_BRACKET_ORGNODE ON tax_tax_bracket(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('tax_tax_bracket');
EXEC dbms_output.put_line('--- CREATING TABLE tax_tax_exemption --- ');
CREATE TABLE tax_tax_exemption(
organization_id NUMBER(10, 0) NOT NULL,
tax_exemption_id VARCHAR2(60 char) NOT NULL,
party_id NUMBER(19, 0),
cert_nbr VARCHAR2(30 char),
reascode VARCHAR2(30 char),
cert_holder_name VARCHAR2(254 char),
cert_country VARCHAR2(2 char),
expiration_date TIMESTAMP(6),
cert_state VARCHAR2(30 char),
notes VARCHAR2(254 char),
address_id VARCHAR2(60 char),
phone_number VARCHAR2(32 char),
region VARCHAR2(30 char),
diplomatic_title VARCHAR2(60 char),
cert_holder_first_name VARCHAR2(60 char),
cert_holder_last_name VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tax_tax_exemption PRIMARY KEY (organization_id, tax_exemption_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tax_tax_exemption TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TAX_TAX_EXEMPTION01 --- ');
CREATE INDEX IDX_TAX_TAX_EXEMPTION01 ON tax_tax_exemption(party_id, organization_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('tax_tax_exemption');
EXEC dbms_output.put_line('--- CREATING TABLE tax_tax_group --- ');
CREATE TABLE tax_tax_group(
organization_id NUMBER(10, 0) NOT NULL,
tax_group_id VARCHAR2(60 char) NOT NULL,
name VARCHAR2(254 char),
description VARCHAR2(254 char),
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
external_system VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tax_tax_group PRIMARY KEY (organization_id, tax_group_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tax_tax_group TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TAX_TAX_GROUP_ORGNODE --- ');
CREATE INDEX IDX_TAX_TAX_GROUP_ORGNODE ON tax_tax_group(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('tax_tax_group');
EXEC dbms_output.put_line('--- CREATING TABLE tax_tax_group_mapping --- ');
CREATE TABLE tax_tax_group_mapping(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
tax_group_id VARCHAR2(60 char) NOT NULL,
customer_group_id VARCHAR2(60 char) NOT NULL,
priority NUMBER(10, 0),
new_tax_group_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tax_tax_group_mapping PRIMARY KEY (organization_id, rtl_loc_id, tax_group_id, customer_group_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tax_tax_group_mapping TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tax_tax_group_mapping');
EXEC dbms_output.put_line('--- CREATING TABLE tax_tax_group_rule --- ');
CREATE TABLE tax_tax_group_rule(
organization_id NUMBER(10, 0) NOT NULL,
tax_group_id VARCHAR2(60 char) NOT NULL,
tax_loc_id VARCHAR2(60 char) NOT NULL,
tax_rule_seq_nbr NUMBER(10, 0) NOT NULL,
tax_authority_id VARCHAR2(60 char),
name VARCHAR2(254 char),
description VARCHAR2(254 char),
compound_seq_nbr NUMBER(10, 0),
compound_flag NUMBER(1, 0) DEFAULT 0,
taxed_at_trans_level_flag NUMBER(1, 0) DEFAULT 0,
tax_typcode VARCHAR2(30 char),
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
external_system VARCHAR2(60 char),
fiscal_tax_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tax_tax_group_rule PRIMARY KEY (organization_id, tax_group_id, tax_loc_id, tax_rule_seq_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tax_tax_group_rule TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TAX_TAX_GROUP_RULE_ORGNODE --- ');
CREATE INDEX IDX_TAX_TAX_GROUP_RULE_ORGNODE ON tax_tax_group_rule(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('tax_tax_group_rule');
EXEC dbms_output.put_line('--- CREATING TABLE tax_tax_loc --- ');
CREATE TABLE tax_tax_loc(
organization_id NUMBER(10, 0) NOT NULL,
tax_loc_id VARCHAR2(60 char) NOT NULL,
name VARCHAR2(254 char),
description VARCHAR2(254 char),
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
external_system VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tax_tax_loc PRIMARY KEY (organization_id, tax_loc_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tax_tax_loc TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TAX_TAX_LOC_ORGNODE --- ');
CREATE INDEX IDX_TAX_TAX_LOC_ORGNODE ON tax_tax_loc(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('tax_tax_loc');
EXEC dbms_output.put_line('--- CREATING TABLE tax_tax_rate_rule --- ');
CREATE TABLE tax_tax_rate_rule(
organization_id NUMBER(10, 0) NOT NULL,
tax_group_id VARCHAR2(60 char) NOT NULL,
tax_loc_id VARCHAR2(60 char) NOT NULL,
tax_rule_seq_nbr NUMBER(10, 0) NOT NULL,
tax_rate_rule_seq NUMBER(10, 0) NOT NULL,
tax_bracket_id VARCHAR2(60 char),
tax_rate_min_taxable_amt NUMBER(17, 6),
effective_datetime TIMESTAMP(6),
expr_datetime TIMESTAMP(6),
percentage NUMBER(8, 6),
amt NUMBER(17, 6),
daily_start_time TIMESTAMP(6),
daily_end_time TIMESTAMP(6),
tax_rate_max_taxable_amt NUMBER(17, 6),
breakpoint_typcode VARCHAR2(30 char),
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
external_system VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tax_tax_rate_rule PRIMARY KEY (organization_id, tax_group_id, tax_loc_id, tax_rule_seq_nbr, tax_rate_rule_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tax_tax_rate_rule TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX XST_TAX_RATERULE_EXPR --- ');
CREATE INDEX XST_TAX_RATERULE_EXPR ON tax_tax_rate_rule(organization_id, tax_group_id, tax_rule_seq_nbr, tax_loc_id, expr_datetime)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TAX_TAX_RATE_RULE_ORGNODE --- ');
CREATE INDEX IDX_TAX_TAX_RATE_RULE_ORGNODE ON tax_tax_rate_rule(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('tax_tax_rate_rule');
EXEC dbms_output.put_line('--- CREATING TABLE tax_tax_rate_rule_override --- ');
CREATE TABLE tax_tax_rate_rule_override(
organization_id NUMBER(10, 0) NOT NULL,
tax_group_id VARCHAR2(60 char) NOT NULL,
tax_loc_id VARCHAR2(60 char) NOT NULL,
tax_rule_seq_nbr NUMBER(10, 0) NOT NULL,
tax_rate_rule_seq NUMBER(10, 0) NOT NULL,
expr_datetime TIMESTAMP(6) NOT NULL,
effective_datetime TIMESTAMP(6),
tax_bracket_id VARCHAR2(60 char),
percentage NUMBER(8, 6),
amt NUMBER(17, 6),
daily_start_time TIMESTAMP(6),
daily_end_time TIMESTAMP(6),
tax_rate_min_taxable_amt NUMBER(17, 6),
tax_rate_max_taxable_amt NUMBER(17, 6),
breakpoint_typcode VARCHAR2(30 char),
org_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
org_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_taxtaxrateruleoverride PRIMARY KEY (organization_id, tax_group_id, tax_loc_id, tax_rule_seq_nbr, tax_rate_rule_seq, expr_datetime) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tax_tax_rate_rule_override TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDXTAXTAXRULEOVERRIDEORGNODE --- ');
CREATE INDEX IDXTAXTAXRULEOVERRIDEORGNODE ON tax_tax_rate_rule_override(UPPER(org_code), UPPER(org_value))
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('tax_tax_rate_rule_override');
EXEC dbms_output.put_line('--- CREATING TABLE thr_payroll --- ');
CREATE TABLE thr_payroll(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
party_id NUMBER(19, 0) NOT NULL,
payroll_category VARCHAR2(30 char) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
hours_count NUMBER(11, 4),
posted_flag NUMBER(1, 0) DEFAULT 0,
posted_date TIMESTAMP(6),
payroll_status VARCHAR2(30 char),
reviewed_date TIMESTAMP(6),
pay_code VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_thr_payroll PRIMARY KEY (organization_id, rtl_loc_id, party_id, payroll_category, business_date) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON thr_payroll TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('thr_payroll');
EXEC dbms_output.put_line('--- CREATING TABLE thr_payroll_category --- ');
CREATE TABLE thr_payroll_category(
organization_id NUMBER(10, 0) NOT NULL,
payroll_category VARCHAR2(30 char) NOT NULL,
description VARCHAR2(254 char),
sort_order NUMBER(10, 0),
include_in_overtime_flag NUMBER(1, 0) DEFAULT 0,
working_category_flag NUMBER(1, 0) DEFAULT 0,
pay_code VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_thr_payroll_category PRIMARY KEY (organization_id, payroll_category) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON thr_payroll_category TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('thr_payroll_category');
EXEC dbms_output.put_line('--- CREATING TABLE thr_payroll_header --- ');
CREATE TABLE thr_payroll_header(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
party_id NUMBER(19, 0) NOT NULL,
week_ending_date TIMESTAMP(6) NOT NULL,
reviewed_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_thr_payroll_header PRIMARY KEY (organization_id, rtl_loc_id, party_id, week_ending_date) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON thr_payroll_header TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('thr_payroll_header');
EXEC dbms_output.put_line('--- CREATING TABLE thr_payroll_notes --- ');
CREATE TABLE thr_payroll_notes(
organization_id NUMBER(10, 0) NOT NULL,
party_id NUMBER(19, 0) NOT NULL,
week_ending_date TIMESTAMP(6) NOT NULL,
note_seq NUMBER(19, 0) NOT NULL,
note_text CLOB,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_thr_payroll_notes PRIMARY KEY (organization_id, party_id, week_ending_date, note_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON thr_payroll_notes TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('thr_payroll_notes');
EXEC dbms_output.put_line('--- CREATING TABLE thr_timecard_entry --- ');
CREATE TABLE thr_timecard_entry(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
party_id NUMBER(19, 0) NOT NULL,
timecard_entry_id NUMBER(10, 0) NOT NULL,
clock_in_timestamp TIMESTAMP(6),
clock_out_timestamp TIMESTAMP(6),
work_code VARCHAR2(30 char),
open_record_flag NUMBER(1, 0) DEFAULT 0,
entry_type_enum VARCHAR2(30 char),
delete_flag NUMBER(1, 0) DEFAULT 0,
duration NUMBER(19, 0),
payroll_update_required NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_thr_timecard_entry PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, party_id, timecard_entry_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON thr_timecard_entry TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('thr_timecard_entry');
EXEC dbms_output.put_line('--- CREATING TABLE thr_timecard_entry_comment --- ');
CREATE TABLE thr_timecard_entry_comment(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
party_id NUMBER(19, 0) NOT NULL,
week_ending_date TIMESTAMP(6) NOT NULL,
comment_seq NUMBER(19, 0) NOT NULL,
comment_text CLOB,
comment_timestamp TIMESTAMP(6),
creator_id VARCHAR2(254 char),
business_date TIMESTAMP(6),
timecard_entry_id NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_thrtimecardentrycomment PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, party_id, week_ending_date, comment_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON thr_timecard_entry_comment TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('thr_timecard_entry_comment');
EXEC dbms_output.put_line('--- CREATING TABLE thr_timecard_journal --- ');
CREATE TABLE thr_timecard_journal(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) DEFAULT 0 NOT NULL,
party_id NUMBER(19, 0) NOT NULL,
timecard_entry_id NUMBER(10, 0) NOT NULL,
timecard_entry_seq NUMBER(19, 0) NOT NULL,
clock_in_timestamp TIMESTAMP(6),
clock_out_timestamp TIMESTAMP(6),
work_code VARCHAR2(30 char),
entry_type_enum VARCHAR2(30 char),
delete_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_thr_timecard_journal PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, party_id, timecard_entry_id, timecard_entry_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON thr_timecard_journal TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('thr_timecard_journal');
EXEC dbms_output.put_line('--- CREATING TABLE thr_timeclk_trans --- ');
CREATE TABLE thr_timeclk_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
timecard_entry_wkstn_id NUMBER(19, 0),
work_code VARCHAR2(30 char),
timeclk_entry_code VARCHAR2(30 char),
party_id NUMBER(19, 0),
timecard_entry_id NUMBER(10, 0),
timecard_entry_seq NUMBER(19, 0),
timecard_entry_business_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_thr_timeclk_trans PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON thr_timeclk_trans TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE tnd_exchange_rate --- ');
CREATE TABLE tnd_exchange_rate(
organization_id NUMBER(10, 0) NOT NULL,
base_currency VARCHAR2(3 char) NOT NULL,
target_currency VARCHAR2(3 char) NOT NULL,
level_code VARCHAR2(30 char) DEFAULT '*' NOT NULL,
level_value VARCHAR2(60 char) DEFAULT '*' NOT NULL,
rate NUMBER(17, 6),
print_as_inverted NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tnd_exchange_rate PRIMARY KEY (organization_id, base_currency, target_currency, level_code, level_value) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tnd_exchange_rate TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tnd_exchange_rate');
EXEC dbms_output.put_line('--- CREATING TABLE tnd_pbl_adyen_result --- ');
CREATE TABLE tnd_pbl_adyen_result(
organization_id NUMBER(10, 0) NOT NULL,
psp_reference VARCHAR2(30 char) NOT NULL,
is_live_auth NUMBER(1, 0) DEFAULT 0,
event_code VARCHAR2(60 char),
event_date TIMESTAMP(6),
merchant_account_code VARCHAR2(254 char),
merchant_reference VARCHAR2(60 char),
original_psp_reference VARCHAR2(30 char),
payment_method VARCHAR2(60 char),
payment_amount NUMBER(17, 6),
currency_id VARCHAR2(3 char),
success NUMBER(1, 0),
reason_code VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tnd_pbl_adyen_result PRIMARY KEY (organization_id, psp_reference) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tnd_pbl_adyen_result TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tnd_pbl_adyen_result');
EXEC dbms_output.put_line('--- CREATING TABLE tnd_tndr --- ');
CREATE TABLE tnd_tndr(
organization_id NUMBER(10, 0) NOT NULL,
tndr_id VARCHAR2(60 char) NOT NULL,
tndr_typcode VARCHAR2(30 char),
currency_id VARCHAR2(3 char) NOT NULL,
description VARCHAR2(254 char),
display_order NUMBER(10, 0),
flash_sales_display_order NUMBER(10, 0),
disabled_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tnd_tndr PRIMARY KEY (organization_id, tndr_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tnd_tndr TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tnd_tndr');
EXEC dbms_output.put_line('--- CREATING TABLE tnd_tndr_availability --- ');
CREATE TABLE tnd_tndr_availability(
organization_id NUMBER(10, 0) NOT NULL,
tndr_id VARCHAR2(60 char) NOT NULL,
availability_code VARCHAR2(30 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tnd_tndr_availability PRIMARY KEY (organization_id, tndr_id, availability_code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tnd_tndr_availability TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tnd_tndr_availability');
EXEC dbms_output.put_line('--- CREATING TABLE tnd_tndr_denomination --- ');
CREATE TABLE tnd_tndr_denomination(
organization_id NUMBER(10, 0) NOT NULL,
tndr_id VARCHAR2(60 char) NOT NULL,
denomination_id VARCHAR2(60 char) NOT NULL,
description VARCHAR2(254 char),
value NUMBER(17, 6),
sort_order NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tnd_tndr_denomination PRIMARY KEY (organization_id, tndr_id, denomination_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tnd_tndr_denomination TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tnd_tndr_denomination');
EXEC dbms_output.put_line('--- CREATING TABLE tnd_tndr_options --- ');
CREATE TABLE tnd_tndr_options(
organization_id NUMBER(10, 0) NOT NULL,
tndr_id VARCHAR2(60 char) NOT NULL,
config_element VARCHAR2(200 char) DEFAULT '*' NOT NULL,
auth_mthd_code VARCHAR2(30 char),
serial_id_nbr_req_flag NUMBER(1, 0) DEFAULT 0,
auth_req_flag NUMBER(1, 0) DEFAULT 0,
auth_expr_date_req_flag NUMBER(1, 0) DEFAULT 0,
pin_req_flag NUMBER(1, 0) DEFAULT 0,
cust_sig_req_flag NUMBER(1, 0) DEFAULT 0,
endorsement_req_flag NUMBER(1, 0) DEFAULT 0,
open_cash_drawer_req_flag NUMBER(1, 0) DEFAULT 0,
unit_count_req_code VARCHAR2(30 char),
mag_swipe_reader_req_flag NUMBER(1, 0) DEFAULT 0,
dflt_to_amt_due_flag NUMBER(1, 0) DEFAULT 0,
min_denomination_amt NUMBER(17, 6),
reporting_group VARCHAR2(30 char),
effective_date TIMESTAMP(6),
expr_date TIMESTAMP(6),
min_days_for_return NUMBER(10, 0),
max_days_for_return NUMBER(10, 0),
cust_id_req_code VARCHAR2(30 char),
cust_association_flag NUMBER(1, 0) DEFAULT 0,
populate_system_count_flag NUMBER(1, 0) DEFAULT 0,
include_in_type_count_flag NUMBER(1, 0) DEFAULT 0,
suggested_deposit_threshold NUMBER(17, 6),
suggest_deposit_flag NUMBER(1, 0) DEFAULT 0,
change_tndr_id VARCHAR2(60 char),
cash_change_limit NUMBER(17, 6),
over_tender_overridable_flag NUMBER(1, 0) DEFAULT 0,
non_voidable_flag NUMBER(1, 0) DEFAULT 0,
disallow_split_tndr_flag NUMBER(1, 0) DEFAULT 0,
close_count_disc_threshold NUMBER(17, 6),
cid_msr_req_flag NUMBER(1, 0) DEFAULT 0,
cid_keyed_req_flag NUMBER(1, 0) DEFAULT 0,
postal_code_req_flag NUMBER(1, 0) DEFAULT 0,
post_void_open_drawer_flag NUMBER(1, 0) DEFAULT 0,
change_allowed_when_foreign NUMBER(1, 0) DEFAULT 0,
fiscal_tndr_id VARCHAR2(60 char),
rounding_mode VARCHAR2(254 char),
assign_cash_drawer_req_flag NUMBER(1, 0) DEFAULT 0,
post_void_assign_drawer_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tnd_tndr_options PRIMARY KEY (organization_id, tndr_id, config_element) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tnd_tndr_options TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tnd_tndr_options');
EXEC dbms_output.put_line('--- CREATING TABLE tnd_tndr_typcode --- ');
CREATE TABLE tnd_tndr_typcode(
organization_id NUMBER(10, 0) NOT NULL,
tndr_typcode VARCHAR2(30 char) NOT NULL,
description VARCHAR2(254 char),
sort_order NUMBER(10, 0),
unit_count_req_code VARCHAR2(30 char),
close_count_disc_threshold NUMBER(17, 6),
hidden_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tnd_tndr_typcode PRIMARY KEY (organization_id, tndr_typcode) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tnd_tndr_typcode TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tnd_tndr_typcode');
EXEC dbms_output.put_line('--- CREATING TABLE tnd_tndr_user_settings --- ');
CREATE TABLE tnd_tndr_user_settings(
organization_id NUMBER(10, 0) NOT NULL,
tndr_id VARCHAR2(60 char) NOT NULL,
group_id VARCHAR2(60 char) NOT NULL,
usage_code VARCHAR2(30 char) NOT NULL,
entry_mthd_code VARCHAR2(60 char) DEFAULT 'DEFAULT' NOT NULL,
config_element VARCHAR2(200 char) DEFAULT '*' NOT NULL,
online_floor_approval_amt NUMBER(17, 6),
online_ceiling_approval_amt NUMBER(17, 6),
over_tndr_limit NUMBER(17, 6),
offline_floor_approval_amt NUMBER(17, 6),
offline_ceiling_approval_amt NUMBER(17, 6),
min_accept_amt NUMBER(17, 6),
max_accept_amt NUMBER(17, 6),
max_refund_with_receipt NUMBER(17, 6),
max_refund_wo_receipt NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tnd_tndr_user_settings PRIMARY KEY (organization_id, tndr_id, group_id, usage_code, entry_mthd_code, config_element) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tnd_tndr_user_settings TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tnd_tndr_user_settings');
EXEC dbms_output.put_line('--- CREATING TABLE trl_ar_sale_lineitm --- ');
CREATE TABLE trl_ar_sale_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
acct_nbr VARCHAR2(60 char),
auth_mthd_code VARCHAR2(30 char),
adjudication_code VARCHAR2(30 char),
entry_mthd_code VARCHAR2(30 char),
auth_code VARCHAR2(30 char),
activity_code VARCHAR2(30 char),
reference_nbr VARCHAR2(254 char),
acct_user_id VARCHAR2(30 char),
acct_user_name VARCHAR2(254 char),
orig_transmission_date_time VARCHAR2(20 char),
orig_stan VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_ar_sale_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_ar_sale_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE trl_commission_mod --- ');
CREATE TABLE trl_commission_mod(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
commission_mod_seq_nbr NUMBER(10, 0) NOT NULL,
typcode VARCHAR2(30 char),
amt NUMBER(17, 6),
percentage NUMBER(6, 4),
percentage_of_item NUMBER(6, 4),
employee_party_id NUMBER(19, 0),
unverifiable_emp_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_commission_mod PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, commission_mod_seq_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_commission_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_commission_mod');
EXEC dbms_output.put_line('--- CREATING TABLE trl_correction_mod --- ');
CREATE TABLE trl_correction_mod(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
original_rtl_loc_id NUMBER(10, 0),
original_wkstn_id NUMBER(19, 0),
original_business_date TIMESTAMP(6),
original_trans_seq NUMBER(19, 0),
original_rtrans_lineitm_seq NUMBER(10, 0),
reascode VARCHAR2(30 char),
notes VARCHAR2(254 char),
original_base_unit_amt NUMBER(17, 6),
original_base_extended_amt NUMBER(17, 6),
original_unit_amt NUMBER(17, 6),
original_extended_amt NUMBER(17, 6),
original_tax_amt NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_correction_mod PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_correction_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_correction_mod');
EXEC dbms_output.put_line('--- CREATING TABLE trl_coupon_lineitm --- ');
CREATE TABLE trl_coupon_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
coupon_id VARCHAR2(254 char),
typcode VARCHAR2(30 char),
serialized_flag NUMBER(1, 0) DEFAULT 0,
expr_date TIMESTAMP(6),
entry_mthd_code VARCHAR2(30 char),
manufacturer_id VARCHAR2(254 char),
value_code VARCHAR2(30 char),
manufacturer_family_code VARCHAR2(254 char),
amt_entered NUMBER(17, 6),
authorized_flag NUMBER(1, 0) DEFAULT 0,
redemption_trans_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_coupon_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_coupon_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE trl_cust_item_acct_mod --- ');
CREATE TABLE trl_cust_item_acct_mod(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
cust_acct_id VARCHAR2(60 char),
cust_acct_code VARCHAR2(30 char),
item_acct_extended_price NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_cust_item_acct_mod PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_cust_item_acct_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_cust_item_acct_mod');
EXEC dbms_output.put_line('--- CREATING TABLE trl_deal_lineitm --- ');
CREATE TABLE trl_deal_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
amt NUMBER(17, 6),
deal_id VARCHAR2(60 char) NOT NULL,
discount_reascode VARCHAR2(30 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_deal_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_deal_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE trl_dimension_mod --- ');
CREATE TABLE trl_dimension_mod(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
dimension_code VARCHAR2(30 char) NOT NULL,
value VARCHAR2(256 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_dimension_mod PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, dimension_code) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_dimension_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_dimension_mod');
EXEC dbms_output.put_line('--- CREATING TABLE trl_discount_lineitm --- ');
CREATE TABLE trl_discount_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
discount_code VARCHAR2(60 char),
percentage NUMBER(6, 4),
amt NUMBER(17, 6),
serial_number VARCHAR2(254 char),
new_price_quantity NUMBER(11, 4),
new_price NUMBER(17, 6),
taxability_code VARCHAR2(30 char),
award_trans_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_discount_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_discount_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE trl_escrow_trans --- ');
CREATE TABLE trl_escrow_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
escrow_amt NUMBER(17, 6),
cust_party_id NUMBER(19, 0),
cust_acct_id VARCHAR2(60 char),
activity_seq_nbr NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_escrow_trans PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_escrow_trans TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE trl_invctl_document_mod --- ');
CREATE TABLE trl_invctl_document_mod(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
invctl_document_mod_seq NUMBER(10, 0) NOT NULL,
invctl_document_id VARCHAR2(60 char),
document_typcode VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_invctl_document_mod PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, invctl_document_mod_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_invctl_document_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_invctl_document_mod');
EXEC dbms_output.put_line('--- CREATING TABLE trl_inventory_loc_mod --- ');
CREATE TABLE trl_inventory_loc_mod(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
mod_seq NUMBER(10, 0) NOT NULL,
serial_nbr VARCHAR2(254 char),
source_location_id VARCHAR2(60 char),
source_bucket_id VARCHAR2(60 char),
dest_location_id VARCHAR2(60 char),
dest_bucket_id VARCHAR2(60 char),
quantity NUMBER(11, 4),
action_code VARCHAR2(30 char),
void_flag NUMBER(1, 0) DEFAULT 0,
item_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_inventory_loc_mod PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, mod_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_inventory_loc_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_inventory_loc_mod');
EXEC dbms_output.put_line('--- CREATING TABLE trl_kit_component_mod --- ');
CREATE TABLE trl_kit_component_mod(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
component_item_id VARCHAR2(60 char) NOT NULL,
seq_nbr NUMBER(10, 0) DEFAULT 1 NOT NULL,
component_item_desc VARCHAR2(254 char),
display_order NUMBER(10, 0),
quantity NUMBER(10, 0),
kit_item_id VARCHAR2(60 char),
serial_nbr VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_kit_component_mod PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, component_item_id, seq_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_kit_component_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_kit_component_mod');
EXEC dbms_output.put_line('--- CREATING TABLE trl_lineitm_assoc_mod --- ');
CREATE TABLE trl_lineitm_assoc_mod(
organization_id NUMBER(10, 0) NOT NULL,
parent_rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
parent_rtl_loc_id NUMBER(10, 0) NOT NULL,
parent_business_date TIMESTAMP(6) NOT NULL,
parent_wkstn_id NUMBER(19, 0) NOT NULL,
parent_trans_seq NUMBER(19, 0) NOT NULL,
lineitm_assoc_mod_seq NUMBER(10, 0) NOT NULL,
lineitm_assoc_typcode VARCHAR2(30 char),
child_rtrans_lineitm_seq NUMBER(10, 0),
child_rtl_loc_id NUMBER(10, 0),
child_wkstn_id NUMBER(19, 0),
child_business_date TIMESTAMP(6),
child_trans_seq NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_lineitm_assoc_mod PRIMARY KEY (organization_id, parent_rtrans_lineitm_seq, parent_rtl_loc_id, parent_business_date, parent_wkstn_id, parent_trans_seq, lineitm_assoc_mod_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_lineitm_assoc_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_lineitm_assoc_mod');
EXEC dbms_output.put_line('--- CREATING TABLE trl_lineitm_assoc_typcode --- ');
CREATE TABLE trl_lineitm_assoc_typcode(
organization_id NUMBER(10, 0) NOT NULL,
lineitm_assoc_typcode VARCHAR2(30 char) NOT NULL,
description VARCHAR2(254 char),
sort_order NUMBER(10, 0),
parent_restrict_quantity_flag NUMBER(1, 0) DEFAULT 0,
child_restrict_quantity_flag NUMBER(1, 0) DEFAULT 0,
parent_restrict_price_flag NUMBER(1, 0) DEFAULT 0,
child_restrict_price_flag NUMBER(1, 0) DEFAULT 0,
parent_restrict_delete_flag NUMBER(1, 0) DEFAULT 0,
child_restrict_delete_flag NUMBER(1, 0) DEFAULT 0,
cascade_delete_flag NUMBER(1, 0) DEFAULT 0,
cascade_quantity_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_lineitm_assoc_typcode PRIMARY KEY (organization_id, lineitm_assoc_typcode) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_lineitm_assoc_typcode TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_lineitm_assoc_typcode');
EXEC dbms_output.put_line('--- CREATING TABLE trl_lineitm_notes --- ');
CREATE TABLE trl_lineitm_notes(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
note_seq NUMBER(10, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
note_datetime TIMESTAMP(6),
posted_flag NUMBER(1, 0) DEFAULT 0,
note CLOB,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_lineitm_notes PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, note_seq, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_lineitm_notes TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_lineitm_notes');
EXEC dbms_output.put_line('--- CREATING TABLE trl_returned_item_count --- ');
CREATE TABLE trl_returned_item_count(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
returned_count NUMBER(11, 4),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_returned_item_count PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_returned_item_count TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_returned_item_count');
EXEC dbms_output.put_line('--- CREATING TABLE trl_returned_item_journal --- ');
CREATE TABLE trl_returned_item_journal(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
journal_seq NUMBER(19, 0) NOT NULL,
returned_count NUMBER(11, 4),
rtn_rtl_loc_id NUMBER(10, 0),
rtn_wkstn_id NUMBER(19, 0),
rtn_business_date TIMESTAMP(6),
rtn_trans_seq NUMBER(19, 0),
rtn_rtrans_lineitm_seq NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_returned_item_journal PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, journal_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_returned_item_journal TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_returned_item_journal');
EXEC dbms_output.put_line('--- CREATING TABLE trl_rtl_price_mod --- ');
CREATE TABLE trl_rtl_price_mod(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
rtl_price_mod_seq_nbr NUMBER(10, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
promotion_id VARCHAR2(60 char),
percentage NUMBER(6, 4),
amt NUMBER(17, 6),
price_change_amt NUMBER(17, 6),
notes VARCHAR2(254 char),
rtl_price_mod_reascode VARCHAR2(30 char),
void_flag NUMBER(1, 0) DEFAULT 0,
disc_rtrans_lineitm_seq NUMBER(10, 0),
disc_rtl_loc_id NUMBER(10, 0),
disc_wkstn_id NUMBER(19, 0),
disc_business_date TIMESTAMP(6),
disc_trans_seq NUMBER(19, 0),
discount_code VARCHAR2(60 char),
price_change_reascode VARCHAR2(30 char),
deal_id VARCHAR2(60 char),
deal_amt NUMBER(17, 6),
serial_number VARCHAR2(254 char),
discount_group_id NUMBER(10, 0),
description VARCHAR2(254 char),
discount_reascode VARCHAR2(30 char),
extended_amt NUMBER(17, 6),
taxability_code VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_rtl_price_mod PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, rtrans_lineitm_seq, rtl_price_mod_seq_nbr, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_rtl_price_mod TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TRL_RTL_PRICE_MOD01 --- ');
CREATE INDEX IDX_TRL_RTL_PRICE_MOD01 ON trl_rtl_price_mod(trans_seq, business_date, rtl_loc_id, wkstn_id, organization_id, rtrans_lineitm_seq, rtl_price_mod_seq_nbr)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('trl_rtl_price_mod');
EXEC dbms_output.put_line('--- CREATING TABLE trl_rtrans --- ');
CREATE TABLE trl_rtrans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
cust_party_id NUMBER(19, 0),
loyalty_card_number VARCHAR2(60 char),
tax_exemption_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_rtrans PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_rtrans TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TRL_RTRANS01 --- ');
CREATE INDEX IDX_TRL_RTRANS01 ON trl_rtrans(trans_seq, business_date, rtl_loc_id, wkstn_id, organization_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TRL_RTRANS02 --- ');
CREATE INDEX IDX_TRL_RTRANS02 ON trl_rtrans(cust_party_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING TABLE trl_rtrans_flight_info --- ');
CREATE TABLE trl_rtrans_flight_info(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
flight_number VARCHAR2(30 char) NOT NULL,
destination_airport VARCHAR2(3 char),
destination_country VARCHAR2(2 char),
destination_zone VARCHAR2(30 char),
destination_airport_name VARCHAR2(254 char),
origin_airport VARCHAR2(3 char),
tax_calculation_mode VARCHAR2(30 char),
first_flight_number VARCHAR2(30 char),
first_destination_airport VARCHAR2(3 char),
first_origin_airport VARCHAR2(3 char),
first_flight_seat_number VARCHAR2(4 char),
first_flight_scheduled_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_rtrans_flight_info PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_rtrans_flight_info TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_rtrans_flight_info');
EXEC dbms_output.put_line('--- CREATING TABLE trl_rtrans_lineitm --- ');
CREATE TABLE trl_rtrans_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
begin_date_timestamp TIMESTAMP(6),
end_date_timestamp TIMESTAMP(6),
notes VARCHAR2(254 char),
rtrans_lineitm_typcode VARCHAR2(30 char),
rtrans_lineitm_statcode VARCHAR2(30 char),
void_flag NUMBER(1, 0) DEFAULT 0,
dtv_class_name VARCHAR2(254 char),
void_lineitm_reascode VARCHAR2(30 char),
generic_storage_flag NUMBER(1, 0) DEFAULT 0,
tlog_lineitm_seq NUMBER(10, 0),
currency_id VARCHAR2(3 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_rtrans_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_rtrans_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TRL_RTRANS_LINEITM01 --- ');
CREATE INDEX IDX_TRL_RTRANS_LINEITM01 ON trl_rtrans_lineitm(trans_seq, business_date, rtl_loc_id, wkstn_id, organization_id, rtrans_lineitm_seq)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TRL_RTRANS_LINEITM02 --- ');
CREATE INDEX IDX_TRL_RTRANS_LINEITM02 ON trl_rtrans_lineitm(organization_id, void_flag, business_date)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TRL_RTRANS_LINEITM03 --- ');
CREATE INDEX IDX_TRL_RTRANS_LINEITM03 ON trl_rtrans_lineitm(organization_id, rtl_loc_id, wkstn_id, trans_seq, void_flag)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('trl_rtrans_lineitm');
EXEC dbms_output.put_line('--- CREATING TABLE trl_rtrans_serial_exchange --- ');
CREATE TABLE trl_rtrans_serial_exchange(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char),
orig_serial_nbr VARCHAR2(60 char),
new_serial_nbr VARCHAR2(60 char),
exchange_comment VARCHAR2(254 char),
exchange_reason_code VARCHAR2(30 char),
orig_lineitm_seq NUMBER(10, 0),
orig_rtl_loc_id NUMBER(10, 0),
orig_wkstn_id NUMBER(19, 0),
orig_business_date TIMESTAMP(6),
orig_trans_seq NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trlrtransserialexchange PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_rtrans_serial_exchange TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_rtrans_serial_exchange');
EXEC dbms_output.put_line('--- CREATING TABLE trl_sale_lineitm --- ');
CREATE TABLE trl_sale_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
merch_level_1 VARCHAR2(60 char),
item_id VARCHAR2(60 char),
quantity NUMBER(11, 4),
gross_quantity NUMBER(11, 4),
net_quantity NUMBER(11, 4),
unit_price NUMBER(17, 6),
extended_amt NUMBER(17, 6),
vat_amt NUMBER(17, 6),
return_flag NUMBER(1, 0) DEFAULT 0,
item_id_entry_mthd_code VARCHAR2(30 char),
price_entry_mthd_code VARCHAR2(30 char),
price_derivtn_mthd_code VARCHAR2(30 char),
price_property_code VARCHAR2(60 char),
net_amt NUMBER(17, 6),
gross_amt NUMBER(17, 6),
serial_nbr VARCHAR2(60 char),
scanned_item_id VARCHAR2(60 char),
sale_lineitm_typcode VARCHAR2(30 char),
tax_group_id VARCHAR2(60 char),
inventory_action_code VARCHAR2(30 char),
original_rtrans_lineitm_seq NUMBER(10, 0),
original_rtl_loc_id NUMBER(10, 0),
original_wkstn_id NUMBER(19, 0),
original_business_date TIMESTAMP(6),
original_trans_seq NUMBER(19, 0),
return_comment VARCHAR2(254 char),
return_reascode VARCHAR2(30 char),
return_typcode VARCHAR2(30 char),
rcpt_count NUMBER(10, 0),
base_unit_price NUMBER(17, 6),
base_extended_price NUMBER(17, 6),
force_zero_extended_amt_flag NUMBER(1, 0) DEFAULT 0,
entered_description VARCHAR2(254 char),
rpt_base_unit_price NUMBER(17, 6),
food_stamps_applied_amount NUMBER(17, 6),
vendor_id VARCHAR2(60 char),
regular_base_price NUMBER(17, 6),
shipping_weight NUMBER(12, 3),
unit_cost NUMBER(17, 6),
attached_item_flag NUMBER(1, 0),
initial_quantity NUMBER(11, 4),
not_returnable_flag NUMBER(1, 0) DEFAULT 0,
exclude_from_net_sales_flag NUMBER(1, 0) DEFAULT 0,
measure_req_flag NUMBER(1, 0) DEFAULT 0,
weight_entry_mthd_code VARCHAR2(30 char),
tare_value NUMBER(11, 4),
tare_type VARCHAR2(30 char),
tare_unit_of_measure_code VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_sale_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_sale_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TRL_SALE_LINEITM01 --- ');
CREATE INDEX IDX_TRL_SALE_LINEITM01 ON trl_sale_lineitm(trans_seq, business_date, rtl_loc_id, wkstn_id, organization_id, rtrans_lineitm_seq)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TRL_SALE_LINEITEM02 --- ');
CREATE INDEX IDX_TRL_SALE_LINEITEM02 ON trl_sale_lineitm(organization_id, business_date, UPPER(sale_lineitm_typcode))
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING TABLE trl_sale_tax_lineitm --- ');
CREATE TABLE trl_sale_tax_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
sale_tax_lineitm_seq NUMBER(10, 0) NOT NULL,
taxable_amt NUMBER(17, 6),
tax_amt NUMBER(17, 6),
tax_exempt_amt NUMBER(17, 6),
tax_loc_id VARCHAR2(60 char),
tax_group_id VARCHAR2(60 char),
tax_rule_seq_nbr NUMBER(10, 0),
tax_exemption_id VARCHAR2(60 char),
tax_override_amt NUMBER(17, 6),
tax_override_percentage NUMBER(10, 8),
tax_override_bracket_id VARCHAR2(60 char),
tax_override_flag NUMBER(1, 0) DEFAULT 0,
tax_override_reascode VARCHAR2(30 char),
void_flag NUMBER(1, 0) DEFAULT 0,
raw_tax_percentage NUMBER(10, 8),
raw_tax_amount NUMBER(17, 6),
exempt_tax_amount NUMBER(17, 6),
tax_percentage NUMBER(10, 8),
authority_id VARCHAR2(60 char),
authority_name VARCHAR2(254 char),
authority_type_code VARCHAR2(60 char),
tax_override_comment VARCHAR2(255 char),
orig_taxable_amount NUMBER(17, 6),
orig_tax_group_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_sale_tax_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, sale_tax_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_sale_tax_lineitm TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_sale_tax_lineitm');
EXEC dbms_output.put_line('--- CREATING TABLE trl_tax_lineitm --- ');
CREATE TABLE trl_tax_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
tax_rule_seq_nbr NUMBER(10, 0),
tax_group_id VARCHAR2(60 char),
taxable_amt NUMBER(17, 6),
tax_amt NUMBER(17, 6),
tax_override_flag NUMBER(1, 0) DEFAULT 0,
tax_override_amt NUMBER(17, 6),
tax_override_percentage NUMBER(10, 8),
tax_override_reascode VARCHAR2(30 char),
tax_loc_id VARCHAR2(60 char) NOT NULL,
raw_tax_percentage NUMBER(8, 6),
raw_tax_amount NUMBER(17, 6),
tax_percentage NUMBER(12, 6),
authority_id VARCHAR2(60 char),
authority_name VARCHAR2(254 char),
authority_type_code VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_tax_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_tax_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE trl_voucher_discount_lineitm --- ');
CREATE TABLE trl_voucher_discount_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
voucher_typcode VARCHAR2(30 char),
auth_mthd_code VARCHAR2(30 char),
adjudication_code VARCHAR2(30 char),
entry_mthd_code VARCHAR2(30 char),
auth_code VARCHAR2(30 char),
activity_code VARCHAR2(30 char),
reference_nbr VARCHAR2(254 char),
effective_date TIMESTAMP(6),
expr_date TIMESTAMP(6),
face_value_amt NUMBER(17, 6),
issue_datetime TIMESTAMP(6),
issue_typcode VARCHAR2(30 char),
unspent_balance_amt NUMBER(17, 6),
voucher_status_code VARCHAR2(30 char),
trace_number VARCHAR2(60 char),
orig_transmission_date_time VARCHAR2(20 char),
orig_stan VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trlvoucherdiscountlineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_voucher_discount_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE trl_voucher_sale_lineitm --- ');
CREATE TABLE trl_voucher_sale_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
voucher_typcode VARCHAR2(30 char),
auth_mthd_code VARCHAR2(30 char),
adjudication_code VARCHAR2(100 char),
entry_mthd_code VARCHAR2(30 char),
auth_code VARCHAR2(30 char),
activity_code VARCHAR2(30 char),
reference_nbr VARCHAR2(254 char),
effective_date TIMESTAMP(6),
expr_date TIMESTAMP(6),
face_value_amt NUMBER(17, 6),
issue_datetime TIMESTAMP(6),
issue_typcode VARCHAR2(30 char),
unspent_balance_amt NUMBER(17, 6),
voucher_status_code VARCHAR2(30 char),
trace_number VARCHAR2(60 char),
orig_local_date_time VARCHAR2(20 char),
orig_transmission_date_time VARCHAR2(20 char),
orig_stan VARCHAR2(60 char),
merchant_cat_code VARCHAR2(4 char),
card_type VARCHAR2(20 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_voucher_sale_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_voucher_sale_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE trl_warranty_modifier --- ');
CREATE TABLE trl_warranty_modifier(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
warranty_modifier_seq NUMBER(10, 0) NOT NULL,
warranty_nbr VARCHAR2(30 char),
warranty_typcode VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trl_warranty_modifier PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, warranty_modifier_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trl_warranty_modifier TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trl_warranty_modifier');
EXEC dbms_output.put_line('--- CREATING TABLE trn_generic_lineitm_storage --- ');
CREATE TABLE trn_generic_lineitm_storage(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
data_storage CLOB,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trngenericlineitmstorage PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_generic_lineitm_storage TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trn_generic_lineitm_storage');
EXEC dbms_output.put_line('--- CREATING TABLE trn_gift_registry_trans --- ');
CREATE TABLE trn_gift_registry_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
registry_id NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_gift_registry_trans PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_gift_registry_trans TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE trn_no_sale_trans --- ');
CREATE TABLE trn_no_sale_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
no_sale_reascode VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_no_sale_trans PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_no_sale_trans TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE trn_poslog_data --- ');
CREATE TABLE trn_poslog_data(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
poslog_bytes BLOB,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_poslog_data PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_poslog_data TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trn_poslog_data');
EXEC dbms_output.put_line('--- CREATING TABLE trn_post_void_trans --- ');
CREATE TABLE trn_post_void_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
voided_rtl_store_id NUMBER(10, 0),
voided_wkstn_id NUMBER(19, 0),
voided_business_date TIMESTAMP(6),
voided_trans_id NUMBER(19, 0),
voided_org_id NUMBER(10, 0),
post_void_reascode VARCHAR2(30 char),
voided_trans_entry_code VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_post_void_trans PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_post_void_trans TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE trn_raincheck --- ');
CREATE TABLE trn_raincheck(
organization_id NUMBER(10, 0) NOT NULL,
rain_check_id VARCHAR2(20 char) NOT NULL,
item_id VARCHAR2(60 char),
sale_price NUMBER(17, 6),
expiration_business_date TIMESTAMP(6),
redeemed_flag NUMBER(1, 0) DEFAULT 0,
rtl_loc_id NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_raincheck PRIMARY KEY (organization_id, rain_check_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_raincheck TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trn_raincheck');
EXEC dbms_output.put_line('--- CREATING TABLE trn_raincheck_trans --- ');
CREATE TABLE trn_raincheck_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rain_check_id VARCHAR2(20 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_raincheck_trans PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_raincheck_trans TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE trn_receipt_data --- ');
CREATE TABLE trn_receipt_data(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
receipt_id VARCHAR2(60 char) NOT NULL,
receipt_data BLOB,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_receipt_data PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, receipt_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_receipt_data TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trn_receipt_data');
EXEC dbms_output.put_line('--- CREATING TABLE trn_receipt_lookup --- ');
CREATE TABLE trn_receipt_lookup(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
receipt_id VARCHAR2(60 char) NOT NULL,
receipt_url VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_receipt_lookup PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq, receipt_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_receipt_lookup TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trn_receipt_lookup');
EXEC dbms_output.put_line('--- CREATING TABLE trn_report_data --- ');
CREATE TABLE trn_report_data(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(10, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
report_id VARCHAR2(60 char) NOT NULL,
report_data BLOB,
luxury_reprint_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
internal_data_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_report_data PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, report_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_report_data TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trn_report_data');
EXEC dbms_output.put_line('--- CREATING TABLE trn_reprint_receipt --- ');
CREATE TABLE trn_reprint_receipt(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
receipt_type VARCHAR2(30 char) NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_reprint_receipt PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_reprint_receipt TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE trn_reprint_receipt_dtl --- ');
CREATE TABLE trn_reprint_receipt_dtl(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
reprint_detail_seq NUMBER(10, 0) NOT NULL,
original_gift_lineitm_seq NUMBER(10, 0),
document_type VARCHAR2(30 char),
series_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_reprint_receipt_dtl PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, reprint_detail_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_reprint_receipt_dtl TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trn_reprint_receipt_dtl');
EXEC dbms_output.put_line('--- CREATING TABLE trn_temp_trans --- ');
CREATE TABLE trn_temp_trans(
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
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_temp_trans TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE trn_trans --- ');
CREATE TABLE trn_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
begin_datetime TIMESTAMP(6),
end_datetime TIMESTAMP(6),
keyed_offline_flag NUMBER(1, 0) DEFAULT 0,
session_id NUMBER(19, 0),
operator_party_id NUMBER(19, 0),
posted_flag NUMBER(1, 0) DEFAULT 0,
dtv_class_name VARCHAR2(254 char),
total NUMBER(17, 6),
taxtotal NUMBER(17, 6),
roundtotal NUMBER(17, 6),
subtotal NUMBER(17, 6),
trans_cancel_reascode VARCHAR2(30 char),
trans_typcode VARCHAR2(30 char),
trans_statcode VARCHAR2(30 char),
post_void_flag NUMBER(1, 0) DEFAULT 0,
generic_storage_flag NUMBER(1, 0) DEFAULT 0,
begin_time_int NUMBER(10, 0),
cash_drawer_id VARCHAR2(60 char),
flash_sales_flag NUMBER(1, 0) DEFAULT 0,
fiscal_number VARCHAR2(100 char),
device_id VARCHAR2(100 char),
fiscal_session_number VARCHAR2(100 char),
trans_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_trans PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_trans TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TRN_TRANS01 --- ');
CREATE INDEX IDX_TRN_TRANS01 ON trn_trans(flash_sales_flag)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TRN_TRANS02 --- ');
CREATE INDEX IDX_TRN_TRANS02 ON trn_trans(organization_id, UPPER(trans_statcode), post_void_flag, business_date)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TRN_TRANS03 --- ');
CREATE INDEX IDX_TRN_TRANS03 ON trn_trans(rtl_loc_id, business_date, UPPER(trans_typcode), UPPER(trans_statcode), post_void_flag, organization_id, wkstn_id, trans_seq)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TRN_TRANS05 --- ');
CREATE INDEX IDX_TRN_TRANS05 ON trn_trans(trans_date)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TRN_TRANS06 --- ');
CREATE INDEX IDX_TRN_TRANS06 ON trn_trans(CASE WHEN device_id IS NOT NULL THEN organization_id END, CASE WHEN device_id IS NOT NULL THEN UPPER(device_id) END, CASE WHEN device_id IS NOT NULL THEN UPPER(fiscal_session_number) END, CASE WHEN device_id IS NOT NULL THEN UPPER(fiscal_number) END)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('trn_trans');
EXEC dbms_output.put_line('--- CREATING TABLE trn_trans_attachment --- ');
CREATE TABLE trn_trans_attachment(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
attachment_type VARCHAR2(60 char) NOT NULL,
attachment_data BLOB,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_trans_attachment PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, attachment_type) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_trans_attachment TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trn_trans_attachment');
EXEC dbms_output.put_line('--- CREATING TABLE trn_trans_link --- ');
CREATE TABLE trn_trans_link(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
link_rtl_loc_id NUMBER(10, 0) NOT NULL,
link_business_date TIMESTAMP(6) NOT NULL,
link_wkstn_id NUMBER(19, 0) NOT NULL,
link_trans_seq NUMBER(19, 0) NOT NULL,
link_typcode VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_trans_link PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, link_rtl_loc_id, link_business_date, link_wkstn_id, link_trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_trans_link TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trn_trans_link');
EXEC dbms_output.put_line('--- CREATING TABLE trn_trans_notes --- ');
CREATE TABLE trn_trans_notes(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
note_seq NUMBER(10, 0) NOT NULL,
note_datetime TIMESTAMP(6),
posted_flag NUMBER(1, 0) DEFAULT 0,
note CLOB,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_trans_notes PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, note_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_trans_notes TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trn_trans_notes');
EXEC dbms_output.put_line('--- CREATING TABLE trn_trans_version --- ');
CREATE TABLE trn_trans_version(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
base_app_version VARCHAR2(30 char),
base_app_date TIMESTAMP(6),
base_schema_version VARCHAR2(30 char),
base_schema_date TIMESTAMP(6),
customer_app_version VARCHAR2(30 char),
customer_schema_version VARCHAR2(30 char),
customer_schema_date TIMESTAMP(6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_trn_trans_version PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, business_date, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON trn_trans_version TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('trn_trans_version');
EXEC dbms_output.put_line('--- CREATING TABLE tsn_safe_bag --- ');
CREATE TABLE tsn_safe_bag(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
safe_bag_id VARCHAR2(60 char) NOT NULL,
tndr_id VARCHAR2(60 char),
currency_id VARCHAR2(3 char),
bag_status VARCHAR2(30 char),
amount NUMBER(17, 6),
session_id NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsn_safe_bag PRIMARY KEY (organization_id, rtl_loc_id, safe_bag_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_safe_bag TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tsn_safe_bag');
EXEC dbms_output.put_line('--- CREATING TABLE tsn_serialized_tndr_count --- ');
CREATE TABLE tsn_serialized_tndr_count(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
tndr_typcode VARCHAR2(30 char) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
serialized_tndr_count_seq NUMBER(10, 0) NOT NULL,
tndr_id VARCHAR2(60 char),
serial_number VARCHAR2(60 char),
amt NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsn_serialized_tndr_count PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, tndr_typcode, trans_seq, serialized_tndr_count_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_serialized_tndr_count TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tsn_serialized_tndr_count');
EXEC dbms_output.put_line('--- CREATING TABLE tsn_session --- ');
CREATE TABLE tsn_session(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
session_id NUMBER(19, 0) NOT NULL,
tndr_repository_id VARCHAR2(60 char),
employee_party_id NUMBER(19, 0),
begin_datetime TIMESTAMP(6),
end_datetime TIMESTAMP(6),
business_date TIMESTAMP(6),
statcode VARCHAR2(30 char),
cash_drawer_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsn_session PRIMARY KEY (organization_id, rtl_loc_id, session_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_session TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tsn_session');
EXEC dbms_output.put_line('--- CREATING TABLE tsn_session_control_trans --- ');
CREATE TABLE tsn_session_control_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
typcode VARCHAR2(30 char),
session_wkstn_seq NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsn_session_control_trans PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_session_control_trans TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE tsn_session_tndr --- ');
CREATE TABLE tsn_session_tndr(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
tndr_id VARCHAR2(60 char) NOT NULL,
session_id NUMBER(19, 0) NOT NULL,
actual_media_count NUMBER(10, 0),
actual_media_amt NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsn_session_tndr PRIMARY KEY (organization_id, rtl_loc_id, tndr_id, session_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_session_tndr TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tsn_session_tndr');
EXEC dbms_output.put_line('--- CREATING TABLE tsn_session_wkstn --- ');
CREATE TABLE tsn_session_wkstn(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
session_id NUMBER(19, 0) NOT NULL,
session_wkstn_seq NUMBER(10, 0) NOT NULL,
wkstn_id NUMBER(19, 0),
cash_drawer_id VARCHAR2(60 char),
begin_datetime TIMESTAMP(6),
end_datetime TIMESTAMP(6),
attached_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsn_session_wkstn PRIMARY KEY (organization_id, rtl_loc_id, session_id, session_wkstn_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_session_wkstn TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tsn_session_wkstn');
EXEC dbms_output.put_line('--- CREATING TABLE tsn_till_control_trans --- ');
CREATE TABLE tsn_till_control_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
typcode VARCHAR2(30 char),
employee_id VARCHAR2(60 char),
reason_code VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsn_till_control_trans PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_till_control_trans TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE tsn_till_ctrl_trans_detail --- ');
CREATE TABLE tsn_till_ctrl_trans_detail(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
trans_lineitm_seq NUMBER(10, 0) NOT NULL,
affected_tndr_repository_id VARCHAR2(60 char),
affected_wkstn_id NUMBER(19, 0),
old_amount NUMBER(17, 6),
new_amount NUMBER(17, 6),
currency_id VARCHAR2(3 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsntillctrltransdetail PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, trans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_till_ctrl_trans_detail TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tsn_till_ctrl_trans_detail');
EXEC dbms_output.put_line('--- CREATING TABLE tsn_tndr_control_trans --- ');
CREATE TABLE tsn_tndr_control_trans(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
amt NUMBER(17, 6),
reascode VARCHAR2(30 char),
typcode VARCHAR2(30 char),
funds_receipt_party_id NUMBER(19, 0),
outbound_session_id NUMBER(19, 0),
inbound_session_id NUMBER(19, 0),
outbound_tndr_repository_id VARCHAR2(60 char),
inbound_tndr_repository_id VARCHAR2(60 char),
deposit_date TIMESTAMP(6),
safe_bag_id VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsn_tndr_control_trans PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_tndr_control_trans TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE tsn_tndr_denomination_count --- ');
CREATE TABLE tsn_tndr_denomination_count(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
tndr_typcode VARCHAR2(30 char) NOT NULL,
tndr_id VARCHAR2(60 char) NOT NULL,
denomination_id VARCHAR2(60 char) NOT NULL,
amt NUMBER(17, 6),
media_count NUMBER(10, 0),
difference_amt NUMBER(17, 6),
difference_media_count NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsntndrdenominationcount PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, tndr_typcode, tndr_id, denomination_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_tndr_denomination_count TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tsn_tndr_denomination_count');
EXEC dbms_output.put_line('--- CREATING TABLE tsn_tndr_repository --- ');
CREATE TABLE tsn_tndr_repository(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
tndr_repository_id VARCHAR2(60 char) NOT NULL,
typcode VARCHAR2(30 char),
not_issuable_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
name VARCHAR2(254 char),
description VARCHAR2(254 char),
dflt_wkstn_id NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsn_tndr_repository PRIMARY KEY (organization_id, rtl_loc_id, tndr_repository_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_tndr_repository TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tsn_tndr_repository');
EXEC dbms_output.put_line('--- CREATING TABLE tsn_tndr_repository_float --- ');
CREATE TABLE tsn_tndr_repository_float(
organization_id NUMBER(10, 0) NOT NULL,
tndr_repository_id VARCHAR2(60 char) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
currency_id VARCHAR2(3 char) NOT NULL,
default_cash_float NUMBER(17, 6),
last_closing_amount NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsn_tndr_repository_float PRIMARY KEY (organization_id, tndr_repository_id, rtl_loc_id, currency_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_tndr_repository_float TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tsn_tndr_repository_float');
EXEC dbms_output.put_line('--- CREATING TABLE tsn_tndr_repository_status --- ');
CREATE TABLE tsn_tndr_repository_status(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
tndr_repository_id VARCHAR2(60 char) NOT NULL,
issued_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
active_session_id NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsntndrrepositorystatus PRIMARY KEY (organization_id, rtl_loc_id, tndr_repository_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_tndr_repository_status TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tsn_tndr_repository_status');
EXEC dbms_output.put_line('--- CREATING TABLE tsn_tndr_tndr_count --- ');
CREATE TABLE tsn_tndr_tndr_count(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
tndr_typcode VARCHAR2(30 char) NOT NULL,
tndr_id VARCHAR2(60 char) NOT NULL,
amt NUMBER(17, 6),
media_count NUMBER(10, 0),
difference_amt NUMBER(17, 6),
difference_media_count NUMBER(10, 0),
deposit_amt NUMBER(17, 6),
local_currency_amt NUMBER(17, 6),
local_currency_difference_amt NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsn_tndr_tndr_count PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, tndr_typcode, tndr_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_tndr_tndr_count TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tsn_tndr_tndr_count');
EXEC dbms_output.put_line('--- CREATING TABLE tsn_tndr_typcode_count --- ');
CREATE TABLE tsn_tndr_typcode_count(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
tndr_typcode VARCHAR2(30 char) NOT NULL,
amt NUMBER(17, 6),
media_count NUMBER(10, 0),
difference_amt NUMBER(17, 6),
difference_media_count NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsn_tndr_typcode_count PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, tndr_typcode) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_tndr_typcode_count TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tsn_tndr_typcode_count');
EXEC dbms_output.put_line('--- CREATING TABLE tsn_xrtrans_lineitm --- ');
CREATE TABLE tsn_xrtrans_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
line_seq NUMBER(10, 0) NOT NULL,
base_currency VARCHAR2(3 char),
target_currency VARCHAR2(3 char),
old_rate NUMBER(17, 6),
new_rate NUMBER(17, 6),
notes VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_tsn_xrtrans_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, line_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON tsn_xrtrans_lineitm TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('tsn_xrtrans_lineitm');
EXEC dbms_output.put_line('--- CREATING TABLE ttr_acct_credit_tndr_lineitm --- ');
CREATE TABLE ttr_acct_credit_tndr_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
cust_acct_id VARCHAR2(60 char),
cust_acct_code VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ttracctcredittndrlineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ttr_acct_credit_tndr_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE ttr_ar_tndr_lineitm --- ');
CREATE TABLE ttr_ar_tndr_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
acct_nbr VARCHAR2(60 char),
party_id NUMBER(19, 0),
acct_user_name VARCHAR2(254 char),
approval_code VARCHAR2(30 char),
po_number VARCHAR2(254 char),
adjudication_code VARCHAR2(30 char),
auth_mthd_code VARCHAR2(30 char),
activity_code VARCHAR2(30 char),
entry_mthd_code VARCHAR2(30 char),
auth_code VARCHAR2(30 char),
acct_user_id VARCHAR2(30 char),
orig_transmission_date_time VARCHAR2(20 char),
orig_stan VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ttr_ar_tndr_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ttr_ar_tndr_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TTR_AR_TNDR_LINEITM01 --- ');
CREATE INDEX IDX_TTR_AR_TNDR_LINEITM01 ON ttr_ar_tndr_lineitm(party_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING TABLE ttr_check_tndr_lineitm --- ');
CREATE TABLE ttr_check_tndr_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
bank_id VARCHAR2(254 char),
check_acct_nbr VARCHAR2(254 char),
check_seq_nbr VARCHAR2(254 char),
adjudication_code VARCHAR2(30 char),
cust_birth_date TIMESTAMP(6),
auth_nbr VARCHAR2(254 char),
entry_mthd_code VARCHAR2(30 char),
auth_mthd_code VARCHAR2(30 char),
micr VARCHAR2(254 char),
orig_transmission_date_time VARCHAR2(20 char),
orig_stan VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ttr_check_tndr_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ttr_check_tndr_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE ttr_coupon_tndr_lineitm --- ');
CREATE TABLE ttr_coupon_tndr_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
manufacturer_id VARCHAR2(254 char),
manufacturer_family_code VARCHAR2(254 char),
typcode VARCHAR2(30 char),
scan_code VARCHAR2(30 char),
expr_date TIMESTAMP(6),
promotion_code VARCHAR2(30 char),
key_entered_flag NUMBER(1, 0) DEFAULT 0,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ttr_coupon_tndr_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ttr_coupon_tndr_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE ttr_credit_debit_tndr_lineitm --- ');
CREATE TABLE ttr_credit_debit_tndr_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
mediaissuer_id VARCHAR2(254 char),
acct_nbr VARCHAR2(254 char),
personal_id_req_typcode VARCHAR2(30 char),
personal_id_ref_nbr VARCHAR2(254 char),
auth_mthd_code VARCHAR2(30 char),
adjudication_code VARCHAR2(30 char),
entry_mthd_code VARCHAR2(30 char),
expr_date VARCHAR2(64 char),
auth_nbr VARCHAR2(254 char),
ps2000 VARCHAR2(254 char),
bank_reference_number VARCHAR2(254 char),
customer_name VARCHAR2(254 char),
cashback_amt NUMBER(17, 6),
card_level_indicator VARCHAR2(30 char),
acct_nbr_hash VARCHAR2(60 char),
authorization_token VARCHAR2(320 char),
transaction_reference_data VARCHAR2(254 char),
trace_number VARCHAR2(60 char),
tax_amt NUMBER(17, 6),
discount_amt NUMBER(17, 6),
freight_amt NUMBER(17, 6),
duty_amt NUMBER(17, 6),
orig_local_date_time VARCHAR2(20 char),
orig_transmission_date_time VARCHAR2(20 char),
orig_stan VARCHAR2(60 char),
transaction_identifier VARCHAR2(20 char),
ccv_error_code VARCHAR2(10 char),
pos_entry_mode_change VARCHAR2(10 char),
processing_code VARCHAR2(10 char),
pos_entry_mode VARCHAR2(10 char),
pos_addl_data VARCHAR2(20 char),
network_result_indicator VARCHAR2(20 char),
merchant_cat_code VARCHAR2(4 char),
usage_reason_code VARCHAR2(30 char),
dcc_currency_id VARCHAR2(3 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ttrcreditdebittndrlineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ttr_credit_debit_tndr_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE ttr_identity_verification --- ');
CREATE TABLE ttr_identity_verification(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
identity_verification_seq NUMBER(10, 0) NOT NULL,
id_typcode VARCHAR2(30 char),
id_nbr VARCHAR2(254 char),
issuing_authority VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ttr_identity_verification PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, identity_verification_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ttr_identity_verification TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('ttr_identity_verification');
EXEC dbms_output.put_line('--- CREATING TABLE ttr_send_check_tndr_lineitm --- ');
CREATE TABLE ttr_send_check_tndr_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
payable_to_name VARCHAR2(254 char),
payable_to_address VARCHAR2(254 char),
payable_to_city VARCHAR2(254 char),
payable_to_state VARCHAR2(254 char),
payable_to_postal_code VARCHAR2(254 char),
reascode VARCHAR2(30 char),
payable_to_address2 VARCHAR2(254 char),
payable_to_address3 VARCHAR2(254 char),
payable_to_address4 VARCHAR2(254 char),
payable_to_apt VARCHAR2(30 char),
payable_to_country VARCHAR2(2 char),
payable_to_neighborhood VARCHAR2(254 char),
payable_to_county VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ttrsendchecktndrlineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ttr_send_check_tndr_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE ttr_signature --- ');
CREATE TABLE ttr_signature(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
signature CLOB,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ttr_signature PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ttr_signature TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('ttr_signature');
EXEC dbms_output.put_line('--- CREATING TABLE ttr_tndr_auth_log --- ');
CREATE TABLE ttr_tndr_auth_log(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
attempt_seq NUMBER(10, 0) NOT NULL,
response_code VARCHAR2(254 char),
reference_nbr VARCHAR2(254 char),
error_code VARCHAR2(254 char),
error_text VARCHAR2(254 char),
start_timestamp TIMESTAMP(6),
end_timestamp TIMESTAMP(6),
approval_code VARCHAR2(254 char),
auth_type VARCHAR2(30 char),
customer_name VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ttr_tndr_auth_log PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq, attempt_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ttr_tndr_auth_log TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('ttr_tndr_auth_log');
EXEC dbms_output.put_line('--- CREATING TABLE ttr_tndr_lineitm --- ');
CREATE TABLE ttr_tndr_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
amt NUMBER(17, 6),
change_flag NUMBER(1, 0) DEFAULT 0,
host_validation_flag NUMBER(1, 0) DEFAULT 0,
tndr_id VARCHAR2(60 char),
tndr_description VARCHAR2(254 char),
serial_nbr VARCHAR2(254 char),
tndr_statcode VARCHAR2(30 char),
foreign_amt NUMBER(17, 6),
exchange_rate NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ttr_tndr_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ttr_tndr_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_TTR_TNDR_LINEITM01 --- ');
CREATE INDEX IDX_TTR_TNDR_LINEITM01 ON ttr_tndr_lineitm(trans_seq, business_date, rtl_loc_id, wkstn_id, organization_id, rtrans_lineitm_seq)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING TABLE ttr_voucher --- ');
CREATE TABLE ttr_voucher(
organization_id NUMBER(10, 0) NOT NULL,
voucher_typcode VARCHAR2(30 char) NOT NULL,
serial_nbr VARCHAR2(60 char) NOT NULL,
issue_datetime TIMESTAMP(6),
effective_date TIMESTAMP(6),
expr_date TIMESTAMP(6),
face_value_amt NUMBER(17, 6),
voucher_status_code VARCHAR2(30 char),
issue_typcode VARCHAR2(30 char),
unspent_balance_amt NUMBER(17, 6),
currency_id VARCHAR2(3 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ttr_voucher PRIMARY KEY (organization_id, voucher_typcode, serial_nbr) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ttr_voucher TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('ttr_voucher');
EXEC dbms_output.put_line('--- CREATING TABLE ttr_voucher_history --- ');
CREATE TABLE ttr_voucher_history(
organization_id NUMBER(10, 0) NOT NULL,
voucher_typcode VARCHAR2(30 char) NOT NULL,
serial_nbr VARCHAR2(60 char) NOT NULL,
history_seq NUMBER(19, 0) NOT NULL,
activity_code VARCHAR2(30 char),
amt NUMBER(17, 6),
rtrans_lineitm_seq NUMBER(10, 0),
rtl_loc_id NUMBER(10, 0),
wkstn_id NUMBER(19, 0),
business_date TIMESTAMP(6),
trans_seq NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ttr_voucher_history PRIMARY KEY (organization_id, voucher_typcode, serial_nbr, history_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ttr_voucher_history TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('ttr_voucher_history');
EXEC dbms_output.put_line('--- CREATING TABLE ttr_voucher_tndr_lineitm --- ');
CREATE TABLE ttr_voucher_tndr_lineitm(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
voucher_typcode VARCHAR2(30 char),
auth_mthd_code VARCHAR2(30 char),
adjudication_code VARCHAR2(30 char),
entry_mthd_code VARCHAR2(30 char),
auth_code VARCHAR2(30 char),
activity_code VARCHAR2(30 char),
reference_nbr VARCHAR2(254 char),
effective_date TIMESTAMP(6),
expr_date TIMESTAMP(6),
face_value_amt NUMBER(17, 6),
issue_datetime TIMESTAMP(6),
issue_typcode VARCHAR2(30 char),
unspent_balance_amt NUMBER(17, 6),
voucher_status_code VARCHAR2(30 char),
trace_number VARCHAR2(60 char),
orig_local_date_time VARCHAR2(20 char),
orig_transmission_date_time VARCHAR2(20 char),
orig_stan VARCHAR2(60 char),
merchant_cat_code VARCHAR2(4 char),
card_type VARCHAR2(20 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_ttr_voucher_tndr_lineitm PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON ttr_voucher_tndr_lineitm TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING TABLE xom_address_mod --- ');
CREATE TABLE xom_address_mod(
organization_id NUMBER(10, 0) NOT NULL,
order_id VARCHAR2(60 char) NOT NULL,
address_seq NUMBER(19, 0) NOT NULL,
address1 VARCHAR2(254 char),
address2 VARCHAR2(254 char),
address3 VARCHAR2(254 char),
address4 VARCHAR2(254 char),
city VARCHAR2(254 char),
state VARCHAR2(30 char),
postal_code VARCHAR2(30 char),
country VARCHAR2(2 char),
apartment VARCHAR2(30 char),
neighborhood VARCHAR2(254 char),
county VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_xom_address_mod PRIMARY KEY (organization_id, order_id, address_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON xom_address_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('xom_address_mod');
EXEC dbms_output.put_line('--- CREATING TABLE xom_balance_mod --- ');
CREATE TABLE xom_balance_mod(
organization_id NUMBER(10, 0) NOT NULL,
order_id VARCHAR2(60 char) NOT NULL,
detail_seq NUMBER(10, 0) NOT NULL,
detail_line_number NUMBER(10, 0) NOT NULL,
mod_seq NUMBER(10, 0) NOT NULL,
typcode VARCHAR2(30 char),
amount NUMBER(17, 6),
void_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_xom_balance_mod PRIMARY KEY (organization_id, order_id, detail_seq, detail_line_number, mod_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON xom_balance_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('xom_balance_mod');
EXEC dbms_output.put_line('--- CREATING TABLE xom_customer_mod --- ');
CREATE TABLE xom_customer_mod(
organization_id NUMBER(10, 0) NOT NULL,
order_id VARCHAR2(60 char) NOT NULL,
customer_id VARCHAR2(60 char),
first_name VARCHAR2(60 char),
last_name VARCHAR2(60 char),
telephone1 VARCHAR2(32 char),
telephone2 VARCHAR2(32 char),
email_address VARCHAR2(254 char),
address_seq NUMBER(19, 0),
organization_name VARCHAR2(254 char),
salutation VARCHAR2(30 char),
middle_name VARCHAR2(60 char),
suffix VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_xom_customer_mod PRIMARY KEY (organization_id, order_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON xom_customer_mod TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_XOM_CUSTOMER_MOD02 --- ');
CREATE INDEX IDX_XOM_CUSTOMER_MOD02 ON xom_customer_mod(UPPER(last_name), UPPER(first_name), UPPER(telephone1), UPPER(telephone2), organization_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_XOM_CUSTOMER_MOD03 --- ');
CREATE INDEX IDX_XOM_CUSTOMER_MOD03 ON xom_customer_mod(UPPER(telephone1), organization_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_XOM_CUSTOMER_MOD04 --- ');
CREATE INDEX IDX_XOM_CUSTOMER_MOD04 ON xom_customer_mod(UPPER(telephone2), organization_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('xom_customer_mod');
EXEC dbms_output.put_line('--- CREATING TABLE xom_customization_mod --- ');
CREATE TABLE xom_customization_mod(
organization_id NUMBER(10, 0) NOT NULL,
order_id VARCHAR2(60 char) NOT NULL,
detail_seq NUMBER(10, 0) NOT NULL,
detail_line_number NUMBER(10, 0) NOT NULL,
mod_seq NUMBER(10, 0) NOT NULL,
customization_code VARCHAR2(30 char),
customization_message VARCHAR2(4000 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_xom_customization_mod PRIMARY KEY (organization_id, order_id, detail_seq, detail_line_number, mod_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON xom_customization_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('xom_customization_mod');
EXEC dbms_output.put_line('--- CREATING TABLE xom_fee_mod --- ');
CREATE TABLE xom_fee_mod(
organization_id NUMBER(10, 0) NOT NULL,
order_id VARCHAR2(60 char) NOT NULL,
detail_seq NUMBER(10, 0) NOT NULL,
detail_line_number NUMBER(10, 0) NOT NULL,
mod_seq NUMBER(10, 0) NOT NULL,
typcode VARCHAR2(30 char),
amount NUMBER(17, 6),
void_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
tax_amount NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_xom_fee_mod PRIMARY KEY (organization_id, order_id, detail_seq, detail_line_number, mod_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON xom_fee_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('xom_fee_mod');
EXEC dbms_output.put_line('--- CREATING TABLE xom_fulfillment_mod --- ');
CREATE TABLE xom_fulfillment_mod(
organization_id NUMBER(10, 0) NOT NULL,
order_id VARCHAR2(60 char) NOT NULL,
detail_seq NUMBER(10, 0) NOT NULL,
detail_line_number NUMBER(10, 0) NOT NULL,
loc_id VARCHAR2(60 char),
loc_name1 VARCHAR2(254 char),
loc_name2 VARCHAR2(254 char),
telephone VARCHAR2(32 char),
email_address VARCHAR2(254 char),
address_seq NUMBER(19, 0),
organization_name VARCHAR2(254 char),
salutation VARCHAR2(30 char),
middle_name VARCHAR2(60 char),
suffix VARCHAR2(30 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_xom_fulfillment_mod PRIMARY KEY (organization_id, order_id, detail_seq, detail_line_number) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON xom_fulfillment_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('xom_fulfillment_mod');
EXEC dbms_output.put_line('--- CREATING TABLE xom_item_mod --- ');
CREATE TABLE xom_item_mod(
organization_id NUMBER(10, 0) NOT NULL,
order_id VARCHAR2(60 char) NOT NULL,
detail_seq NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char),
description VARCHAR2(254 char),
image_url VARCHAR2(254 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_xom_item_mod PRIMARY KEY (organization_id, order_id, detail_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON xom_item_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('xom_item_mod');
EXEC dbms_output.put_line('--- CREATING TABLE xom_order --- ');
CREATE TABLE xom_order(
organization_id NUMBER(10, 0) NOT NULL,
order_id VARCHAR2(60 char) NOT NULL,
order_type VARCHAR2(30 char),
status_code VARCHAR2(30 char),
order_date TIMESTAMP(6),
order_loc_id VARCHAR2(60 char),
subtotal NUMBER(17, 6),
tax_amount NUMBER(17, 6),
total NUMBER(17, 6),
balance_due NUMBER(17, 6),
notes CLOB,
ref_nbr VARCHAR2(60 char),
additional_freight_charges NUMBER(17, 6),
additional_charges NUMBER(17, 6),
ship_complete_flag NUMBER(1, 0) DEFAULT 0,
freight_tax NUMBER(17, 6),
order_message VARCHAR2(4000 char),
gift_message VARCHAR2(4000 char),
under_review_flag NUMBER(1, 0) DEFAULT 0,
status_code_reason VARCHAR2(30 char),
status_code_reason_note VARCHAR2(4000 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_xom_order PRIMARY KEY (organization_id, order_id) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON xom_order TO POSUSERS,DBAUSERS;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_XOM_ORDER02 --- ');
CREATE INDEX IDX_XOM_ORDER02 ON xom_order(order_id, UPPER(order_type), UPPER(status_code), organization_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_XOM_ORDER03 --- ');
CREATE INDEX IDX_XOM_ORDER03 ON xom_order(UPPER(order_type), UPPER(status_code), organization_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC dbms_output.put_line('--- CREATING INDEX IDX_XOM_ORDER04 --- ');
CREATE INDEX IDX_XOM_ORDER04 ON xom_order(UPPER(status_code), organization_id)
TABLESPACE &dbIndexTableSpace.
;

EXEC CREATE_PROPERTY_TABLE('xom_order');
EXEC dbms_output.put_line('--- CREATING TABLE xom_order_fee --- ');
CREATE TABLE xom_order_fee(
organization_id NUMBER(10, 0) NOT NULL,
order_id VARCHAR2(60 char) NOT NULL,
detail_seq NUMBER(10, 0) NOT NULL,
typcode VARCHAR2(30 char),
amount NUMBER(17, 6),
void_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
item_id VARCHAR2(60 char),
tax_amount NUMBER(17, 6),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_xom_order_fee PRIMARY KEY (organization_id, order_id, detail_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON xom_order_fee TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('xom_order_fee');
EXEC dbms_output.put_line('--- CREATING TABLE xom_order_line --- ');
CREATE TABLE xom_order_line(
organization_id NUMBER(10, 0) NOT NULL,
order_id VARCHAR2(60 char) NOT NULL,
detail_seq NUMBER(10, 0) NOT NULL,
item_id VARCHAR2(60 char),
quantity NUMBER(11, 4),
fulfillment_type VARCHAR2(20 char),
item_upc_code VARCHAR2(60 char),
item_ean_code VARCHAR2(60 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_xom_order_line PRIMARY KEY (organization_id, order_id, detail_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON xom_order_line TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('xom_order_line');
EXEC dbms_output.put_line('--- CREATING TABLE xom_order_line_detail --- ');
CREATE TABLE xom_order_line_detail(
organization_id NUMBER(10, 0) NOT NULL,
order_id VARCHAR2(60 char) NOT NULL,
detail_seq NUMBER(10, 0) NOT NULL,
detail_line_number NUMBER(10, 0) NOT NULL,
external_order_id VARCHAR2(60 char),
item_id VARCHAR2(60 char),
quantity NUMBER(11, 4),
fulfillment_type VARCHAR2(20 char),
status_code VARCHAR2(30 char),
unit_price NUMBER(17, 6),
extended_price NUMBER(17, 6),
tax_amount NUMBER(17, 6),
notes CLOB,
selected_ship_method VARCHAR2(60 char),
tracking_nbr VARCHAR2(60 char),
void_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
actual_ship_method VARCHAR2(60 char),
drop_ship_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
status_code_reason VARCHAR2(30 char),
status_code_reason_note VARCHAR2(4000 char),
extended_freight NUMBER(17, 6),
customization_charge NUMBER(17, 6),
gift_wrap_flag NUMBER(1, 0) DEFAULT 0,
ship_alone_flag NUMBER(1, 0) DEFAULT 0,
ship_weight NUMBER(17, 6),
line_message VARCHAR2(4000 char),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_xom_order_line_detail PRIMARY KEY (organization_id, order_id, detail_seq, detail_line_number) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON xom_order_line_detail TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('xom_order_line_detail');
EXEC dbms_output.put_line('--- CREATING TABLE xom_order_mod --- ');
CREATE TABLE xom_order_mod(
organization_id NUMBER(10, 0) NOT NULL,
rtl_loc_id NUMBER(10, 0) NOT NULL,
business_date TIMESTAMP(6) NOT NULL,
wkstn_id NUMBER(19, 0) NOT NULL,
trans_seq NUMBER(19, 0) NOT NULL,
rtrans_lineitm_seq NUMBER(10, 0) NOT NULL,
order_id VARCHAR2(60 char),
external_order_id VARCHAR2(60 char),
order_type VARCHAR2(30 char),
detail_type VARCHAR2(20 char),
detail_seq NUMBER(10, 0),
detail_line_number NUMBER(10, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_xom_order_mod PRIMARY KEY (organization_id, rtl_loc_id, business_date, wkstn_id, trans_seq, rtrans_lineitm_seq) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON xom_order_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('xom_order_mod');
EXEC dbms_output.put_line('--- CREATING TABLE xom_order_payment --- ');
CREATE TABLE xom_order_payment(
organization_id NUMBER(10, 0) NOT NULL,
order_id VARCHAR2(60 char) NOT NULL,
sequence NUMBER(10, 0) NOT NULL,
typcode VARCHAR2(30 char),
item_id VARCHAR2(60 char),
amount NUMBER(17, 6),
void_flag NUMBER(1, 0) DEFAULT 0 NOT NULL,
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_xom_order_payment PRIMARY KEY (organization_id, order_id, sequence) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON xom_order_payment TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('xom_order_payment');
EXEC dbms_output.put_line('--- CREATING TABLE xom_source_mod --- ');
CREATE TABLE xom_source_mod(
organization_id NUMBER(10, 0) NOT NULL,
order_id VARCHAR2(60 char) NOT NULL,
detail_seq NUMBER(10, 0) NOT NULL,
detail_line_number NUMBER(10, 0) NOT NULL,
loc_id VARCHAR2(60 char),
loc_type VARCHAR2(30 char),
loc_name1 VARCHAR2(254 char),
loc_name2 VARCHAR2(254 char),
telephone VARCHAR2(32 char),
email_address VARCHAR2(254 char),
address_seq NUMBER(19, 0),
create_user_id VARCHAR2(256 char),
create_date TIMESTAMP(6),
update_user_id VARCHAR2(256 char),
update_date TIMESTAMP(6),
record_state VARCHAR2(30 char), 
CONSTRAINT pk_xom_source_mod PRIMARY KEY (organization_id, order_id, detail_seq, detail_line_number) USING INDEX TABLESPACE &dbIndexTableSpace.
)
TABLESPACE &dbDataTableSpace.
; 

GRANT SELECT,INSERT,UPDATE,DELETE ON xom_source_mod TO POSUSERS,DBAUSERS;

EXEC CREATE_PROPERTY_TABLE('xom_source_mod');
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


INSERT INTO ctl_version_history (
    organization_id, base_schema_version, customer_schema_version, base_schema_date, 
    create_user_id, create_date, update_user_id, update_date)
VALUES (
    $(OrgID), '22.0.0.0.20230127185818', '0.0.0 - 0.0', SYSDATE, 
    'Oracle', SYSDATE, 'Oracle', SYSDATE);

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
