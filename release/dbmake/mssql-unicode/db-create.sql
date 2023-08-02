-------------------------------------------------------------------------------------------------------------------
-- This script will create an Xstore database compatible with DB platform <platform> and, where 
-- applicable, create/assign the appropriate users, roles, and platform-specific options for it.
--
-- This script does not define any schematics for the new database.  To identify an Xstore-compatible
-- schema for it, run the "new" script designated for the desired application version.
--
-- Platform:  Microsoft SQL Server 2012/2014/2016
-------------------------------------------------------------------------------------------------------------------

-----------------------------------------
-- Variables
-----------------------------------------
-- Search/replace all occurrences of the following to configure the script
-- $(DbName) - The Database name (ie. xstore, training, etc.)
-- $(DbDataFilePath) - Location where data files should be created
-- $(DbSchema) - The admin DB user (ie. dtv)
-- $(DbSchemaPwd) - The admin DB user password
-- $(DbUser) - The login DB user (ie. pos)
-- $(DbUserPwd) - The login DB user password
-- $(DbBackup) - The backup DB user (ie. dbauser)
-- $(DbBackupPwd) - The backup DB user password

-----------------------------------------
PRINT '* PROLOGUE';
-----------------------------------------
USE master;
GO
DECLARE @dbName nvarchar(30) = N'$(DbName)';
DECLARE @dbPath nvarchar(128) = N'$(DbDataFilePath)\';

-----------------------------------------
PRINT '* CREATE DB';
PRINT '     - Name: ' + @dbName;
PRINT '     - Path: ' + @dbPath;
-----------------------------------------
DECLARE @dataName nvarchar(48) = @dbName + '_data';
DECLARE @dataFile nvarchar(128) = @dbPath + @dataName + '.mdf';
DECLARE @logName nvarchar(48) = @dbName + '_log';
DECLARE @logFile nvarchar(128) = @dbPath + @logName + '.ldf';
DECLARE @sql nvarchar(512) = N'CREATE DATABASE ' + @dbName + ' ON (
      NAME = ' + @dataName + ',
      FILENAME = ''' + @dataFile + ''',
      SIZE = 8,
      FILEGROWTH = 10%)
    LOG ON (
      NAME = ' + @logName + ',
      FILENAME = ''' + @logFile + ''',
      SIZE = 9, 
      FILEGROWTH = 10%)';
IF DB_ID(@dbName) IS NULL
  EXEC (@sql);
GO

USE $(DbName);
GO


-----------------------------------------
PRINT '* CONFIGURE DB';
-----------------------------------------
DECLARE @dbName nvarchar(30) = N'$(DbName)';
DECLARE @dbSchema nvarchar(30) = '$(DbSchema)';
DECLARE @dbSchemaPwd nvarchar(30) = '$(DbSchemaPwd)';
DECLARE @dbUser nvarchar(30) = '$(DbUser)';
DECLARE @dbUserPwd nvarchar(30) = '$(DbUserPwd)';
DECLARE @DbBackup nvarchar(30) = '$(DbBackup)';
DECLARE @DbBackupPwd nvarchar(30) = '$(DbBackupPwd)';
DECLARE @sql nvarchar(512);
DECLARE @loginDb nvarchar(132) = null;
DECLARE @loginLang nvarchar(132) = N'us_english';
IF @loginDb IS NULL OR NOT EXISTS (Select * From master.dbo.sysdatabases Where name = @loginDb)
  SET @loginDb = N'master';
IF @loginLang IS NULL OR NOT EXISTS (Select * From master.dbo.syslanguages Where name = @loginLang And name <> 'us_english')
  SET @loginLang = N'us_english';
execute('ALTER DATABASE ' + @dbName + ' SET TORN_PAGE_DETECTION ON;')
execute('ALTER DATABASE ' + @dbName + ' SET AUTO_CREATE_STATISTICS ON;')
execute('ALTER DATABASE ' + @dbName + ' SET AUTO_UPDATE_STATISTICS ON;')

-----------------------------------------
PRINT '* CONFIGURE USERS';
-----------------------------------------

-- **************************************
PRINT '     - Admin User: ' + @dbSchema;
PRINT '     - Role: db_owner ';
-- **************************************
SET @sql = 'CREATE LOGIN ' + @dbSchema + ' ' +
  'WITH PASSWORD = ''' + @dbSchemaPwd + ''', ' +
  'SID = 0x42E5E3FF09069A47B8386FF8BF31BC56,' +
  'DEFAULT_LANGUAGE =  ' + @loginLang + ', ' +
  'DEFAULT_DATABASE = ' + @dbName + ', ' +
  'CHECK_POLICY = OFF';
IF NOT EXISTS (Select * From master.dbo.syslogins Where loginname = @dbSchema)
  EXEC(@sql);


IF NOT EXISTS (Select * From dbo.sysusers Where name = @dbSchema And uid < 16382)
  exec('CREATE USER ' + @dbSchema + ' FOR LOGIN ' + @dbSchema + ' WITH DEFAULT_SCHEMA=dbo');
EXEC sp_addrolemember N'db_owner', @dbSchema;


-----------------------------------------
PRINT '     - User: ' + @dbUser;
PRINT '     - Role: db_datareader';
PRINT '     - Role: db_datawriter';
PRINT '     - Role: execute';
-----------------------------------------
SET @sql = 'CREATE LOGIN ' + @dbUser + ' ' +
    'WITH PASSWORD = ''' + @dbUserPwd + ''', ' +
    'SID = 0x477813751A36C7409AB5A801D1691F35,' +
    'DEFAULT_LANGUAGE =  ' + @loginLang + ', ' +
    'DEFAULT_DATABASE = ' + @dbName + ', ' +
    'CHECK_POLICY = OFF';
IF NOT EXISTS (Select * From master.dbo.syslogins Where loginname = @dbUser)
  EXEC(@sql);

IF NOT EXISTS (Select * From dbo.sysusers Where name = @dbUser And uid < 16382)
  exec('CREATE USER ' + @dbUser + ' FOR LOGIN ' + @dbUser + ' WITH DEFAULT_SCHEMA=dbo');
EXEC sp_addrolemember N'db_datareader', @dbUser;
EXEC sp_addrolemember N'db_datawriter', @dbUser;
EXEC('GRANT execute to ' + @dbUser);


-----------------------------------------
PRINT '     - Backup User: dbauser';
-----------------------------------------
SET @sql = 'CREATE LOGIN ' + @dbBackup + ' ' +
    'WITH PASSWORD = ''' + @DbBackupPwd +''', ' +
    'SID = 0xF095E77FF66663429D7883DFECDADF3C,' +
    'DEFAULT_LANGUAGE =  ' + @loginLang + ', ' +
    'DEFAULT_DATABASE = ' + @dbName + ', ' +
    'CHECK_POLICY = OFF';
IF NOT EXISTS (Select * From master.dbo.syslogins Where loginname = @dbBackup)
  EXEC(@sql);

EXEC sp_addsrvrolemember @dbBackup, dbcreator;
IF NOT EXISTS (Select * From dbo.sysusers Where name = @dbBackup And uid < 16382)
  EXEC('CREATE USER ' + @dbBackup + ' FOR LOGIN ' + @dbBackup + ' WITH DEFAULT_SCHEMA=[dbo]');
EXEC sp_addrolemember N'db_backupoperator', @dbBackup;

-----------------------------------------
PRINT '* EPILOGUE';
-----------------------------------------
PRINT '     - Close SQL Server security loopholes';
-----------------------------------------
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 0;
EXEC sp_configure 'Ad Hoc Distributed Queries', 0;
GO

-- **************************************
PRINT '     - Set index fill factor = 80%';
-- **************************************
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'fill factor', 80;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;
GO
