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
-- DB platform:     Microsoft SQL Server 2012/2014/2016
-- ***************************************************************************

-- ***************************************************************************
-- ***************************************************************************
-- 21.0.x -> 22.0.0
-- ***************************************************************************
-- ***************************************************************************
-- ***************************************************************************
PRINT '**************************************';
PRINT '* UPGRADE to release 22.0';
PRINT '**************************************';

IF  OBJECT_ID('dbo.SP_DEFAULT_CONSTRAINT_EXISTS') is not null
  DROP FUNCTION dbo.SP_DEFAULT_CONSTRAINT_EXISTS
GO

CREATE FUNCTION dbo.SP_DEFAULT_CONSTRAINT_EXISTS (@tableName nvarchar(max), @columnName varchar(max))
RETURNS nvarchar(255)
AS 
BEGIN
    DECLARE @return nvarchar(255)
    
    SELECT TOP 1 
            @return = default_constraints.name
        FROM 
            sys.all_columns
                INNER JOIN
            sys.tables
                ON all_columns.object_id = tables.object_id
                INNER JOIN 
            sys.schemas
                ON tables.schema_id = schemas.schema_id
                INNER JOIN
            sys.default_constraints
                ON all_columns.default_object_id = default_constraints.object_id
        WHERE 
                schemas.name = 'dbo'
            AND tables.name = @tableName
            AND all_columns.name = @columnName
            
    RETURN @return
END;
GO


-- [RXPS-61392] START

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'company_business_name' AND object_id = OBJECT_ID('dat_legal_entity_change'))
BEGIN
  ALTER TABLE dat_legal_entity_change ADD company_business_name nvarchar(254) NULL;
  PRINT 'dat_legal_entity_change.company_business_name added';
END
GO

-- [RXPS-61392] END

-- 21.0.x -> 22.0.x

-- [RXPS-42020] START

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'organization_id' AND object_id = OBJECT_ID('rpt_stock_rollup'))
 BEGIN
  EXEC('ALTER TABLE rpt_stock_rollup ADD organization_id int');
  EXEC('ALTER TABLE rpt_stock_rollup DROP CONSTRAINT pk_rpt_stock_rollup');
  EXEC('INSERT INTO rpt_stock_rollup (organization_id, id, user_id , fiscal_year , start_date ,end_date , status , create_date, create_user_id, update_date, update_user_id) 
(select distinct ccv.code, rsr.id, rsr.user_id , rsr.fiscal_year , rsr.start_date ,rsr.end_date , rsr.status , rsr.create_date, rsr.create_user_id, rsr.update_date, rsr.update_user_id  FROM cfg_code_value ccv     
 cross join  rpt_stock_rollup rsr where ccv.category=''OrganizationId'')');
  EXEC('Delete from rpt_stock_rollup where organization_id IS null');
  EXEC('ALTER TABLE rpt_stock_rollup ALTER COLUMN organization_id int NOT NULL');
  EXEC('ALTER TABLE rpt_stock_rollup ADD CONSTRAINT pk_rpt_stock_rollup
    PRIMARY KEY CLUSTERED (organization_id, id) WITH (FILLFACTOR = 80)');
  PRINT 'rpt_stock_rollup.organization_id added';
END
GO

-- [RXPS-42020] END

-- [RXPS-62145] START 
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'sick_days_used' AND object_id = OBJECT_ID('dat_emp_change'))
BEGIN
  ALTER TABLE dat_emp_change ADD sick_days_used decimal(11, 2) NULL;
  PRINT 'dat_emp_change.sick_days_used added';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'marital_status' AND object_id = OBJECT_ID('dat_emp_change'))
BEGIN
  ALTER TABLE dat_emp_change ADD marital_status nvarchar(30) NULL;
  PRINT 'dat_emp_change.marital_status added';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'spouse_name' AND object_id = OBJECT_ID('dat_emp_change'))
BEGIN
  ALTER TABLE dat_emp_change ADD spouse_name nvarchar(254) NULL;
  PRINT 'dat_emp_change.spouse_name added';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'vacation_days' AND object_id = OBJECT_ID('dat_emp_change'))
BEGIN
  ALTER TABLE dat_emp_change ADD vacation_days decimal(11, 2) NULL;
  PRINT 'dat_emp_change.vacation_days added';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'vacation_days_used' AND object_id = OBJECT_ID('dat_emp_change'))
BEGIN
  ALTER TABLE dat_emp_change ADD vacation_days_used decimal(11, 2) NULL;
  PRINT 'dat_emp_change.vacation_days_used added';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'sick_days' AND object_id = OBJECT_ID('dat_emp_change'))
BEGIN
  ALTER TABLE dat_emp_change ADD sick_days decimal(11, 2) NULL;
  PRINT 'dat_emp_change.sick_days added';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'personal_days' AND object_id = OBJECT_ID('dat_emp_change'))
BEGIN
  ALTER TABLE dat_emp_change ADD personal_days decimal(11, 2) NULL;
  PRINT 'dat_emp_change.personal_days added';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'personal_days_used' AND object_id = OBJECT_ID('dat_emp_change'))
BEGIN
  ALTER TABLE dat_emp_change ADD personal_days_used decimal(11, 2) NULL;
  PRINT 'dat_emp_change.personal_days_used added';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'employee_role_code' AND object_id = OBJECT_ID('dat_emp_change'))
BEGIN
  ALTER TABLE dat_emp_change ADD employee_role_code nvarchar(30) NULL;
  PRINT 'dat_emp_change.employee_role_code added';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'employee_group_id' AND object_id = OBJECT_ID('dat_emp_change'))
BEGIN
  ALTER TABLE dat_emp_change ADD employee_group_id nvarchar(60) NULL;
  PRINT 'dat_emp_change.employee_group_id added';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'social_security_nbr' AND object_id = OBJECT_ID('dat_emp_change'))
BEGIN
  ALTER TABLE dat_emp_change ADD social_security_nbr nvarchar(255) NULL;
  PRINT 'dat_emp_change.social_security_nbr added';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'national_tax_id' AND object_id = OBJECT_ID('dat_emp_change'))
BEGIN
  ALTER TABLE dat_emp_change ADD national_tax_id nvarchar(30) NULL;
  PRINT 'dat_emp_change.national_tax_id added';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE name = 'personal_tax_id' AND object_id = OBJECT_ID('dat_emp_change'))
BEGIN
  ALTER TABLE dat_emp_change ADD personal_tax_id nvarchar(30) NULL;
  PRINT 'dat_emp_change.personal_tax_id added';
END
GO

-- [RXPS-62145] END 

-- [RXPS-62673] START

/* 
 * TABLE: [dbo].[cfg_paybylink] 
 */
IF OBJECT_ID('cfg_paybylink') IS NULL
BEGIN
PRINT 'Create the cfg_paybylink table.'
exec('CREATE TABLE [dbo].[cfg_paybylink](
    [organization_id]                 int            NOT NULL,
    [hmac_key]                        nvarchar(256)   NOT NULL,
    [expiration_date]                 datetime       NULL,
    [create_date]                     datetime       NULL,
    [create_user_id]                  nvarchar(256)   NULL,
    [update_date]                     datetime       NULL,
    [update_user_id]                  nvarchar(256)   NULL,
    CONSTRAINT [pk_cfg_paybylink] PRIMARY KEY CLUSTERED ([organization_id], [hmac_key])
    WITH FILLFACTOR = 80
)');
END

-- [RXPS-62673] END


-- [RXPS-63335] START
  BEGIN

    -- Check if the column to be change is not datetime
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'DPL_DEPLOYMENT' AND COLUMN_NAME = 'CANCEL_TIMESTAMP' AND DATA_TYPE != 'datetime')
      BEGIN
        -- Check if temp column doesn't exist
        IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'DPL_DEPLOYMENT' AND COLUMN_NAME = 'TEMP_CANCEL_TIMESTAMP')
        BEGIN
          EXEC('ALTER TABLE DPL_DEPLOYMENT ADD TEMP_CANCEL_TIMESTAMP datetime')
          -- Create temp column
        END

          -- Set the current value to temp column
        EXEC('UPDATE DPL_DEPLOYMENT SET TEMP_CANCEL_TIMESTAMP
               = (SELECT Convert(datetime, CANCEL_TIMESTAMP))
                 WHERE CANCEL_TIMESTAMP IS NOT NULL AND TEMP_CANCEL_TIMESTAMP IS NULL')

        -- The original value is now on temp column, we can remove the value fro original column
        EXEC('UPDATE DPL_DEPLOYMENT SET CANCEL_TIMESTAMP = NULL WHERE CANCEL_TIMESTAMP IS NOT NULL')

        -- Change original column to datetime
        EXEC('ALTER TABLE DPL_DEPLOYMENT ALTER COLUMN CANCEL_TIMESTAMP datetime')
      END;

    -- Check if the temp column still exist
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'DPL_DEPLOYMENT' AND COLUMN_NAME = 'TEMP_CANCEL_TIMESTAMP')
      BEGIN
        -- Move the original information to the original column
        EXEC('UPDATE DPL_DEPLOYMENT SET CANCEL_TIMESTAMP = TEMP_CANCEL_TIMESTAMP WHERE CANCEL_TIMESTAMP IS NULL')
        -- Remove the temp column
        EXEC('ALTER TABLE DPL_DEPLOYMENT DROP COLUMN TEMP_CANCEL_TIMESTAMP')
      END;

  END;
GO
-- [RXPS-63335] END

-- [RXPS-63846] START

    -- Check if the column length is still 25
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CFG_INTEGRATION' AND COLUMN_NAME = 'INTEGRATION_SYSTEM' AND CHARACTER_MAXIMUM_LENGTH = 25)
    BEGIN
      -- alter the length to 50
      ALTER TABLE CFG_INTEGRATION DROP CONSTRAINT pk_cfg_integration;
      ALTER TABLE CFG_INTEGRATION ALTER COLUMN INTEGRATION_SYSTEM nvarchar(50) NOT NULL;
      ALTER TABLE CFG_INTEGRATION ADD CONSTRAINT pk_cfg_integration
      PRIMARY KEY CLUSTERED (organization_id, integration_system, integration_type, implementation_type)
      WITH (FILLFACTOR = 80);
      PRINT 'CFG_INTEGRATION.INTEGRATION_SYSTEM length altered.';
    END
GO
    
    -- Check if the column length is still 25
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CFG_INTEGRATION_P' AND COLUMN_NAME = 'INTEGRATION_SYSTEM' AND CHARACTER_MAXIMUM_LENGTH = 25)
    BEGIN
      -- alter the length to 50
      ALTER TABLE CFG_INTEGRATION_P DROP CONSTRAINT pk_cfg_integration_p;
      ALTER TABLE CFG_INTEGRATION_P ALTER COLUMN INTEGRATION_SYSTEM nvarchar(50) NOT NULL;
      ALTER TABLE CFG_INTEGRATION_P ADD CONSTRAINT pk_cfg_integration_p
      PRIMARY KEY CLUSTERED (organization_id, integration_system, integration_type, implementation_type, property_code)
      WITH (FILLFACTOR = 80);
      PRINT 'CFG_INTEGRATION_P.INTEGRATION_SYSTEM length altered.';
    END
GO

/* 
 * TABLE: [dbo].[cfg_attachment_types] 
 */
IF OBJECT_ID('cfg_attachment_types') IS NULL
BEGIN
PRINT 'Create the cfg_attachment_types table.'
exec('CREATE TABLE [dbo].[cfg_attachment_types](
    [attachment_type_id]    nvarchar(30)     NOT NULL,
    [description]     nvarchar(255)    NULL,
    [create_date]     datetime        NULL,
    [create_user_id]  nvarchar(256)    NULL,
    [update_date]     datetime        NULL,
    [update_user_id]  nvarchar(256)    NULL,
    CONSTRAINT [pk_cfg_attachment_types] PRIMARY KEY CLUSTERED ([attachment_type_id])
    WITH FILLFACTOR = 80
)');
END

GO

-- [RXPS-63846] END




-- LEAVE BLANK LINE BELOW
