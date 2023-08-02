SET SERVEROUTPUT ON SIZE 10000


-- ***************************************************************************
-- This script will apply after all schema artifacts have been upgraded to a given version.  It is
-- generally useful for performing conversions between legacy and modern representations of affected
-- data sets.
--
-- Source version:  18.0.x
-- Target version:  19.0.0
-- DB platform:     Oracle 12c
-- ***************************************************************************

UNDEFINE dbDataTableSpace;
UNDEFINE dbIndexTableSpace;

-- LEAVE BLANK LINE BELOW
