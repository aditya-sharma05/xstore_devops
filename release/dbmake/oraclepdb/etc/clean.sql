--------------------------------------------------------------------------------
-- This script will drop the pluggable database created for 
-- XStore.
--
-- Product:         XStore
-- Version:         19.0.0
-- DB platform:     Oracle 12c
-- $Name$
--------------------------------------------------------------------------------
SET SERVEROUTPUT ON;
SPOOL clean.log;

--------------------------------------------------------------------------------
-- Drop the XStore PDB
--------------------------------------------------------------------------------
alter session set container = cdb$root;

alter pluggable database $(DbName) close immediate;

exec dbms_lock.sleep(10);

drop pluggable database $(DbName) including datafiles;

DECLARE
  li_rowcnt INT;
  l_exists     boolean;
  l_size       integer;
  l_block_size integer;
BEGIN
select count(*) INTO li_rowcnt from v$parameter where upper(name) like '%LOCKDOWN%' and value is not null;
IF li_rowcnt = 0 THEN
    execute immediate 'CREATE OR REPLACE DIRECTORY EXT_DATA_FILES AS ''$(DbDataFilePath)''';

    utl_file.fgetattr( 'EXT_DATA_FILES', 
                      'SYSTEM01.DBF', 
                      l_exists, 
                      l_size, 
                      l_block_size );
    if( l_exists )
    then
      dbms_lock.sleep(30);
      utl_file.fremove('EXT_DATA_FILES', 'SYSTEM01.DBF');
    end if;
    
    utl_file.fgetattr( 'EXT_DATA_FILES', 
                      'PDBSEED_TEMP01.DBF', 
                      l_exists, 
                      l_size, 
                      l_block_size );
    if( l_exists )
    then
      dbms_lock.sleep(30);
      utl_file.fremove('EXT_DATA_FILES', 'PDBSEED_TEMP01.DBF');
    end if;
 
    utl_file.fgetattr( 'EXT_DATA_FILES', 
                      'SYSAUX01.DBF', 
                      l_exists, 
                      l_size, 
                      l_block_size );
    if( l_exists )
    then
      dbms_lock.sleep(30);
      utl_file.fremove('EXT_DATA_FILES', 'SYSAUX01.DBF');
    end if;

END IF;
END;
/

SPOOL OFF;


