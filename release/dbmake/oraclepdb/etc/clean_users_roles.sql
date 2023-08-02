--------------------------------------------------------------------------------
-- This script will drop all of the users, roles and the profile created for 
-- XStore.  
--
-- Product:         XStore
-- Version:         19.0.0
-- DB platform:     Oracle 12c
-- $Name$
--------------------------------------------------------------------------------
SET SERVEROUTPUT ON;
SPOOL cleanusersroles.log;

BEGIN
EXECUTE IMMEDIATE 'drop user $(DbBackup) cascade';
EXECUTE IMMEDIATE 'drop user dev cascade';
EXECUTE IMMEDIATE 'drop user dbauser cascade';
EXECUTE IMMEDIATE 'drop user xbruser cascade';
EXECUTE IMMEDIATE 'drop user xtool cascade';
EXECUTE IMMEDIATE 'drop user xtoolusers cascade';

--------------------------------------------------------------------------------
-- Drop all of the XStore Roles
--------------------------------------------------------------------------------
EXECUTE IMMEDIATE 'DROP ROLE posusers';
EXECUTE IMMEDIATE 'DROP ROLE dbausers';
EXECUTE IMMEDIATE 'DROP ROLE hhlookupusers';
EXECUTE IMMEDIATE 'DROP ROLE xtool_app';
EXECUTE IMMEDIATE 'DROP ROLE cwiusers';

--------------------------------------------------------------------------------
-- Drop all of the XStore Profile
--------------------------------------------------------------------------------
EXECUTE IMMEDIATE 'DROP PROFILE xstore CASCADE';

--------------------------------------------------------------------------------
-- Drop all of the XStore Public Synonyms
--------------------------------------------------------------------------------
--SET SERVEROUTPUT ON;
DECLARE
  CURSOR Drop_Syn_Cur IS
    SELECT 'DROP SYNONYM ' || owner || '.' || table_name
      from dba_synonyms
      where table_owner IN ('REPQUEUE', 'XTOOL');
    
  ls_sqlcmd     VARCHAR(128);
  
BEGIN
  OPEN Drop_Syn_Cur;
  LOOP
    FETCH Drop_Syn_Cur INTO ls_sqlcmd;
  EXIT WHEN DROP_SYN_CUR%NOTFOUND;
  
  DBMS_OUTPUT.PUT_LINE(ls_sqlcmd);
    EXECUTE IMMEDIATE ls_sqlcmd;
  
  END LOOP;
END;

END;
/
