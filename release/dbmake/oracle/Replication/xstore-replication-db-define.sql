SPOOL rep.log;
--
-- Variables
--
DEFINE dbDataTableSpace = '$(DbTblspace)_DATA';-- Name of data file tablespace
DEFINE dbIndexTableSpace = '$(DbTblspace)_INDEX';-- Name of index file tablespace 

-- 
-- TABLE: REPQUEUE.ctl_replication_queue 
--

alter session set current_schema=$(DbSchema);

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM ALL_TABLES
    WHERE OWNER = upper('$(DbSchema)')
    AND TABLE_NAME = 'CTL_REPLICATION_QUEUE';
          
    IF li_rowcnt = 0 THEN
      EXECUTE IMMEDIATE 'CREATE TABLE $(DbSchema).CTL_REPLICATION_QUEUE(
        organization_id             NUMBER(10, 0)    NOT NULL,
        rtl_loc_id                  NUMBER(10, 0)    NOT NULL,
        wkstn_id                    NUMBER(19, 0)    NOT NULL,
        db_trans_id                 VARCHAR2(60 char)     NOT NULL,
        service_name                VARCHAR2(60 char)     NOT NULL,
        date_time                   NUMBER(19, 0),
        expires_after               NUMBER(19, 0),
        expires_immediately_flag    NUMBER(1, 0)     DEFAULT 0,
        never_expires_flag          NUMBER(1, 0)     DEFAULT 0,
        offline_failures            NUMBER(10, 0),
        error_failures              NUMBER(10, 0)    DEFAULT 0 NOT NULL,
        replication_data            CLOB,
        create_date                 TIMESTAMP(6),
        create_user_id              VARCHAR2(30 char),
        update_date                 TIMESTAMP(6),
        update_user_id              VARCHAR2(30 char),
        record_state                VARCHAR2(30 char),
        CONSTRAINT pk_ctl_replication_queue PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, db_trans_id, service_name)
        USING INDEX
      TABLESPACE &dbIndexTableSpace.
      )
      TABLESPACE &dbDataTableSpace.'
      ;
  
      EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON $(DbSchema).ctl_replication_queue TO posusers,dbausers';          
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM ALL_TABLES
    WHERE OWNER = upper('$(DbSchema)')
    AND TABLE_NAME = 'CTL_SERVICE_RETRY_QUEUE';
          
    IF li_rowcnt = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE $(DbSchema).CTL_SERVICE_RETRY_QUEUE(
      organization_id             NUMBER(10, 0)    NOT NULL,
      rtl_loc_id                  NUMBER(10, 0)    NOT NULL,
      wkstn_id                    NUMBER(19, 0)    NOT NULL,
      retry_id                    VARCHAR2(100 char)    NOT NULL,
      service_id                  VARCHAR2(60 char)     NOT NULL,
      service_type                VARCHAR2(60 char)     NOT NULL,
      retry_type                  VARCHAR2(60 char)     NOT NULL,
      processing_wkstn_id         NUMBER(19, 0)    NOT NULL,
      entry_date_time             TIMESTAMP(6)     NULL,
      last_attempt_time           NUMBER(19, 0)    NULL,
      retry_count                 NUMBER(10, 0)    DEFAULT ((0)) NOT NULL,
      context_info                VARCHAR2(255 char)    NULL,
      request_data                CLOB             NULL,
      create_date                 TIMESTAMP(6)     NULL,
      create_user_id              VARCHAR2(30 char)     NULL,
      update_date                 TIMESTAMP(6)     NULL,
      update_user_id              VARCHAR2(30 char)     NULL,
      record_state                VARCHAR2(30 char)     NULL,
      CONSTRAINT pk_ctl_service_retry_queue PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, retry_id, service_id, service_type)
      USING INDEX
    TABLESPACE &dbIndexTableSpace.
    )
    TABLESPACE &dbDataTableSpace.'
    ;

    EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON $(DbSchema).CTL_SERVICE_RETRY_QUEUE TO posusers,dbausers';           
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM ALL_TABLES
    WHERE OWNER = upper('$(DbSchema)')
    AND TABLE_NAME = 'RCPT_ERECEIPT_QUEUE';
          
    IF li_rowcnt = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE $(DbSchema).RCPT_ERECEIPT_QUEUE(
      organization_id             NUMBER(10, 0)    NOT NULL,
      rtl_loc_id                  NUMBER(10, 0)    NOT NULL,
      wkstn_id                    NUMBER(19, 0)    NOT NULL,
      queue_id                    VARCHAR2(100 char)    NOT NULL,
      service_id                  VARCHAR2(60 char)     NOT NULL,
      service_type                VARCHAR2(60 char)     NOT NULL,
      processing_wkstn_id         NUMBER(19, 0)    NOT NULL,
      entry_date_time             TIMESTAMP(6)     NULL,
      last_attempt_time           NUMBER(19, 0)    NULL,
      request_data                CLOB             NULL,
      original_trans_id_ref       VARCHAR2(254 char)     NULL,
      create_date                 TIMESTAMP(6)     NULL,
      create_user_id              VARCHAR2(30 char)     NULL,
      update_date                 TIMESTAMP(6)     NULL,
      update_user_id              VARCHAR2(30 char)     NULL,
      record_state                VARCHAR2(30 char)     NULL,
      CONSTRAINT pk_rcpt_ereceipt_queue PRIMARY KEY (organization_id, rtl_loc_id, wkstn_id, queue_id, service_id, service_type)
      USING INDEX
    TABLESPACE &dbIndexTableSpace.
    )
    TABLESPACE &dbDataTableSpace.'
    ;

    EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON $(DbSchema).RCPT_ERECEIPT_QUEUE TO posusers,dbausers';
    END IF;
END;
/


declare
vcnt int;
begin
	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY TRIGGER';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY TRIGGER FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='GRANT PUBLIC SYNONYM';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE PUBLIC SYNONYM FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='GRANT ANY VIEW';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY VIEW FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='GRANT ANY DIRECTORY';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY DIRECTORY FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='GRANT ANY SEQUENCE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY SEQUENCE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='GRANT ANY PROCEDURE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY PROCEDURE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='GRANT ANY TABLE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY TABLE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='GRANT ANY JOB';

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

	select count(*) into vcnt from DBA_ROLE_PRIVS where GRANTEE=upper('$(DbSchema)') and GRANTED_ROLE='IMP_FULL_DATABASE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE IMP_FULL_DATABASE FROM $(DbSchema)';
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

		EXECUTE IMMEDIATE 'REVOKE GRANT ANY PRIVILEGE FROM $(DbSchema)';
	end if;
end;
/
