/* 
 * TABLE: [dbo].[cfg_alert_severity_threshold] 
 */

CREATE TABLE [dbo].[cfg_alert_severity_threshold](
    [organization_id]     int            NOT NULL,
    [alert_type]          nvarchar(60)    NOT NULL,
    [medium_threshold]    int            NULL,
    [high_threshold]      int            NULL,
    [critical_threshold]  int            NULL,
    [create_date]         datetime       NULL,
    [create_user_id]      nvarchar(256)   NULL,
    [update_date]         datetime       NULL,
    [update_user_id]      nvarchar(256)   NULL,
    CONSTRAINT [pk_cfg_alert_severity_threshold] PRIMARY KEY CLUSTERED ([organization_id], [alert_type])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_attachment_types] 
 */

CREATE TABLE [dbo].[cfg_attachment_types](
    [attachment_type_id]    nvarchar(30)     NOT NULL,
    [description]     nvarchar(255)    NULL,
    [create_date]     datetime        NULL,
    [create_user_id]  nvarchar(256)    NULL,
    [update_date]     datetime        NULL,
    [update_user_id]  nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_attachment_types] PRIMARY KEY CLUSTERED ([attachment_type_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_base_feature] 
 */

CREATE TABLE [dbo].[cfg_base_feature](
    [feature_id]             nvarchar(200)    NOT NULL,
    [description]            nvarchar(max)    NULL,
    [depends_on_feature_id]  nvarchar(200)    NULL,
    [sort_order]             int             NULL,
    [create_date]            datetime        NULL,
    [create_user_id]         nvarchar(256)    NULL,
    [update_date]            datetime        NULL,
    [update_user_id]         nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_base_feature] PRIMARY KEY CLUSTERED ([feature_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_broadcaster] 
 */

CREATE TABLE [dbo].[cfg_broadcaster](
    [organization_id]                 int            NOT NULL,
    [service_id]                      nvarchar(200)   NOT NULL,
    [type]                            nvarchar(30)    NOT NULL,
    [endpoint_url]                    nvarchar(254)   NULL,
    [enabled]                         bit            DEFAULT 1 NOT NULL,
    [user_name]                       nvarchar(255)   NULL,
    [password]                        nvarchar(255)   NULL,
    [auth_mode]                       nvarchar(30)    NULL,
    [retry_sleep_millis]              int            NULL,
    [batch_size]                      int            NULL,
    [polling_int_millis]              int            NULL,
    [thread_count]                    int            NULL,
    [connect_timeout]                 int            NULL,
    [request_timeout]                 int            NULL,
    [custom_mapping]                  nvarchar(max)   NULL,
    [use_compression_flag]            bit            NULL,
    [relate_org_code]                 nvarchar(10)    NULL,
    [create_date]                     datetime       NULL,
    [create_user_id]                  nvarchar(256)   NULL,
    [update_date]                     datetime       NULL,
    [update_user_id]                  nvarchar(256)   NULL,
    CONSTRAINT [pk_cfg_broadcaster] PRIMARY KEY CLUSTERED ([organization_id], [service_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_broadcaster_filters] 
 */

CREATE TABLE [dbo].[cfg_broadcaster_filters](
    [organization_id]                 int            NOT NULL,
    [service_id]                      nvarchar(200)   NOT NULL,
    [trans_type_to_filter]            nvarchar(50)    NOT NULL,
    CONSTRAINT [pk_cfg_broadcaster_filters] PRIMARY KEY CLUSTERED ([organization_id], [service_id], [trans_type_to_filter])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_broadcaster_mods] 
 */

CREATE TABLE [dbo].[cfg_broadcaster_mods](
    [organization_id]                 int            NOT NULL,
    [service_id]                      nvarchar(200)   NOT NULL,
    [option_id]                       int            NOT NULL,
    CONSTRAINT [pk_cfg_broadcaster_mods] PRIMARY KEY CLUSTERED ([organization_id], [service_id], [option_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_code_category] 
 */

CREATE TABLE [dbo].[cfg_code_category](
    [organization_id]  int             NOT NULL,
    [category_group]   nvarchar(254)    NULL,
    [category]         nvarchar(254)    NOT NULL,
    [internal_flag]    bit             DEFAULT 0 NOT NULL,
    [description]      nvarchar(254)    NULL,
    [comments]         nvarchar(254)    NULL,
    [privilege_id]     nvarchar(30)     NULL,
    [uses_image_url]   bit             DEFAULT 0 NOT NULL,
    [uses_rank]        bit             DEFAULT 0 NOT NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_code_category] PRIMARY KEY CLUSTERED ([organization_id], [category])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_code_value] 
 */

CREATE TABLE [dbo].[cfg_code_value](
    [code_id]         numeric(19, 0)    IDENTITY(0,1),
    [category]        nvarchar(30)       NOT NULL,
    [config_name]     nvarchar(195)      NOT NULL,
    [code]            nvarchar(195)      NOT NULL,
    [sub_category]    nvarchar(30)       NOT NULL,
    [description]     nvarchar(256)      NULL,
    [sort_order]      int               NULL,
    [data1]           nvarchar(120)      NULL,
    [data2]           nvarchar(120)      NULL,
    [data3]           nvarchar(120)      NULL,
    [create_date]     datetime          NULL,
    [create_user_id]  nvarchar(256)      NULL,
    [update_date]     datetime          NULL,
    [update_user_id]  nvarchar(256)      NULL,
    CONSTRAINT [pk_cfg_code_value] PRIMARY KEY CLUSTERED ([code_id])
    WITH FILLFACTOR = 80,
    CONSTRAINT [uq_cfg_code_value]  UNIQUE ([category], [config_name], [sub_category], [code])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_code_value_change] 
 */

CREATE TABLE [dbo].[cfg_code_value_change](
    [organization_id]     int             NOT NULL,
    [profile_group_id]    nvarchar(60)     NOT NULL,
    [profile_element_id]  nvarchar(60)     NOT NULL,
    [change_id]           nvarchar(254)    NOT NULL,
	[config_version]	  bigint		  DEFAULT 0 NOT NULL,
    [category]            nvarchar(30)     NOT NULL,
    [code]                nvarchar(60)     NOT NULL,
    [description]         nvarchar(254)    NULL,
    [sort_order]          int             NULL,
    [hidden_flag]         bit             DEFAULT 0 NULL,
    [enabled_flag]        bit             DEFAULT 0 NULL,
    [image_url]           nvarchar(254)    NULL,
    [rank]                int             NULL,
    [create_date]         datetime        NULL,
    [create_user_id]      nvarchar(256)    NULL,
    [update_date]         datetime        NULL,
    [update_user_id]      nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_code_value_change] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_id],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_critical_alert_email] 
 */

CREATE TABLE [dbo].[cfg_critical_alert_email](
    [organization_id]  int            NOT NULL,
    [email_address]    nvarchar(254)   NOT NULL,
    [create_date]      datetime       NULL,
    [create_user_id]   nvarchar(256)   NULL,
    [update_date]      datetime       NULL,
    [update_user_id]   nvarchar(256)   NULL,
    CONSTRAINT [pk_cfg_critical_alert_email] PRIMARY KEY CLUSTERED ([organization_id], [email_address])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_customization] 
 */
CREATE TABLE [dbo].[cfg_customization](
    [name]                            nvarchar(200)   NOT NULL,
    [contents]                        VARBINARY(MAX) NULL,
    [customization_type]              nvarchar(30)    NULL,
    [create_date]                     datetime       NULL,
    [create_user_id]                  nvarchar(256)   NULL,
    [update_date]                     datetime       NULL,
    [update_user_id]                  nvarchar(256)   NULL,
    CONSTRAINT [pk_cfg_customization] PRIMARY KEY CLUSTERED ([name])
    WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: [dbo].[cfg_desc_translation_map] 
 */

CREATE TABLE [dbo].[cfg_desc_translation_map](
    [s_organization_id]     int             NOT NULL,
    [s_profile_group_id]    nvarchar(60)     NOT NULL,
    [s_profile_element_id]  nvarchar(60)     NOT NULL,
	[s_config_version]		bigint			NULL,
    [change_id]             nvarchar(254)    NOT NULL,
    [t_organization_id]     int             NOT NULL,
    [t_profile_group_id]    nvarchar(60)     NOT NULL,
    [t_profile_element_id]  nvarchar(60)     NOT NULL,
	[t_config_version]		bigint			NULL,
    [translation_key]       nvarchar(150)    NOT NULL,
    [locale]                nvarchar(30)     NOT NULL
)
go



/* 
 * TABLE: [dbo].[cfg_description_translation] 
 */

CREATE TABLE [dbo].[cfg_description_translation](
    [organization_id]     int             NOT NULL,
    [profile_group_id]    nvarchar(60)     NOT NULL,
    [profile_element_id]  nvarchar(60)     NOT NULL,
    [translation_key]     nvarchar(150)    NOT NULL,
    [locale]              nvarchar(30)     NOT NULL,
	[config_version]	  bigint		  DEFAULT 0 NOT NULL,
    [translation]         nvarchar(max)    NULL,
    [create_date]         datetime        NULL,
    [create_user_id]      nvarchar(256)    NULL,
    [update_date]         datetime        NULL,
    [update_user_id]      nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_translation] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [translation_key], [locale],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_discount_change] 
 */

CREATE TABLE [dbo].[cfg_discount_change](
    [organization_id]       int               NOT NULL,
    [profile_group_id]      nvarchar(60)       NOT NULL,
    [profile_element_id]    nvarchar(60)       NOT NULL,
    [change_id]             nvarchar(254)      NOT NULL,
	[config_version]		bigint			  DEFAULT 0 NOT NULL,
    [discount_code]         nvarchar(60)       NOT NULL,
    [enabled_flag]          bit               DEFAULT 0 NULL,
    [effective_date]        nvarchar(8)        NULL,
    [expiration_date]       nvarchar(8)        NULL,
    [type_code]             nvarchar(30)       NULL,
    [application_method]    nvarchar(30)       NULL,
    [percentage]            decimal(6, 4)     NULL,
    [description]           nvarchar(254)      NULL,
    [calculation_method]    nvarchar(30)       NULL,
    [prompt_message]        nvarchar(254)      NULL,
    [max_trans_count]       int               NULL,
    [exclusive_flag]        bit               DEFAULT 0 NULL,
    [privilege_type]        nvarchar(60)       NULL,
    [amount]                decimal(17, 6)    NULL,
    [min_eligible_amount]   decimal(17, 6)    NULL,
    [serialized_flag]       bit               DEFAULT 0 NULL,
    [max_discount_amount]   decimal(17, 6)    NULL,
    [sort_order]            int               NULL,
    [disallow_change_flag]  bit               DEFAULT 0 NULL,
	[max_amount]			decimal(17, 6)	  NULL,
	[max_percentage]		decimal(17, 6)	  NULL,
    [create_date]           datetime          NULL,
    [create_user_id]        nvarchar(256)      NULL,
    [update_date]           datetime          NULL,
    [update_user_id]        nvarchar(256)      NULL,
    CONSTRAINT [pk_dsc_discount_change] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_id],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_dsc_group_mapping_change] 
 */

CREATE TABLE [dbo].[cfg_dsc_group_mapping_change](
    [organization_id]     int             NOT NULL,
    [profile_group_id]    nvarchar(60)     NOT NULL,
    [profile_element_id]  nvarchar(60)     NOT NULL,
    [change_id]           nvarchar(254)    NOT NULL,
    [discount_code]       nvarchar(60)     NOT NULL,
    [customer_group_id]   nvarchar(60)     NOT NULL,
	[config_version]	  bigint		  DEFAULT 0 NOT NULL,
    [create_date]         datetime        NULL,
    [create_user_id]      nvarchar(256)    NULL,
    [update_date]         datetime        NULL,
    [update_user_id]      nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_dsc_group_mapping_change] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_id], [customer_group_id],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_dsc_valid_item_type_change] 
 */

CREATE TABLE [dbo].[cfg_dsc_valid_item_type_change](
    [organization_id]     int             NOT NULL,
    [profile_group_id]    nvarchar(60)     NOT NULL,
    [profile_element_id]  nvarchar(60)     NOT NULL,
    [change_id]           nvarchar(254)    NOT NULL,
    [discount_code]       nvarchar(60)     NOT NULL,
    [item_type_code]      nvarchar(30)     NOT NULL,
	[config_version]	  bigint		  DEFAULT 0 NOT NULL,
    [create_date]         datetime        NULL,
    [create_user_id]      nvarchar(256)    NULL,
    [update_date]         datetime        NULL,
    [update_user_id]      nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_dsc_valid_item_type_change] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_id], [item_type_code],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_integration] 
 */

CREATE TABLE [dbo].[cfg_integration](
    [organization_id]         int             NOT NULL,
    [integration_system]      nvarchar(50)     NOT NULL,
    [implementation_type]     nvarchar(25)     NOT NULL,
    [integration_type]        nvarchar(25)     NOT NULL,
    [status]                  nvarchar(25)     DEFAULT('PENDING') NOT NULL,
    [user_name]               nvarchar(255)    NULL,
    [password]                nvarchar(255)    NULL,
    [pause_integration_flag]  bit             DEFAULT 0, 
    [auth_mode]               nvarchar(25)     NULL,
    [create_date]             datetime        NULL,
    [create_user_id]          nvarchar(256)    NULL,
    [update_date]             datetime        NULL,
    [update_user_id]          nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_integration] PRIMARY KEY CLUSTERED ([organization_id], [integration_system], [integration_type], [implementation_type])
      WITH (FILLFACTOR = 80)
)
go
/* 
 * TABLE: [dbo].[cfg_integration_p] 
 */

CREATE TABLE [dbo].[cfg_integration_p](
      [organization_id]       int           NOT NULL,
      [integration_system]    nvarchar(50)   NOT NULL,
      [implementation_type]   nvarchar(25)   NOT NULL,
      [integration_type]      nvarchar(25)   NOT NULL,
      [property_code]         nvarchar(30)   NOT NULL,
      [type]                  nvarchar(30)   NULL,
      [string_value]          nvarchar(max)  NULL,
      [date_value]            datetime      NULL,
      [decimal_value]         decimal(17,6) NULL,
      [create_date]           datetime      NULL,
      [create_user_id]        nvarchar(256)  NULL,
      [update_date]           datetime      NULL,
      [update_user_id]        nvarchar(256)  NULL,
      CONSTRAINT [pk_cfg_integration_p] PRIMARY KEY CLUSTERED ([organization_id], [integration_system], [integration_type], [implementation_type], [property_code])
      WITH (FILLFACTOR = 80)
)
go
/* 
 * TABLE: [dbo].[cfg_landscape] 
 */

CREATE TABLE [dbo].[cfg_landscape](
    [organization_id]  int             NOT NULL,
    [landscape_id]     bigint          NOT NULL,
    [description]      nvarchar(255)    NULL,
    [comments]         nvarchar(max)    NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [PK_cfg_landscape] PRIMARY KEY CLUSTERED ([organization_id], [landscape_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_landscape_group] 
 */

CREATE TABLE [dbo].[cfg_landscape_group](
    [organization_id]      int            NOT NULL,
    [landscape_id]         bigint         NOT NULL,
    [profile_group_id]     nvarchar(60)    NOT NULL,
    [profile_group_order]  int            NOT NULL,
    [create_date]          datetime       NULL,
    [create_user_id]       nvarchar(256)   NULL,
    [update_date]          datetime       NULL,
    [update_user_id]       nvarchar(256)   NULL,
    CONSTRAINT [PK_cfg_landscape_group] PRIMARY KEY CLUSTERED ([organization_id], [landscape_id], [profile_group_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_landscape_range] 
 */

CREATE TABLE [dbo].[cfg_landscape_range](
    [organization_id]     int            NOT NULL,
    [landscape_id]        bigint         NOT NULL,
    [profile_group_id]    nvarchar(60)    NOT NULL,
    [range_seq]           int            NOT NULL,
    [profile_element_id]  nvarchar(60)    NOT NULL,
    [range_start]         int            NOT NULL,
    [range_end]           int            NOT NULL,
    [create_date]         datetime       NULL,
    [create_user_id]      nvarchar(256)   NULL,
    [update_date]         datetime       NULL,
    [update_user_id]      nvarchar(256)   NULL,
    CONSTRAINT [PK_cfg_landscape_range] PRIMARY KEY CLUSTERED ([organization_id], [landscape_id], [profile_group_id], [range_seq])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_menu_config] 
 */

CREATE TABLE [dbo].[cfg_menu_config](
    [category]                  nvarchar(60)     NOT NULL,
    [menu_name]                 nvarchar(100)    NOT NULL,
    [parent_menu_name]          nvarchar(100)    NULL,
    [config_type]               nvarchar(120)    NULL,
    [title]                     nvarchar(60)     NULL,
    [sort_order]                int             NULL,
    [action_expression]         nvarchar(200)    NULL,
    [active_flag]               bit             DEFAULT 0 NOT NULL,
    [security_privilege]        nvarchar(30)     NULL,
    [menu_small_icon]           nvarchar(254)    NULL,
    [description]               nvarchar(max)    NULL,
    [create_date]               datetime        NULL,
    [create_user_id]            nvarchar(256)    NULL,
    [update_date]               datetime        NULL,
    [update_user_id]            nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_menu_config] PRIMARY KEY CLUSTERED ([category], [menu_name])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_message_translation] 
 */

CREATE TABLE [dbo].[cfg_message_translation](
    [organization_id]     int             NOT NULL,
    [profile_group_id]    nvarchar(60)     NOT NULL,
    [profile_element_id]  nvarchar(60)     NOT NULL,
    [translation_key]     nvarchar(150)    NOT NULL,
    [locale]              nvarchar(30)     NOT NULL,
	[config_version]	  bigint		  DEFAULT 0 NOT NULL,
    [translation]         nvarchar(max)    NULL,
    [create_date]         datetime        NULL,
    [create_user_id]      nvarchar(256)    NULL,
    [update_date]         datetime        NULL,
    [update_user_id]      nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_message_translation] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [translation_key], [locale],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_msg_translation_map] 
 */

CREATE TABLE [dbo].[cfg_msg_translation_map](
    [s_organization_id]     int             NOT NULL,
    [s_profile_group_id]    nvarchar(60)     NOT NULL,
    [s_profile_element_id]  nvarchar(60)     NOT NULL,
	[s_config_version]		bigint			NULL,
    [change_id]             nvarchar(254)    NOT NULL,
    [t_organization_id]     int             NOT NULL,
    [t_profile_group_id]    nvarchar(60)     NOT NULL,
    [t_profile_element_id]  nvarchar(60)     NOT NULL,
	[t_config_version]		bigint			NULL,
    [translation_key]       nvarchar(150)    NOT NULL,
    [locale]                nvarchar(30)     NOT NULL
)
go



/* 
 * TABLE: [dbo].[cfg_org_hierarchy_level] 
 */

CREATE TABLE [dbo].[cfg_org_hierarchy_level](
    [organization_id]  int             NOT NULL,
    [org_code]         nvarchar(30)     NOT NULL,
    [parent_org_code]  nvarchar(30)     NULL,
    [description]      nvarchar(254)    NULL,
    [system_flag]      bit             DEFAULT 0 NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_org_hierarchy_level] PRIMARY KEY CLUSTERED ([organization_id], [org_code])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_paybylink] 
 */

CREATE TABLE [dbo].[cfg_paybylink](
    [organization_id]                 int            NOT NULL,
    [hmac_key]                        nvarchar(256)   NOT NULL,
    [expiration_date]                 datetime       NULL,
    [create_date]                     datetime       NULL,
    [create_user_id]                  nvarchar(256)   NULL,
    [update_date]                     datetime       NULL,
    [update_user_id]                  nvarchar(256)   NULL,
    CONSTRAINT [pk_cfg_paybylink] PRIMARY KEY CLUSTERED ([organization_id], [hmac_key])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_personality] 
 */

CREATE TABLE [dbo].[cfg_personality](
    [organization_id]  int             NOT NULL,
    [personality_id]   bigint	       NOT NULL,
    [description]      nvarchar(255)    NULL,
    [comments]         nvarchar(max)	   NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [PK_cfg_personality] PRIMARY KEY CLUSTERED ([organization_id], [personality_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_personality_base_feature] 
 */

CREATE TABLE [dbo].[cfg_personality_base_feature](
    [organization_id]  int             NOT NULL,
    [personality_id]   bigint          NOT NULL,
    [feature_id]       nvarchar(200)    NOT NULL,
    [sort_order]       int             NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_personality_base_feature] PRIMARY KEY CLUSTERED ([organization_id], [personality_id], [feature_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_personality_element] 
 */

CREATE TABLE [dbo].[cfg_personality_element](
    [organization_id]  int            NOT NULL,
    [personality_id]   bigint	      NOT NULL,
    [element_id]       nvarchar(60)    NOT NULL,
    [group_id]         nvarchar(60)    NOT NULL,
    [sort_order]       int            NULL,
    [create_date]      datetime       NULL,
    [create_user_id]   nvarchar(256)   NULL,
    [update_date]      datetime       NULL,
    [update_user_id]   nvarchar(256)   NULL,
    CONSTRAINT [PK_cfg_personality_element] PRIMARY KEY CLUSTERED ([organization_id], [personality_id], [element_id], [group_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_privilege] 
 */

CREATE TABLE [dbo].[cfg_privilege](
    [privilege_id]    nvarchar(30)     NOT NULL,
    [privilege_desc]  nvarchar(255)    NULL,
    [short_desc]      nvarchar(60)     NULL,
    [category]        nvarchar(30)     NULL,
    [create_date]     datetime        NULL,
    [create_user_id]  nvarchar(256)    NULL,
    [update_date]     datetime        NULL,
    [update_user_id]  nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_privileges] PRIMARY KEY CLUSTERED ([privilege_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_profile_element] 
 */

CREATE TABLE [dbo].[cfg_profile_element](
    [element_id]           nvarchar(60)     NOT NULL,
    [group_id]             nvarchar(60)     NOT NULL,
    [element_description]  nvarchar(255)    NULL,
    [comments]             nvarchar(max)    NULL,
    [organization_id]      int             NOT NULL,
    [create_date]          datetime        NULL,
    [create_user_id]       nvarchar(256)    NULL,
    [update_date]          datetime        NULL,
    [update_user_id]       nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_profile_element] PRIMARY KEY CLUSTERED ([organization_id], [element_id], [group_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_profile_element_changes] 
 */

CREATE TABLE [dbo].[cfg_profile_element_changes](
    [organization_id]     int             NOT NULL,
    [profile_group_id]    nvarchar(60)     NOT NULL,
    [profile_element_id]  nvarchar(60)     NOT NULL,
    [change_type]         nvarchar(60)     NOT NULL,
    [change_subtype]      nvarchar(254)    NOT NULL,
    [config_version]      bigint          DEFAULT 0 NOT NULL,
    [change_format]       nvarchar(30)     NULL,
    [changes]             nvarchar(max)    NULL,
    [inactive_flag]       bit             DEFAULT 0 NOT NULL,
    [create_date]         datetime        NULL,
    [create_user_id]      nvarchar(256)    NULL,
    [update_date]         datetime        NULL,
    [update_user_id]      nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_profile_element_changes] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_type], [change_subtype],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_profile_element_version] 
 */

CREATE TABLE [dbo].[cfg_profile_element_version](
    [organization_id]     int            NOT NULL,
    [profile_group_id]    nvarchar(60)    NOT NULL,
    [profile_element_id]  nvarchar(60)    NOT NULL,
    [config_version]      bigint         NOT NULL,
    [deployed]            bit            DEFAULT 0 NULL,
    [create_date]         datetime       NULL,
    [create_user_id]      nvarchar(256)   NULL,
    [update_date]         datetime       NULL,
    [update_user_id]      nvarchar(256)   NULL,
    CONSTRAINT [PK_cfg_profile_element_version] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_profile_group] 
 */

CREATE TABLE [dbo].[cfg_profile_group](
    [group_id]           nvarchar(60)     NOT NULL,
    [group_description]  nvarchar(255)    NULL,
    [comments]           nvarchar(max)    NULL,
    [organization_id]    int             NOT NULL,
	[group_type]		 nvarchar(60)	 null,
    [create_date]        datetime        NULL,
    [create_user_id]     nvarchar(256)    NULL,
    [update_date]        datetime        NULL,
    [update_user_id]     nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_profile_group] PRIMARY KEY CLUSTERED ([organization_id], [group_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_reason_code_change] 
 */

CREATE TABLE [dbo].[cfg_reason_code_change](
    [organization_id]     int               NOT NULL,
    [profile_group_id]    nvarchar(60)       NOT NULL,
    [profile_element_id]  nvarchar(60)       NOT NULL,
    [change_id]           nvarchar(254)      NOT NULL,
	[config_version]	  bigint			DEFAULT 0 NOT NULL,
    [enabled_flag]        bit               DEFAULT 0 NULL,
    [type_code]           nvarchar(30)       NOT NULL,
    [reason_code]         nvarchar(30)       NOT NULL,
    [description]         nvarchar(254)      NULL,
    [parent_code]         nvarchar(30)       NULL,
    [gl_account_number]   nvarchar(254)      NULL,
    [min_amount]          decimal(17, 6)    NULL,
    [max_amount]          decimal(17, 6)    NULL,
    [comment_req]         nvarchar(10)       NULL,
    [cust_message]        nvarchar(254)      NULL,
    [inv_action_code]     nvarchar(30)       NULL,
    [location_id]         nvarchar(60)       NULL,
    [bucket_id]           nvarchar(60)       NULL,
    [sort_order]          int               NULL,
    [hidden_flag]         bit               DEFAULT 0 NULL,
    [create_date]         datetime          NULL,
    [create_user_id]      nvarchar(256)      NULL,
    [update_date]         datetime          NULL,
    [update_user_id]      nvarchar(256)      NULL,
    CONSTRAINT [pk_cfg_reason_code_change] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_id],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_reason_code_change] 
 */

CREATE TABLE [dbo].[cfg_reason_code_p_change](
    [organization_id]     int               NOT NULL,
    [profile_group_id]    nvarchar(60)       NOT NULL,
    [profile_element_id]  nvarchar(60)       NOT NULL,
    [change_id]           nvarchar(254)      NOT NULL,
    [config_version]      bigint            DEFAULT 0 NOT NULL,
    [enabled_flag]        bit               DEFAULT 0 NULL,
    [type_code]           nvarchar(30)       NOT NULL,
    [reason_code]         nvarchar(30)       NOT NULL,
    [property_code]       nvarchar(30)       NOT NULL,
    [type]                nvarchar(30)       NULL,
    [string_value]        nvarchar(max)      NULL,
    [date_value]          datetime          NULL,
    [decimal_value]       decimal(17, 6)    NULL,
    [create_date]         datetime          NULL,
    [create_user_id]      nvarchar(256)      NULL,
    [update_date]         datetime          NULL,
    [update_user_id]      nvarchar(256)      NULL,
    CONSTRAINT [pk_cfg_reason_code_p_change] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_id], [config_version], [type_code], [reason_code], [property_code])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_reason_code_type] 
 */

CREATE TABLE [dbo].[cfg_reason_code_type](
    [organization_id]   int             NOT NULL,
    [reason_code_type]  nvarchar(30)     NOT NULL,
    [description]       nvarchar(254)    NULL,
    [create_date]       datetime        NULL,
    [create_user_id]    nvarchar(256)    NULL,
    [update_date]       datetime        NULL,
    [update_user_id]    nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_reason_code_type] PRIMARY KEY CLUSTERED ([organization_id], [reason_code_type])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_receipt_text_change] 
 */

CREATE TABLE [dbo].[cfg_receipt_text_change](
    [organization_id]     int             NOT NULL,
    [profile_group_id]    nvarchar(60)     NOT NULL,
    [profile_element_id]  nvarchar(60)     NOT NULL,
    [change_id]           nvarchar(254)    NOT NULL,
	[config_version]	  bigint		  DEFAULT 0 NOT NULL,
    [text_code]           nvarchar(30)     NOT NULL,
    [text_subcode]        nvarchar(30)     NOT NULL,
    [receipt_text]        nvarchar(max)    NOT NULL,
    [eff_date]            nvarchar(8)      NULL,
    [expr_date]           nvarchar(8)      NULL,
    [line_format]         nvarchar(254)    NULL,
    [reformat_flag]       bit             DEFAULT 1 NULL,
    [text_seq]            int             DEFAULT 0 NOT NULL,
    [enabled_flag]        bit             DEFAULT 1 NULL,
    [create_date]         datetime        NULL,
    [create_user_id]      nvarchar(256)    NULL,
    [update_date]         datetime        NULL,
    [update_user_id]      nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_receipt_text_changes] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_id],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_resource] 
 */

CREATE TABLE [dbo].[cfg_resource](
      organization_id     int             NOT NULL,
      profile_group_id    nvarchar(60)     NOT NULL,
      profile_element_id  nvarchar(60)     NOT NULL,
      bundle_name         nvarchar(60)     NOT NULL,
      locale              nvarchar(30)     NOT NULL,
	  config_version	  bigint		  DEFAULT (0) NOT NULL,
      data                nvarchar(max)    NULL,
      create_date         datetime        NULL,
      create_user_id      nvarchar(256)    NULL,
      update_date         datetime        NULL,
      update_user_id      nvarchar(256)    NULL,
      CONSTRAINT pk_cfg_resource_bundle PRIMARY KEY CLUSTERED (organization_id, profile_group_id, profile_element_id, bundle_name, locale, config_version)
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_role] 
 */

CREATE TABLE [dbo].[cfg_role](
    [organization_id]   int             NOT NULL,
    [role_id]           nvarchar(30)     NOT NULL,
    [role_desc]         nvarchar(255)    NULL,
    [system_role_flag]  bit             DEFAULT ((0)) NOT NULL,
    [xadmin_rank]       int             DEFAULT 0 NOT NULL,
    [xstore_rank]       int             DEFAULT 0 NOT NULL,
    [create_date]       datetime        NULL,
    [create_user_id]    nvarchar(256)    NULL,
    [update_date]       datetime        NULL,
    [update_user_id]    nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_role] PRIMARY KEY CLUSTERED ([organization_id], [role_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_role_privilege] 
 */

CREATE TABLE [dbo].[cfg_role_privilege](
    [organization_id] int            NOT NULL,
    [role_id]         nvarchar(30)    NOT NULL,
    [privilege_id]    nvarchar(30)    NOT NULL,
    [create_date]     datetime       NULL,
    [create_user_id]  nvarchar(256)   NULL,
    [update_date]     datetime       NULL,
    [update_user_id]  nvarchar(256)   NULL,
    CONSTRAINT [pk_cfg_role_privilege] PRIMARY KEY CLUSTERED ([organization_id], [role_id], [privilege_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_sec_group_change] 
 */

CREATE TABLE [dbo].[cfg_sec_group_change](
    [organization_id]     int             NOT NULL,
    [profile_group_id]    nvarchar(60)     NOT NULL,
    [profile_element_id]  nvarchar(60)     NOT NULL,
    [change_id]           nvarchar(254)    NOT NULL,
	[config_version]	  bigint		  DEFAULT 0 NOT NULL,
    [group_id]            nvarchar(60)     NOT NULL,
    [description]         nvarchar(254)    NULL,
    [bitmap_position]     int             NULL,
    [group_rank]          int             NULL,
    [create_date]         datetime        NULL,
    [create_user_id]      nvarchar(256)    NULL,
    [update_date]         datetime        NULL,
    [update_user_id]      nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_sec_group_change] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_id],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_sec_privilege_change] 
 */

CREATE TABLE [dbo].[cfg_sec_privilege_change](
    [organization_id]                 int             NOT NULL,
    [profile_group_id]                nvarchar(60)     NOT NULL,
    [profile_element_id]              nvarchar(60)     NOT NULL,
    [change_id]                       nvarchar(254)    NOT NULL,
	[config_version]				  bigint		  DEFAULT 0 NOT NULL,
    [privilege_type]                  nvarchar(60)     NOT NULL,
    [authentication_req]              bit             DEFAULT 0 NULL,
    [description]                     nvarchar(254)    NULL,
    [overridable_flag]                bit             DEFAULT 0 NULL,
    [group_membership]                nvarchar(max)    NULL,
    [second_prompt_settings]          nvarchar(30)     NULL,
    [second_prompt_req_diff_emp]      bit             DEFAULT 0 NULL,
    [second_prompt_group_membership]  nvarchar(max)    NULL,
    [create_date]                     datetime        NULL,
    [create_user_id]                  nvarchar(256)    NULL,
    [update_date]                     datetime        NULL,
    [update_user_id]                  nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_sec_privilege_change] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_id],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_sequence] 
 */

CREATE TABLE [dbo].[cfg_sequence](
    [organization_id]  int               NOT NULL,
    [rtl_loc_id]       int               NOT NULL,
    [wkstn_id]         bigint            NOT NULL,
    [sequence_id]      nvarchar(255)      NOT NULL,
    [sequence_nbr]     numeric(19, 0)    NOT NULL,
    [create_date]      datetime          NULL,
    [create_user_id]   nvarchar(256)      NULL,
    [update_date]      datetime          NULL,
    [update_user_id]   nvarchar(256)      NULL,
    CONSTRAINT [pk_cfg_sequence] PRIMARY KEY CLUSTERED ([organization_id], [rtl_loc_id], [wkstn_id], [sequence_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_sequence_part] 
 */

CREATE TABLE [dbo].[cfg_sequence_part](
    [organization_id]   int               NOT NULL,
    [sequence_id]       nvarchar(255)      NOT NULL,
    [prefix]            nvarchar(30)       NULL,
    [suffix]            nvarchar(30)       NULL,
    [encode_flag]       bit               NULL,
    [check_digit_algo]  nvarchar(30)       NULL,
    [numeric_flag]      bit               NULL,
    [pad_length]        int               NULL,
    [pad_character]     nvarchar(2)        NULL,
    [initial_value]     int               NULL,
    [max_value]         numeric(10, 0)    NULL,
    [value_increment]   int               NULL,
    [include_store_id]  bit               NULL,
    [store_pad_length]  int               NULL,
    [include_wkstn_id]  bit               NULL,
    [wkstn_pad_length]  int               NULL,
    [create_date]       datetime          NULL,
    [create_user_id]    nvarchar(256)      NULL,
    [update_date]       datetime          NULL,
    [update_user_id]    nvarchar(256)      NULL,
    CONSTRAINT [pk_cfg_sequence_part] PRIMARY KEY CLUSTERED ([organization_id], [sequence_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_store_personality] 
 */

CREATE TABLE [dbo].[cfg_store_personality](
    [organization_id]  int            NOT NULL,
    [store_number]     int            NOT NULL,
    [personality_id]   bigint         NOT NULL,
    [landscape_id]     bigint         NOT NULL,
    [create_date]      datetime       NULL,
    [create_user_id]   nvarchar(256)   NULL,
    [update_date]      datetime       NULL,
    [update_user_id]   nvarchar(256)   NULL,
    CONSTRAINT [pk_cfg_store_personality] PRIMARY KEY CLUSTERED ([organization_id], [store_number])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_system_setting] 
 */

CREATE TABLE [dbo].[cfg_system_setting](
    [config_id]        nvarchar(60)     NOT NULL,
    [config_value]     nvarchar(200)    NULL,
    [modified_event]   nvarchar(200)    NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_system_setting] PRIMARY KEY CLUSTERED ([config_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_tab_property] 
 */

CREATE TABLE [dbo].[cfg_tab_property](
    [tab_id]             nvarchar(30)      NOT NULL,
    [property_id]        nvarchar(30)      NOT NULL,
    [display_component]  nvarchar(1000)    NOT NULL,
    [value_type]         nvarchar(1000)    NOT NULL,
    [label]              nvarchar(1000)    NOT NULL,
    [create_date]        datetime         NULL,
    [create_user_id]     nvarchar(256)     NULL,
    [update_date]        datetime         NULL,
    [update_user_id]     nvarchar(256)     NULL,
    CONSTRAINT [pk_cfg_tab_property] PRIMARY KEY CLUSTERED ([property_id], [tab_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_tender_availability_change] 
 */

CREATE TABLE [dbo].[cfg_tender_availability_change](
    [organization_id]     int             NOT NULL,
    [profile_group_id]    nvarchar(60)     NOT NULL,
    [profile_element_id]  nvarchar(60)     NOT NULL,
    [change_id]           nvarchar(254)    NOT NULL,
    [tndr_id]             nvarchar(60)     NOT NULL,
    [availability_code]   nvarchar(30)     NOT NULL,
	[config_version]	  bigint		  DEFAULT 0 NOT NULL,
    [enabled_flag]        bit             DEFAULT 0 NULL,
    [create_date]         datetime        NULL,
    [create_user_id]      nvarchar(256)    NULL,
    [update_date]         datetime        NULL,
    [update_user_id]      nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_tender_avail_change] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_id], [availability_code],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_tender_change] 
 */

CREATE TABLE [dbo].[cfg_tender_change](
    [organization_id]               int               NOT NULL,
    [profile_group_id]              nvarchar(60)       NOT NULL,
    [profile_element_id]            nvarchar(60)       NOT NULL,
    [change_id]                     nvarchar(254)      NOT NULL,
	[config_version]				bigint			  DEFAULT 0 NOT NULL,
    [tndr_id]                       nvarchar(60)       NOT NULL,
    [tndr_typcode]                  nvarchar(30)       NULL,
    [currency_id]                   nvarchar(3)        NULL,
    [description]                   nvarchar(254)      NULL,
    [display_order]                 int               NULL,
    [flash_sales_display_order]     int               NULL,
    [disabled_flag]                 bit               DEFAULT 0 NULL,
    [create_date]                   datetime          NULL,
    [create_user_id]                nvarchar(256)      NULL,
    [update_date]                   datetime          NULL,
    [update_user_id]                nvarchar(256)      NULL,
    CONSTRAINT [pk_cfg_tender_change] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_id],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_tender_denomination_change] 
 */

CREATE TABLE [dbo].[cfg_tender_denomination_change](
    [organization_id]     int               NOT NULL,
    [profile_group_id]    nvarchar(60)       NOT NULL,
    [profile_element_id]  nvarchar(60)       NOT NULL,
    [change_id]           nvarchar(254)      NOT NULL,
    [tndr_id]             nvarchar(60)       NOT NULL,
    [denomination_id]     nvarchar(60)       NOT NULL,
	[config_version]	  bigint			DEFAULT 0 NOT NULL,
    [description]         nvarchar(254)      NULL,
    [value]               decimal(17, 6)    NULL,
    [sort_order]          int               NULL,
    [enabled_flag]        bit               DEFAULT 0 NULL,
    [create_date]         datetime          NULL,
    [create_user_id]      nvarchar(256)      NULL,
    [update_date]         datetime          NULL,
    [update_user_id]      nvarchar(256)      NULL,
    CONSTRAINT [pk_cfg_tender_denom_change] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_id], [denomination_id],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_tender_options_change] 
 */

CREATE TABLE [dbo].[cfg_tender_options_change](
    [organization_id]               int               NOT NULL,
    [profile_group_id]              nvarchar(60)       NOT NULL,
    [profile_element_id]            nvarchar(60)       NOT NULL,
    [change_id]                     nvarchar(254)      NOT NULL,
	[config_version]				bigint			  DEFAULT 0 NOT NULL,
    [tndr_id]                       nvarchar(60)       NOT NULL,
    [auth_mthd_code]                nvarchar(30)       NULL,
    [serial_id_nbr_req_flag]        bit               DEFAULT 0 NULL,
    [auth_req_flag]                 bit               DEFAULT 0 NULL,
    [auth_expr_date_req_flag]       bit               DEFAULT 0 NULL,
    [pin_req_flag]                  bit               DEFAULT 0 NULL,
    [cust_sig_req_flag]             bit               DEFAULT 0 NULL,
    [endorsement_req_flag]          bit               DEFAULT 0 NULL,
    [open_cash_drawer_req_flag]     bit               DEFAULT 0 NULL,
    [unit_count_req_code]           nvarchar(30)       NULL,
    [mag_swipe_reader_req_flag]     bit               DEFAULT 0 NULL,
    [dflt_to_amt_due_flag]          bit               DEFAULT 0 NULL,
    [min_denomination_amt]          decimal(17, 6)    NULL,
    [reporting_group]               nvarchar(30)       NULL,
    [effective_date]                nvarchar(8)        NULL,
    [expr_date]                     nvarchar(8)        NULL,
    [min_days_for_return]           int               NULL,
    [max_days_for_return]           int               NULL,
    [cust_id_req_code]              nvarchar(30)       NULL,
    [cust_association_flag]         bit               DEFAULT 0 NULL,
    [populate_system_count_flag]    bit               DEFAULT 0 NULL,
    [include_in_type_count_flag]    bit               DEFAULT 0 NULL,
    [suggested_deposit_threshold]   decimal(17, 6)    NULL,
    [suggest_deposit_flag]          bit               DEFAULT 0 NULL,
    [change_tndr_id]                nvarchar(60)       NULL,
    [cash_change_limit]             decimal(17, 6)    NULL,
    [over_tender_overridable_flag]  bit               DEFAULT 0 NULL,
    [non_voidable_flag]             bit               DEFAULT 0 NULL,
    [disallow_split_tndr_flag]      bit               DEFAULT 0 NULL,
    [close_count_disc_threshold]    decimal(17, 6)    NULL,
    [cid_msr_req_flag]              bit               DEFAULT 0 NULL,
    [cid_keyed_req_flag]            bit               DEFAULT 0 NULL,
    [postal_code_req_flag]          bit               DEFAULT 0 NULL,
    [post_void_open_drawer_flag]    bit               DEFAULT 0 NULL,
    [change_allowed_when_foreign]   bit               DEFAULT 0 NULL,
    [fiscal_tndr_id]                nvarchar(60)       NULL,
    [rounding_mode]                 nvarchar(254)      NULL,
    [assign_cash_drawer_req_flag]   bit               DEFAULT 0 NULL,
    [post_void_assign_drawer_flag]  bit               DEFAULT 0 NULL,
    [create_date]                   datetime          NULL,
    [create_user_id]                nvarchar(256)      NULL,
    [update_date]                   datetime          NULL,
    [update_user_id]                nvarchar(256)      NULL,
    [record_state]                  nvarchar(30)       NULL,
    CONSTRAINT [pk_cfg_tender_options_change] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_id],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_tender_settings_change] 
 */

CREATE TABLE [dbo].[cfg_tender_settings_change](
    [organization_id]               int               NOT NULL,
    [profile_group_id]              nvarchar(60)       NOT NULL,
    [profile_element_id]            nvarchar(60)       NOT NULL,
    [change_id]                     nvarchar(254)      NOT NULL,
	[config_version]				bigint			  DEFAULT 0 NOT NULL,
    [tndr_id]                       nvarchar(60)       NOT NULL,
    [group_id]                      nvarchar(60)       NOT NULL,
    [usage_code]                    nvarchar(30)       NOT NULL,
    [entry_mthd_code]               nvarchar(60)       NOT NULL,
    [online_floor_approval_amt]     decimal(17, 6)    NULL,
    [online_ceiling_approval_amt]   decimal(17, 6)    NULL,
    [over_tndr_limit]               decimal(17, 6)    NULL,
    [offline_floor_approval_amt]    decimal(17, 6)    NULL,
    [offline_ceiling_approval_amt]  decimal(17, 6)    NULL,
    [min_accept_amt]                decimal(17, 6)    NULL,
    [max_accept_amt]                decimal(17, 6)    NULL,
    [max_refund_with_receipt]       decimal(17, 6)    NULL,
    [max_refund_wo_receipt]         decimal(17, 6)    NULL,
    [enabled_flag]                  bit               DEFAULT 0 NULL,
    [create_date]                   datetime          NULL,
    [create_user_id]                nvarchar(256)      NULL,
    [update_date]                   datetime          NULL,
    [update_user_id]                nvarchar(256)      NULL,
    CONSTRAINT [pk_cfg_tender_settings_change] PRIMARY KEY CLUSTERED ([organization_id], [profile_group_id], [profile_element_id], [change_id],[config_version])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_tender_type_category] 
 */

CREATE TABLE [dbo].[cfg_tender_type_category](
    [organization_id]  int            NOT NULL,
    [tender_category]  nvarchar(30)    NOT NULL,
    [tender_type]      nvarchar(30)    NOT NULL,
    [create_date]      datetime       NULL,
    [create_user_id]   nvarchar(256)   NULL,
    [update_date]      datetime       NULL,
    [update_user_id]   nvarchar(256)   NULL,
    CONSTRAINT [pk_cfg_tender_type_category] PRIMARY KEY CLUSTERED ([organization_id], [tender_category], [tender_type])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_upload_record] 
 */

CREATE TABLE [dbo].[cfg_upload_record](
    [organization_id]  int             NOT NULL,
    [name]             nvarchar(255)    NOT NULL,
    [user_org_nodes]   nvarchar(max)    NULL,
    [file_desc]        nvarchar(100)    NULL,
    [file_size]        bigint		   NULL,
    [create_date]      datetime        DEFAULT getdate() NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_upload_record] PRIMARY KEY CLUSTERED ([organization_id], [name])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_upload_record_hash] 
 */

CREATE TABLE [dbo].[cfg_upload_record_hash](
    [organization_id]       int             NOT NULL,
    [name]                  nvarchar(255)    NOT NULL,
    [file_hash_algorithm]   nvarchar(30)     NOT NULL,
    [file_hash]             nvarchar(255)    NULL,
    [create_date]           datetime        DEFAULT getdate() NULL,
    [create_user_id]        nvarchar(256)    NULL,
    [update_date]           datetime        NULL,
    [update_user_id]        nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_upload_record_hash] PRIMARY KEY CLUSTERED ([organization_id], [name], [file_hash_algorithm])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_user] 
 */

CREATE TABLE [dbo].[cfg_user](
    [user_name]              nvarchar(256)   NOT NULL,
    [first_name]             nvarchar(60)    NULL,
    [last_name]              nvarchar(60)    NULL,
    [locale]                 nvarchar(30)    NULL,
    [email_address]          nvarchar(256)   NULL,
    [idp_resource_id]        nvarchar(60)    NULL,
    [user_status]            nvarchar(30)    NULL,
    [is_account_locked]      bit            DEFAULT 0 NOT NULL,
    [failed_login_attempts]  int            DEFAULT 0 NOT NULL,
    [directory_type]         nvarchar(30)    DEFAULT 'INTERNAL' NOT NULL,
    [create_date]            datetime       NULL,
    [create_user_id]         nvarchar(256)   NULL,
    [update_date]            datetime       NULL,
    [update_user_id]         nvarchar(256)   NULL,
    CONSTRAINT [pk_cfg_user] PRIMARY KEY CLUSTERED ([user_name])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_user_node] 
 */

CREATE TABLE [dbo].[cfg_user_node](
    [organization_id]  int             NOT NULL,
    [user_name]        nvarchar(256)    NOT NULL,
    [org_scope]        nvarchar(100)    NOT NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_user_node] PRIMARY KEY CLUSTERED ([organization_id], [user_name], [org_scope])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[cfg_user_org_role] 
 */

CREATE TABLE [dbo].[cfg_user_org_role](
    [user_name]              nvarchar(256)   NOT NULL,
    [organization_id]        int            NOT NULL,
    [role_id]                nvarchar(30)    NULL,
    [is_dashboard_homepage]  bit            DEFAULT 0 NOT NULL,
    [create_date]            datetime       NULL,
    [create_user_id]         nvarchar(256)   NULL,
    [update_date]            datetime       NULL,
    [update_user_id]         nvarchar(256)   NULL,
    CONSTRAINT [pk_cfg_user_org_role] PRIMARY KEY CLUSTERED ([user_name], [organization_id])
    WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: [dbo].[cfg_user_password] 
 */

CREATE TABLE [dbo].[cfg_user_password](
    [user_name]        nvarchar(256)      NOT NULL,
    [password_id]      numeric(19, 0)    IDENTITY(0,1),
    [password]         nvarchar(255)      NULL,
    [effective_date]   datetime          NULL,
	[temporary_flag]   bit				 DEFAULT 0 NULL,
    [create_date]      datetime          NULL,
    [create_user_id]   nvarchar(256)      NULL,
    [update_date]      datetime          NULL,
    [update_user_id]   nvarchar(256)      NULL,
    CONSTRAINT [pk_cfg_user_password] PRIMARY KEY CLUSTERED ([password_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_address_change] 
 */

CREATE TABLE [dbo].[dat_address_change](
    [organization_id]  int             NOT NULL,
    [target_node]      nvarchar(100)    NOT NULL,
    [target_date]      nvarchar(8)      NOT NULL,
    [sequence_number]  int             NOT NULL,
    [record_id]        nvarchar(254)    NOT NULL,
    [address_id]       nvarchar(60)     NOT NULL,
    [org_code]         nvarchar(30)     DEFAULT '*' NOT NULL,
    [org_value]        nvarchar(60)     DEFAULT '*' NOT NULL,
    [address1]         nvarchar(254)    NULL,
    [address2]         nvarchar(254)    NULL,
    [address3]         nvarchar(254)    NULL,
    [address4]         nvarchar(254)    NULL,
    [apartment]        nvarchar(30)     NULL,
    [city]             nvarchar(254)    NULL,
    [territory]        nvarchar(254)    NULL,
    [postal_code]      nvarchar(254)    NULL,
    [country]          nvarchar(254)    NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [pk_dat_address_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_attached_item_change] 
 */

CREATE TABLE [dbo].[dat_attached_item_change](
    [organization_id]            int               NOT NULL,
    [target_node]                nvarchar(100)      NOT NULL,
    [target_date]                nvarchar(8)        NOT NULL,
    [sequence_number]            int               NOT NULL,
    [record_id]                  nvarchar(254)      NOT NULL,
    [sold_item_id]               nvarchar(60)       NOT NULL,
    [attached_item_id]           nvarchar(60)       NOT NULL,
    [level_code]                 nvarchar(30)       DEFAULT '*' NOT NULL,
    [level_value]                nvarchar(60)       DEFAULT '*' NOT NULL,
    [begin_datetime]             nvarchar(8)        NULL,
    [end_datetime]               nvarchar(8)        NULL,
    [prompt_to_add_flag]         bit               DEFAULT 0 NOT NULL,
    [prompt_to_add_msg_key]      nvarchar(254)      NULL,
    [quantity_to_add]            decimal(11, 4)    NULL,
    [lineitm_assoc_typcode]      nvarchar(30)       NULL,
    [prompt_for_return_flag]     bit               DEFAULT 0 NOT NULL,
    [prompt_for_return_msg_key]  nvarchar(254)      NULL,
    [deployed_flag]              bit               DEFAULT 0 NULL,
    [create_date]                datetime          NULL,
    [create_user_id]             nvarchar(256)      NULL,
    [update_date]                datetime          NULL,
    [update_user_id]             nvarchar(256)      NULL,
    CONSTRAINT [pk_dat_attached_item_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_datamanager_change] 
 */

CREATE TABLE [dbo].[dat_datamanager_change](
    [organization_id]     int              NOT NULL,
    [target_node]         nvarchar(100)     NOT NULL,
    [target_date]         nvarchar(8)       NOT NULL,
    [sequence_number]     int              NOT NULL,
    [record_id]           nvarchar(254)     NOT NULL,
    [action_type]         nvarchar(60)      NULL,
    [record_type]         nvarchar(60)      NOT NULL,
    [record_description]  nvarchar(1000)    NULL,
    [deployed_flag]       bit              DEFAULT 0 NULL,
    [create_date]         datetime         NULL,
    [create_user_id]      nvarchar(256)     NULL,
    [update_date]         datetime         NULL,
    [update_user_id]      nvarchar(256)     NULL,
    CONSTRAINT [pk_dat_datamanager_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id], [record_type])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_emp_change] 
 */

CREATE TABLE [dbo].[dat_emp_change](
    [organization_id]          int               NOT NULL,
    [target_node]              nvarchar(100)      NOT NULL,
    [target_date]              nvarchar(8)        NOT NULL,
    [sequence_number]          int               NOT NULL,
    [record_id]                nvarchar(254)      NOT NULL,
    [deployed_flag]            bit               DEFAULT 0 NULL,
    [employee_id]              nvarchar(60)       NOT NULL,
    [party_id]                 bigint            NULL,
    [login_id]                 nvarchar(60)       NULL,
    [hire_date]                nvarchar(8)        NULL,
    [active_date]              nvarchar(8)        NULL,
    [terminated_date]          nvarchar(8)        NULL,
    [job_title]                nvarchar(254)      NULL,
    [base_pay]                 decimal(17, 6)    NULL,
    [emergency_contact_name]   nvarchar(254)      NULL,
    [emergency_contact_phone]  nvarchar(32)       NULL,
    [last_review_date]         nvarchar(8)        NULL,
    [next_review_date]         nvarchar(8)        NULL,
    [additional_withholdings]  decimal(17, 6)    NULL,
    [clock_in_not_req_flag]    bit               DEFAULT 0 NULL,
    [employee_pay_status]      nvarchar(30)       NULL,
    [employee_statcode]        nvarchar(30)       NULL,
    [group_membership]         nvarchar(max)      NULL,
    [primary_group]            nvarchar(60)       NULL,
    [department_id]            nvarchar(30)       NULL,
    [training_status_enum]     nvarchar(30)       NULL,
    [locked_out_flag]          bit               DEFAULT 0 NULL,
    [overtime_eligible_flag]   bit               DEFAULT 0 NULL,
    [salutation]               nvarchar(30)       NULL,
    [first_name]               nvarchar(60)       NULL,
    [middle_name]              nvarchar(60)       NULL,
    [last_name]                nvarchar(60)       NULL,
    [suffix]                   nvarchar(30)       NULL,
    [gender]                   nvarchar(30)       NULL,
    [preferred_locale]         nvarchar(30)       NULL,
    [birth_date]               nvarchar(8)        NULL,
    [address1]                 nvarchar(254)      NULL,
    [address2]                 nvarchar(254)      NULL,
    [city]                     nvarchar(254)      NULL,
    [state]                    nvarchar(30)       NULL,
    [postal_code]              nvarchar(30)       NULL,
    [country]                  nvarchar(254)      NULL,
    [primary_phone]            nvarchar(32)       NULL,
    [email_address]            nvarchar(254)      NULL,
    [other_phone]              nvarchar(32)       NULL,
    [sick_days_used]           decimal(11, 2)    NULL,
    [marital_status]           nvarchar(30)       NULL,
    [spouse_name]              nvarchar(254)      NULL,
    [vacation_days]            decimal(11, 2)    NULL,
    [vacation_days_used]       decimal(11, 2)    NULL,
    [sick_days]                decimal(11, 2)    NULL,
    [personal_days]            decimal(11, 2)    NULL,
    [personal_days_used]       decimal(11, 2)    NULL,
    [employee_role_code]       nvarchar(30)       NULL,
    [employee_group_id]        nvarchar(60)       NULL,
    [social_security_nbr]      nvarchar(255)      NULL,
    [national_tax_id]          nvarchar(30)       NULL,
    [personal_tax_id]          nvarchar(30)       NULL,
    [create_date]              datetime          NULL,
    [create_user_id]           nvarchar(256)      NULL,
    [update_date]              datetime          NULL,
    [update_user_id]           nvarchar(256)      NULL,
    CONSTRAINT [pk_emp_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [record_id], [sequence_number])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_emp_cust_group_change] 
 */

CREATE TABLE [dbo].[dat_emp_cust_group_change](
    [organization_id]  int             NOT NULL,
    [target_node]      nvarchar(100)    NOT NULL,
    [target_date]      nvarchar(8)      NOT NULL,
    [sequence_number]  int             NOT NULL,
    [record_id]        nvarchar(254)    NOT NULL,
    [group_id]         nvarchar(60)     NOT NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [pk_dat_emp_cust_group_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [record_id], [sequence_number], [group_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_emp_store_change] 
 */

CREATE TABLE [dbo].[dat_emp_store_change](
    [organization_id]       int             NOT NULL,
    [target_node]           nvarchar(100)    NOT NULL,
    [target_date]           nvarchar(8)      NOT NULL,
    [sequence_number]       int             NOT NULL,
    [record_id]             nvarchar(254)    NOT NULL,
    [rtl_loc_id]            int             NOT NULL,
    [employee_id]           nvarchar(60)     NOT NULL,
    [employee_store_seq]    int             NOT NULL,
    [begin_date]            nvarchar(8)      NULL,
    [end_date]              nvarchar(8)      NULL,
    [temp_assignment_flag]  bit             DEFAULT 0 NULL,
    [create_date]           datetime        NULL,
    [create_user_id]        nvarchar(256)    NULL,
    [update_date]           datetime        NULL,
    [update_user_id]        nvarchar(256)    NULL,
    CONSTRAINT [pk_emp_store_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [record_id], [sequence_number], [employee_store_seq])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_emp_task_change] 
 */

CREATE TABLE [dbo].[dat_emp_task_change](
    [organization_id]  int             NOT NULL,
    [target_node]      nvarchar(100)    NOT NULL,
    [target_date]      nvarchar(8)      NOT NULL,
    [sequence_number]  int             NOT NULL,
    [record_id]        nvarchar(254)    NOT NULL,
    [rtl_loc_id]       int             NOT NULL,
    [task_id]          bigint          NOT NULL,
    [start_date]       nvarchar(8)      NULL,
    [start_time]       nvarchar(4)      NULL,
    [end_date]         nvarchar(8)      NULL,
    [end_time]         nvarchar(4)      NULL,
    [typcode]          nvarchar(60)     NULL,
    [visibility]       nvarchar(30)     NULL,
    [assignment_id]    nvarchar(60)     NULL,
    [title]            nvarchar(255)    NULL,
    [description]      nvarchar(max)    NULL,
    [priority]         nvarchar(20)     NULL,
    [deployed_flag]    bit             DEFAULT 0 NULL,
    [status_code]      nvarchar(30)     NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [pk_dat_emp_task_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_exchange_rate_change] 
 */

CREATE TABLE [dbo].[dat_exchange_rate_change](
    [organization_id]  int               NOT NULL,
    [target_node]      nvarchar(100)      NOT NULL,
    [target_date]      nvarchar(8)        NOT NULL,
    [sequence_number]  int               NOT NULL,
    [record_id]        nvarchar(254)      NOT NULL,
    [level_code]       nvarchar(30)       DEFAULT '*' NOT NULL,
    [level_value]      nvarchar(60)       DEFAULT '*' NOT NULL,
    [base_currency]    nvarchar(3)        NOT NULL,
    [target_currency]  nvarchar(3)        NOT NULL,
    [rate]             decimal(17, 6)    NULL,
    [print_as_inverted]bit               DEFAULT 0,
    [deployed_flag]    bit               DEFAULT 0 NULL,
    [create_date]      datetime          NULL,
    [create_user_id]   nvarchar(256)      NULL,
    [update_date]      datetime          NULL,
    [update_user_id]   nvarchar(256)      NULL,
    [record_state]     nvarchar(30)       NULL,
    CONSTRAINT [pk_data_exchange_rate_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_item_change] 
 */

CREATE TABLE [dbo].[dat_item_change](
    [organization_id]               int               NOT NULL,
    [target_node]                   nvarchar(100)      NOT NULL,
    [target_date]                   nvarchar(8)        NOT NULL,
    [sequence_number]               int               NOT NULL,
    [record_id]                     nvarchar(254)      NOT NULL,
    [dtype]                         nvarchar(100)      NULL,
    [item_id]                       nvarchar(60)       NOT NULL,
    [org_code]                      nvarchar(30)       DEFAULT '*' NOT NULL,
    [org_value]                     nvarchar(60)       DEFAULT '*' NOT NULL,
    [name]                          nvarchar(254)      NULL,
    [description]                   nvarchar(254)      NULL,
    [merch_level_1]                 nvarchar(60)       DEFAULT 'DEFAULT' NULL,
    [merch_level_2]		            nvarchar(60)       NULL,
    [merch_level_3]                 nvarchar(60)       NULL,
    [merch_level_4]                 nvarchar(60)       NULL,
    [item_url]                      nvarchar(254)      NULL,
    [LIST_PRICE]                    decimal(17, 6)    NULL,
    [MEASURE_REQ_FLAG]		        bit               DEFAULT ((0)) NULL,
    [item_lvlcode]                  nvarchar(30)       NULL,
    [parent_item_id]                nvarchar(60)       NULL,
    [NOT_INVENTORIED_FLAG]          bit               DEFAULT ((0)) NULL,
    [serialized_item_flag]          bit               DEFAULT 0 NULL,
    [item_typcode]                  nvarchar(30)       NULL,
    [dtv_class_name]                nvarchar(254)      NULL,
    [dimension_system]              nvarchar(60)       NULL,
    [disallow_matrix_display_flag]  bit               DEFAULT 0 NULL,
    [item_matrix_color]             nvarchar(20)       NULL,
    [deployed_flag]                 bit               DEFAULT 0 NULL,
    [dimension1]                    nvarchar(60)       NULL,
    [dimension2]                    nvarchar(60)       NULL,
    [dimension3]                    nvarchar(60)       NULL,
    [create_date]                   datetime          NULL,
    [create_user_id]                nvarchar(256)      NULL,
    [update_date]                   datetime          NULL,
    [update_user_id]                nvarchar(256)      NULL,
    [record_state]                  nvarchar(30)       NULL,
    CONSTRAINT [pk_dat_item_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go


/* 
 * INDEX: [idx_dat_item_change02] 
 */

CREATE INDEX [idx_dat_item_change02] ON [dbo].[dat_item_change]([item_id], [item_typcode], [merch_level_1], [organization_id])
WITH FILLFACTOR = 80
go
/* 
 * INDEX: [xst_dat_item_change_mrchlvl3] 
 */

CREATE INDEX [xst_dat_item_change_mrchlvl3] ON [dbo].[dat_item_change]([organization_id], [merch_level_3])
WITH FILLFACTOR = 80
go
/* 
 * INDEX: [xst_dat_item_change_mrchlvl1] 
 */

CREATE INDEX [xst_dat_item_change_mrchlvl1] ON [dbo].[dat_item_change]([organization_id], [merch_level_1])
WITH FILLFACTOR = 80
go
/* 
 * INDEX: [xst_dat_item_change_desc] 
 */

CREATE INDEX [xst_dat_item_change_desc] ON [dbo].[dat_item_change]([organization_id], [description])
WITH FILLFACTOR = 80
go
/* 
 * INDEX: [xst_dat_item_change_id_parntid] 
 */

CREATE INDEX [xst_dat_item_change_id_parntid] ON [dbo].[dat_item_change]([organization_id], [parent_item_id], [item_id])
WITH FILLFACTOR = 80
go
/* 
 * INDEX: [xst_dat_item_change_mrchlvl4] 
 */

CREATE INDEX [xst_dat_item_change_mrchlvl4] ON [dbo].[dat_item_change]([organization_id], [merch_level_4])
WITH FILLFACTOR = 80
go
/* 
 * INDEX: [xst_dat_item_change_mrchlvl2] 
 */

CREATE INDEX [xst_dat_item_change_mrchlvl2] ON [dbo].[dat_item_change]([organization_id], [merch_level_2])
WITH FILLFACTOR = 80
go
/* 
 * INDEX: [xst_dat_item_change_typcode] 
 */

CREATE INDEX [xst_dat_item_change_typcode] ON [dbo].[dat_item_change]([organization_id], [item_typcode])
WITH FILLFACTOR = 80
go
/* 
 * TABLE: [dbo].[dat_item_msg_change] 
 */

CREATE TABLE [dbo].dat_item_msg_change(
    [organization_id]            int                      NOT NULL,
    [target_node]                nvarchar(100)             NOT NULL,
    [target_date]                nvarchar(8)               NOT NULL,
    [sequence_number]            int                      NOT NULL,
    [record_id]                  nvarchar(254)             NOT NULL,
    [msg_id]                     nvarchar(60)              NOT NULL,
    [effective_datetime]         datetime                 NOT NULL,
    [org_code]                   nvarchar(30)              DEFAULT('*') NOT NULL,
    [org_value]                  nvarchar(60)              DEFAULT('*') NOT NULL,
    [expr_datetime]              datetime                 NULL,
    [msg_key]                    nvarchar(254)             NOT NULL,
    [title_key]                  nvarchar(254)             NULL,
    [content_type]               nvarchar(30)              NULL,
    [contents]                   varbinary(max)           NULL,
    [deployed_flag]              bit                      DEFAULT 0    NULL,
    [create_date]                datetime                 NULL,
    [create_user_id]             nvarchar(256)             NULL,
    [update_date]                datetime                 NULL,
    [update_user_id]             nvarchar(256)             NULL,
    [record_state]               nvarchar(30)              NULL,
        
  CONSTRAINT [pk_dat_item_msg_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: [dbo].[dat_item_msg_types_change] 
 */
 
CREATE TABLE [dbo].[dat_item_msg_types_change](
   [organization_id]                int                         NOT NULL,
    [target_node]                   nvarchar(100)                NOT NULL,
    [target_date]                   nvarchar(8)                  NOT NULL,
    [sequence_number]               int                         NOT NULL,
    [record_id]                     nvarchar(254)                NOT NULL,
    [msg_id]                        nvarchar(60)                 NOT NULL,
    [sale_lineitm_typcode]          nvarchar(30)                 NOT NULL,
    [org_code]                      nvarchar(30)                 DEFAULT('*') NOT NULL,
    [org_value]                     nvarchar(60)                 DEFAULT('*') NOT NULL,    
    [deployed_flag]                 bit                         DEFAULT 0  NULL,
    [create_date]                   datetime                    NULL,
    [create_user_id]                nvarchar(256)                NULL,
    [update_date]                   datetime                    NULL,
    [update_user_id]                nvarchar(256)                NULL,
    [record_state]                  nvarchar(30)                 NULL,
    CONSTRAINT [pk_dat_item_msg_types_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go




/* 
 * TABLE: [dbo].[dat_item_msg_xref_change] 
 */

CREATE TABLE [dbo].[dat_item_msg_xref_change](
    [organization_id]               int               NOT NULL,
    [target_node]                   nvarchar(100)      NOT NULL,
    [target_date]                   nvarchar(8)        NOT NULL,
    [sequence_number]               int               NOT NULL,
    [record_id]                     nvarchar(254)      NOT NULL,
    [item_id]                       nvarchar(60)       NOT NULL,
    [msg_id]                        nvarchar(60)       NOT NULL,
    [org_code]                      nvarchar(30)       DEFAULT('*')    NOT NULL,
    [org_value]                     nvarchar(60)       DEFAULT('*')    NOT NULL,    
    [deployed_flag]                 bit               DEFAULT 0       NULL,
    [create_date]                   datetime          NULL,
    [create_user_id]                nvarchar(256)      NULL,
    [update_date]                   datetime          NULL,
    [update_user_id]                nvarchar(256)      NULL,
    [record_state]                  nvarchar(30)       NULL,
    
    CONSTRAINT [pk_dat_item_msg_xref_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
  WITH FILLFACTOR = 80
)
go




/* 
 * TABLE: [dbo].[dat_item_options_change] 
 */
 
CREATE TABLE [dbo].[dat_item_options_change] (
    [ORGANIZATION_ID]              int               NOT NULL,
    [target_node]                  nvarchar(100)      NOT NULL,
    [target_date]                  nvarchar(8)        NOT NULL,
    [sequence_number]              int               NOT NULL,
    [record_id]                    nvarchar(254)      NOT NULL,
    [deployed_flag]                bit               DEFAULT 0 NULL,
    [ITEM_ID]                      nvarchar(60)       NOT NULL,
    [LEVEL_CODE]		           nvarchar(30)	     DEFAULT('*') NOT NULL,
    [LEVEL_VALUE]			       nvarchar(60)	     DEFAULT('*') NOT NULL,
    [UNIT_COST]                    decimal(17, 6)    NULL,
    [CURR_SALE_PRICE]              decimal(17, 6)    NULL,
    [UNIT_OF_MEASURE_CODE]         nvarchar(30)       NULL,
    [COMPARE_AT_PRICE]             decimal(17, 6)    NULL,
    [MIN_SALE_UNIT_COUNT]          decimal(11, 4)    NULL,
    [MAX_SALE_UNIT_COUNT]          decimal(11, 4)    NULL,
    [ITEM_AVAILABILITY_CODE]       nvarchar(30)       NULL,
    [DISALLOW_DISCOUNTS_FLAG]      bit               DEFAULT ((0)) NULL,
    [PROMPT_FOR_QUANTITY_FLAG]     bit               DEFAULT ((0)) NULL,
    [PROMPT_FOR_PRICE_FLAG]        bit               DEFAULT ((0)) NULL,
    [PROMPT_FOR_DESCRIPTION_FLAG]  bit               DEFAULT ((0)) NULL,
    [FORCE_QUANTITY_OF_ONE_FLAG]   bit               DEFAULT ((0)) NULL,
    [NOT_RETURNABLE_FLAG]          bit               DEFAULT ((0)) NULL,
    [NO_GIVEAWAYS_FLAG]            bit               DEFAULT ((0)) NULL,
    [ATTACHED_ITEMS_FLAG]          bit               DEFAULT ((0)) NULL,
    [SUBSTITUTE_AVAILABLE_FLAG]    bit               DEFAULT ((0)) NULL,
    [TAX_GROUP_ID]                 nvarchar(60)       NULL,
    [MESSAGES_FLAG]                bit               DEFAULT ((0)) NULL,
    [VENDOR]                       nvarchar(256)      NULL,
    [SEASON_CODE]                  nvarchar(30)       NULL,
    [PART_NUMBER]                  nvarchar(254)      NULL,
    [QTY_SCALE]                    int               NULL,
    [RESTOCKING_FEE]               decimal(17, 6)    NULL,
    [SPECIAL_ORDER_LEAD_DAYS]      int               NULL,
    [APPLY_RESTOCKING_FEE_FLAG]    bit               DEFAULT ((0)) NULL,
    [DISALLOW_SEND_SALE_FLAG]      bit               DEFAULT ((0)) NULL,
    [DISALLOW_PRICE_CHANGE_FLAG]   bit               DEFAULT ((0)) NULL,
    [DISALLOW_LAYAWAY_FLAG]        bit               DEFAULT ((0)) NULL,
    [DISALLOW_SPECIAL_ORDER_FLAG]  bit               DEFAULT ((0)) NULL,
    [DISALLOW_SELF_CHECKOUT_FLAG]  bit               DEFAULT ((0)) NULL,
    [DISALLOW_WORK_ORDER_FLAG]     bit               DEFAULT ((0)) NULL,
    [DISALLOW_REMOTE_SEND_FLAG]    bit               DEFAULT ((0)) NULL,
    [DISALLOW_COMMISSION_FLAG]     bit               DEFAULT 0 NULL,
    [WARRANTY_FLAG]                bit               DEFAULT ((0)) NULL,
    [GENERIC_ITEM_FLAG]            bit               DEFAULT ((0)) NULL,
    [INITIAL_SALE_QTY]             decimal(11, 4)    NULL,
    [DISPOSITION_CODE]             nvarchar(30)       NULL,
    [FOODSTAMP_ELIGIBLE_FLAG]      bit               DEFAULT ((0)) NULL,
    [STOCK_STATUS]                 nvarchar(60)       NULL,
    [PROMPT_FOR_CUSTOMER]          nvarchar(30)       NULL,
    [SHIPPING_WEIGHT]              decimal(12, 3)    NULL,
    [DISALLOW_ORDER_FLAG]          bit               DEFAULT 0 NULL,
    [DISALLOW_DEALS_FLAG]          bit               DEFAULT 0 NULL,
    [pack_size]                    decimal(11, 4)    NULL,
    [default_source_type]          nvarchar(60)       NULL,
    [default_source_id]            nvarchar(60)       NULL,
    [DISALLOW_RAIN_CHECK]		   bit		         DEFAULT 0 NULL,
    [SELLING_GROUP_ID]             nvarchar(60)       NULL,
    [FISCAL_ITEM_ID]		       nvarchar(254)		 NULL,
    [FISCAL_ITEM_DESCRIPTION]	   nvarchar(254)		 NULL,
    [exclude_from_net_sales_flag]  bit               DEFAULT 0 NULL,
    [CREATE_DATE]                  datetime          NULL,
    [CREATE_USER_ID]               nvarchar(256)      NULL,
    [UPDATE_DATE]                  datetime          NULL,
    [UPDATE_USER_ID]               nvarchar(256)      NULL,
    [RECORD_STATE]                 nvarchar(30)       NULL,
    CONSTRAINT [pk_dat_item_options_change] PRIMARY KEY CLUSTERED ([ORGANIZATION_ID], [target_node], [target_date], [sequence_number], [record_id]) WITH (FILLFACTOR = 80)
)
go
/* 
 * TABLE: [dbo].[dat_item_price_change] 
 */

CREATE TABLE [dbo].[dat_item_price_change](
    [organization_id]  int               NOT NULL,
    [target_node]      nvarchar(100)      NOT NULL,
    [target_date]      nvarchar(8)        NOT NULL,
    [sequence_number]  int               NOT NULL,
    [record_id]        nvarchar(254)      NOT NULL,
    [item_id]          nvarchar(60)       NOT NULL,
    [level_code]       nvarchar(30)       DEFAULT '*' NOT NULL,
    [level_value]      nvarchar(60)       DEFAULT '*' NOT NULL,
    [property_code]    nvarchar(60)       NOT NULL,
    [effective_date]   nvarchar(8)        NOT NULL,
    [expiration_date]  nvarchar(8)        NULL,
    [price]            decimal(17, 6)    NOT NULL,
    [price_qty]        decimal(11, 4)    DEFAULT 1 NOT NULL,
    [deployed_flag]    bit               DEFAULT 0 NULL,
    [create_date]      datetime          NULL,
    [create_user_id]   nvarchar(256)      NULL,
    [update_date]      datetime          NULL,
    [update_user_id]   nvarchar(256)      NULL,
    CONSTRAINT [pk_dat_item_price_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_item_upc_change] 
 */

CREATE TABLE [dbo].[dat_item_upc_change](
    [organization_id]   int             NOT NULL,
    [target_node]       nvarchar(100)    NOT NULL,
    [target_date]       nvarchar(8)      NOT NULL,
    [sequence_number]   int             NOT NULL,
    [record_id]         nvarchar(254)    NOT NULL,
    [manufacturer_upc]  nvarchar(60)     NOT NULL,
    [org_code]          nvarchar(30)     DEFAULT '*' NOT NULL,
    [org_value]         nvarchar(60)     DEFAULT '*' NOT NULL,
    [item_id]           nvarchar(60)     NULL,
    [manufacturer]      nvarchar(254)    NULL,
    [primary_flag]      bit             DEFAULT 0 NOT NULL,
    [deployed_flag]     bit             DEFAULT 0 NOT NULL,
    [create_date]       datetime        NULL,
    [create_user_id]    nvarchar(256)    NULL,
    [update_date]       datetime        NULL,
    [update_user_id]    nvarchar(256)    NULL,
    [record_state]      nvarchar(30)     NULL,
    CONSTRAINT [pk_dat_item_upc_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id], [manufacturer_upc])
    WITH FILLFACTOR = 80
)
go



/* 
 * INDEX: [xst_dat_item_upc_change_itemid] 
 */

CREATE INDEX xst_dat_item_upc_change_itemid ON [dbo].[dat_item_upc_change]([organization_id], [item_id])
WITH FILLFACTOR = 80
go
/* 
 * INDEX: [xst_dat_item_upc_change_upc] 
 */

CREATE INDEX xst_dat_item_upc_change_upc ON [dbo].[dat_item_upc_change]([manufacturer_upc], [item_id], [organization_id])
WITH FILLFACTOR = 80
go
/*
 * TABLE: [dbo].[dat_legal_entity_change]
 */

CREATE TABLE [dbo].[dat_legal_entity_change](
    [organization_id]           int               NOT NULL,
    [target_node]               nvarchar(100)      NOT NULL,
    [target_date]               nvarchar(8)        NOT NULL,
    [sequence_number]           int               NOT NULL,
    [record_id]                 nvarchar(254)      NOT NULL,
    [legal_entity_id]           nvarchar(30)       NOT NULL,
    [description]               nvarchar(254)      NULL,
    [legal_form]                nvarchar(60)       NULL,
    [social_capital]            nvarchar(60)       NULL,
    [companies_register_number] nvarchar(30)       NULL,
    [address1]                  nvarchar(254)      NULL,
    [address2]                  nvarchar(254)      NULL,
    [address3]                  nvarchar(254)      NULL,
    [address4]                  nvarchar(254)      NULL,
    [city]                      nvarchar(254)      NULL,
    [state]                     nvarchar(30)       NULL,
    [district]                  nvarchar(30)       NULL,
    [area]                      nvarchar(30)       NULL,
    [postal_code]               nvarchar(30)       NULL,
    [country]                   nvarchar(2)        NULL,
    [neighborhood]              nvarchar(254)      NULL,
    [county]                    nvarchar(254)      NULL,
    [apartment]                 nvarchar(30)       NULL,
    [email_addr]                nvarchar(254)      NULL,
    [tax_id]                    nvarchar(30)       NULL,
    [fiscal_code]               nvarchar(30)       NULL,
    [taxation_regime]           nvarchar(30)       NULL,
    [legal_employer_id]         nvarchar(30)       NULL,
    [activity_code]             nvarchar(30)       NULL,
    [tax_office_code]           nvarchar(30)       NULL,
    [statistical_code]          nvarchar(30)       NULL,
    [fax_number]                nvarchar(32)       NULL,
    [phone_number]              nvarchar(32)       NULL,
    [web_site]                  nvarchar(254)      NULL,
    [establishment_code]        nvarchar(30)       NULL,
    [registration_city]         nvarchar(254)      NULL,
    [activity_description]      nvarchar(254)      NULL,
    [company_business_name]     nvarchar(254)      NULL,
    [deployed_flag]             bit               DEFAULT 0 NULL,
    [create_date]               datetime          NULL,
    [create_user_id]            nvarchar(256)      NULL,
    [update_date]               datetime          NULL,
    [update_user_id]            nvarchar(256)      NULL
    CONSTRAINT [pk_dat_legal_entity_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id], [legal_entity_id]) WITH (FILLFACTOR = 80)
)
go



/* 
 * TABLE: [dbo].[dat_matrix_sort_order_change] 
 */

CREATE TABLE [dbo].[dat_matrix_sort_order_change](
    [organization_id]   int             NOT NULL,
    [target_node]       nvarchar(100)    NOT NULL,
    [target_date]       nvarchar(8)      NOT NULL,
    [sequence_number]   int             NOT NULL,
    [record_id]         nvarchar(254)    NOT NULL,
    [matrix_sort_type]  nvarchar(60)     NOT NULL,
    [matrix_sort_id]    nvarchar(60)     NOT NULL,
    [org_code]          nvarchar(30)     NOT NULL,
    [org_value]         nvarchar(60)     NOT NULL,
    [sort_order]        int             NULL,
    [deployed_flag]     bit             DEFAULT 0 NULL,
    [create_date]       datetime        NULL,
    [create_user_id]    nvarchar(256)    NULL,
    [update_date]       datetime        NULL,
    [update_user_id]    nvarchar(256)    NULL,
    CONSTRAINT [pk_dat_matrix_sort_order_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_merch_hierarchy_change] 
 */

CREATE TABLE [dbo].[dat_merch_hierarchy_change](
    [organization_id]               int             NOT NULL,
    [target_node]                   nvarchar(100)    NOT NULL,
    [target_date]                   nvarchar(8)      NOT NULL,
    [sequence_number]               int             NOT NULL,
    [record_id]                     nvarchar(254)    NOT NULL,
    [hierarchy_id]                  nvarchar(60)     NOT NULL,
    [org_code]                      nvarchar(30)     DEFAULT '*' NOT NULL,
    [org_value]                     nvarchar(60)     DEFAULT '*' NOT NULL,
    [parent_id]                     nvarchar(60)     NULL,
    [level_code]                    nvarchar(30)     NULL,
    [description]                   nvarchar(254)    NULL,
    [sort_order]                    int             NULL,
    [hidden_flag]                   bit             DEFAULT 0 NULL,
    [disallow_matrix_display_flag]  bit             DEFAULT 0 NULL,
    [item_matrix_color]             nvarchar(20)     NULL,
    [deployed_flag]                 bit             DEFAULT 0 NULL,
    [create_date]                   datetime        NULL,
    [create_user_id]                nvarchar(256)    NULL,
    [update_date]                   datetime        NULL,
    [update_user_id]                nvarchar(256)    NULL,
    CONSTRAINT [pk_dat_merch_hierarchy_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_non_phys_item_change] 
 */

CREATE TABLE [dbo].[dat_non_phys_item_change](
    [organization_id]              int             NOT NULL,
    [target_node]                  nvarchar(100)    NOT NULL,
    [target_date]                  nvarchar(8)      NOT NULL,
    [sequence_number]              int             NOT NULL,
    [record_id]                    nvarchar(254)    NOT NULL,
    [dtype]                        nvarchar(100)    NULL,
    [item_id]                      nvarchar(60)     NOT NULL,
    [org_code]                     nvarchar(30)     DEFAULT '*' NOT NULL,
    [org_value]                    nvarchar(60)     DEFAULT '*' NOT NULL,
    [display_order]                int             NULL,
    [non_phys_item_typcode]        nvarchar(30)     NULL,
    [non_phys_item_subtype]        nvarchar(30)     NULL,
    [exclude_from_net_sales_flag]  bit             DEFAULT 0 NULL,
    [create_date]                  datetime        NULL,
    [create_user_id]               nvarchar(256)    NULL,
    [update_date]                  datetime        NULL,
    [update_user_id]               nvarchar(256)    NULL,
    CONSTRAINT [pk_dat_non_phys_item_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_restriction_cal_change] 
 */

CREATE TABLE [dbo].[dat_restriction_cal_change](
    [organization_id]       int            NOT NULL,
    [target_node]           nvarchar(100)   NOT NULL,
    [target_date]           nvarchar(8)     NOT NULL,
    [sequence_number]       int            NOT NULL,
    [record_id]             nvarchar(254)   NOT NULL,
    [restriction_id]        nvarchar(30)    NOT NULL,
    [restriction_typecode]  nvarchar(60)    NOT NULL,
    [day_code]              nvarchar(3)     NOT NULL,
    [org_code]				      nvarchar(30)	   DEFAULT '*' NOT NULL,
    [org_value]				      nvarchar(60)	   DEFAULT '*' NOT NULL,
    [start_time]            nvarchar(4)     NULL,
    [end_time]              nvarchar(4)     NULL,
    [deployed_flag]         bit            DEFAULT 0 NULL,
    [create_date]           datetime       NULL,
    [create_user_id]        nvarchar(256)   NULL,
    [update_date]           datetime       NULL,
    [update_user_id]        nvarchar(256)   NULL,
    [record_state]          nvarchar(30)    NULL,
    CONSTRAINT [pk_dat_restriction_cal_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id]) WITH (FILLFACTOR = 80)
)

go



/* 
 * TABLE: [dbo].[dat_restriction_change] 
 */

CREATE TABLE [dbo].[dat_restriction_change](
    [organization_id]         int NOT NULL,
    [target_node]             nvarchar(100)  NOT NULL,
    [target_date]             nvarchar(8)    NOT NULL,
    [sequence_number]         int           NOT NULL,
    [record_id]               nvarchar(254)  NOT NULL,
    [restriction_id]          nvarchar(30)   NOT NULL,
    [restriction_description] nvarchar(254)  NULL,
    [deployed_flag]           bit           DEFAULT 0 NULL,
    [create_date]             datetime      NULL,
    [create_user_id]          nvarchar(256)  NULL,
    [update_date]             datetime      NULL,
    [update_user_id]          nvarchar(256)  NULL,
    [record_state]            nvarchar(30)   NULL,
    CONSTRAINT [pk_dat_restriction_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id]) WITH FILLFACTOR = 80
)

go



/* 
 * TABLE: [dbo].[dat_restriction_map_change] 
 */

CREATE TABLE [dbo].[dat_restriction_map_change](
    [organization_id]           int            NOT NULL,
    [target_node]               nvarchar(100)   NOT NULL,
    [target_date]               nvarchar(8)     NOT NULL,
    [sequence_number]           int            NOT NULL,
    [record_id]                 nvarchar(254)   NOT NULL,
    [restriction_id]            nvarchar(30)    NOT NULL,
    [merch_hierarchy_level]     nvarchar(60)    NOT NULL,
    [merch_hierarchy_id]        nvarchar(60)    NOT NULL,
    [deployed_flag]             bit            DEFAULT 0 NULL,
    [create_date]               datetime       NULL,
    [create_user_id]            nvarchar(256)   NULL,
    [update_date]               datetime       NULL,
    [update_user_id]            nvarchar(256)   NULL,
    [record_state]              nvarchar(30)    NULL,
    CONSTRAINT [pk_dat_restriction_map_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id]) WITH (FILLFACTOR = 80)
)

go



/* 
 * TABLE: [dbo].[dat_restriction_type_change] 
 */

CREATE TABLE [dbo].[dat_restriction_type_change](
    [organization_id]       int               NOT NULL,
    [target_node]           nvarchar(100)      NOT NULL,
    [target_date]           nvarchar(8)        NOT NULL,
    [sequence_number]       int               NOT NULL,
    [record_id]             nvarchar(254)      NOT NULL,
    [restriction_id]        nvarchar(30)       NOT NULL,
    [restriction_typecode]  nvarchar(60)       NOT NULL,
    [org_code]				      nvarchar(30)       DEFAULT('*') NOT NULL,
    [org_value]				      nvarchar(60)       DEFAULT('*') NOT NULL,
    [effective_date]        nvarchar(8)        NULL,
    [expiration_date]       nvarchar(8)        NULL,
    [value_type]            nvarchar(30)       NULL,
    [boolean_value]         bit               NULL,
    [date_value]            nvarchar(8)        NULL,
    [decimal_value]         decimal(17, 6)    NULL,
    [string_value]          nvarchar(254)      NULL,
    [exclude_returns_flag]  bit               DEFAULT 0 NULL,
    [deployed_flag]         bit               DEFAULT 0 NULL,
    [create_date]           datetime          NULL,
    [create_user_id]        nvarchar(256)      NULL,
    [update_date]           datetime          NULL,
    [update_user_id]        nvarchar(256)      NULL,
    [record_state]          nvarchar(30)       NULL,
    CONSTRAINT [pk_dat_restriction_type_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id]) WITH FILLFACTOR = 80
)

go



/* 
 * TABLE: [dat_retail_loc_wkstn_change] 
 */

CREATE TABLE [dat_retail_loc_wkstn_change](
    [organization_id]  int             NOT NULL,
    [target_node]      nvarchar(100)    NOT NULL,
    [target_date]      nvarchar(8)      NOT NULL,
    [sequence_number]  int             NOT NULL,
    [record_id]        nvarchar(254)    NOT NULL,
    [rtl_loc_id]       int             NOT NULL,
    [wkstn_id]         bigint          NOT NULL,
    [delete_flag]      bit             DEFAULT 0 NOT NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [PK_dat_retail_loc_wkstn] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id], [wkstn_id])
    WITH FILLFACTOR = 80
)
go



/*
 * TABLE: [dbo].[dat_retail_location_change]
 */

CREATE TABLE [dbo].[dat_retail_location_change](
    [organization_id]          int               NOT NULL,
    [target_node]              nvarchar(100)      NOT NULL,
    [target_date]              nvarchar(8)        NOT NULL,
    [sequence_number]          int               NOT NULL,
    [record_id]                nvarchar(254)      NOT NULL,
    [rtl_loc_id]               int               NOT NULL,
    [store_name]               nvarchar(254)      NULL,
    [address1]                 nvarchar(254)      NULL,
    [address2]                 nvarchar(254)      NULL,
    [address3]                 nvarchar(254)      NULL,
    [address4]                 nvarchar(254)      NULL,
    [city]                     nvarchar(254)      NULL,
    [state]                    nvarchar(30)       NULL,
    [district]                 nvarchar(30)       NULL,
    [area]                     nvarchar(30)       NULL,
    [postal_code]              nvarchar(30)       NULL,
    [country]                  nvarchar(254)      NULL,
    [locale]                   nvarchar(30)       NULL,
    [currency_id]              nvarchar(3)        NULL,
    [latitude]                 decimal(17, 6)    NULL,
    [longitude]                decimal(17, 6)    NULL,
    [telephone1]               nvarchar(32)       NULL,
    [telephone2]               nvarchar(32)       NULL,
    [telephone3]               nvarchar(32)       NULL,
    [telephone4]               nvarchar(32)       NULL,
    [description]              nvarchar(254)      NULL,
    [store_nbr]                nvarchar(254)      NULL,
    [apartment]                nvarchar(30)       NULL,
    [store_manager]            nvarchar(254)      NULL,
    [email_addr]               nvarchar(254)      NULL,
    [default_tax_percentage]   decimal(8, 6)     NULL,
    [location_type]            nvarchar(60)       NULL,
    [delivery_available_flag]  bit               DEFAULT 0 NOT NULL,
    [pickup_available_flag]    bit               DEFAULT 0 NOT NULL,
    [transfer_available_flag]  bit               DEFAULT 0 NOT NULL,
    [geo_code]                 nvarchar(20)       NULL,
    [uez_flag]                 bit               DEFAULT 0 NOT NULL,
    [alternate_store_nbr]      nvarchar(254)      NULL,
    [tax_loc_id]               nvarchar(60)       NULL,
    [deployed_flag]            bit               DEFAULT 0 NULL,
	[use_till_accountability_flag] bit           DEFAULT 0 NOT NULL,
	[deposit_bank_name]		   nvarchar(254)		 NULL,
	[deposit_bank_account_number] nvarchar(30)	 NULL,
	[airport_code]             nvarchar(3)        NULL,
    [legal_entity_id]          nvarchar(30)       NULL,
    [create_date]              datetime          NULL,
    [create_user_id]           nvarchar(256)      NULL,
    [update_date]              datetime          NULL,
    [update_user_id]           nvarchar(256)      NULL,
    CONSTRAINT [pk_dat_retail_location_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/*
 * TABLE: [dbo].[DAT_RETAIL_LOC_PROP_CHANGE]
 */

CREATE TABLE [dbo].[dat_retail_location_p_change](
    [organization_id]          int               NOT NULL,
    [target_node]              nvarchar(100)      NOT NULL,
    [target_date]              nvarchar(8)        NOT NULL,
    [sequence_number]          int               NOT NULL,
    [record_id]                nvarchar(254)      NOT NULL,
    [rtl_loc_id]               int               NOT NULL,
    [property_code]            nvarchar(30)       NOT NULL,
    [type]                     nvarchar(30)       NULL,
    [string_value]             nvarchar(max)      NULL,
    [date_value]               datetime          NULL,
    [decimal_value]            decimal(17, 6)    NULL,
    [create_date]              datetime          NULL,
    [create_user_id]           nvarchar(256)      NULL,
    [update_date]              datetime          NULL,
    [update_user_id]           nvarchar(256)      NULL,
    [record_state]             nvarchar(30)       NULL,
    CONSTRAINT [pk_dat_retail_loc_p_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id], [rtl_loc_id], [property_code])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_store_message_change] 
 */

CREATE TABLE [dbo].[dat_store_message_change](
    [organization_id]      int             NOT NULL,
    [target_node]          nvarchar(100)    NOT NULL,
    [target_date]          nvarchar(8)      NOT NULL,
    [sequence_number]      int             NOT NULL,
    [record_id]            nvarchar(254)    NOT NULL,
    [deployed_flag]        bit             DEFAULT 0 NULL,
    [message_id]           bigint          NULL,
    [org_code]             nvarchar(30)     DEFAULT '*' NULL,
    [org_value]            nvarchar(60)     DEFAULT '*' NULL,
    [start_date]           nvarchar(8)      NULL,
    [end_date]             nvarchar(8)      NULL,
    [priority]             nvarchar(20)     NULL,
    [content]              nvarchar(max)    NULL,
    [store_created_flag]   bit             DEFAULT 0 NULL,
    [wkstn_specific_flag]  bit             DEFAULT 0 NULL,
    [wkstn_id]             bigint          NULL,
    [void_flag]            bit             DEFAULT 0 NULL,
    [message_url]          nvarchar(254)    NULL,
    [create_date]          datetime        NULL,
    [create_user_id]       nvarchar(256)    NULL,
    [update_date]          datetime        NULL,
    [update_user_id]       nvarchar(256)    NULL,
    CONSTRAINT [pk_dat_store_message_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_tax_authority_change] 
 */

CREATE TABLE [dbo].[dat_tax_authority_change](
    [organization_id]           int             NOT NULL,
    [target_node]               nvarchar(100)    NOT NULL,
    [target_date]               nvarchar(8)      NOT NULL,
    [sequence_number]           int             NOT NULL,
    [record_id]                 nvarchar(254)    NOT NULL,
    [tax_authority_id]          nvarchar(60)     NOT NULL,
    [name]                      nvarchar(254)    NULL,
    [rounding_code]             nvarchar(30)     NULL,
    [rounding_digits_quantity]  int             NULL,
    [deployed_flag]             bit             DEFAULT 0 NULL,
    [org_code]                  nvarchar(30)     DEFAULT '*' NOT NULL,
    [org_value]                 nvarchar(60)     DEFAULT '*' NOT NULL,
    [create_date]               datetime        NULL,
    [create_user_id]            nvarchar(256)    NULL,
    [update_date]               datetime        NULL,
    [update_user_id]            nvarchar(256)    NULL,
    CONSTRAINT [pk_dat_tax_authority_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_tax_bracket_change] 
 */

CREATE TABLE [dbo].[dat_tax_bracket_change](
    [organization_id]  int             NOT NULL,
    [target_node]      nvarchar(100)    NOT NULL,
    [target_date]      nvarchar(8)      NOT NULL,
    [sequence_number]  int             NOT NULL,
    [record_id]        nvarchar(254)    NOT NULL,
    [tax_bracket_id]   nvarchar(60)     NOT NULL,
    [org_code]         nvarchar(30)     DEFAULT '*' NOT NULL,
    [org_value]        nvarchar(60)     DEFAULT '*' NOT NULL,
    [deployed_flag]    bit             DEFAULT 0 NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [pk_dat_tax_bracket_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_tax_bracket_dtl_change] 
 */

CREATE TABLE [dbo].[dat_tax_bracket_dtl_change](
    [organization_id]      int               NOT NULL,
    [target_node]          nvarchar(100)      NOT NULL,
    [target_date]          nvarchar(8)        NOT NULL,
    [sequence_number]      int               NOT NULL,
    [record_id]            nvarchar(254)      NOT NULL,
    [tax_bracket_id]       nvarchar(60)       NOT NULL,
    [org_code]             nvarchar(30)       DEFAULT '*' NOT NULL,
    [org_value]            nvarchar(60)       DEFAULT '*' NOT NULL,
    [tax_bracket_seq_nbr]  int               NOT NULL,
    [tax_breakpoint]       decimal(17, 6)    NULL,
    [tax_amount]           decimal(17, 6)    NULL,
    [deleted_flag]         bit               DEFAULT 0 NULL,
    [create_date]          datetime          NULL,
    [create_user_id]       nvarchar(256)      NULL,
    [update_date]          datetime          NULL,
    [update_user_id]       nvarchar(256)      NULL,
    CONSTRAINT [pk_dat_tax_bracket_dtl_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id], [tax_bracket_seq_nbr])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_tax_group_change] 
 */

CREATE TABLE [dbo].[dat_tax_group_change](
    [organization_id]  int             NOT NULL,
    [target_node]      nvarchar(100)    NOT NULL,
    [target_date]      nvarchar(8)      NOT NULL,
    [sequence_number]  int             NOT NULL,
    [record_id]        nvarchar(254)    NOT NULL,
    [tax_group_id]     nvarchar(60)     NOT NULL,
    [name]             nvarchar(254)    NULL,
    [description]      nvarchar(254)    NULL,
    [deployed_flag]    bit             DEFAULT 0 NULL,
    [org_code]         nvarchar(30)     DEFAULT '*' NOT NULL,
    [org_value]        nvarchar(60)     DEFAULT '*' NOT NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [pk_dat_tax_group_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_tax_group_rule_change] 
 */

CREATE TABLE [dbo].[dat_tax_group_rule_change](
    [organization_id]            int             NOT NULL,
    [target_node]                nvarchar(100)    NOT NULL,
    [target_date]                nvarchar(8)      NOT NULL,
    [sequence_number]            int             NOT NULL,
    [record_id]                  nvarchar(254)    NOT NULL,
    [tax_group_id]               nvarchar(60)     NOT NULL,
    [tax_loc_id]                 nvarchar(60)     NOT NULL,
    [tax_rule_seq_nbr]           int             NOT NULL,
    [tax_authority_id]           nvarchar(60)     NULL,
    [name]                       nvarchar(254)    NULL,
    [description]                nvarchar(254)    NULL,
    [compound_seq_nbr]           int             NULL,
    [compound_flag]              bit             DEFAULT 0 NULL,
    [taxed_at_trans_level_flag]  bit             DEFAULT 0 NULL,
    [tax_typcode]                nvarchar(30)     NULL,
    [deployed_flag]              bit             DEFAULT 0 NULL,
    [org_code]                   nvarchar(30)     DEFAULT '*' NOT NULL,
    [org_value]                  nvarchar(60)     DEFAULT '*' NOT NULL,
    [fiscal_tax_id]              nvarchar(60)     NULL,
    [create_date]                datetime        NULL,
    [create_user_id]             nvarchar(256)    NULL,
    [update_date]                datetime        NULL,
    [update_user_id]             nvarchar(256)    NULL,
    CONSTRAINT [pk_dat_tax_group_rule_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_tax_location_change] 
 */

CREATE TABLE [dbo].[dat_tax_location_change](
    [organization_id]  int             NOT NULL,
    [target_node]      nvarchar(100)    NOT NULL,
    [target_date]      nvarchar(8)      NOT NULL,
    [sequence_number]  int             NOT NULL,
    [record_id]        nvarchar(254)    NOT NULL,
    [tax_loc_id]       nvarchar(60)     NOT NULL,
    [name]             nvarchar(254)    NULL,
    [description]      nvarchar(254)    NULL,
    [deployed_flag]    bit             DEFAULT 0 NULL,
    [org_code]         nvarchar(30)     DEFAULT '*' NOT NULL,
    [org_value]        nvarchar(60)     DEFAULT '*' NOT NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [pk_dat_tax_location_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_tax_rate_override_change] 
 */

CREATE TABLE [dbo].[dat_tax_rate_override_change](
    [organization_id]           int               NOT NULL,
    [target_node]               nvarchar(100)      NOT NULL,
    [target_date]               nvarchar(8)        NOT NULL,
    [sequence_number]           int               NOT NULL,
    [record_id]                 nvarchar(254)      NOT NULL,
    [tax_group_id]              nvarchar(60)       NOT NULL,
    [tax_loc_id]                nvarchar(60)       NOT NULL,
    [tax_rule_seq_nbr]          int               NOT NULL,
    [tax_rate_rule_seq]         int               NOT NULL,
    [tax_bracket_id]            nvarchar(60)       NULL,
    [tax_rate_min_taxable_amt]  decimal(17, 6)    NULL,
    [effective_datetime]        nvarchar(8)        NULL,
    [expr_datetime]             nvarchar(8)        NULL,
    [percentage]                decimal(8, 6)     NULL,
    [amt]                       decimal(17, 6)    NULL,
    [daily_start_time]          nvarchar(8)        NULL,
    [daily_end_time]            nvarchar(8)        NULL,
    [tax_rate_max_taxable_amt]  decimal(17, 6)    NULL,
    [breakpoint_typcode]        nvarchar(30)       NULL,
    [deployed_flag]             bit               DEFAULT 0 NULL,
    [org_code]                  nvarchar(30)       DEFAULT '*' NOT NULL,
    [org_value]                 nvarchar(60)       DEFAULT '*' NOT NULL,
    [create_date]               datetime          NULL,
    [create_user_id]            nvarchar(256)      NULL,
    [update_date]               datetime          NULL,
    [update_user_id]            nvarchar(256)      NULL,
    CONSTRAINT [pk_dat_tax_rate_override_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_tax_rate_rule_change] 
 */

CREATE TABLE [dbo].[dat_tax_rate_rule_change](
    [organization_id]           int               NOT NULL,
    [target_node]               nvarchar(100)      NOT NULL,
    [target_date]               nvarchar(8)        NOT NULL,
    [sequence_number]           int               NOT NULL,
    [record_id]                 nvarchar(254)      NOT NULL,
    [tax_group_id]              nvarchar(60)       NOT NULL,
    [tax_loc_id]                nvarchar(60)       NOT NULL,
    [tax_rule_seq_nbr]          int               NOT NULL,
    [tax_rate_rule_seq]         int               NOT NULL,
    [tax_bracket_id]            nvarchar(60)       NULL,
    [tax_rate_min_taxable_amt]  decimal(17, 6)    NULL,
    [effective_datetime]        nvarchar(8)        NULL,
    [expr_datetime]             nvarchar(8)        NULL,
    [percentage]                decimal(8, 6)     NULL,
    [amt]                       decimal(17, 6)    NULL,
    [daily_start_time]          nvarchar(8)        NULL,
    [daily_end_time]            nvarchar(8)        NULL,
    [tax_rate_max_taxable_amt]  decimal(17, 6)    NULL,
    [breakpoint_typcode]        nvarchar(30)       NULL,
    [deployed_flag]             bit               DEFAULT 0 NULL,
    [org_code]                  nvarchar(30)       DEFAULT '*' NOT NULL,
    [org_value]                 nvarchar(60)       DEFAULT '*' NOT NULL,
    [create_date]               datetime          NULL,
    [create_user_id]            nvarchar(256)      NULL,
    [update_date]               datetime          NULL,
    [update_user_id]            nvarchar(256)      NULL,
    CONSTRAINT [pk_dat_tax_rate_rule_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dat_tender_rep_float_change] 
 */

CREATE TABLE [dat_tender_rep_float_change](
    [organization_id]      int               NOT NULL,
    [target_node]          nvarchar(100)      NOT NULL,
    [target_date]          nvarchar(8)        NOT NULL,
    [sequence_number]      int               NOT NULL,
    [record_id]            nvarchar(254)      NOT NULL,
    [rtl_loc_id]           int               NOT NULL,
    [tndr_repository_id]   nvarchar(60)       NOT NULL,
    [currency_id]          nvarchar(3)        NOT NULL,
    [default_cash_float]   decimal(17, 6)    NULL,
    [last_closing_amount]  decimal(17, 6)    NULL,
    [delete_flag]          bit               DEFAULT 0 NOT NULL,
    [create_date]          datetime          NULL,
    [create_user_id]       nvarchar(256)      NULL,
    [update_date]          datetime          NULL,
    [update_user_id]       nvarchar(256)      NULL,
    CONSTRAINT [PK_dat_tender_rep_float] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id], [tndr_repository_id], [currency_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dat_tender_repository_change] 
 */

CREATE TABLE [dat_tender_repository_change](
    [organization_id]     int             NOT NULL,
    [target_node]         nvarchar(100)    NOT NULL,
    [target_date]         nvarchar(8)      NOT NULL,
    [sequence_number]     int             NOT NULL,
    [record_id]           nvarchar(254)    NOT NULL,
    [rtl_loc_id]          int             NOT NULL,
    [tndr_repository_id]  nvarchar(60)     NOT NULL,
    [typcode]             nvarchar(30)     NULL,
    [not_issuable_flag]   bit             DEFAULT 0 NOT NULL,
    [name]                nvarchar(254)    NULL,
    [description]         nvarchar(254)    NULL,
    [dflt_wkstn_id]       bigint          NULL,
    [delete_flag]         bit             DEFAULT 0 NOT NULL,
    [create_date]         datetime        NULL,
    [create_user_id]      nvarchar(256)    NULL,
    [update_date]         datetime        NULL,
    [update_user_id]      nvarchar(256)    NULL,
    CONSTRAINT [PK_dat_tender_repository] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id], [tndr_repository_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dat_vendor_change] 
 */

CREATE TABLE [dbo].[dat_vendor_change](
    [organization_id]    int             NOT NULL,
    [target_node]        nvarchar(100)    NOT NULL,
    [target_date]        nvarchar(8)      NOT NULL,
    [sequence_number]    int             NOT NULL,
    [record_id]          nvarchar(254)    NOT NULL,
    [vendor_id]          nvarchar(60)     NOT NULL,
    [org_code]           nvarchar(30)     DEFAULT '*' NOT NULL,
    [org_value]          nvarchar(60)     DEFAULT '*' NOT NULL,
    [name]               nvarchar(254)    NULL,
    [buyer]              nvarchar(254)    NULL,
    [address_id]         nvarchar(60)     NULL,
    [telephone]          nvarchar(32)     NULL,
    [contact_telephone]  nvarchar(32)     NULL,
    [typcode]            nvarchar(30)     NULL,
    [contact]            nvarchar(254)    NULL,
    [fax]                nvarchar(32)     NULL,
    [status]             nvarchar(30)     NULL,
    [deployed_flag]      bit             DEFAULT 0 NULL,
    [create_date]        datetime        NULL,
    [create_user_id]     nvarchar(256)    NULL,
    [update_date]        datetime        NULL,
    [update_user_id]     nvarchar(256)    NULL,
    CONSTRAINT [pk_dat_vendor_change] PRIMARY KEY CLUSTERED ([organization_id], [target_node], [target_date], [sequence_number], [record_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dpl_deployment] 
 */

CREATE TABLE [dbo].[dpl_deployment](
    [organization_id]          int               NOT NULL,
    [deployment_id]            bigint            NOT NULL,
    [deployment_name]          nvarchar(75)       NULL,
    [plan_id]                  numeric(19, 0)    NULL,
    [xstore_version]           nvarchar(40)       NULL,
    [plan_name]                nvarchar(60)       NULL,
    [deployment_type]          nvarchar(30)       NULL,
    [org_scope]                nvarchar(100)      NULL,
    [staging_status]           nvarchar(30)       NULL,
    [staging_progress]         numeric(3, 0)     DEFAULT 0,
    [deploy_status]            nvarchar(30)       NULL,
    [purge_status]             nvarchar(30)       NULL,
    [download_time]            nvarchar(30)       NULL,
    [apply_immediately]        bit               NULL,
    [deployment_manifest_xml]  nvarchar(max)      NULL,
    [cancel_timestamp]         datetime          NULL,
    [cancel_user_id]           nvarchar(256)      NULL,
    [profile_group_id]         nvarchar(60)       NULL,
    [profile_element_id]       nvarchar(60)       NULL,
	[config_version]		   bigint			 NULL,
	[verification_version]     nvarchar(30)       NULL,
    [create_date]              datetime          NULL,
    [create_user_id]           nvarchar(256)      NULL,
    [update_date]              datetime          NULL,
    [update_user_id]           nvarchar(256)      NULL,
    CONSTRAINT [pk_dpl_deployment] PRIMARY KEY CLUSTERED ([organization_id], [deployment_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dpl_deployment_email] 
 */

CREATE TABLE [dbo].[dpl_deployment_email](
    [deployment_id]    bigint         NOT NULL,
    [organization_id]  int            NOT NULL,
    [user_name]        nvarchar(256)   NOT NULL,
    [create_date]      datetime       NULL,
    [create_user_id]   nvarchar(256)   NULL,
    [update_date]      datetime       NULL,
    [update_user_id]   nvarchar(256)   NULL,
    CONSTRAINT [pk_dpl_deployment_email] PRIMARY KEY CLUSTERED ([organization_id], [deployment_id], [user_name])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dpl_deployment_file] 
 */

CREATE TABLE [dbo].[dpl_deployment_file](
    [organization_id]  int             NOT NULL,
    [deployment_id]    bigint          NOT NULL,
    [file_seq]         int             NOT NULL,
    [file_type]        nvarchar(100)    NULL,
    [relative_path]    nvarchar(254)    NULL,
    [purge_status]     nvarchar(30)     NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [pk_dpl_deployment_file] PRIMARY KEY CLUSTERED ([organization_id], [deployment_id], [file_seq])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dpl_deployment_file_status] 
 */

CREATE TABLE [dbo].[dpl_deployment_file_status](
    [organization_id]       int             NOT NULL,
    [deployment_id]         bigint          NOT NULL,
    [deployment_wave_id]    int             NOT NULL,
    [store_number]          int             NOT NULL,
    [file_seq]              int             NOT NULL,
    [downloaded_status]     nvarchar(100)    NULL,
    [downloaded_details]    nvarchar(max)    NULL,
    [downloaded_timestamp]  datetime        NULL,
    [applied_status]        nvarchar(100)    NULL,
    [applied_details]       nvarchar(max)    NULL,
    [applied_timestamp]     datetime        NULL,
    [create_date]           datetime        NULL,
    [create_user_id]        nvarchar(256)    NULL,
    [update_date]           datetime        NULL,
    [update_user_id]        nvarchar(256)    NULL,
    CONSTRAINT [pk_dpl_deployment_file_status] PRIMARY KEY CLUSTERED ([organization_id], [deployment_id], [deployment_wave_id], [store_number], [file_seq])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dpl_deployment_plan] 
 */

CREATE TABLE [dbo].[dpl_deployment_plan](
    [plan_id]          numeric(19, 0)    NOT NULL,
    [plan_name]        nvarchar(60)       NOT NULL,
    [description]      nvarchar(255)      NULL,
    [organization_id]  int               NOT NULL,
    [org_scope]        nvarchar(100)      NULL,
    [create_date]      datetime          NULL,
    [create_user_id]   nvarchar(256)      NULL,
    [update_date]      datetime          NULL,
    [update_user_id]   nvarchar(256)      NULL,
    CONSTRAINT [pk_dpl_deployment_plan] PRIMARY KEY CLUSTERED ([organization_id], [plan_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dpl_deployment_plan_emails] 
 */

CREATE TABLE [dbo].[dpl_deployment_plan_emails](
    [plan_id]          numeric(19, 0)    NOT NULL,
    [organization_id]  int               NOT NULL,
    [user_name]        nvarchar(256)      NOT NULL,
    [create_date]      datetime          NULL,
    [create_user_id]   nvarchar(256)      NULL,
    [update_date]      datetime          NULL,
    [update_user_id]   nvarchar(256)      NULL,
    CONSTRAINT [pk_dpl_deployment_plan_emails] PRIMARY KEY CLUSTERED ([organization_id], [plan_id], [user_name])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dpl_deployment_plan_wave] 
 */

CREATE TABLE [dbo].[dpl_deployment_plan_wave](
    [wave_id]                 numeric(19, 0)    NOT NULL,
    [wave_name]               nvarchar(60)       NOT NULL,
    [plan_id]                 numeric(19, 0)    NOT NULL,
    [description]             nvarchar(255)      NULL,
    [timeline]                int               NULL,
    [approval_needed]         bit               DEFAULT 0 NULL,
    [is_all_remaining_store]  bit               DEFAULT 0 NULL,
    [organization_id]         int               NOT NULL,
    [create_date]             datetime          NULL,
    [create_user_id]          nvarchar(256)      NULL,
    [update_date]             datetime          NULL,
    [update_user_id]          nvarchar(256)      NULL,
    CONSTRAINT [pk_dpl_deployment_plan_wave] PRIMARY KEY CLUSTERED ([organization_id], [wave_id], [plan_id])
    WITH FILLFACTOR = 80,
    CONSTRAINT [uc_dpl_deployment_plan_wave]  UNIQUE ([wave_name], [plan_id], [organization_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dpl_deployment_plan_wavetarget] 
 */

CREATE TABLE [dbo].[dpl_deployment_plan_wavetarget](
    [wave_id]          numeric(19, 0)    NOT NULL,
    [plan_id]          numeric(19, 0)    NOT NULL,
    [org_scope]        nvarchar(100)      NOT NULL,
    [organization_id]  int               NOT NULL,
    [create_date]      datetime          NULL,
    [create_user_id]   nvarchar(256)      NULL,
    [update_date]      datetime          NULL,
    [update_user_id]   nvarchar(256)      NULL,
    CONSTRAINT [pk_dpldeploymentplanwavetarget] PRIMARY KEY CLUSTERED ([organization_id], [wave_id], [plan_id], [org_scope])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dpl_deployment_target] 
 */

CREATE TABLE [dbo].[dpl_deployment_target](
    [organization_id]                int             NOT NULL,
    [deployment_id]                  bigint          NOT NULL,
    [deployment_wave_id]             int             NOT NULL,
    [store_number]                   int             NOT NULL,
    [manifest_downloaded_timestamp]  datetime        NULL,
    [files_downloaded_status]        nvarchar(100)    NULL,
    [files_applied_status]           nvarchar(100)    NULL,
    [create_date]                    datetime        NULL,
    [create_user_id]                 nvarchar(256)    NULL,
    [update_date]                    datetime        NULL,
    [update_user_id]                 nvarchar(256)    NULL,
    CONSTRAINT [pk_dpl_deployment_target] PRIMARY KEY CLUSTERED ([organization_id], [deployment_id], [deployment_wave_id], [store_number])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dpl_deployment_wave] 
 */

CREATE TABLE [dbo].[dpl_deployment_wave](
    [organization_id]         int             NOT NULL,
    [deployment_id]           bigint          NOT NULL,
    [deployment_wave_id]      int             NOT NULL,
    [wave_name]               nvarchar(60)     NOT NULL,
    [approval_needed]         bit             DEFAULT 0 NULL,
    [approved]                bit             DEFAULT 1 NULL,
    [is_approval_email_sent]  bit             DEFAULT 0 NULL,
    [is_onhold_email_sent]    bit             DEFAULT 0 NULL,
    [wave_status]             nvarchar(100)    NULL,
    [target_date]             nvarchar(8)      NULL,
    [create_date]             datetime        NULL,
    [create_user_id]          nvarchar(256)    NULL,
    [update_date]             datetime        NULL,
    [update_user_id]          nvarchar(256)    NULL,
    CONSTRAINT [pk_dpl_deployment_wave] PRIMARY KEY CLUSTERED ([organization_id], [deployment_id], [deployment_wave_id])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[dpl_deployment_wave_approvals] 
 */

CREATE TABLE [dbo].[dpl_deployment_wave_approvals](
    [log_id]              numeric(19, 0)    IDENTITY(0,1),
    [organization_id]     int               NOT NULL,
    [deployment_id]       bigint            NOT NULL,
    [deployment_wave_id]  int               NOT NULL,
    [comments]            nvarchar(255)      NULL,
    [action]              nvarchar(100)      NULL,
    [create_date]         datetime          NULL,
    [create_user_id]      nvarchar(256)      NULL,
    [update_date]         datetime          NULL,
    [update_user_id]      nvarchar(256)      NULL,
    CONSTRAINT [pk_dpl_deployment_wave_approvals] PRIMARY KEY CLUSTERED ([log_id])
    WITH FILLFACTOR = 80
)
go



/*
 * TABLE: dtx_def
 */

CREATE TABLE dbo.dtx_def (
    dtx_name           nvarchar(256) NOT NULL,
    table_name         nvarchar(128)     NULL, 
    package_name       nvarchar(256)     NULL, 
    extends_dtx_name   nvarchar(256)     NULL,
    create_date        datetime         NULL,
    create_user_id     nvarchar(256)     NULL,
    update_date        datetime         NULL,
    update_user_id     nvarchar(256)     NULL,
    CONSTRAINT pk_dtx_def PRIMARY KEY CLUSTERED ([dtx_name])
      WITH FILLFACTOR = 80
)
go
/*
 * TABLE: dtx_field
 */

CREATE TABLE dbo.dtx_field (
    dtx_name        nvarchar(256) NOT NULL,
    field_name      nvarchar(256) NOT NULL,
    column_name     nvarchar(30)      NULL,
    data_type       nvarchar(256)     NULL,
    data_length     int              NULL,
    data_scale      int              NULL,
    primary_key     bit              NULL,
    sort_order      int              NULL,
    create_date     datetime         NULL,
    create_user_id  nvarchar(256)     NULL,
    update_date     datetime         NULL,
    update_user_id  nvarchar(256)     NULL,
    CONSTRAINT pk_dtx_field PRIMARY KEY CLUSTERED ([dtx_name], [field_name]) 
      WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: dtx_relationship
 */

CREATE TABLE dbo.dtx_relationship (
    dtx_name            nvarchar(256) NOT NULL,
    relationship_name   nvarchar(256) NOT NULL,
    other_dtx_name      nvarchar(256)     NULL,
    relationship_type   nvarchar(30)      NULL,
    element_name        nvarchar(256)     NULL,
    exported            bit              NULL,
    dependent           bit              NULL,
    transient           bit              NULL,
    create_date         datetime         NULL,
    create_user_id      nvarchar(256)     NULL,
    update_date         datetime         NULL,
    update_user_id      nvarchar(256)     NULL,
    CONSTRAINT pk_dtx_relationship PRIMARY KEY CLUSTERED ([dtx_name], [relationship_name])
      WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: dtx_relationship_field
 */

CREATE TABLE dbo.dtx_relationship_field (
    dtx_name          nvarchar(256) NOT NULL,
    relationship_name nvarchar(256) NOT NULL,
    field_name        nvarchar(256) NOT NULL,
    other_dtx_name    nvarchar(256)     NULL,
    other_field_name  nvarchar(256)     NULL,
    create_date       datetime         NULL,
    create_user_id    nvarchar(256)     NULL,
    update_date       datetime         NULL,
    update_user_id    nvarchar(256)     NULL,
    CONSTRAINT pk_dtx_relationship_field PRIMARY KEY CLUSTERED ([dtx_name], [relationship_name], [field_name])
      WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: [dbo].[loc_rtl_loc_collection] 
 */

CREATE TABLE [dbo].[loc_rtl_loc_collection](
    [collection_name]  nvarchar(60)     NOT NULL,
    [organization_id]  int             DEFAULT ((1)) NOT NULL,
    [description]      nvarchar(256)    NULL,
    [create_date]      datetime        NULL,
    [create_user_id]   nvarchar(256)    NULL,
    [update_date]      datetime        NULL,
    [update_user_id]   nvarchar(256)    NULL,
    CONSTRAINT [pk_loc_rtl_loc_collection] PRIMARY KEY CLUSTERED ([organization_id], [collection_name])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[loc_rtl_loc_collection_element] 
 */

CREATE TABLE [dbo].[loc_rtl_loc_collection_element](
    [collection_name]  nvarchar(60)    NOT NULL,
    [org_scope_code]   nvarchar(60)    NOT NULL,
    [organization_id]  int            DEFAULT ((1)) NOT NULL,
    [create_date]      datetime       NULL,
    [create_user_id]   nvarchar(256)   NULL,
    [update_date]      datetime       NULL,
    [update_user_id]   nvarchar(256)   NULL,
    CONSTRAINT [pk_loc_rtl_loc_collection_element] PRIMARY KEY CLUSTERED ([organization_id], [collection_name], [org_scope_code])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[ocds_job_history] 
 */
CREATE TABLE [dbo].[ocds_job_history](
    [organization_id]      int               NOT NULL,
    [job_type]             nvarchar(10)       NOT NULL,
    [job_id]               int               NOT NULL,
    [job_start_time]       datetime          NULL,
    [job_end_time]         datetime          NULL,
    [request_param_since]  datetime          NULL,
    [request_param_before] datetime          NULL,
    [status]               nvarchar(30)       NULL,
    [create_date]          datetime          NULL,
    [create_user_id]       nvarchar(256)      NULL,
    [update_date]          datetime          NULL,
    [update_user_id]       nvarchar(256)      NULL,
    CONSTRAINT [pk_ocds_job_history] PRIMARY KEY CLUSTERED ([organization_id], [job_type], [job_id])
    WITH FILLFACTOR = 80
)
go

/* 
 * TABLE: [dbo].[ocds_on_demand] 
 */
CREATE TABLE [dbo].[ocds_on_demand](
    [organization_id]      int               NOT NULL,
    [job_id]               int               NOT NULL,
    [subtasks]             nvarchar(256)      NOT NULL,
    [destination]          nvarchar(30)       NOT NULL,
    [org_scope]            nvarchar(2000)     NULL,
    [download_time]        nvarchar(30)       NULL,
    [apply_immediately]    bit               NOT NULL DEFAULT ((0)),
    [create_date]          datetime          NULL,
    [create_user_id]       nvarchar(256)      NULL,
    [update_date]          datetime          NULL,
    [update_user_id]       nvarchar(256)      NULL,
    CONSTRAINT [pk_ocds_on_demand] PRIMARY KEY CLUSTERED ([organization_id], [job_id])
    WITH FILLFACTOR = 80
)
go

/* 
 * TABLE: [dbo].[ocds_subtask_details] 
 */
CREATE TABLE [dbo].[ocds_subtask_details](
    [organization_id]    int            NOT NULL,
    [subtask_id]         nvarchar(30)    NOT NULL,
    [filename_prefix]    nvarchar(30)    NULL,
    [query_by_chain]     bit            NOT NULL DEFAULT ((0)),
    [query_by_org_node]  bit            NOT NULL DEFAULT ((0)),
    [destination]        nvarchar(30)    NOT NULL,
    [download_time]      nvarchar(30)    NULL,
    [apply_immediately]  bit            NOT NULL DEFAULT ((0)),
    [family]             nvarchar(30)    NOT NULL, 
    [path]               nvarchar(120)   NULL,    
    [create_date]        datetime       NULL,
    [create_user_id]     nvarchar(256)   NULL,
    [update_date]        datetime       NULL,
    [update_user_id]     nvarchar(256)   NULL,
    CONSTRAINT [pk_ocds_subtask_details] PRIMARY KEY CLUSTERED ([organization_id], [subtask_id])
    WITH FILLFACTOR = 80
)
go

/* 
 * TABLE: [dbo].[qrtz_blob_triggers] 
 */

CREATE TABLE [dbo].[qrtz_blob_triggers](
    [sched_name]                  nvarchar(120)        NOT NULL,
    [trigger_name]                nvarchar(160)        NOT NULL,
    [trigger_group]               nvarchar(160)        NOT NULL,
    [blob_data]                   varbinary(max)      NULL,
    CONSTRAINT [pk_qrtz_blob_triggers] PRIMARY KEY CLUSTERED ([sched_name], [trigger_name], [trigger_group])
    WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: [dbo].[qrtz_calendars] 
 */

CREATE TABLE [dbo].[qrtz_calendars](
    [sched_name]                  nvarchar(120)             NOT NULL,
    [calendar_name]               nvarchar(200)             NOT NULL,
    [calendar]                    varbinary(max)           NULL,
    CONSTRAINT [pk_qrtz_calendars] PRIMARY KEY CLUSTERED ([sched_name], [calendar_name])
    WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: [dbo].[qrtz_cron_triggers] 
 */

CREATE TABLE [dbo].[qrtz_cron_triggers](
    [sched_name]                  nvarchar(120)             NOT NULL,
    [trigger_name]                nvarchar(160)             NOT NULL,
    [trigger_group]               nvarchar(160)             NOT NULL,
    [cron_expression]             nvarchar(120)             NOT NULL,
    [time_zone_id]                nvarchar(80),
    CONSTRAINT [pk_qrtz_cron_triggers] PRIMARY KEY CLUSTERED ([sched_name], [trigger_name], [trigger_group])
    WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: [dbo].[qrtz_fired_triggers] 
 */

CREATE TABLE [dbo].[qrtz_fired_triggers](
    [sched_name]                  nvarchar(120)        NOT NULL,
    [entry_id]                    nvarchar(95)         NOT NULL,
    [trigger_name]                nvarchar(200)        NOT NULL,
    [trigger_group]               nvarchar(200)        NOT NULL,
    [instance_name]               nvarchar(200)        NOT NULL,
    [fired_time]                  bigint              NOT NULL,
    [sched_time]                  bigint              NOT NULL,
    [priority]                    integer             NOT NULL,
    [state]                       nvarchar(16)         NOT NULL,
    [job_name]                    nvarchar(200)        NULL,
    [job_group]                   nvarchar(200)        NULL,
    [is_nonconcurrent]            nvarchar(1)          NULL,
    [requests_recovery]           nvarchar(1)          NULL,
    CONSTRAINT [pk_qrtz_fired_triggers] PRIMARY KEY CLUSTERED ([sched_name], [entry_id])
    WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: [dbo].[qrtz_job_details] 
 */

CREATE TABLE [dbo].[qrtz_job_details](
    [sched_name]                  nvarchar(120)        NOT NULL,
    [job_name]                    nvarchar(200)        NOT NULL,
    [job_group]                   nvarchar(200)        NOT NULL,
    [description]                 nvarchar(250)        NULL,
    [job_class_name]              nvarchar(250)        NOT NULL,
    [is_durable]                  nvarchar(1)          NOT NULL,
    [is_nonconcurrent]            nvarchar(1)          NOT NULL,
    [is_update_data]              nvarchar(1)          NOT NULL,
    [requests_recovery]           nvarchar(1)          NOT NULL,
    [job_data]                    varbinary(max)      NULL,
    CONSTRAINT [pk_qrtz_job_details] PRIMARY KEY CLUSTERED ([sched_name], [job_name], [job_group])
    WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: [dbo].[qrtz_locks] 
 */

CREATE TABLE [dbo].[qrtz_locks](
    [sched_name]                      nvarchar(120)   NOT NULL,
    [lock_name]                       nvarchar(40)    NOT NULL,
    CONSTRAINT [pk_qrtz_locks] PRIMARY KEY CLUSTERED ([sched_name], [lock_name])
    WITH FILLFACTOR = 80
)
go



/* 
 * TABLE: [dbo].[qrtz_paused_trigger_grps] 
 */

CREATE TABLE [dbo].[qrtz_paused_trigger_grps](
    [sched_name]                  nvarchar(120)        NOT NULL,
    [trigger_group]               nvarchar(160)        NOT NULL,
    CONSTRAINT [pk_qrtz_paused_trigger_grps] PRIMARY KEY CLUSTERED ([sched_name], [trigger_group])
    WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: [dbo].[qrtz_scheduler_state] 
 */

CREATE TABLE [dbo].[qrtz_scheduler_state](
    [sched_name]                  nvarchar(120)        NOT NULL,
    [instance_name]               nvarchar(200)        NOT NULL,
    [last_checkin_time]           bigint              NOT NULL,
    [checkin_interval]            bigint              NOT NULL,
    CONSTRAINT [pk_qrtz_scheduler_state] PRIMARY KEY CLUSTERED ([sched_name], [instance_name])
    WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: [dbo].[qrtz_simple_triggers] 
 */

CREATE TABLE [dbo].[qrtz_simple_triggers](
    [sched_name]                  nvarchar(120)        NOT NULL,
    [trigger_name]                nvarchar(160)        NOT NULL,
    [trigger_group]               nvarchar(160)        NOT NULL,
    [repeat_count]                bigint              NOT NULL,
    [repeat_interval]             bigint              NOT NULL,
    [times_triggered]             bigint              NOT NULL,
    CONSTRAINT [pk_qrtz_simple_triggers] PRIMARY KEY CLUSTERED ([sched_name], [trigger_name], [trigger_group])
    WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: [dbo].[qrtz_simprop_triggers] 
 */

CREATE TABLE [dbo].[qrtz_simprop_triggers](
    [sched_name]                  nvarchar(120)        NOT NULL,
    [trigger_name]                nvarchar(160)        NOT NULL,
    [trigger_group]               nvarchar(160)        NOT NULL,
    [str_prop_1]                  nvarchar(512)        NULL,
    [str_prop_2]                  nvarchar(512)        NULL,
    [str_prop_3]                  nvarchar(512)        NULL,
    [int_prop_1]                  int                 NULL,
    [int_prop_2]                  int                 NULL,
    [long_prop_1]                 bigint              NULL,
    [long_prop_2]                 bigint              NULL,
    [dec_prop_1]                  numeric(13,4)       NULL,
    [dec_prop_2]                  numeric(13,4)       NULL,
    [bool_prop_1]                 nvarchar(1)          NULL,
    [bool_prop_2]                 nvarchar(1)          NULL,
    CONSTRAINT [pk_qrtz_simprop_triggers] PRIMARY KEY CLUSTERED ([sched_name], [trigger_name], [trigger_group])
    WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: [dbo].[qrtz_triggers] 
 */

CREATE TABLE [dbo].[qrtz_triggers](
    [sched_name]                  nvarchar(120)        NOT NULL,
    [trigger_name]                nvarchar(160)        NOT NULL,
    [trigger_group]               nvarchar(160)        NOT NULL,
    [job_name]                    nvarchar(200)        NOT NULL,
    [job_group]                   nvarchar(200)        NOT NULL,
    [description]                 nvarchar(250)        NULL,
    [next_fire_time]              bigint              NULL,
    [prev_fire_time]              bigint              NULL,
    [priority]                    integer             NULL,
    [trigger_state]               nvarchar(16)         NOT NULL,
    [trigger_type]                nvarchar(8)          NOT NULL,
    [start_time]                  bigint              NOT NULL,
    [end_time]                    bigint              NULL,
    [calendar_name]               nvarchar(200)        NULL,
    [misfire_instr]               smallint            NULL,
    [job_data]                    varbinary(max)      NULL,
    CONSTRAINT [pk_qrtz_triggers] PRIMARY KEY CLUSTERED ([sched_name], [trigger_name], [trigger_group])
    WITH FILLFACTOR = 80
)
go
/* 
 * TABLE: [dbo].[rpt_stock_rollup] 
 */

CREATE TABLE [dbo].[rpt_stock_rollup](
    [organization_id] int               NOT NULL,
    [id]              numeric(19, 0)    NOT NULL,
    [user_id]         nvarchar(50)       NULL,
    [fiscal_year]     numeric(19, 0)    NULL,
    [start_date]      nvarchar(8)        NULL,
    [end_date]        nvarchar(8)        NULL,
    [status]          nvarchar(30)       NULL,
    [create_date]     datetime          NULL,
    [create_user_id]  nvarchar(256)      NULL,
    [update_date]     datetime          NULL,
    [update_user_id]  nvarchar(256)      NULL,
    CONSTRAINT [pk_rpt_stock_rollup] PRIMARY KEY CLUSTERED ([organization_id], [id])
    WITH FILLFACTOR = 80
)
go



/* 
 * VIEW: [Test_Connection] 
 */

CREATE VIEW Test_Connection(result)
AS
SELECT 1
go

