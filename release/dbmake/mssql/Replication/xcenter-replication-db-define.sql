

DECLARE
  @dbName nvarchar(30);

SELECT @dbName = DB_NAME();

IF OBJECT_ID('rpl_replication_data') IS NULL
BEGIN
PRINT 'Create the rpl_replication_data table.'
exec('CREATE TABLE [dbo].[rpl_replication_data](
    [organization_id]         int            NOT NULL,
    [rtl_loc_id]              int            NOT NULL,
    [wkstn_id]                bigint         NOT NULL,
    [timestamp_str]           char(24)       NOT NULL,
    [publish_status]          varchar(32)    NULL,
    [payload]                 varchar(max)   NULL,
    [payload_bytes]           varbinary(max) NULL,
    [payload_summary]         varchar(254)   NULL,
    [error_details]           varchar(max)   NULL,
    [orig_arrival_timestamp]  datetime       NULL,
    [reprocess_user_id]       varchar(30)    NULL,
    [reprocess_timestamp]     datetime       NULL,
    [reprocess_attempts]      int            NULL,
    [create_date]             datetime       NULL,
    [create_user_id]          varchar(256)    NULL,
    [update_date]             datetime       NULL,
    [update_user_id]          varchar(256)    NULL,
    CONSTRAINT [PK_rpl_replication_data] PRIMARY KEY CLUSTERED ([organization_id], [rtl_loc_id], [timestamp_str], [wkstn_id]) WITH (FILLFACTOR = 60)
)');
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE name = 'payload_bytes' AND object_id = OBJECT_ID('rpl_replication_data'))
  exec('ALTER TABLE rpl_replication_data ADD payload_bytes varbinary(max)');
GO

/* 
 * INDEX: [idx_repl_data_timestamp_str] 
 */
IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('rpl_replication_data') AND name = 'idx_repl_data_timestamp_str')
    exec('DROP INDEX idx_repl_data_timestamp_str ON rpl_replication_data');
    PRINT 'Dropped index idx_repl_data_timestamp_str on rpl_replication_data';
GO

/* 
 * INDEX: [idx_repl_data_org_ps] 
 */
IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('rpl_replication_data') AND name = 'idx_repl_data_org_ps')
    exec('DROP INDEX idx_repl_data_org_ps ON rpl_replication_data');
    PRINT 'Dropped index idx_repl_data_org_ps on rpl_replication_data';
GO

/* 
 * INDEX: [idx_repl_data_org_loc_ps] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('rpl_replication_data') AND name = 'idx_repl_data_org_loc_ps')
    exec('CREATE INDEX idx_repl_data_org_loc_ps ON rpl_replication_data(ORGANIZATION_ID, rtl_loc_id, publish_status) WITH (FILLFACTOR = 60)');
    PRINT 'Created index idx_repl_data_org_loc_ps on rpl_replication_data';
GO


/* 
 * INDEX: [idx_repl_data_date_ps] 
 */
IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('rpl_replication_data') AND name = 'idx_repl_data_date_ps')
    exec('DROP INDEX idx_repl_data_date_ps ON rpl_replication_data');
    PRINT 'Dropped index idx_repl_data_date_ps on rpl_replication_data';
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'reprocess_user_id' AND object_id = OBJECT_ID('rpl_replication_data'))
  exec('ALTER TABLE rpl_replication_data ALTER COLUMN reprocess_user_id varchar(30) NULL');
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'payload' AND object_id = OBJECT_ID('rpl_replication_data') AND system_type_id <> 231 AND system_type_id <> 167)
  exec('ALTER TABLE rpl_replication_data ALTER COLUMN payload varchar(max) NULL');
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'error_details' AND object_id = OBJECT_ID('rpl_replication_data') AND system_type_id <> 231 AND system_type_id <> 167)
  exec('ALTER TABLE rpl_replication_data ALTER COLUMN error_details varchar(max) NULL');
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'create_user_id' AND object_id = OBJECT_ID('rpl_replication_data'))
  exec('ALTER TABLE rpl_replication_data ALTER COLUMN create_user_id varchar(256) NULL');
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'update_user_id' AND object_id = OBJECT_ID('rpl_replication_data'))
  exec('ALTER TABLE rpl_replication_data ALTER COLUMN update_user_id varchar(256) NULL');
GO

IF OBJECT_ID('poll_file_status') IS NULL
BEGIN
PRINT 'Create the poll_file_status table.'
exec('CREATE TABLE [dbo].[poll_file_status](
    [organization_id]         int           NOT NULL,
    [file_name]               varchar(254)  NOT NULL,
    [timestamp_str]           char(24)      NOT NULL,
    [create_date]             datetime      NULL,
    [create_user_id]          varchar(256)   NULL,
    [update_date]             datetime      NULL,
    [update_user_id]          varchar(256)   NULL,
    CONSTRAINT [PK_poll_file_status] PRIMARY KEY CLUSTERED ([organization_id], [file_name]) WITH (FILLFACTOR = 80)
)');
END


IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'timestamp_str' AND object_id = OBJECT_ID('poll_file_status'))
  exec('ALTER TABLE poll_file_status ALTER COLUMN timestamp_str char(24) NOT NULL');
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'create_user_id' AND object_id = OBJECT_ID('poll_file_status'))
  exec('ALTER TABLE poll_file_status ALTER COLUMN create_user_id varchar(256) NULL');
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'update_user_id' AND object_id = OBJECT_ID('poll_file_status'))
  exec('ALTER TABLE poll_file_status ALTER COLUMN update_user_id varchar(256) NULL');
GO

IF OBJECT_ID('rpl_cleanup_log') IS NULL
BEGIN
PRINT 'Create the rpl_cleanup_log table.'
exec('CREATE TABLE [dbo].[rpl_cleanup_log](
    [deleted_records]   int         NOT NULL,
    [start_time]        datetime    NOT NULL,
    [end_time]          datetime    NOT NULL,
    [table_name]        varchar(20) NOT NULL,
    CONSTRAINT [PK_rpl_cleanup_log] PRIMARY KEY CLUSTERED ([start_time],[table_name]) WITH (FILLFACTOR = 80)
)');
END

IF OBJECT_ID('trn_poslog_work_item') IS NULL
BEGIN
PRINT 'Create the trn_poslog_work_item table.'
exec('CREATE TABLE [dbo].[trn_poslog_work_item](
    [organization_id]    int            NOT NULL,
    [rtl_loc_id]         int            NOT NULL,
    [business_date]      datetime       NOT NULL,
    [wkstn_id]           bigint         NOT NULL,
    [trans_seq]          bigint         NOT NULL,
    [service_id]         varchar(60)    NOT NULL,
    [work_status]        varchar(200)   NULL,
    [error_details]      varchar(max)   NULL,
    [create_date]        datetime       NULL,
    [create_user_id]     varchar(256)   NULL,
    [update_date]        datetime       NULL,
    [update_user_id]     varchar(256)   NULL,
    CONSTRAINT [pk_trn_poslog_work_item] PRIMARY KEY CLUSTERED ([organization_id], [rtl_loc_id], [business_date], [wkstn_id], [trans_seq], [service_id]) WITH (FILLFACTOR = 80)
)');
END

IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'error_details' AND object_id = OBJECT_ID('trn_poslog_work_item') AND system_type_id <> 231 AND system_type_id <> 167)
  exec('ALTER TABLE trn_poslog_work_item ALTER COLUMN error_details varchar(max) NULL');
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'create_user_id' AND object_id = OBJECT_ID('trn_poslog_work_item'))
  exec('ALTER TABLE trn_poslog_work_item ALTER COLUMN create_user_id varchar(256) NULL');
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'update_user_id' AND object_id = OBJECT_ID('trn_poslog_work_item'))
  exec('ALTER TABLE trn_poslog_work_item ALTER COLUMN update_user_id varchar(256) NULL');
GO

IF OBJECT_ID('clu_cluster_consensus') IS NULL
BEGIN
PRINT 'Create the clu_cluster_consensus table.'
exec('CREATE TABLE [dbo].[clu_cluster_consensus](
    [consensusid] int           NOT NULL,
    [directive]   varchar(128)  NULL,
    [reason]      varchar(128)  NULL,
    [setbynode]   varchar(128)  NULL,
    [membership]  varchar(4000) NULL,
    [tmstmp]      datetime2     NULL,
    CONSTRAINT [PK_clu_cluster_consensus] PRIMARY KEY CLUSTERED ([consensusid]) WITH (FILLFACTOR = 80)
)');
END

/* 
 * INDEX: [idx_cluster_consensus_tmstmp] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('clu_cluster_consensus') AND name = 'idx_cluster_consensus_tmstmp')
    exec('CREATE INDEX idx_cluster_consensus_tmstmp ON clu_cluster_consensus(tmstmp) WITH (FILLFACTOR = 80)');

IF OBJECT_ID('clu_cluster_nodes') IS NULL
BEGIN
PRINT 'Create the clu_cluster_nodes table.'
exec('CREATE TABLE [dbo].[clu_cluster_nodes](
    [nodename]     varchar(128)  NOT NULL,
    [stateseq]     int           NOT NULL,
    [consensusid]  int           NULL,
    [state]        varchar(128)  NULL,
    [tmstmp]       datetime2   NULL,
    CONSTRAINT [PK_clu_cluster_nodes] PRIMARY KEY CLUSTERED ([nodename], [stateseq]) WITH (FILLFACTOR = 80)
)');
END

/* 
 * INDEX: [idx_cluster_nodes_tmstmp] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('clu_cluster_nodes') AND name = 'idx_cluster_nodes_tmstmp')
    exec('CREATE INDEX idx_cluster_nodes_tmstmp ON clu_cluster_nodes(tmstmp) WITH (FILLFACTOR = 80)');


IF OBJECT_ID('dat_migration_log') IS NULL
BEGIN
PRINT 'Create the dat_migration_log table.'
exec('CREATE TABLE [dbo].[dat_migration_log](
    [batch_id]    bigint        NOT NULL,
    [table_name]  varchar(50)   NOT NULL,
    [file_name]   varchar(128)  NOT NULL,
    CONSTRAINT [PK_dat_migration_log] PRIMARY KEY CLUSTERED ([batch_id], [table_name], [file_name]) WITH (FILLFACTOR = 80)
)');
END

/* 
 * TABLE: [dbo].[xctr_qrtz_job_details] 
 */
 
IF OBJECT_ID('xctr_qrtz_job_details') IS NULL
BEGIN
PRINT 'Create the xctr_qrtz_job_details table.'
exec('CREATE TABLE [dbo].[xctr_qrtz_job_details](
    [sched_name]                  varchar(120)        NOT NULL,
    [job_name]                    varchar(200)        NOT NULL,
    [job_group]                   varchar(200)        NOT NULL,
    [description]                 varchar(250)        NULL,
    [job_class_name]              varchar(250)        NOT NULL,
    [is_durable]                  varchar(1)          NOT NULL,
    [is_nonconcurrent]            varchar(1)          NOT NULL,
    [is_update_data]              varchar(1)          NOT NULL,
    [requests_recovery]           varchar(1)          NOT NULL,
    [job_data]                    varbinary(max)      NULL,
    CONSTRAINT [pk_xctr_qrtz_job_details] PRIMARY KEY CLUSTERED ([sched_name], [job_name], [job_group])
    WITH FILLFACTOR = 80
)');
END

/* 
 * INDEX: [idx_xctr_qrtz_j_req_recovery] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_job_details') AND name = 'idx_xctr_qrtz_j_req_recovery')
    exec('CREATE INDEX idx_xctr_qrtz_j_req_recovery ON xctr_qrtz_job_details(sched_name, requests_recovery) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_j_grp] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_job_details') AND name = 'idx_xctr_qrtz_j_grp')
    exec('CREATE INDEX idx_xctr_qrtz_j_grp ON xctr_qrtz_job_details(sched_name, job_group) WITH (FILLFACTOR = 80)');

/* 
 * TABLE: [dbo].[xctr_qrtz_triggers] 
 */
 
IF OBJECT_ID('xctr_qrtz_triggers') IS NULL
BEGIN
PRINT 'Create the xctr_qrtz_triggers table.'
exec('CREATE TABLE [dbo].[xctr_qrtz_triggers](
    [sched_name]                  varchar(120)        NOT NULL,
    [trigger_name]                varchar(160)        NOT NULL,
    [trigger_group]               varchar(160)        NOT NULL,
    [job_name]                    varchar(200)        NOT NULL,
    [job_group]                   varchar(200)        NOT NULL,
    [description]                 varchar(250)        NULL,
    [next_fire_time]              bigint              NULL,
    [prev_fire_time]              bigint              NULL,
    [priority]                    integer             NULL,
    [trigger_state]               varchar(16)         NOT NULL,
    [trigger_type]                varchar(8)          NOT NULL,
    [start_time]                  bigint              NOT NULL,
    [end_time]                    bigint              NULL,
    [calendar_name]               varchar(200)        NULL,
    [misfire_instr]               smallint            NULL,
    [job_data]                    varbinary(max)      NULL,
    CONSTRAINT [pk_xctr_qrtz_triggers] PRIMARY KEY CLUSTERED ([sched_name], [trigger_name], [trigger_group])
    WITH (FILLFACTOR = 80)
)');
END

/* 
 * INDEX: [idx_xctr_qrtz_t_j] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_triggers') AND name = 'idx_xctr_qrtz_t_j')
    exec('CREATE INDEX idx_xctr_qrtz_t_j ON xctr_qrtz_triggers(sched_name, job_name, job_group) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_j_grp] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_triggers') AND name = 'idx_xctr_qrtz_j_grp')
    exec('CREATE INDEX idx_xctr_qrtz_j_grp ON xctr_qrtz_triggers(sched_name, job_group) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_t_c] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_triggers') AND name = 'idx_xctr_qrtz_t_c')
    exec('CREATE INDEX idx_xctr_qrtz_t_c ON xctr_qrtz_triggers(sched_name,calendar_name) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_t_g] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_triggers') AND name = 'idx_xctr_qrtz_t_g')
    exec('CREATE INDEX idx_xctr_qrtz_t_g ON xctr_qrtz_triggers(sched_name,trigger_group) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_t_state] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_triggers') AND name = 'idx_xctr_qrtz_t_state')
    exec('CREATE INDEX idx_xctr_qrtz_t_state ON xctr_qrtz_triggers(sched_name,trigger_state) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_t_n_state] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_triggers') AND name = 'idx_xctr_qrtz_t_n_state')
    exec('CREATE INDEX idx_xctr_qrtz_t_n_state ON xctr_qrtz_triggers(sched_name,trigger_name,trigger_group,trigger_state) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_t_n_g_state] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_triggers') AND name = 'idx_xctr_qrtz_t_n_g_state')
    exec('CREATE INDEX idx_xctr_qrtz_t_n_g_state ON xctr_qrtz_triggers(sched_name,trigger_group,trigger_state) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_t_next_fire_time] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_triggers') AND name = 'idx_xctr_qrtz_t_next_fire_time')
    exec('CREATE INDEX idx_xctr_qrtz_t_next_fire_time ON xctr_qrtz_triggers(sched_name,next_fire_time) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_t_nft_st] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_triggers') AND name = 'idx_xctr_qrtz_t_nft_st')
    exec('CREATE INDEX idx_xctr_qrtz_t_nft_st ON xctr_qrtz_triggers(sched_name,trigger_state,next_fire_time) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_t_nft_misfire] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_triggers') AND name = 'idx_xctr_qrtz_t_nft_misfire')
    exec('CREATE INDEX idx_xctr_qrtz_t_nft_misfire ON xctr_qrtz_triggers(sched_name,misfire_instr,next_fire_time) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_t_nft_st_misfire] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_triggers') AND name = 'idx_xctr_qrtz_t_nft_st_misfire')
    exec('CREATE INDEX idx_xctr_qrtz_t_nft_st_misfire ON xctr_qrtz_triggers(sched_name,misfire_instr,next_fire_time,trigger_state) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_t_nft_st_misfire_grp] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_triggers') AND name = 'idx_xctr_qrtz_t_nft_st_misfire_grp')
    exec('CREATE INDEX idx_xctr_qrtz_t_nft_st_misfire_grp ON xctr_qrtz_triggers(sched_name,misfire_instr,next_fire_time,trigger_group,trigger_state) WITH (FILLFACTOR = 80)');


/* 
 * TABLE: [dbo].[xctr_qrtz_simple_triggers] 
 */
 
IF OBJECT_ID('xctr_qrtz_simple_triggers') IS NULL
BEGIN
PRINT 'Create the xctr_qrtz_simple_triggers table.'
exec('CREATE TABLE [dbo].[xctr_qrtz_simple_triggers](
    [sched_name]                  varchar(120)        NOT NULL,
    [trigger_name]                varchar(160)        NOT NULL,
    [trigger_group]               varchar(160)        NOT NULL,
    [repeat_count]                bigint              NOT NULL,
    [repeat_interval]             bigint              NOT NULL,
    [times_triggered]             bigint              NOT NULL,
    CONSTRAINT [pk_xctr_qrtz_simple_triggers] PRIMARY KEY CLUSTERED ([sched_name], [trigger_name], [trigger_group])
    WITH FILLFACTOR = 80
)');
END

/* 
 * TABLE: [dbo].[xctr_qrtz_cron_triggers] 
 */
 
IF OBJECT_ID('xctr_qrtz_cron_triggers') IS NULL
BEGIN
PRINT 'Create the xctr_qrtz_cron_triggers table.'
exec('CREATE TABLE [dbo].[xctr_qrtz_cron_triggers](
    [sched_name]                  varchar(120)             NOT NULL,
    [trigger_name]                varchar(160)             NOT NULL,
    [trigger_group]               varchar(160)             NOT NULL,
    [cron_expression]             varchar(120)             NOT NULL,
    [time_zone_id]                varchar(80),
    CONSTRAINT [pk_xctr_qrtz_cron_triggers] PRIMARY KEY CLUSTERED ([sched_name], [trigger_name], [trigger_group])
    WITH FILLFACTOR = 80
)');
END

/* 
 * TABLE: [dbo].[xctr_qrtz_simprop_triggers] 
 */
 
IF OBJECT_ID('xctr_qrtz_simprop_triggers') IS NULL
BEGIN
PRINT 'Create the xctr_qrtz_simprop_triggers table.'
exec('CREATE TABLE [dbo].[xctr_qrtz_simprop_triggers](
    [sched_name]                  varchar(120)        NOT NULL,
    [trigger_name]                varchar(160)        NOT NULL,
    [trigger_group]               varchar(160)        NOT NULL,
    [str_prop_1]                  varchar(512)        NULL,
    [str_prop_2]                  varchar(512)        NULL,
    [str_prop_3]                  varchar(512)        NULL,
    [int_prop_1]                  int                 NULL,
    [int_prop_2]                  int                 NULL,
    [long_prop_1]                 bigint              NULL,
    [long_prop_2]                 bigint              NULL,
    [dec_prop_1]                  numeric(13,4)       NULL,
    [dec_prop_2]                  numeric(13,4)       NULL,
    [bool_prop_1]                 varchar(1)          NULL,
    [bool_prop_2]                 varchar(1)          NULL,
    CONSTRAINT [pk_xctr_qrtz_simprop_triggers] PRIMARY KEY CLUSTERED ([sched_name], [trigger_name], [trigger_group])
    WITH FILLFACTOR = 80
)');
END

/* 
 * TABLE: [dbo].[xctr_qrtz_blob_triggers] 
 */
 
IF OBJECT_ID('xctr_qrtz_blob_triggers') IS NULL
BEGIN
PRINT 'Create the xctr_qrtz_blob_triggers table.'
exec('CREATE TABLE [dbo].[xctr_qrtz_blob_triggers](
    [sched_name]                  varchar(120)        NOT NULL,
    [trigger_name]                varchar(160)        NOT NULL,
    [trigger_group]               varchar(160)        NOT NULL,
    [blob_data]                   varbinary(max)      NULL,
    CONSTRAINT [pk_xctr_qrtz_blob_triggers] PRIMARY KEY CLUSTERED ([sched_name], [trigger_name], [trigger_group])
    WITH FILLFACTOR = 80
)');
END

/* 
 * TABLE: [dbo].[xctr_qrtz_fired_triggers] 
 */
 
IF OBJECT_ID('xctr_qrtz_fired_triggers') IS NULL
BEGIN
PRINT 'Create the xctr_qrtz_fired_triggers table.'
exec('CREATE TABLE [dbo].[xctr_qrtz_fired_triggers](
    [sched_name]                  varchar(120)        NOT NULL,
    [entry_id]                    varchar(95)         NOT NULL,
    [trigger_name]                varchar(200)        NOT NULL,
    [trigger_group]               varchar(200)        NOT NULL,
    [instance_name]               varchar(200)        NOT NULL,
    [fired_time]                  bigint              NOT NULL,
    [sched_time]                  bigint              NOT NULL,
    [priority]                    integer             NOT NULL,
    [state]                       varchar(16)         NOT NULL,
    [job_name]                    varchar(200)        NULL,
    [job_group]                   varchar(200)        NULL,
    [is_nonconcurrent]            varchar(1)          NULL,
    [requests_recovery]           varchar(1)          NULL,
    CONSTRAINT [pk_xctr_qrtz_fired_triggers] PRIMARY KEY CLUSTERED ([sched_name], [entry_id])
    WITH FILLFACTOR = 80
)');
END

IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'TRIGGER_NAME' AND object_id = OBJECT_ID('XCTR_QRTZ_FIRED_TRIGGERS'))
  exec('ALTER TABLE XCTR_QRTZ_FIRED_TRIGGERS ALTER COLUMN TRIGGER_NAME VARCHAR(200) NOT NULL');
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'TRIGGER_GROUP' AND object_id = OBJECT_ID('XCTR_QRTZ_FIRED_TRIGGERS'))
  exec('ALTER TABLE XCTR_QRTZ_FIRED_TRIGGERS ALTER COLUMN TRIGGER_GROUP VARCHAR(200) NOT NULL');
GO

/* 
 * INDEX: [idx_xctr_qrtz_ft_trig_inst_name] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_fired_triggers') AND name = 'idx_xctr_qrtz_ft_trig_inst_name')
    exec('CREATE INDEX idx_xctr_qrtz_ft_trig_inst_name ON xctr_qrtz_fired_triggers(sched_name, instance_name) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_ft_inst_job_req_rcvry] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_fired_triggers') AND name = 'idx_xctr_qrtz_ft_inst_job_req_rcvry')
    exec('CREATE INDEX idx_xctr_qrtz_ft_inst_job_req_rcvry ON xctr_qrtz_fired_triggers(sched_name,instance_name,requests_recovery) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_ft_j_g] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_fired_triggers') AND name = 'idx_xctr_qrtz_ft_j_g')
    exec('CREATE INDEX idx_xctr_qrtz_ft_j_g ON xctr_qrtz_fired_triggers(sched_name,job_name,job_group) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_ft_jg] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_fired_triggers') AND name = 'idx_xctr_qrtz_ft_jg')
    exec('CREATE INDEX idx_xctr_qrtz_ft_jg ON xctr_qrtz_fired_triggers(sched_name,job_group) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_ft_t_g] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_fired_triggers') AND name = 'idx_xctr_qrtz_ft_t_g')
    exec('CREATE INDEX idx_xctr_qrtz_ft_t_g ON xctr_qrtz_fired_triggers(sched_name,trigger_name,trigger_group) WITH (FILLFACTOR = 80)');

/* 
 * INDEX: [idx_xctr_qrtz_ft_tg] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('xctr_qrtz_fired_triggers') AND name = 'idx_xctr_qrtz_ft_tg')
    exec('CREATE INDEX idx_xctr_qrtz_ft_tg ON xctr_qrtz_fired_triggers(sched_name,trigger_group) WITH (FILLFACTOR = 80)');


/* 
 * TABLE: [dbo].[xctr_qrtz_paused_trigger_grps] 
 */
 
IF OBJECT_ID('xctr_qrtz_paused_trigger_grps') IS NULL
BEGIN
PRINT 'Create the xctr_qrtz_paused_trigger_grps table.'
exec('CREATE TABLE [dbo].[xctr_qrtz_paused_trigger_grps](
    [sched_name]                  varchar(120)        NOT NULL,
    [trigger_group]               varchar(160)        NOT NULL,
    CONSTRAINT [pk_xctr_qrtz_paused_trigger_grps] PRIMARY KEY CLUSTERED ([sched_name], [trigger_group])
    WITH FILLFACTOR = 80
)');
END

/* 
 * TABLE: [dbo].[xctr_qrtz_scheduler_state] 
 */
 
IF OBJECT_ID('xctr_qrtz_scheduler_state') IS NULL
BEGIN
PRINT 'Create the xctr_qrtz_scheduler_state table.'
exec('CREATE TABLE [dbo].[xctr_qrtz_scheduler_state](
    [sched_name]                  varchar(120)        NOT NULL,
    [instance_name]               varchar(200)        NOT NULL,
    [last_checkin_time]           bigint              NOT NULL,
    [checkin_interval]            bigint              NOT NULL,
    CONSTRAINT [pk_xctr_qrtz_scheduler_state] PRIMARY KEY CLUSTERED ([sched_name], [instance_name])
    WITH FILLFACTOR = 80
)');
END

/* 
 * TABLE: [dbo].[xctr_qrtz_locks] 
 */
 
IF OBJECT_ID('xctr_qrtz_locks') IS NULL
BEGIN
PRINT 'Create the xctr_qrtz_locks table.'
exec('CREATE TABLE [dbo].[xctr_qrtz_locks](
    [sched_name]                      varchar(120)   NOT NULL,
    [lock_name]                       varchar(40)    NOT NULL,
    CONSTRAINT [pk_xctr_qrtz_locks] PRIMARY KEY CLUSTERED ([sched_name], [lock_name])
    WITH FILLFACTOR = 80
)');
END

/* 
 * TABLE: [dbo].[xctr_qrtz_calendars] 
 */
 
IF OBJECT_ID('xctr_qrtz_calendars') IS NULL
BEGIN
PRINT 'Create the xctr_qrtz_locks table.'
exec('CREATE TABLE [dbo].[xctr_qrtz_calendars](
    [sched_name]                  varchar(120)             NOT NULL,
    [calendar_name]               varchar(200)             NOT NULL,
    [calendar]                    varbinary(max)           NOT NULL,
    CONSTRAINT [pk_xctr_qrtz_calendars] PRIMARY KEY CLUSTERED ([sched_name], [calendar_name])
    WITH FILLFACTOR = 80
)');
END

-- [RXPS-44196] 
IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'blob_data' AND object_id = OBJECT_ID('xctr_qrtz_blob_triggers'))
BEGIN
    ALTER TABLE xctr_qrtz_blob_triggers ALTER COLUMN blob_data varbinary(max);
    PRINT 'Column type of xctr_qrtz_blob_triggers.blob_data is altered to varbinary(max)';
END
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'job_data' AND object_id = OBJECT_ID('xctr_qrtz_job_details'))
BEGIN
    ALTER TABLE xctr_qrtz_job_details ALTER COLUMN job_data varbinary(max);
    PRINT 'Column type of xctr_qrtz_job_details.job_data is altered to varbinary(max)';
END
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'calendar' AND object_id = OBJECT_ID('xctr_qrtz_calendars'))
BEGIN
    ALTER TABLE xctr_qrtz_calendars ALTER COLUMN calendar varbinary(max);
    PRINT 'Column type of xctr_qrtz_calendars.calendar is altered to varbinary(max)';
END
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'job_data' AND object_id = OBJECT_ID('xctr_qrtz_triggers'))
BEGIN
    ALTER TABLE xctr_qrtz_triggers ALTER COLUMN job_data varbinary(max);
    PRINT 'Column type of xctr_qrtz_triggers.job_data is altered to varbinary(max)';
END
GO
-- [RXPS-44196] - END

-- [RXPS-61785]
/* 
 * TABLE: [app_log] 
 */
IF OBJECT_ID('app_log') IS NULL
BEGIN
PRINT 'Create the app_log table.'
exec('CREATE TABLE [dbo].[app_log](
    [id]             numeric(19, 0)  IDENTITY(1,1),
    [ctx_id]         varchar(40)     NULL,
    [lvl]            varchar(20)     NOT NULL,
    [time]           datetime2       NOT NULL,
    [app_id]         varchar(20)     NOT NULL,
    [thread]         varchar(256)    NOT NULL,
    [category]       varchar(256)    NOT NULL,
    [message]        varchar(max)    NULL,
    [exception]      varchar(max)    NULL,
    CONSTRAINT [pk_app_log] PRIMARY KEY CLUSTERED ([id]) WITH (FILLFACTOR = 80)
)');
END

/* 
 * INDEX: [idx_app_log_lvl_appid] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('app_log') AND name = 'idx_app_log_lvl_appid')
    exec('CREATE INDEX idx_app_log_lvl_appid ON app_log(lvl, app_id) WITH (FILLFACTOR = 80)');
    
/* 
 * INDEX: [idx_app_log_appid] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('app_log') AND name = 'idx_app_log_appid')
    exec('CREATE INDEX idx_app_log_appid ON app_log(app_id) WITH (FILLFACTOR = 80)');
    
/* 
 * INDEX: [idx_app_log_lvl_appid_time] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('app_log') AND name = 'idx_app_log_lvl_appid_time')
    exec('CREATE INDEX idx_app_log_lvl_appid_time ON app_log(lvl, time, app_id) WITH (FILLFACTOR = 80)');
    
/* 
 * INDEX: [idx_app_log_appid_time] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('app_log') AND name = 'idx_app_log_appid_time')
    exec('CREATE INDEX idx_app_log_appid_time ON app_log(time, app_id) WITH (FILLFACTOR = 80)');
    
/* 
 * INDEX: [idx_app_log_ctxid] 
 */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('app_log') AND name = 'idx_app_log_ctxid')
    exec('CREATE INDEX idx_app_log_ctxid ON app_log(ctx_id) WITH (FILLFACTOR = 80)');
    
-- [RXPS-61785] END

PRINT 'sp_Replication_Cleanup';

IF OBJECT_ID('sp_Replication_Cleanup') IS NOT NULL
  exec('DROP PROCEDURE sp_Replication_Cleanup;');

  
exec('CREATE PROCEDURE sp_Replication_Cleanup (@ai_delay int = 3)
AS
BEGIN
-------------------------------------------------------------------------------------------------------------------
--                     
-- Procedure         : sp_Replication_Cleanup (@ai_delay int)
-- Parameters    : @ai_delay
-- Description       : 
-- Version           : 6.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
    SET NOCOUNT ON;
    Declare @li_cnt     int,
      @ld_start   datetime,
      @ld_end     datetime

    SET @ld_start=GETDATE();

    SELECT @li_cnt=COUNT(*) FROM RPL_REPLICATION_DATA WHERE PUBLISH_STATUS=''COMPLETE'' AND update_date < @ld_start-@ai_delay;

    WHILE (SELECT COUNT(*) FROM RPL_REPLICATION_DATA WHERE PUBLISH_STATUS=''COMPLETE'' AND update_date < @ld_start-@ai_delay)>0
     DELETE TOP(5000) FROM RPL_REPLICATION_DATA WITH(TABLOCK) WHERE PUBLISH_STATUS=''COMPLETE'' AND update_date < @ld_start-@ai_delay;

    SET @ld_end=GETDATE();

    INSERT INTO rpl_cleanup_log (deleted_records,start_time,end_time,table_name) VALUES(@li_cnt,@ld_start,@ld_end,''RPL_REPLICATION_DATA'');

    SET @ld_start=GETDATE();

    SELECT @li_cnt=COUNT(*) FROM trn_poslog_work_item WHERE WORK_STATUS=''COMPLETE'' AND update_date < @ld_start-@ai_delay;

    WHILE (SELECT COUNT(*) FROM trn_poslog_work_item WHERE WORK_STATUS=''COMPLETE'' AND update_date < @ld_start-@ai_delay)>0
     DELETE TOP(5000) FROM trn_poslog_work_item WITH(TABLOCK) WHERE WORK_STATUS=''COMPLETE'' AND update_date < @ld_start-@ai_delay;

    SET @ld_end=GETDATE();

    INSERT INTO rpl_cleanup_log (deleted_records,start_time,end_time,table_name) VALUES(@li_cnt,@ld_start,@ld_end,''trn_poslog_work_item'');

END');

PRINT 'sp_shrink';


IF OBJECT_ID('sp_shrink') IS NOT NULL
  exec('DROP PROCEDURE sp_shrink;');

  
exec('CREATE PROCEDURE sp_shrink (@ai_free_space  int = 10)
AS
BEGIN
-------------------------------------------------------------------------------------------------------------------
--                     
-- Procedure         : sp_shrink (ai_free_space int)
-- Parameters    : ai_free_space
-- Description       : 
-- Version           : 6.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
  DECLARE
    @ls_owner_nm      sysname,
    @ls_table_nm      sysname,
    @ls_index_nm      sysname,
    @li_index_id      integer,
    @li_fillfactor      integer,
    @ls_domain        char(3),
    @ls_sqlcmd        varchar(256);
    
  DECLARE Table_List CURSOR FOR
    SELECT schema_name(schema_id), object_name (object_id)
      FROM sys.tables
      WHERE type = ''U''
  
  --
  -- Loop through the tables and rebuild the indexes with 100% fill factor
  --
  OPEN Table_List

  FETCH NEXT
  FROM Table_List
  INTO @ls_owner_nm, @ls_table_nm

  WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @ls_sqlcmd = ''ALTER INDEX ALL  on ['' + @ls_owner_nm + ''].['' + @ls_table_nm + ''] REBUILD WITH (FILLFACTOR=100)'';  -- Online only works with Enterprise Edition
    --print @ls_sqlcmd;
    exec (@ls_sqlcmd);

    FETCH NEXT
    FROM Table_List
    INTO @ls_owner_nm, @ls_table_nm
  END;
  
  CLOSE Table_List;
  DEALLOCATE Table_List;

  --
  -- Shrink the database to the desired size
  --
  print ''Free Space%: '' + str(@ai_free_space);
  DBCC SHRINKDATABASE (0, @ai_free_space);

  DECLARE Index_List CURSOR FOR
    SELECT schema_name(t.schema_id), object_name(i.object_id), i.index_id, i.name
      FROM sys.indexes i
      JOIN sys.tables t on i.object_id = t.object_id
      WHERE t.type = ''U''
        and i.index_id > 0
  
  --
  -- Loop through the indexes and rebuild the indexes
  --
  OPEN Index_List

  FETCH NEXT
  FROM Index_List
  INTO @ls_owner_nm, @ls_table_nm, @li_index_id, @ls_index_nm

  WHILE @@FETCH_STATUS = 0
  BEGIN
    set @li_fillfactor = 80;    -- non-clustered indexes
    
    SET @ls_sqlcmd = ''ALTER INDEX ['' + @ls_index_nm + '']  on ['' + @ls_owner_nm + ''].['' + @ls_table_nm + ''] REBUILD WITH (FILLFACTOR='' + ltrim(str(@li_fillfactor)) + '')'';  -- Online only works with Enterprise Edition
    --print @ls_sqlcmd;
    exec (@ls_sqlcmd);

    FETCH NEXT
    FROM Index_List
    INTO @ls_owner_nm, @ls_table_nm, @li_index_id, @ls_index_nm
  END;
  
  CLOSE Index_List;
  DEALLOCATE Index_List;
END');


PRINT 'sp_defrag_indexes';

IF OBJECT_ID('sp_defrag_indexes') IS NOT NULL
  exec('DROP PROCEDURE sp_defrag_indexes;')

  
exec('CREATE PROCEDURE sp_defrag_indexes (@minfrag int = 10,
                      @minindexpages int = 1)
AS
BEGIN
-------------------------------------------------------------------------------------------------------------------
--                                                                                                               --
-- Procedure         : sp_defrag_indexes (@minfrag int, @minindexpage int)                     --
-- Parameters    : minfrag - The minum about a fragmentation allowed in the database.  Tables with less than
--                               the amont specified will not be reorganized.
--                   : minindexpages - The minum number of pages in the indexes for a reorganized to be performed --
-- Description       : Reorganizes the tables that are fragmented with the respective minimume fragmentation 
-- Version           : 6.0                                                                                       --
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-- ST  01/30/07  Initially created
-- PGH 11/07/09  Rewriten for 2005 / 2008
-- BCW 12/02/11  Added fill factor to rebuild
-------------------------------------------------------------------------------------------------------------------
-- Declare variables

  SET NOCOUNT ON
  SET QUOTED_IDENTIFIER ON

  DECLARE @ls_version     varchar(128),
      @li_version     integer,
      @li_pos       integer,
      @table_nm     VARCHAR (128),
      @index_nm     varchar(128),
      @objectid     INT,
      @indexid      INT,
      @part_nbr     int,
      @index_typ      varchar(60),
      @index_depth    int,
      @page_cnt     int,
      @frag       DECIMAL,
      @dbname       sysname,
      @ls_sqlcmd      nvarchar(128)

  --check to verify the version, this procedure is using the DMV views introduced in 2005
  --check this is being run in a user database
  SET @ls_version = CONVERT(varchar(128), SERVERPROPERTY (''ProductVersion''))
  SET @li_pos = CHARINDEX(''.'', @ls_version) - 1
  SET @li_version = CONVERT(int, SUBSTRING(@ls_version, 1, @li_pos))
  IF @li_version < 9
  BEGIN
    PRINT ''Wrong Version, this procedure requires SQL SERVER 2005 or greater''
    RETURN
  END

  SELECT @dbname = db_name()
  IF @dbname IN (''master'', ''msdb'', ''model'', ''tempdb'')
  BEGIN
    PRINT ''This procedure should not be run in system databases.''
    RETURN
  END

  --begin Stage 1: Find the indexes with fragmentation
  -- Declare cursor 
  DECLARE FindIDXFrag CURSOR FOR
  SELECT object_name(i.object_id) as ''Table Name'', 
      i.name as ''Index Name'',
      i.object_id,
      i.index_id,
      partition_number,
      index_type_desc,
      index_depth,
      avg_fragmentation_in_percent,
      page_count
    FROM sys.dm_db_index_physical_stats(db_id(), NULL, NULL, NULL , NULL) ips
    JOIN sys.indexes i on i.object_id = ips.object_id and i.index_id = ips.index_id
    where index_type_desc in (''CLUSTERED INDEX'', ''NONCLUSTERED INDEX'')
      --and avg_fragmentation_in_percent > @minfrag
      and page_count > @minindexpages

  ---- Report the ouput of showcontig for results checking
  -- SELECT * FROM #fraglist order by 1

  -- Write to output start time for information purposes
  PRINT ''Started defragmenting indexes at '' + CONVERT(VARCHAR,GETDATE())
  PRINT ''REORGANIZING:''

  -- Open the cursor
  OPEN FindIDXFrag

  -- Loop through the indexes
  FETCH NEXT
  FROM FindIDXFrag
  INTO @table_nm,
    @index_nm,
    @objectid,
    @indexid,
    @part_nbr,
    @index_typ,
    @index_depth,
    @frag,
    @page_cnt

  WHILE @@FETCH_STATUS = 0
  BEGIN

    IF @frag > @minfrag
    BEGIN 
      IF @frag > 50
        BEGIN
          PRINT ''Index '' + @index_nm + '' on '' + @table_nm + '' Rebuilt'';
--          SET @ls_sqlcmd = ''ALTER INDEX ['' + @index_nm + ''] on ['' + @table_nm + ''] REBUILD WITH ONLINE=ON'';  -- Online only works with Enterprise Edition
          SET @ls_sqlcmd = ''ALTER INDEX ['' + @index_nm + ''] on ['' + @table_nm + ''] REBUILD WITH (FILLFACTOR = 80)'';
          print @ls_sqlcmd;
          exec (@ls_sqlcmd);
        END;
      ELSE
        BEGIN
          PRINT ''Index '' + @index_nm + '' on '' + @table_nm + '' Reorganized'';
          SET @ls_sqlcmd = ''ALTER INDEX ['' + @index_nm + ''] on ['' + @table_nm + ''] REORGANIZE'';
          --print @ls_sqlcmd;
          exec (@ls_sqlcmd);
          SET @ls_sqlcmd = ''UPDATE STATISTICS ['' + @table_nm + ''] ['' + @index_nm + '']'';
          --print @ls_sqlcmd;
          exec (@ls_sqlcmd);
        END;
    END;
    ELSE
      BEGIN
        PRINT ''Index '' + @index_nm + '' on '' + @table_nm + '' Statistics Updated'';
        SET @ls_sqlcmd = ''UPDATE STATISTICS ['' + @table_nm + ''] ['' + @index_nm + '']'';
        --print @ls_sqlcmd;
        exec (@ls_sqlcmd);
      END;
    
    FETCH NEXT
    FROM FindIDXFrag
      INTO  @table_nm,
        @index_nm,
        @objectid,
        @indexid,
        @part_nbr,
        @index_typ,
        @index_depth,
        @frag,
        @page_cnt;
    
  END;

  -- Close and deallocate the cursor
  CLOSE FindIDXFrag;
  DEALLOCATE FindIDXFrag;

  -- move back to full mode 
  -- alter database xstore set recovery full

  -- Report on finish time for information purposes
  PRINT ''Finished defragmenting indexes at '' + CONVERT(VARCHAR,GETDATE());
END');

PRINT 'sp_dbMaintenance';


IF OBJECT_ID('sp_dbMaintenance') IS NOT NULL
  exec('DROP PROCEDURE sp_dbMaintenance;');


exec('CREATE PROCEDURE sp_dbMaintenance
AS
-------------------------------------------------------------------------------------------------------------------
--                                                                                                               --
-- Procedure         : sp_dbMaintenance
-- Description       : Performs standard maitntenance to a SQL Server database
--            1) Check recovery model and last backup
--            2) Index Reorganize
--            3) CheckDB
-- Version           : 6.0                                                                                       --
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-- ST  01/30/07  Initially created
-- PGH 02/11/10  Rewriten for 2005 / 2008
-------------------------------------------------------------------------------------------------------------------
DECLARE @dbName       sysname,
    @dbRecovery     varchar(60),
    @LastFullBackup   datetime,
    @LastTransBackup  datetime,
    @MinFragmentation decimal
--    @dbBk       varchar(255),
--    @logBk        varchar(255),
--    @doBk       bit

BEGIN
  -- config
  SET @MinFragmentation = 30 --Percent
--  SET @dbBk = ''c:\xstoredb\backup\xstoreDb.bk'' -- db back up destinataion
--  SET @logBk = ''c:\xstoredb\backup\xstoreLog.bk''  -- log file back up destination
--  SET @doBK = 0 -- set to true for backup
  -- end config

  SET @dbName = db_name();
  SELECT @dbRecovery = recovery_model_desc FROM SYS.DATABASES WHERE NAME =DB_NAME();
  SELECT @LastFullBackup = max(backup_finish_date) from msdb..backupset
    WHERE type = ''D''
      AND database_name = DB_NAME();
  SELECT @LastTransBackup = max(backup_finish_date) from msdb..backupset
    WHERE type = ''L''
      AND database_name = DB_NAME();
      
  --
  -- 1) Check Backup Status
  --
  
  PRINT '''';
  PRINT '' Database Backup Info:'';
  PRINT ''    Database Name:     '' + db_name();
  PRINT ''    Recovery Mode:     '' + @dbRecovery;
  PRINT ''    Last Full Backup:  '' + COALESCE(cast(@LastFullBackup as varchar), '' '');
  PRINT ''     Last Trans Backup: '' + COALESCE(cast(@LastTransBackup as varchar), '' '');
  PRINT '''';

  SELECT  CASE df.data_space_id
        WHEN 0 THEN ''LOG''
        ELSE  ds.name
      END AS [FileGroupName],
      df.name AS [FileName], 
      df.physical_name AS [PhysicalName], 
      round((cast(df.size as decimal) / 128) , 2) AS [Size], 
      round((FILEPROPERTY(df.name, ''SpaceUsed'')/ 128.0),2) AS [SpaceUsed],  --Changed from Available Space to Used Space
      cast(ROUND(((FILEPROPERTY(df.name, ''SpaceUsed'')/ 128.0) / (cast(df.size as decimal) / 128)) * 100, 0) as int)
        AS [SpaceUsedPCT],
      CASE is_percent_growth
      WHEN 0 THEN growth / 128
      ELSE growth
    END AS [Growth],
    CASE is_percent_growth
      WHEN 0 THEN ''MB''
      ELSE ''PCT''
    END AS [Growth Type],
    CASE df.max_size
      WHEN -1 THEN df.max_size
      ELSE max_size / 128
    END AS [Max Growth Size],         
    state_desc
  FROM sys.database_files df
  LEFT JOIN sys.data_spaces ds on ds.data_space_id = df.data_space_id;
  
  --
  -- 2) Index Reorganize
  --

  PRINT ''Reorganizing Indexes''
  EXEC sp_defrag_indexes @MinFragmentation

  -- 3) Update the stats
  --PRINT ''Updating Statistics''
  --EXEC sp_updatestats -- with default parameters runs stats for sample rows on all tables
  

  -- 3) Check DB
  PRINT ''CheckDB'';
  DBCC CHECKDB WITH NO_INFOMSGS;

  -- 5) Backup Database
  --IF @doBk = 1
  --  BEGIN
  --    BACKUP DATABASE @dbName TO DISK = @dbBk
  --    BACKUP LOG @dbName TO DISK = @logBk
  --  END
END');

PRINT 'Xcenter Replication Cleanup job'

exec('/****** Object:  Job [Xcenter Replication Cleanup] ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N''Xcenter Replication Cleanup'')
BEGIN
    declare @jobid varchar(254);
    SELECT @jobid=job_id FROM msdb.dbo.sysjobs_view WHERE name = N''Xcenter Replication Cleanup''
    EXEC msdb.dbo.sp_delete_job @job_id=@jobid, @delete_unused_schedule=0
END');

exec('/****** Object:  Job [Xcenter Replication Cleanup] ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

/****** Object:  JobCategory [[Uncategorized (Local)]]] ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

DECLARE @jobId BINARY(16),
     @db_name VARCHAR(128);
     set @db_name = db_name();
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N''Xcenter Replication Cleanup'', 
    @enabled=1, 
    @notify_level_eventlog=0, 
    @notify_level_email=0, 
    @notify_level_netsend=0, 
    @notify_level_page=0, 
    @delete_level=0, 
    @description=N''No description available.'', 
    @category_name=N''[Uncategorized (Local)]'', 
    @owner_login_name=N''sa'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Object:  Step [Remove Completed Records] ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N''Remove Completed Records'', 
    @step_id=1, 
    @cmdexec_success_code=0, 
    @on_success_action=1, 
    @on_success_step_id=0, 
    @on_fail_action=2, 
    @on_fail_step_id=0, 
    @retry_attempts=0, 
    @retry_interval=0, 
    @os_run_priority=0, @subsystem=N''TSQL'', 
    @command=N''EXEC sp_Replication_Cleanup'', 
    @database_name=@db_name, 
    @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Object:  Schedule [Nightly at Midnight.] ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N''Nightly at Midnight.'', 
    @enabled=1, 
    @freq_type=4, 
    @freq_interval=1, 
    @freq_subday_type=1, 
    @freq_subday_interval=0, 
    @freq_relative_interval=0, 
    @freq_recurrence_factor=0, 
    @active_start_date=20120831, 
    @active_end_date=99991231, 
    @active_start_time=0, 
    @active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

/****** Object:  Target Server [local] ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

COMMIT TRANSACTION
return;
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION');

