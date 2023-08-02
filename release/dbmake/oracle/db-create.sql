SET SERVEROUTPUT ON SIZE 10000
SET VERIFY OFF


-------------------------------------------------------------------------------------------------------------------
--                                                                                                              
-- Script           : db-create.sql                                                                    
-- Description      : Creates the Tablespaces, Roles, Profiles and Users for a new Oracle database.               
-- Author           : Sundar Thiagarajan
-- DB platform:     : Oracle 12c
-- Version          : 20.0.0                                                                                   
-------------------------------------------------------------------------------------------------------------------

--
-- Variables
--
DEFINE dbDataTableSpace = '$(DbTblspace)_DATA';-- Name of data file tablespace
DEFINE dbDataFilePath = '$(DbDataFilePath)/&dbDataTableSpace..dbf';-- Location of data file
DEFINE dbIndexTableSpace = '$(DbTblspace)_INDEX';-- Name of index file tablespace
DEFINE dbIndexFilePath = '$(DbIndexFilePath)/&dbIndexTableSpace..dbf';-- Location of index file
DEFINE dbProfileName = 'XSTORE';-- The name of the database profile governing access limits
DEFINE dbSchema = '$(DbSchema)';-- Schema where the objects reside (i.e. DTV, TRAINING, or REPQUEUE)
DEFINE dbSchemaPwd = '$(DbSchemaPwd)';-- Schema where the objects reside password
DEFINE dbUser = '$(DbUser)';-- User using the objects (i.e. POS, TRAINING, or REPQUEUE) 
DEFINE dbUserPwd = '$(DbUserPwd)';-- User using the objects password
DEFINE dbBackup = '$(DbBackup)';-- The backup DB user (ie. dbauser)
DEFINE dbBackupPwd = '$(DbBackupPwd)';-- The backup DB user password
DEFINE dbBigFile = 'false';  -- specify a big file for table space either 'true' or 'false'
DEFINE dbFileOpts = 'SIZE 512M AUTOEXTEND ON NEXT 512M MAXSIZE UNLIMITED'; -- datafile sizing options

--
-- Create the Tablespaces: Data and Index
--
-- spool after variable declaration to avoid disclosing credentials in logs
SPOOL dbcreate.log;

DECLARE
li_rowcnt INT;
BEGIN
SELECT count(*) INTO li_rowcnt FROM dba_tablespaces WHERE tablespace_name = upper('&dbDataTableSpace.');

IF li_rowcnt = 0 THEN
  IF UPPER('&dbBigFile.') = 'TRUE' THEN
      EXECUTE IMMEDIATE 'CREATE BIGFILE TABLESPACE &dbDataTableSpace. DATAFILE
      ''&dbDataFilePath.'' ' || '&dbFileOpts.';
  ELSE
    -- Non BigFile storage
    EXECUTE IMMEDIATE 'CREATE TABLESPACE &dbDataTableSpace. DATAFILE
    ''&dbDataFilePath.'' ' || '&dbFileOpts.';
  END IF;
END IF;
END;
/

DECLARE
li_rowcnt INT;
BEGIN
SELECT count(*) INTO li_rowcnt FROM dba_tablespaces WHERE tablespace_name = upper('&dbIndexTableSpace.');

IF li_rowcnt = 0 THEN
  IF UPPER('&dbBigFile.') = 'TRUE' THEN
    EXECUTE IMMEDIATE 'CREATE BIGFILE TABLESPACE &dbIndexTableSpace. DATAFILE
      ''&dbIndexFilePath.'' ' || '&dbFileOpts.';
  ELSE
    -- Non BigFile storage
    EXECUTE IMMEDIATE 'CREATE TABLESPACE &dbIndexTableSpace. DATAFILE
    ''&dbIndexFilePath.'' ' || '&dbFileOpts.';
  END IF;
END IF;
END;
/

--
-- Create Roles
--

-- pos user Role
DECLARE
li_rowcnt INT;
BEGIN
SELECT count(*) INTO li_rowcnt FROM dba_roles WHERE role = 'POSUSERS';

IF li_rowcnt = 0 THEN
  EXECUTE IMMEDIATE 'CREATE ROLE posusers';
END IF;
END;
/

-- dba user Role
DECLARE
li_rowcnt INT;
BEGIN
SELECT count(*) INTO li_rowcnt FROM dba_roles WHERE role = 'DBAUSERS';

IF li_rowcnt = 0 THEN
  EXECUTE IMMEDIATE 'CREATE ROLE dbausers';
END IF;
END;
/

--
-- Create User Profiles
--

-- xstore user role
DECLARE
li_rowcnt INT;
BEGIN
SELECT count(*) INTO li_rowcnt FROM dba_profiles WHERE profile = upper('&dbProfileName.');

IF li_rowcnt = 0 THEN
  EXECUTE IMMEDIATE 'CREATE PROFILE &dbProfileName.
  LIMIT
    CONNECT_TIME unlimited
    FAILED_LOGIN_ATTEMPTS 5
    IDLE_TIME 30
    SESSIONS_PER_USER unlimited
    PASSWORD_LIFE_TIME unlimited';
END IF;
END;
/

--
-- Create Schema Owner Users
--

-- schema owner user
DECLARE
li_rowcnt INT;
lc_rowcnt INT;
BEGIN
SELECT count(*) INTO li_rowcnt FROM dba_users WHERE username = upper('&dbSchema.');
select count(*) INTO lc_rowcnt from v$parameter where upper(name) like '%LOCKDOWN%' and value is not null;

IF li_rowcnt = 0 THEN
  EXECUTE IMMEDIATE 'CREATE USER &dbSchema.
    IDENTIFIED BY "' || '&dbSchemaPwd.' || '"
    DEFAULT TABLESPACE &dbDataTableSpace.
    TEMPORARY TABLESPACE TEMP
    PROFILE &dbProfileName.
    ACCOUNT UNLOCK';
  
  EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO &dbSchema.';
  EXECUTE IMMEDIATE 'GRANT UNLIMITED TABLESPACE TO &dbSchema.';
  EXECUTE IMMEDIATE 'GRANT CREATE TRIGGER TO &dbSchema.';
  EXECUTE IMMEDIATE 'GRANT CREATE VIEW TO &dbSchema.';
  EXECUTE IMMEDIATE 'GRANT CREATE SEQUENCE TO &dbSchema.';
  EXECUTE IMMEDIATE 'GRANT CREATE PROCEDURE TO &dbSchema.';
  EXECUTE IMMEDIATE 'GRANT CREATE TABLE TO &dbSchema.';
  EXECUTE IMMEDIATE 'GRANT CREATE TYPE TO &dbSchema.';
  EXECUTE IMMEDIATE 'GRANT CREATE JOB TO &dbSchema.';
  IF lc_rowcnt = 0 THEN
    -- these can't be granted in ATP
    EXECUTE IMMEDIATE 'GRANT EXP_FULL_DATABASE TO &dbSchema.';
    EXECUTE IMMEDIATE 'GRANT IMP_FULL_DATABASE TO &dbSchema.';
  END IF;
  EXECUTE IMMEDIATE 'GRANT SELECT_CATALOG_ROLE TO &dbSchema.';
  EXECUTE IMMEDIATE 'GRANT dbausers TO &dbSchema.';
END IF;
END;
/

--
-- Create Non-Schema-Owner Users
--

-- Xstore application user
DECLARE
li_rowcnt INT;
BEGIN
SELECT count(*) INTO li_rowcnt FROM dba_users WHERE username = upper('&dbUser.');

IF li_rowcnt = 0 THEN
  EXECUTE IMMEDIATE 'CREATE USER &dbUser. 
    IDENTIFIED BY "' || '&dbUserPwd.' || '"
    DEFAULT TABLESPACE &dbDataTableSpace.
    TEMPORARY TABLESPACE TEMP
    PROFILE &dbProfileName.
    ACCOUNT UNLOCK';

  EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO &dbUser.';
  EXECUTE IMMEDIATE 'GRANT UNLIMITED TABLESPACE TO &dbUser.';
  EXECUTE IMMEDIATE 'GRANT CREATE SYNONYM TO &dbUser.';
  EXECUTE IMMEDIATE 'GRANT CREATE TABLE TO &dbUser.';
  EXECUTE IMMEDIATE 'GRANT SELECT_CATALOG_ROLE TO &dbUser.';
  EXECUTE IMMEDIATE 'GRANT posusers to &dbUser.';  
END IF;
END;
/
-- database backup/restore user
DECLARE
li_rowcnt INT;
lc_rowcnt INT;
BEGIN
SELECT count(*) INTO li_rowcnt FROM dba_users WHERE username = upper('&dbBackup.');
select count(*) INTO lc_rowcnt from v$parameter where upper(name) like '%LOCKDOWN%' and value is not null;

IF li_rowcnt = 0 AND lc_rowcnt = 0 THEN
  EXECUTE IMMEDIATE 'CREATE USER &dbBackup.
    IDENTIFIED BY "' || '&dbBackupPwd.' || '"
    DEFAULT TABLESPACE &dbDataTableSpace.
    TEMPORARY TABLESPACE TEMP
    PROFILE &dbProfileName.
    ACCOUNT UNLOCK';

  EXECUTE IMMEDIATE 'GRANT UNLIMITED TABLESPACE TO &dbBackup.';
  EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO &dbBackup.';
  EXECUTE IMMEDIATE 'GRANT EXP_FULL_DATABASE TO &dbBackup.';
  EXECUTE IMMEDIATE 'GRANT IMP_FULL_DATABASE TO &dbBackup.';
  EXECUTE IMMEDIATE 'GRANT dbausers TO &dbBackup.';
END IF;
END;
/

DECLARE
li_rowcnt INT;
BEGIN
select count(*) INTO li_rowcnt from v$parameter where upper(name) like '%LOCKDOWN%' and value is not null;
IF li_rowcnt = 0 THEN
  EXECUTE IMMEDIATE 'CREATE OR REPLACE DIRECTORY EXP_DIR AS ''xstoredb/backup''';
  EXECUTE IMMEDIATE 'GRANT READ, WRITE ON DIRECTORY EXP_DIR TO &dbBackup.,&dbSchema.';
END IF;
END;
/

UNDEFINE dbDataFilePath;
UNDEFINE dbDataTableSpace;
UNDEFINE dbIndexFilePath;
UNDEFINE dbIndexTableSpace;
UNDEFINE dbProfileName;
UNDEFINE dbSchema;
UNDEFINE dbSchemaPwd;
UNDEFINE dbUser;
UNDEFINE dbUserPwd;
UNDEFINE dbBackup;
UNDEFINE dbBackupPwd;

--SPOOL OFF;
