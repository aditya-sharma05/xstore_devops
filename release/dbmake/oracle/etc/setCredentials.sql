--------------------------------------------------------------------------------
-- This script will set the password for sys and system users
--
-- Product:         XStore
-- Version:         19.0.0
-- DB platform:     Oracle 12c
-- $Name$
--------------------------------------------------------------------------------
SET SERVEROUTPUT ON;
SPOOL clean.log;

ALTER USER system IDENTIFIED BY $(DbAdmpwd);
ALTER USER sys IDENTIFIED BY $(DbAdmpwd);

SPOOL OFF;

