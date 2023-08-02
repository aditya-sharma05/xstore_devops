--------------------------------------------------------------------------------
-- This script will drop all of the users, roles and the profile created for 
-- XStore.  The script will drop all tables and synonyms in the xstore schema
--
-- Product:         XStore
-- Version:         19.0.0
-- DB platform:     Oracle 12c
-- $Name$
--------------------------------------------------------------------------------
SET SERVEROUTPUT ON;
SPOOL clean.log;

--
-- Variables
--
DEFINE dbDataTableSpace = '$(DbTblspace)_DATA';-- Name of data file tablespace
DEFINE dbIndexTableSpace = '$(DbTblspace)_INDEX';-- Name of index file tablespace 

drop user $(DbSchema) cascade;

BEGIN
if upper('$(DbUser)') <> upper('$(DbSchema)') then
  EXECUTE IMMEDIATE 'drop user $(DbUser) cascade';
end if;
END;
/

SET SERVEROUTPUT ON;
DECLARE
  CURSOR Drop_Syn_Cur IS
    SELECT 'DROP SYNONYM ' || owner || '.' || table_name
      from dba_synonyms
      where table_owner = upper('$(DbSchema)');
    
  ls_sqlcmd     VARCHAR(256);
  
BEGIN
  OPEN Drop_Syn_Cur;
  LOOP
    FETCH Drop_Syn_Cur INTO ls_sqlcmd;
  EXIT WHEN DROP_SYN_CUR%NOTFOUND;
  
  DBMS_OUTPUT.PUT_LINE(ls_sqlcmd);
    EXECUTE IMMEDIATE ls_sqlcmd;
  
  END LOOP;
END;
/
--------------------------------------------------------------------------------
-- Drop the tablespaces
--------------------------------------------------------------------------------
DECLARE
  li_rowcnt INT;
  l_exists     boolean;
  l_size       integer;
  l_block_size integer;
BEGIN
select count(*) INTO li_rowcnt from v$parameter where upper(name) like '%LOCKDOWN%' and value is not null;
IF li_rowcnt = 0 THEN
  execute immediate 'CREATE OR REPLACE DIRECTORY EXT_DATA_FILES AS ''$(DbDataFilePath)''';

  execute immediate 'DROP TABLESPACE &dbDataTableSpace. INCLUDING CONTENTS AND DATAFILES';
  utl_file.fgetattr( 'EXT_DATA_FILES', 
                     lower('&dbDataTableSpace..dbf'), 
                     l_exists, 
                     l_size, 
                     l_block_size );
   if( l_exists )
   then
     dbms_lock.sleep(30);
     utl_file.fremove('EXT_DATA_FILES', '&dbDataTableSpace..dbf');
   end if;

  execute immediate 'DROP TABLESPACE &dbIndexTableSpace. INCLUDING CONTENTS AND DATAFILES';
  utl_file.fgetattr( 'EXT_DATA_FILES', 
                     lower('&dbIndexTableSpace..dbf'), 
                     l_exists, 
                     l_size, 
                     l_block_size );
   if( l_exists )
   then
     dbms_lock.sleep(30);
     utl_file.fremove('EXT_DATA_FILES', '&dbIndexTableSpace..dbf');
   end if;

END IF;
END;
/

UNDEFINE dbDataTableSpace;
UNDEFINE dbIndexTableSpace;

SPOOL OFF;

