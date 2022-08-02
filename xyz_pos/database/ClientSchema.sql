-- ***************************************************************************
-- Place any customer specific schema changes into this file
--
-- All sql statements that goes here should be defined in a update-safe way, ie. the final script should be able 
-- to run against the database any number of times and should produce the same output.
--
-- This file should finish with a database commit; at least at the end of the file.
--
-- ***************************************************************************

-- ***************************************************************************
-- Oracle db specific command. Remove or comment this line out for all other DBMS.
ALTER SESSION SET CURRENT_SCHEMA=$(DbSchema);
-- ***************************************************************************
