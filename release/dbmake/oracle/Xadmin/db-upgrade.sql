SET SERVEROUTPUT ON SIZE 20000

SPOOL dbupdate.log;

-- ***************************************************************************
-- This script will upgrade a database from version <source> of the Xadmin base schema to version
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
-- 21.0.x -> 22.0.0
-- ***************************************************************************
-- ***************************************************************************

BEGIN dbms_output.put_line('--- CREATING sp_column_exists --- '); END;
/
CREATE OR REPLACE function sp_column_exists (
 table_name     varchar2,
 column_name    varchar2
) return boolean is

 v_count integer;
 v_exists boolean;
 curSchema VARCHAR2(128);

begin

select sys_context( 'userenv', 'current_schema' ) into curSchema from dual;
select decode(count(*),0,0,1) into v_count
    from all_tab_columns
    where owner = upper(curSchema)
      and table_name = upper(sp_column_exists.table_name)
      and column_name = upper(sp_column_exists.column_name);

 if v_count = 1 then
   v_exists := true;
 else
   v_exists := false;
 end if;

 return v_exists;

end sp_column_exists;
/

BEGIN dbms_output.put_line('--- CREATING sp_table_exists --- '); END;
/
CREATE OR REPLACE function sp_table_exists (
  table_name varchar2
) return boolean is

  v_count integer;
  v_exists boolean;
  curSchema VARCHAR2(128);
begin

  select sys_context( 'userenv', 'current_schema' ) into curSchema from dual;
  select decode(count(*),0,0,1) into v_count
    from all_tables
    where owner = upper(curSchema)
      and table_name = upper(sp_table_exists.table_name);

  if v_count = 1 then
    v_exists := true;
  else
    v_exists := false;
  end if;

  return v_exists;

end sp_table_exists;
/

BEGIN dbms_output.put_line('--- CREATING sp_constraint_exists --- '); END;
/
CREATE OR REPLACE function sp_constraint_exists (
 table_name     varchar2,
 constraint_name    varchar2
) return boolean is

 v_count integer;
 v_exists boolean;
 curSchema VARCHAR2(128);

begin

select sys_context( 'userenv', 'current_schema' ) into curSchema from dual;
select decode(count(*),0,0,1) into v_count
    from all_constraints
    where owner = upper(curSchema)
      and table_name = upper(sp_constraint_exists.table_name)
      and constraint_name = upper(sp_constraint_exists.constraint_name);

 if v_count = 1 then
   v_exists := true;
 else
   v_exists := false;
 end if;

 return v_exists;

end sp_constraint_exists;
/

BEGIN dbms_output.put_line('--- CREATING sp_column_size --- '); END;
/
CREATE OR REPLACE FUNCTION sp_column_size (
 table_name     VARCHAR2,
 column_name    VARCHAR2,
 column_size    INTEGER
)
RETURN BOOLEAN IS
 v_count INTEGER;
 v_exists BOOLEAN;
 curSchema VARCHAR2(128);

BEGIN
  SELECT sys_context( 'userenv', 'current_schema' ) INTO curSchema FROM DUAL;
  SELECT decode(count(*),0,0,1) INTO v_count
    FROM all_tab_columns
    WHERE owner = upper(curSchema)
      AND table_name = upper(sp_column_size.table_name)
      AND column_name = upper(sp_column_size.column_name)
      AND char_length = sp_column_size.column_size;

  IF v_count = 1 THEN
    v_exists := true;
  ELSE
    v_exists := false;
  END IF;

  RETURN v_exists;

END sp_column_size;
/

BEGIN dbms_output.put_line('--- CREATING SP_PK_CONSTRAINT_EXISTS --- '); END;
/
CREATE OR REPLACE function SP_PK_CONSTRAINT_EXISTS (
 table_name     varchar2
) 
RETURN varchar2 is
 v_pk varchar2(256);
 curSchema VARCHAR2(128);
begin
	select sys_context( 'userenv', 'current_schema' ) into curSchema from dual;
  select initcap(CONSTRAINT_NAME) into v_pk
    from all_constraints
   where owner = upper(curSchema)
     and table_name = upper(SP_PK_CONSTRAINT_EXISTS.table_name)
     and constraint_type = 'P'
     and ROWNUM = 1;
   return v_pk;
   EXCEPTION
   WHEN NO_DATA_FOUND
   then return 'NOT_FOUND';
end SP_PK_CONSTRAINT_EXISTS;
/

--[RXPS-61392] START 

BEGIN
    IF SP_COLUMN_EXISTS ('dat_legal_entity_change','company_business_name') THEN
        dbms_output.put_line('     dat_legal_entity_change.company_business_name already exists');
    ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE dat_legal_entity_change ADD company_business_name VARCHAR2(254 char) NULL';
        dbms_output.put_line('     dat_legal_entity_change.company_business_name created');
    END IF;
END;
/

-- [RXPS-61392] END

-- 21.0.x -> 22.0.x

-- [RXPS-42020] START 
BEGIN
  IF SP_COLUMN_EXISTS( 'rpt_stock_rollup','organization_id') THEN
        dbms_output.put_line('     rpt_stock_rollup.organization_id already exists');
  ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE rpt_stock_rollup ADD organization_id NUMBER(10,0)';
        EXECUTE IMMEDIATE 'ALTER TABLE rpt_stock_rollup DROP PRIMARY KEY DROP INDEX';
        EXECUTE IMMEDIATE 'INSERT INTO rpt_stock_rollup (organization_id, id, user_id , fiscal_year , start_date ,end_date , status , create_date, create_user_id, update_date, update_user_id) 
(select distinct ccv.code, rsr.id, rsr.user_id , rsr.fiscal_year , rsr.start_date ,rsr.end_date , rsr.status , rsr.create_date, rsr.create_user_id, rsr.update_date, rsr.update_user_id  FROM cfg_code_value ccv     
 cross join  rpt_stock_rollup rsr where ccv.category=''OrganizationId'')';
       EXECUTE IMMEDIATE 'Delete from rpt_stock_rollup where organization_id IS null';
        EXECUTE IMMEDIATE 'ALTER TABLE rpt_stock_rollup ADD CONSTRAINT pk_rpt_stock_rollup PRIMARY KEY (organization_id, id)';
        dbms_output.put_line('     rpt_stock_rollup.organization_id created');
  END IF;
END;
/

-- [RXPS-42020] END

-- [RXPS-62145] START 
BEGIN
    IF SP_COLUMN_EXISTS ('dat_emp_change','sick_days_used') THEN
        dbms_output.put_line('     dat_emp_change.sick_days_used already exists');
    ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE dat_emp_change ADD sick_days_used NUMBER(11, 2) NULL';
        dbms_output.put_line('     dat_emp_change.sick_days_used created');
    END IF;
END;
/

BEGIN
    IF SP_COLUMN_EXISTS ('dat_emp_change','marital_status') THEN
        dbms_output.put_line('     dat_emp_change.marital_status already exists');
    ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE dat_emp_change ADD marital_status VARCHAR2(30 char) NULL';
        dbms_output.put_line('     dat_emp_change.marital_status created');
    END IF;
END;
/

BEGIN
    IF SP_COLUMN_EXISTS ('dat_emp_change','spouse_name') THEN
        dbms_output.put_line('     dat_emp_change.spouse_name already exists');
    ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE dat_emp_change ADD spouse_name VARCHAR2(254 char) NULL';
        dbms_output.put_line('     dat_emp_change.spouse_name created');
    END IF;
END;
/

BEGIN
    IF SP_COLUMN_EXISTS ('dat_emp_change','vacation_days') THEN
        dbms_output.put_line('     dat_emp_change.vacation_days already exists');
    ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE dat_emp_change ADD vacation_days NUMBER(11, 2) NULL';
        dbms_output.put_line('     dat_emp_change.vacation_days created');
    END IF;
END;
/

BEGIN
    IF SP_COLUMN_EXISTS ('dat_emp_change','vacation_days_used') THEN
        dbms_output.put_line('     dat_emp_change.vacation_days_used already exists');
    ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE dat_emp_change ADD vacation_days_used NUMBER(11, 2) NULL';
        dbms_output.put_line('     dat_emp_change.vacation_days_used created');
    END IF;
END;
/

BEGIN
    IF SP_COLUMN_EXISTS ('dat_emp_change','sick_days') THEN
        dbms_output.put_line('     dat_emp_change.sick_days already exists');
    ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE dat_emp_change ADD sick_days NUMBER(11, 2) NULL';
        dbms_output.put_line('     dat_emp_change.sick_days created');
    END IF;
END;
/

BEGIN
    IF SP_COLUMN_EXISTS ('dat_emp_change','personal_days') THEN
        dbms_output.put_line('     dat_emp_change.personal_days already exists');
    ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE dat_emp_change ADD personal_days NUMBER(11, 2) NULL';
        dbms_output.put_line('     dat_emp_change.personal_days created');
    END IF;
END;
/

BEGIN
    IF SP_COLUMN_EXISTS ('dat_emp_change','personal_days_used') THEN
        dbms_output.put_line('     dat_emp_change.personal_days_used already exists');
    ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE dat_emp_change ADD personal_days_used NUMBER(11, 2) NULL';
        dbms_output.put_line('     dat_emp_change.personal_days_used created');
    END IF;
END;
/

BEGIN
    IF SP_COLUMN_EXISTS ('dat_emp_change','employee_role_code') THEN
        dbms_output.put_line('     dat_emp_change.employee_role_code already exists');
    ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE dat_emp_change ADD employee_role_code VARCHAR2(30 char) NULL';
        dbms_output.put_line('     dat_emp_change.employee_role_code created');
    END IF;
END;
/

BEGIN
    IF SP_COLUMN_EXISTS ('dat_emp_change','employee_group_id') THEN
        dbms_output.put_line('     dat_emp_change.employee_group_id already exists');
    ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE dat_emp_change ADD employee_group_id VARCHAR2(60 char) NULL';
        dbms_output.put_line('     dat_emp_change.employee_group_id created');
    END IF;
END;
/

BEGIN
    IF SP_COLUMN_EXISTS ('dat_emp_change','social_security_nbr') THEN
        dbms_output.put_line('     dat_emp_change.social_security_nbr already exists');
    ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE dat_emp_change ADD social_security_nbr VARCHAR2(255 char) NULL';
        dbms_output.put_line('     dat_emp_change.social_security_nbr created');
    END IF;
END;
/

BEGIN
    IF SP_COLUMN_EXISTS ('dat_emp_change','national_tax_id') THEN
        dbms_output.put_line('     dat_emp_change.national_tax_id already exists');
    ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE dat_emp_change ADD national_tax_id VARCHAR2(30 char) NULL';
        dbms_output.put_line('     dat_emp_change.national_tax_id created');
    END IF;
END;
/

BEGIN
    IF SP_COLUMN_EXISTS ('dat_emp_change','personal_tax_id') THEN
        dbms_output.put_line('     dat_emp_change.personal_tax_id already exists');
    ELSE
        EXECUTE IMMEDIATE 'ALTER TABLE dat_emp_change ADD personal_tax_id VARCHAR2(30 char) NULL';
        dbms_output.put_line('     dat_emp_change.personal_tax_id created');
    END IF;
END;
/

-- [RXPS-62145] END 


-- [RXPS-62673] START

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE TABLE_NAME = upper('cfg_paybylink');
          
    IF li_rowcnt = 0 THEN
        dbms_output.put_line('     cfg_paybylink table does not exist. creating table cfg_paybylink.');
        EXECUTE IMMEDIATE 'CREATE TABLE cfg_paybylink(
    organization_id                 NUMBER(10, 0)         NOT NULL,
    hmac_key                        VARCHAR2(256 char)    NOT NULL,
    expiration_date                 TIMESTAMP(6),
    create_date                     TIMESTAMP(6),
    create_user_id                  VARCHAR2(256 char),
    update_date                     TIMESTAMP(6),
    update_user_id                  VARCHAR2(256 char),
    CONSTRAINT pk_cfg_paybylink PRIMARY KEY (organization_id, hmac_key)
)';

EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON cfg_paybylink TO POSUSERS,DBAUSERS';
    END IF;
END;
/

-- [RXPS-62673] END

-- [RXPS-63335] START
DECLARE
    li_rowcnt   INT;
BEGIN    
    -- Check if the column to be change still not VARCHAR
    li_rowcnt := 0;
    SELECT
        COUNT(*)
    INTO li_rowcnt
    FROM
        all_tab_columns
    WHERE
        table_name LIKE 'DPL_DEPLOYMENT'
        AND column_name LIKE 'CANCEL_TIMESTAMP'
        AND data_type != 'TIMESTAMP(6)';

    IF li_rowcnt >= 1 THEN
    
      -- Check if temp column exist
        li_rowcnt := 0;
        SELECT
            COUNT(*)
        INTO li_rowcnt
        FROM
            all_tab_columns
        WHERE
            table_name LIKE 'DPL_DEPLOYMENT'
            AND column_name LIKE 'TEMP_CANCEL_TIMESTAMP';

        IF li_rowcnt = 0 THEN --True, if column do not exist
        -- Create temp column
            EXECUTE IMMEDIATE 'ALTER TABLE DPL_DEPLOYMENT ADD TEMP_CANCEL_TIMESTAMP TIMESTAMP(6)';
        END IF;
    
      -- Set the current value to temp column
        EXECUTE IMMEDIATE 'UPDATE DPL_DEPLOYMENT SET TEMP_CANCEL_TIMESTAMP = 
                                                     TO_TIMESTAMP(CANCEL_TIMESTAMP,''yyyyMMdd'') WHERE CANCEL_TIMESTAMP IS NOT NULL AND TEMP_CANCEL_TIMESTAMP IS NULL';
      
      -- The original value is now on temp column, we can remove the value fro original column
        EXECUTE IMMEDIATE 'UPDATE DPL_DEPLOYMENT SET CANCEL_TIMESTAMP = NULL WHERE CANCEL_TIMESTAMP IS NOT NULL';
      
      -- Change original column to varchar
        EXECUTE IMMEDIATE 'ALTER TABLE DPL_DEPLOYMENT MODIFY CANCEL_TIMESTAMP TIMESTAMP(6)';
    END IF;
    
    -- Check if the temp column still exist

    li_rowcnt := 0;
    SELECT
        COUNT(*)
    INTO li_rowcnt
    FROM
        all_tab_columns
    WHERE
        table_name = 'DPL_DEPLOYMENT'
        AND column_name = 'TEMP_CANCEL_TIMESTAMP';

    IF li_rowcnt >= 1 THEN
      -- Move the original information to the original column
        EXECUTE IMMEDIATE 'UPDATE DPL_DEPLOYMENT SET CANCEL_TIMESTAMP = TEMP_CANCEL_TIMESTAMP WHERE CANCEL_TIMESTAMP IS NULL';
      -- Remove the temp column
        EXECUTE IMMEDIATE 'ALTER TABLE DPL_DEPLOYMENT DROP COLUMN TEMP_CANCEL_TIMESTAMP';
    END IF;
    
    -- Display OK message
    dbms_output.put_line('DPL_DEPLOYMENT.CANCEL_TIMESTAMP updated');
END;
/

-- [RXPS-63335] END

-- [RXPS-63846] START

DECLARE
    li_rowcnt   INT;
BEGIN    
    -- Check if the column char length is still 25
    li_rowcnt := 0;
    SELECT
        COUNT(*)
    INTO li_rowcnt
    FROM
        all_tab_columns
    WHERE
        table_name = 'CFG_INTEGRATION' and column_name = 'INTEGRATION_SYSTEM' and char_length = 25;
    IF li_rowcnt >= 1 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE CFG_INTEGRATION MODIFY INTEGRATION_SYSTEM VARCHAR2 (50)';
    END IF;
    
    dbms_output.put_line('CFG_INTEGRATION.INTEGRATION_SYSTEM updated');
END;
/

DECLARE
    li_rowcnt   INT;
BEGIN    
    -- Check if the column char length is still 25
    li_rowcnt := 0;
    SELECT
        COUNT(*)
    INTO li_rowcnt
    FROM
        all_tab_columns
    WHERE
        table_name = 'CFG_INTEGRATION_P' and column_name = 'INTEGRATION_SYSTEM' and char_length = 25;
    IF li_rowcnt >= 1 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE CFG_INTEGRATION_P MODIFY INTEGRATION_SYSTEM VARCHAR2 (50)';
    END IF;
    
    dbms_output.put_line('CFG_INTEGRATION_P.INTEGRATION_SYSTEM updated');
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE TABLE_NAME = upper('cfg_attachment_types');
          
    IF li_rowcnt = 0 THEN
        dbms_output.put_line('     cfg_attachment_types table does not exist. creating table cfg_attachment_types.');
        EXECUTE IMMEDIATE 'CREATE TABLE cfg_attachment_types(
    attachment_type_id      VARCHAR2(30 char)     NOT NULL,
    description       VARCHAR2(255 char),
    create_date       TIMESTAMP(6),
    create_user_id    VARCHAR2(256 char),
    update_date       TIMESTAMP(6),
    update_user_id    VARCHAR2(256 char),
    CONSTRAINT pk_cfg_attachment_types PRIMARY KEY (attachment_type_id)
)';

EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON cfg_attachment_types TO POSUSERS,DBAUSERS';
    END IF;
END;
/

-- [RXPS-63846] END

commit;
--SPOOL OFF;
-- LEAVE BLANK LINE BELOW
