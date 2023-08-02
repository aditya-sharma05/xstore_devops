--------------------------------------------------------------------------------
-- This script will drop a database.
--
-- Product:         XStore
-- Version:         19.0.0
-- DB platform:     Microsoft SQL Server 2012/2014/2016
-- $Name$
--------------------------------------------------------------------------------

USE master;
GO

ALTER DATABASE [$(DbName)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DROP database [$(DbName)];
GO

