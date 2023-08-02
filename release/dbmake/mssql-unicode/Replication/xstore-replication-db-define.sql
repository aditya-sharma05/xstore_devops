IF OBJECT_ID('ctl_replication_queue') IS NULL
BEGIN
PRINT 'Create the ctl_replication_queue table.'
CREATE TABLE [dbo].[ctl_replication_queue](
    [organization_id]           int             NOT NULL,
    [rtl_loc_id]                int             NOT NULL,
    [wkstn_id]                  bigint          NOT NULL,
    [db_trans_id]               nvarchar(60)     NOT NULL,
    [service_name]              nvarchar(60)     NOT NULL,
    [date_time]                 bigint          NULL,
    [expires_after]             bigint          NULL,
    [expires_immediately_flag]  bit             DEFAULT ((0)) NULL,
    [never_expires_flag]        bit             DEFAULT ((0)) NULL,
    [offline_failures]          int             NULL,
    [error_failures]            int             DEFAULT ((0)) NOT NULL,
    [replication_data]          nvarchar(max)    NULL,
    [create_date]               datetime        NULL,
    [create_user_id]            nvarchar(30)     NULL,
    [update_date]               datetime        NULL,
    [update_user_id]            nvarchar(30)     NULL,
    [record_state]              nvarchar(30)     NULL,
    CONSTRAINT [pk_ctl_replication_queue] PRIMARY KEY CLUSTERED ([organization_id], [rtl_loc_id], [wkstn_id], [db_trans_id], [service_name]) WITH (FILLFACTOR = 80)
)
END

IF OBJECT_ID('ctl_service_retry_queue') IS NULL
BEGIN
PRINT 'Create the ctl_service_retry_queue table.'
CREATE TABLE [dbo].[ctl_service_retry_queue](
    [organization_id]           int             NOT NULL,
    [rtl_loc_id]                int             NOT NULL,
    [wkstn_id]                  bigint          NOT NULL,
    [retry_id]                  nvarchar(100)    NOT NULL,
    [service_id]                nvarchar(60)     NOT NULL,
    [service_type]              nvarchar(60)     NOT NULL,
    [retry_type]                nvarchar(60)     NOT NULL,
    [processing_wkstn_id]       bigint          NOT NULL,
    [entry_date_time]           datetime        NULL,
    [last_attempt_time]         bigint          NULL,
    [retry_count]               int             DEFAULT ((0)) NOT NULL,
    [context_info]              nvarchar(255)    NULL,
    [request_data]              nvarchar(max)    NULL,
    [create_date]               datetime        NULL,
    [create_user_id]            nvarchar(30)     NULL,
    [update_date]               datetime        NULL,
    [update_user_id]            nvarchar(30)     NULL,
    [record_state]              nvarchar(30)     NULL,
    CONSTRAINT [pk_ctl_service_retry_queue] PRIMARY KEY CLUSTERED ([organization_id], [rtl_loc_id], [wkstn_id], [retry_id], [service_id], [service_type]) WITH (FILLFACTOR = 80)
)
END

IF OBJECT_ID('rcpt_ereceipt_queue') IS NULL
BEGIN
PRINT 'Create the rcpt_ereceipt_queue table.'
CREATE TABLE [dbo].[rcpt_ereceipt_queue](
    [organization_id]           int             NOT NULL,
    [rtl_loc_id]                int             NOT NULL,
    [wkstn_id]                  bigint          NOT NULL,
    [queue_id]                  nvarchar(100)    NOT NULL,
    [service_id]                nvarchar(60)     NOT NULL,
    [service_type]              nvarchar(60)     NOT NULL,
    [processing_wkstn_id]       bigint          NOT NULL,
    [entry_date_time]           datetime        NULL,
    [last_attempt_time]         bigint          NULL,
    [request_data]              nvarchar(max)    NULL,
    [original_trans_id_ref]     nvarchar(254)    NULL,
    [create_date]               datetime        NULL,
    [create_user_id]            nvarchar(30)     NULL,
    [update_date]               datetime        NULL,
    [update_user_id]            nvarchar(30)     NULL,
    [record_state]              nvarchar(30)     NULL,
    CONSTRAINT [pk_rcpt_ereceipt_queue] PRIMARY KEY CLUSTERED ([organization_id], [rtl_loc_id], [wkstn_id], [queue_id], [service_id], [service_type]) WITH (FILLFACTOR = 80)
)
END

