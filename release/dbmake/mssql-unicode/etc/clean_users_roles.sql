--------------------------------------------------------------------------------
-- This script will drop all of the users and roles created for XStore.  
--
-- Product:         XStore
-- Version:         19.0.0
-- DB platform:     Microsoft SQL Server 2012/2014/2016
-- $Name$
--------------------------------------------------------------------------------

USE [master]
GO

DROP LOGIN [handheld]
DROP LOGIN [$(DbUser)]
DROP LOGIN [xbruser]
DROP LOGIN [xtoolusers]
DROP LOGIN [$(DbSchema)]
DROP LOGIN [dbauser]
DROP LOGIN [$(DbBackup)]
GO

