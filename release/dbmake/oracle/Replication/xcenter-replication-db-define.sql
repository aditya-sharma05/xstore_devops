SET SERVEROUTPUT ON;
SPOOL replication.log;

--
-- Variables
--
DEFINE replPartitionInterval = '5';-- The partition interval in rpl_replication_data

-- finally create required tables
DECLARE
    li_rowcnt       int;
    li_partclause   varchar2(80);
    li_partenabled  varchar2(5);
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE TABLE_NAME = 'RPL_REPLICATION_DATA';
          
    IF li_rowcnt = 0 THEN
      SELECT VALUE into li_partenabled
        FROM V$OPTION
       WHERE PARAMETER = 'Partitioning';
        
      IF li_partenabled = 'TRUE' THEN
        li_partclause := ' PARTITION BY RANGE(rtl_loc_id) INTERVAL(&replPartitionInterval.) (PARTITION VALUES LESS THAN (&replPartitionInterval.))';
      ELSE
        li_partclause := '';
        DBMS_OUTPUT.put_line('WARNING: Partitioning is not enabled in this instance and cannot be enabled.');
      END IF;
    
      EXECUTE IMMEDIATE 'CREATE TABLE rpl_replication_data(
             organization_id        number(10,0)     NOT NULL,
             rtl_loc_id             number(10,0)     NOT NULL,
             wkstn_id               number(19,0)     NOT NULL,
             timestamp_str          char(24 char)    NOT NULL,
             publish_status         varchar2(32 char),
             payload                clob,
             payload_bytes          blob,
             payload_summary        varchar2(254 char),
             error_details          clob,
             orig_arrival_timestamp TIMESTAMP(6),
             reprocess_user_id      varchar2(30 char),
             reprocess_timestamp    TIMESTAMP(6),
             reprocess_attempts     number(10, 0),
             create_date            TIMESTAMP(6),
             create_user_id         varchar2(256 char),
             update_date            TIMESTAMP(6),
             update_user_id         varchar2(256 char),
             CONSTRAINT PK_rpl_replication_data PRIMARY KEY (organization_id, rtl_loc_id, timestamp_str, wkstn_id)
             USING INDEX REVERSE PCTFREE 40 
            )' || li_partclause
            ;
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_TAB_COLUMNS WHERE TABLE_NAME='RPL_REPLICATION_DATA' AND COLUMN_NAME='PAYLOAD_BYTES';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE rpl_replication_data ADD payload_bytes BLOB';
    END IF; 
END;
/

/* 
 * INDEX: [idx_repl_data_timestamp_str] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE TABLE_NAME = 'RPL_REPLICATION_DATA' AND INDEX_NAME='IDX_REPL_DATA_TIMESTAMP_STR';
          
    IF li_rowcnt <> 0 THEN
        EXECUTE IMMEDIATE 'DROP INDEX idx_repl_data_timestamp_str';
    END IF; 
END;
/

/* 
 * INDEX: [idx_repl_data_org_ps] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE TABLE_NAME = 'RPL_REPLICATION_DATA' AND INDEX_NAME='IDX_REPL_DATA_ORG_PS';
          
    IF li_rowcnt <> 0 THEN
        EXECUTE IMMEDIATE 'DROP INDEX idx_repl_data_org_ps';
    END IF; 
END;
/

/* 
 * INDEX: [idx_repl_data_org_loc_ps] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE TABLE_NAME = 'RPL_REPLICATION_DATA' AND INDEX_NAME='IDX_REPL_DATA_ORG_LOC_PS';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_repl_data_org_loc_ps ON rpl_replication_data(ORGANIZATION_ID, rtl_loc_id, publish_status) PCTFREE 40';
    END IF; 
END;
/

/* 
 * INDEX: [idx_repl_data_date_ps] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE TABLE_NAME = 'RPL_REPLICATION_DATA' AND INDEX_NAME='IDX_REPL_DATA_DATE_PS';
          
    IF li_rowcnt <> 0 THEN
        EXECUTE IMMEDIATE 'DROP INDEX idx_repl_data_date_ps';
    END IF; 
END;
/

DECLARE
    v_count int;
BEGIN
    SELECT char_length into v_count FROM user_tab_columns WHERE table_name = UPPER('rpl_replication_data') AND column_name=UPPER('reprocess_user_id');
    IF v_count < 30 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE rpl_replication_data MODIFY reprocess_user_id VARCHAR2(30 char)';
        dbms_output.put_line(' rpl_replication_data.reprocess_user_id column updated');
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_TAB_COLUMNS WHERE TABLE_NAME='RPL_REPLICATION_DATA' AND COLUMN_NAME='CREATE_USER_ID';
          
    IF li_rowcnt > 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE rpl_replication_data MODIFY create_user_id VARCHAR2(256 char)';
    END IF; 
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_TAB_COLUMNS WHERE TABLE_NAME='RPL_REPLICATION_DATA' AND COLUMN_NAME='UPDATE_USER_ID';
          
    IF li_rowcnt > 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE rpl_replication_data MODIFY update_user_id VARCHAR2(256 char)';
    END IF; 
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE TABLE_NAME = upper('poll_file_status');
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE poll_file_status(
          organization_id  number(10,0)        NOT NULL,
          file_name        varchar2(254 char)  NOT NULL,
          timestamp_str    char(24 char)       NOT NULL,
          create_date      TIMESTAMP(6),
          create_user_id   varchar2(256 char),
          update_date      TIMESTAMP(6),
          update_user_id   varchar2(256 char),
          CONSTRAINT PK_poll_file_status PRIMARY KEY (organization_id, file_name)
            )'
            ;
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_TAB_COLUMNS WHERE TABLE_NAME='POLL_FILE_STATUS' AND COLUMN_NAME='CREATE_USER_ID';
          
    IF li_rowcnt > 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE poll_file_status MODIFY create_user_id VARCHAR2(256 char)';
    END IF; 
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_TAB_COLUMNS WHERE TABLE_NAME='POLL_FILE_STATUS' AND COLUMN_NAME='UPDATE_USER_ID';
          
    IF li_rowcnt > 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE poll_file_status MODIFY update_user_id VARCHAR2(256 char)';
    END IF; 
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE TABLE_NAME = 'RPL_CLEANUP_LOG';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE rpl_cleanup_log(
           deleted_records  number(10, 0)       NOT NULL,
           start_time       TIMESTAMP(6)        NOT NULL,
           end_time         TIMESTAMP(6)        NOT NULL,
           table_name       varchar2(20 char)   NOT NULL,
           CONSTRAINT PK_rpl_cleanup_log PRIMARY KEY (start_time,table_name)
            )'
            ;
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE TABLE_NAME = 'TRN_POSLOG_WORK_ITEM';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE TRN_POSLOG_WORK_ITEM(
       organization_id      NUMBER(10, 0)        NOT NULL,
       rtl_loc_id           NUMBER(10, 0)        NOT NULL,
       BUSINESS_DATE        TIMESTAMP(6)         NOT NULL,
       WKSTN_ID             NUMBER(19, 0)        NOT NULL,
       TRANS_SEQ            NUMBER(19, 0)        NOT NULL,
       SERVICE_ID           VARCHAR2(60 char)    NOT NULL,
       WORK_STATUS          VARCHAR2(200 char),
       ERROR_DETAILS        CLOB,
       CREATE_DATE          TIMESTAMP(6),
       CREATE_USER_ID       VARCHAR2(256 char),
       UPDATE_DATE          TIMESTAMP(6),
       UPDATE_USER_ID       VARCHAR2(256 char),
       CONSTRAINT PK_TRN_POSLOG_WORK_ITEM PRIMARY KEY (organization_id, rtl_loc_id, BUSINESS_DATE, WKSTN_ID, TRANS_SEQ, SERVICE_ID)
       )'
       ;
    END IF;
END;
/

DECLARE
    v_count int;
BEGIN
    SELECT char_length into v_count FROM user_tab_columns WHERE table_name = 'TRN_POSLOG_WORK_ITEM' AND column_name='CREATE_USER_ID';
    IF v_count < 256 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE trn_poslog_work_item MODIFY create_user_id VARCHAR2(256 char)';
        dbms_output.put_line(' trn_poslog_work_item.create_user_id column updated');
    END IF;
    SELECT char_length into v_count FROM user_tab_columns WHERE table_name = 'TRN_POSLOG_WORK_ITEM' AND column_name='UPDATE_USER_ID';
    IF v_count < 256 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE trn_poslog_work_item MODIFY update_user_id VARCHAR2(256 char)';
        dbms_output.put_line(' trn_poslog_work_item.update_user_id column updated');
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE TABLE_NAME = 'CLU_CLUSTER_CONSENSUS';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE CLU_CLUSTER_CONSENSUS(
       CONSENSUSID NUMBER(10,0),
       DIRECTIVE   VARCHAR2(128 CHAR),
       REASON      VARCHAR2(128 CHAR),
       SETBYNODE   VARCHAR2(128 CHAR),
       MEMBERSHIP  VARCHAR2(4000 CHAR),
       TMSTMP      TIMESTAMP(6),
       CONSTRAINT PK_CLU_CLUSTER_CONSENSUS PRIMARY KEY (CONSENSUSID)
            )'
            ;
    END IF;
END;
/

/* 
 * INDEX: [IDX_CLUSTER_CONSENSUS_TMSTMP] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE TABLE_NAME = 'CLU_CLUSTER_CONSENSUS' AND INDEX_NAME='IDX_CLUSTER_CONSENSUS_TMSTMP';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IDX_CLUSTER_CONSENSUS_TMSTMP ON CLU_CLUSTER_CONSENSUS(TMSTMP)';
    END IF; 
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE TABLE_NAME = 'CLU_CLUSTER_NODES';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE CLU_CLUSTER_NODES(
       NODENAME VARCHAR2(128 CHAR),
       STATESEQ NUMBER(10,0),
       CONSENSUSID NUMBER(10,0),
       STATE VARCHAR2(128 CHAR),
       TMSTMP TIMESTAMP(6),
       CONSTRAINT PK_CLU_CLUSTER_NODES PRIMARY KEY(NODENAME, STATESEQ)
            )'
            ;
    END IF;
END;
/

/* 
 * INDEX: [IDX_CLUSTER_NODES_TMSTMP] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE TABLE_NAME = 'CLU_CLUSTER_NODES' AND INDEX_NAME='IDX_CLUSTER_NODES_TMSTMP';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IDX_CLUSTER_NODES_TMSTMP ON CLU_CLUSTER_NODES(TMSTMP)';
    END IF; 
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE TABLE_NAME = 'DAT_MIGRATION_LOG';

    IF li_rowcnt = 0 THEN
       EXECUTE IMMEDIATE 'CREATE TABLE dat_migration_log(
       batch_id            NUMBER(13,0),
       table_name          VARCHAR2(50 CHAR),
       file_name           VARCHAR2(128 CHAR),
       CONSTRAINT pk_dat_migration_log PRIMARY KEY (batch_id, table_name, file_name)
            )'
            ;
    END IF;
END;
/


DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE TABLE_NAME = 'TRN_BRCST_SVC_QUEUE';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'create table TRN_BRCST_SVC_QUEUE (
       organization_id number(10,0),
       service_id      varchar2(254 char),
       rtl_loc_id      number(10,0),
       wkstn_id        number(19,0),
       trans_seq       number(19,0),
       business_date   timestamp(6),
       work_status     varchar2(30 char) NOT NULL,
       batch_id        char(36 char),
       CREATE_DATE     TIMESTAMP(6),
       CREATE_USER_ID  VARCHAR2(256 char),
       UPDATE_DATE     TIMESTAMP(6),
       UPDATE_USER_ID  VARCHAR2(256 char),
       CONSTRAINT PK_TRN_BRCST_SVC_QUEUE PRIMARY KEY (
         organization_id, service_id, rtl_loc_id, wkstn_id, trans_seq, business_date)
       USING INDEX
       )'
       ;
    END IF;
END;
/

DECLARE
    v_count int;
BEGIN
    SELECT char_length into v_count FROM user_tab_columns WHERE table_name = 'TRN_BRCST_SVC_QUEUE' AND column_name='CREATE_USER_ID';
    IF v_count < 256 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TRN_BRCST_SVC_QUEUE MODIFY create_user_id VARCHAR2(256 char)';
        dbms_output.put_line(' TRN_BRCST_SVC_QUEUE.create_user_id column updated');
    END IF;
    SELECT char_length into v_count FROM user_tab_columns WHERE table_name = 'TRN_BRCST_SVC_QUEUE' AND column_name='UPDATE_USER_ID';
    IF v_count < 256 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE TRN_BRCST_SVC_QUEUE MODIFY update_user_id VARCHAR2(256 char)';
        dbms_output.put_line(' TRN_BRCST_SVC_QUEUE.update_user_id column updated');
    END IF;
END;
/

/* 
 * INDEX: [IDX_BSQ_WKSTAT] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE TABLE_NAME = 'TRN_BRCST_SVC_QUEUE' AND INDEX_NAME='IDX_BSQ_WKSTAT';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX IDX_BSQ_WKSTAT ON TRN_BRCST_SVC_QUEUE(work_status)';
    END IF; 
END;
/

DECLARE
    v_count int;
BEGIN
    SELECT char_length into v_count FROM user_tab_columns WHERE table_name = 'TRN_BRCST_SVC_QUEUE' AND column_name='CREATE_USER_ID';
    IF v_count < 256 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE trn_brcst_svc_queue MODIFY create_user_id VARCHAR2(256 char)';
        dbms_output.put_line(' trn_brcst_svc_queue.create_user_id column updated');
    END IF;
    SELECT char_length into v_count FROM user_tab_columns WHERE table_name = 'TRN_BRCST_SVC_QUEUE' AND column_name='UPDATE_USER_ID';
    IF v_count < 256 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE trn_brcst_svc_queue MODIFY update_user_id VARCHAR2(256 char)';
        dbms_output.put_line(' trn_brcst_svc_queue.update_user_id column updated');
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_job_details';
 
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE xctr_qrtz_job_details (
    sched_name                    VARCHAR2(120)            NOT NULL,
    job_name                      VARCHAR2(200)            NOT NULL,
    job_group                     VARCHAR2(200)            NOT NULL,
    description                   VARCHAR2(250)            NULL,
    job_class_name                VARCHAR2(250)            NOT NULL, 
    is_durable                    VARCHAR2(1)              NOT NULL,
    is_nonconcurrent              VARCHAR2(1)              NOT NULL,
    is_update_data                VARCHAR2(1)              NOT NULL,
    requests_recovery             VARCHAR2(1)              NOT NULL,
    job_data                      BLOB                     NULL,
    CONSTRAINT xctr_qrtz_job_details_pk PRIMARY KEY (sched_name,job_name,job_group)
    )'
       ;
    END IF;
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_j_req_recovery] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_job_details' AND LOWER(INDEX_NAME) = 'idx_xctr_qrtz_j_req_recovery';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_j_req_recovery ON xctr_qrtz_job_details(SCHED_NAME,REQUESTS_RECOVERY)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_j_grp] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_job_details' AND LOWER(INDEX_NAME) = 'idx_xctr_qrtz_j_grp';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_j_grp ON xctr_qrtz_job_details(SCHED_NAME,JOB_GROUP)';
    END IF; 
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_triggers';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE xctr_qrtz_triggers (
    sched_name                    VARCHAR2(120)            NOT NULL,
    trigger_name                  VARCHAR2(160)            NOT NULL,
    trigger_group                 VARCHAR2(160)            NOT NULL,
    job_name                      VARCHAR2(200)            NOT NULL, 
    job_group                     VARCHAR2(200)            NOT NULL,
    description                   VARCHAR2(250)            NULL,
    next_fire_time                NUMBER(13)               NULL,
    prev_fire_time                NUMBER(13)               NULL,
    priority                      NUMBER(13)               NULL,
    trigger_state                 VARCHAR2(16)             NOT NULL,
    trigger_type                  VARCHAR2(8)              NOT NULL,
    start_time                    NUMBER(13)               NOT NULL,
    end_time                      NUMBER(13)               NULL,
    calendar_name                 VARCHAR2(200)            NULL,
    misfire_instr                 NUMBER(2)                NULL,
    job_data                      BLOB                     NULL,
    CONSTRAINT xctr_qrtz_triggers_pk PRIMARY KEY (sched_name,trigger_name,trigger_group)
  )'
       ;
    END IF;
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_t_j] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_triggers' AND LOWER(INDEX_NAME) = 'idx_xctr_qrtz_t_j';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_t_j ON xctr_qrtz_triggers(sched_name,job_name,job_group)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_t_jg] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_triggers' AND LOWER(INDEX_NAME) = 'idx_xctr_qrtz_t_jg';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_t_jg ON xctr_qrtz_triggers(sched_name,job_group)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_t_c] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_triggers' AND LOWER(INDEX_NAME) = 'idx_xctr_qrtz_t_c';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_t_c ON xctr_qrtz_triggers(sched_name,calendar_name)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_t_g] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_triggers' AND LOWER(INDEX_NAME) = 'idx_xctr_qrtz_t_g';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_t_g ON xctr_qrtz_triggers(sched_name,trigger_group)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_t_state] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_triggers' AND LOWER(INDEX_NAME) = 'idx_xctr_qrtz_t_state';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_t_state ON xctr_qrtz_triggers(sched_name,trigger_state)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_t_n_state] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_triggers' AND LOWER(INDEX_NAME) = 'idx_xctr_qrtz_t_n_state';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_t_n_state ON xctr_qrtz_triggers(sched_name,trigger_name,trigger_group,trigger_state)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_t_n_g_state] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_triggers' AND LOWER(INDEX_NAME) = 'idx_xctr_qrtz_t_n_g_state';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_t_n_g_state ON xctr_qrtz_triggers(sched_name,trigger_group,trigger_state)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_t_next_fire_time] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_triggers' AND LOWER(INDEX_NAME) = 'idx_xctr_qrtz_t_next_fire_time';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_t_next_fire_time ON xctr_qrtz_triggers(sched_name,next_fire_time)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_t_nft_st] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_triggers' AND LOWER(INDEX_NAME) ='idx_xctr_qrtz_t_nft_st';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_t_nft_st ON xctr_qrtz_triggers(sched_name,trigger_state,next_fire_time)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_t_nft_misfire] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_triggers' AND LOWER(INDEX_NAME) ='idx_xctr_qrtz_t_nft_misfire';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_t_nft_misfire ON xctr_qrtz_triggers(sched_name,misfire_instr,next_fire_time)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_t_nft_st_misfire] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_triggers' AND LOWER(INDEX_NAME) ='idx_xctr_qrtz_t_nft_st_misfire';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_t_nft_st_misfire ON xctr_qrtz_triggers(sched_name,misfire_instr,next_fire_time,trigger_state)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_qrtz_t_nft_st_misfire_grp] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_triggers' AND LOWER(INDEX_NAME) ='idx_qrtz_t_nft_st_misfire_grp';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_qrtz_t_nft_st_misfire_grp ON xctr_qrtz_triggers(sched_name,misfire_instr,next_fire_time,trigger_group,trigger_state)';
    END IF; 
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_simple_triggers';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE xctr_qrtz_simple_triggers (
    sched_name                    VARCHAR2(120)            NOT NULL,
    trigger_name                  VARCHAR2(160)            NOT NULL,
    trigger_group                 VARCHAR2(160)            NOT NULL, 
    repeat_count                  NUMBER(7)                NOT NULL,
    repeat_interval               NUMBER(12)               NOT NULL,
    times_triggered               NUMBER(10)               NOT NULL,
    CONSTRAINT xctr_qrtz_simple_triggers_pk PRIMARY KEY (sched_name,trigger_name,trigger_group)
)'
       ;
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_simprop_triggers';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE xctr_qrtz_simprop_triggers (          
    sched_name                    VARCHAR2(120)            NOT NULL,
    trigger_name                  VARCHAR2(160)            NOT NULL,
    trigger_group                 VARCHAR2(160)            NOT NULL,
    str_prop_1                    VARCHAR2(512)            NULL,
    str_prop_2                    VARCHAR2(512)            NULL,
    str_prop_3                    VARCHAR2(512)            NULL,
    int_prop_1                    NUMBER(10)               NULL,
    int_prop_2                    NUMBER(10)               NULL,
    long_prop_1                   NUMBER(13)               NULL,
    long_prop_2                   NUMBER(13)               NULL,
    dec_prop_1                    NUMERIC(13,4)            NULL,
    dec_prop_2                    NUMERIC(13,4)            NULL,
    bool_prop_1                   VARCHAR2(1)              NULL,
    bool_prop_2                   VARCHAR2(1)              NULL,
    CONSTRAINT xctr_qrtz_simprop_trig_pk PRIMARY KEY (sched_name,trigger_name,trigger_group)
)'
       ;
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_cron_triggers';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE xctr_qrtz_cron_triggers (
    sched_name                    VARCHAR2(120)            NOT NULL,
    trigger_name                  VARCHAR2(160)            NOT NULL,
    trigger_group                 VARCHAR2(160)            NOT NULL, 
    cron_expression               VARCHAR2(120)            NOT NULL,
    time_zone_id                  VARCHAR2(80),
    CONSTRAINT xctr_qrtz_cron_triggers_pk PRIMARY KEY (sched_name,trigger_name,trigger_group)
)'
       ;
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_blob_triggers';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE xctr_qrtz_blob_triggers (
    sched_name                    VARCHAR2(120)            NOT NULL,
    trigger_name                  VARCHAR2(160)            NOT NULL,
    trigger_group                 VARCHAR2(160)            NOT NULL,
    blob_data                     BLOB                     NULL,
    CONSTRAINT xctr_qrtz_blob_trig_pk PRIMARY KEY (sched_name,trigger_name,trigger_group)
  )'
       ;
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_fired_triggers';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE xctr_qrtz_fired_triggers (
    sched_name                    VARCHAR2(120)            NOT NULL,
    entry_id                      VARCHAR2(95)             NOT NULL,
    TRIGGER_NAME                  VARCHAR2(200)            NOT NULL,
    TRIGGER_GROUP                 VARCHAR2(200)            NOT NULL,
    INSTANCE_NAME                 VARCHAR2(200)            NOT NULL,
    FIRED_TIME                    NUMBER(13)               NOT NULL,
    SCHED_TIME                    NUMBER(13)               NOT NULL,
    PRIORITY                      NUMBER(13)               NOT NULL,
    STATE                         VARCHAR2(16)             NOT NULL,
    JOB_NAME                      VARCHAR2(200)            NULL,
    JOB_GROUP                     VARCHAR2(200)            NULL,
    IS_NONCONCURRENT              VARCHAR2(1)              NULL,
    REQUESTS_RECOVERY             VARCHAR2(1)              NULL,
    CONSTRAINT xctr_qrtz_fired_triggers_pk PRIMARY KEY (sched_name,entry_id)
  )'
       ;
    END IF;
END;
/

/* 
 * INDEX: [idx_qrtz_ft_trig_inst_name] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_fired_triggers' AND LOWER(INDEX_NAME) ='idx_qrtz_ft_trig_inst_name';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_qrtz_ft_trig_inst_name ON xctr_qrtz_fired_triggers(sched_name,instance_name)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_qrtz_ft_inst_job_req_rcvry] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_fired_triggers' AND LOWER(INDEX_NAME) ='idx_qrtz_ft_inst_job_req_rcvry';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_qrtz_ft_inst_job_req_rcvry ON xctr_qrtz_fired_triggers(sched_name,instance_name,requests_recovery)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_ft_j_g] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_fired_triggers' AND LOWER(INDEX_NAME) ='idx_xctr_qrtz_ft_j_g';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_ft_j_g ON xctr_qrtz_fired_triggers(sched_name,job_name,job_group)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_ft_jg] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_fired_triggers' AND LOWER(INDEX_NAME) ='idx_xctr_qrtz_ft_jg';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_ft_jg ON xctr_qrtz_fired_triggers(sched_name,job_group)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_ft_t_g] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_fired_triggers' AND LOWER(INDEX_NAME) ='idx_xctr_qrtz_ft_t_g';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_ft_t_g ON xctr_qrtz_fired_triggers(sched_name,trigger_name,trigger_group)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_xctr_qrtz_ft_tg] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_fired_triggers' AND LOWER(INDEX_NAME) ='idx_xctr_qrtz_ft_tg';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_xctr_qrtz_ft_tg ON xctr_qrtz_fired_triggers(sched_name,trigger_group)';
    END IF; 
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_calendars';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE xctr_qrtz_calendars (
    sched_name                    VARCHAR2(120)            NOT NULL,
    calendar_name                 VARCHAR2(200)            NOT NULL,
    calendar                      BLOB                     NULL,
    CONSTRAINT xctr_qrtz_calendars_pk PRIMARY KEY (sched_name,calendar_name)
  )'
       ;
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_paused_trigger_grps';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE xctr_qrtz_paused_trigger_grps (
    sched_name                    VARCHAR2(120)            NOT NULL,
    trigger_group                 VARCHAR2(160)            NOT NULL, 
    CONSTRAINT qrtz_paused_trigger_grps_pk PRIMARY KEY (sched_name,trigger_group)
  )'
       ;
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_locks';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE xctr_qrtz_locks (
    sched_name                    VARCHAR2(120)            NOT NULL,
    lock_name                     VARCHAR2(40)             NOT NULL, 
    CONSTRAINT xctr_qrtz_locks_pk PRIMARY KEY (sched_name, lock_name)
  )'
       ;
    END IF;
END;
/

DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE LOWER(TABLE_NAME) = 'xctr_qrtz_scheduler_state';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE xctr_qrtz_scheduler_state (
    sched_name                    VARCHAR2(120)            NOT NULL,
    instance_name                 VARCHAR2(200)            NOT NULL,
    last_checkin_time             NUMBER(13)               NOT NULL,
    checkin_interval              NUMBER(13)               NOT NULL,
    CONSTRAINT xctr_qrtz_scheduler_state_pk PRIMARY KEY (sched_name,instance_name)
  )'
       ;
    END IF;
END;
/

-- [RXPS-61785]
/* 
 * TABLE: [app_log] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt
    FROM USER_TABLES
    WHERE TABLE_NAME = upper('app_log');
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE app_log(
    id NUMBER(19, 0) GENERATED ALWAYS AS IDENTITY (
      START WITH 1 
      INCREMENT BY 1 
      MINVALUE 1
      MAXVALUE 9999999999999999999
      CYCLE
      CACHE 200
      ORDER),
    ctx_id VARCHAR2(40 char),
    lvl VARCHAR2(20 char) NOT NULL,
    time TIMESTAMP(6) NOT NULL,
    app_id VARCHAR2(20 char) NOT NULL,
    thread VARCHAR2(256 char) NOT NULL,
    category VARCHAR2(256 char) NOT NULL,
    message CLOB,
    exception CLOB,
    CONSTRAINT pk_app_log PRIMARY KEY (id)
     )';
    END IF;
END;
/

/* 
 * INDEX: [idx_app_log_lvl_appid] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'app_log' AND LOWER(INDEX_NAME) ='idx_app_log_lvl_appid';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_app_log_lvl_appid ON app_log(lvl, app_id)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_app_log_appid] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'app_log' AND LOWER(INDEX_NAME) ='idx_app_log_appid';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_app_log_appid ON app_log(app_id)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_app_log_lvl_appid_time] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'app_log' AND LOWER(INDEX_NAME) ='idx_app_log_lvl_appid_time';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_app_log_lvl_appid_time ON app_log(lvl, time, app_id)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_app_log_appid_time] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'app_log' AND LOWER(INDEX_NAME) ='idx_app_log_appid_time';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_app_log_appid_time ON app_log(time, app_id)';
    END IF; 
END;
/

/* 
 * INDEX: [idx_app_log_ctxid] 
 */
DECLARE
    li_rowcnt       int;
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'app_log' AND LOWER(INDEX_NAME) ='idx_app_log_ctxid';
          
    IF li_rowcnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX idx_app_log_ctxid ON app_log(ctx_id)';
    END IF; 
END;
/

--
-- Domain indexes for Text Search scheduled to synchronize every 10 minutes.
--

/* 
 * INDEX: [idx_app_log_message] 
 */
DECLARE
    li_rowcnt       int;
    dyn_sql_statement   VARCHAR2(1000);
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'app_log' AND LOWER(INDEX_NAME) ='idx_app_log_message';
          
    IF li_rowcnt = 0 THEN
        dyn_sql_statement := 'CREATE INDEX idx_app_log_message ON app_log(message) INDEXTYPE IS CTXSYS.CONTEXT PARAMETERS (''SYNC (EVERY "SYSDATE+10/24/60") STOPLIST CTXSYS.EMPTY_STOPLIST'')';
        EXECUTE IMMEDIATE dyn_sql_statement;
    END IF; 
END;
/

/* 
 * INDEX: [idx_app_log_exception] 
 */
DECLARE
    li_rowcnt       int;
    dyn_sql_statement   VARCHAR2(1000);
BEGIN
    SELECT count(*) INTO li_rowcnt FROM USER_INDEXES WHERE LOWER(TABLE_NAME) = 'app_log' AND LOWER(INDEX_NAME) ='idx_app_log_exception';
          
    IF li_rowcnt = 0 THEN
        dyn_sql_statement := 'CREATE INDEX idx_app_log_exception ON app_log(exception) INDEXTYPE IS CTXSYS.CONTEXT PARAMETERS (''SYNC (EVERY "SYSDATE+10/24/60") STOPLIST CTXSYS.EMPTY_STOPLIST'')';
        EXECUTE IMMEDIATE dyn_sql_statement;
    END IF; 
END;
/

-- [RXPS-61785] END

/* 
 * STORED PROCEDURE: [BSQ_LOCK_BATCH] 
 */
create or replace PROCEDURE BSQ_LOCK_BATCH (
  argOrgId IN number,
  argServiceId IN varchar2,
  argBatchId IN varchar2,
  argMaxBatchRecords IN number,
  argUpdateUserId IN varchar2,
  argBatchSize OUT number) IS
rowcount number := 0;
c_row TRN_BRCST_SVC_QUEUE%rowtype;
CURSOR C IS
   select *
   from TRN_BRCST_SVC_QUEUE
   where ORGANIZATION_ID = argOrgId
   and SERVICE_ID = argServiceId
   and WORK_STATUS='NEW'
   order by CREATE_DATE
   for update skip locked
   ;
BEGIN
  OPEN C;
  LOOP
    FETCH C into c_row;
    EXIT WHEN rowcount >= argMaxBatchRecords OR C%notfound;
    update TRN_BRCST_SVC_QUEUE
    set WORK_STATUS='PROCESSED', BATCH_ID=argBatchId, UPDATE_USER_ID=argUpdateUserId, UPDATE_DATE=LOCALTIMESTAMP
    where current of C;
    rowcount := rowcount + 1;
  END LOOP;
  argBatchSize := rowCount;
END;
/


/*
 *  STORED PROCEDURE: [ORACLE_MAINT_REPLDATA]
 *
 *  Important note: this procedure should NOT be scheduled itself; this stored procedure is
 *  is really just a private "sub procedure" called by ORACLE_MAINT, which is the one that
 *  should be scheduled.
 */
CREATE OR REPLACE PROCEDURE ORACLE_MAINT_REPLDATA(ai_delay IN NUMBER)
IS
  CURSOR c1 IS
    SELECT t.INTERVAL FROM USER_PART_TABLES t, USER_PART_KEY_COLUMNS c
      WHERE t.table_name = 'RPL_REPLICATION_DATA'
      AND t.table_name = c.name
      AND c.object_type = 'TABLE'
      AND c.column_name = 'RTL_LOC_ID'
      AND t.partitioning_type = 'RANGE';

  ls_dyn_sql_statement   VARCHAR2(1000);
  li_interval            INT := -1;

  CURSOR c2 IS
    SELECT tp.PARTITION_NAME FROM USER_TAB_PARTITIONS tp
      WHERE tp.TABLE_NAME = 'RPL_REPLICATION_DATA';
      
  li_cnt      INT;
  ld_start    DATE;
  ld_end      DATE;
  ld_old_data DATE;

BEGIN
  --
  -- The c1 cursor helps us determine the partioning interval size (or else find out that the
  -- the table is not partitioned the way we expect it, or it's not partitioned at all).
  --
  FOR c1rec IN c1 LOOP
     EXIT WHEN c1%notfound;
     
     -- The Oracle tables for getting "metadata" about partitioning use a datatype that's not a
     -- standard numeric type, so working with this data does not work with standard SQL
     -- facilities.  The technique you see here is the most straightforward way I've found to work
     -- around this limitation.
     ls_dyn_sql_statement := 'SELECT '||c1rec.INTERVAL||' FROM DUAL';
     EXECUTE IMMEDIATE ls_dyn_sql_statement INTO li_interval;
  END LOOP;

  ld_start := SYSDATE;
  ld_old_data := ld_start - ai_delay;
  IF li_interval > 0 THEN
    --
    -- Since we know we're partitioned, iterate through the current partitions, and individually
    -- delete the appropriate records from each one.
    --
    li_cnt := 0;

    FOR c2rec IN c2 LOOP
    
      -- Use "partition selection" syntax to limit the query to each specific partition table;
      -- e.g. "select * from MYTABLE partition(SYS_P1234)".  Note that partition names are very
      -- much like table names, meaning you can't refer to them by a string (kinda like how you
      -- can't do this:  select * from 'MYTABLE'  ...you can't have 'MYTABLE' as a string).  So
      -- that's why we have to build the SQL statement and run it via EXECUTE IMMEDIATE.
      ls_dyn_sql_statement := 'DELETE FROM RPL_REPLICATION_DATA partition('
        || c2rec.PARTITION_NAME
        || ') WHERE PUBLISH_STATUS=''COMPLETE'' AND UPDATE_DATE < '''
        || ld_old_data || ''' ';

      EXECUTE IMMEDIATE ls_dyn_sql_statement;
      li_cnt := li_cnt + sql%rowcount;
      
    END LOOP;

  ELSE
    --
    -- Partitioning not set up, so delete data the old-fashioned way.
    --
    DELETE FROM RPL_REPLICATION_DATA WHERE PUBLISH_STATUS='COMPLETE' AND UPDATE_DATE < ld_old_data;
    li_cnt := sql%rowcount;

  END IF;

  --
  -- Finally, log results of the deletions.
  --

  ld_end := SYSDATE;

  INSERT INTO rpl_cleanup_log (deleted_records, start_time, end_time, table_name)
    VALUES(li_cnt,ld_start,ld_end,'RPL_REPLICATION_DATA');

END ORACLE_MAINT_REPLDATA;
/


PROMPT ORACLE_MAINT;

CREATE OR REPLACE PROCEDURE ORACLE_MAINT (ai_delay IN NUMBER := 3)
 IS
li_cnt    int;
ld_start    date;
ld_end    date;
BEGIN

 -- call a separate procedure to delete old RPL_REPLICATION_DATA since this is now a more complicated
 -- operation given our partitioning approach on this table.
 ORACLE_MAINT_REPLDATA(ai_delay);

 ld_start := SYSDATE;

 DELETE FROM trn_poslog_work_item WHERE UPPER(WORK_STATUS)='COMPLETE' AND UPDATE_DATE < ld_start-ai_delay;

 li_cnt := sql%rowcount;

 ld_end := SYSDATE;

 INSERT INTO rpl_cleanup_log (deleted_records,start_time,end_time,table_name) VALUES(li_cnt,ld_start,ld_end,'trn_poslog_work_item');

 ld_start := SYSDATE;

 DELETE FROM trn_brcst_svc_queue WHERE UPPER(WORK_STATUS)='PROCESSED' AND UPDATE_DATE < ld_start-ai_delay;

 li_cnt := sql%rowcount;
 
 ld_end := SYSDATE;

 INSERT INTO rpl_cleanup_log (deleted_records,start_time,end_time,table_name) VALUES(li_cnt,ld_start,ld_end,'trn_brcst_svc_queue');
return;
END ORACLE_MAINT;
/

declare
    cnt number;
    curSchema VARCHAR2(100);
BEGIN 
   select sys_context( 'userenv', 'current_schema' ) into curSchema from dual;
   select count(*) into cnt from DBA_SCHEDULER_JOBS where job_name='MAINT_JOB' and owner=upper(curSchema);
    if cnt>0 then
     sys.dbms_scheduler.drop_job(job_name => 'MAINT_JOB'); 
    end if;
COMMIT;
END;
/

BEGIN
    sys.dbms_scheduler.create_job(
    job_name => 'MAINT_JOB',
    job_type => 'PLSQL_BLOCK',
    job_action => 'ORACLE_MAINT;',
    repeat_interval => 'FREQ=DAILY;INTERVAL = 1; BYHOUR=0',
    start_date => sysdate,
    enabled => true);
COMMIT;
END;
/

