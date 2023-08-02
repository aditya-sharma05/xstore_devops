--------------------------------------------------------------------------------
-- This script will create the synonyms for the $(DbUser).
--
-- Product:         XStore
-- Version:         19.0.0
-- DB platform:     Oracle 12c
--------------------------------------------------------------------------------
SET SERVEROUTPUT ON;
BEGIN
  if '$(DbSchema)' <> '$(DbUser)' then
	DECLARE
	  CURSOR Drop_Syn_Cur IS
		SELECT 'DROP SYNONYM ' || owner || '.' || synonym_name
		  from all_synonyms
		  where owner = upper('$(DbUser)') and TABLE_OWNER = upper('$(DbSchema)');
	  
	  ls_sqlcmd			VARCHAR(1024);
  
	BEGIN
		  OPEN Drop_Syn_Cur;
		  LOOP
			FETCH Drop_Syn_Cur INTO ls_sqlcmd;
			EXIT WHEN DROP_SYN_CUR%NOTFOUND;
	
	--		DBMS_OUTPUT.PUT_LINE(ls_sqlcmd);
			EXECUTE IMMEDIATE ls_sqlcmd;
	
		  END LOOP;
	END;

	DECLARE
	  CURSOR Create_Syn_Cur IS
		SELECT 'CREATE SYNONYM $(DbUser).' || table_name || ' FOR ' || owner || '.' || table_name
		  from all_tables
		  where owner = upper('$(DbSchema)');
	  
	  ls_sqlcmd			VARCHAR(1024);
  
	BEGIN
		  OPEN Create_Syn_Cur;
		  LOOP
			FETCH Create_Syn_Cur INTO ls_sqlcmd;
			EXIT WHEN CREATE_SYN_CUR%NOTFOUND;
	
	--		DBMS_OUTPUT.PUT_LINE(ls_sqlcmd);
			EXECUTE IMMEDIATE ls_sqlcmd;
	
		  END LOOP;
	END;

	DECLARE
	  CURSOR Create_Syn_Cur IS
		SELECT 'CREATE OR REPLACE SYNONYM $(DbUser).' || view_name || ' FOR ' || owner || '.' || view_name
		  from all_views
		  where owner = upper('$(DbSchema)');
	  
	  ls_sqlcmd			VARCHAR(1024);
  
	BEGIN
		  OPEN Create_Syn_Cur;
		  LOOP
			FETCH Create_Syn_Cur INTO ls_sqlcmd;
			EXIT WHEN CREATE_SYN_CUR%NOTFOUND;
	
	--		DBMS_OUTPUT.PUT_LINE(ls_sqlcmd);
			EXECUTE IMMEDIATE ls_sqlcmd;
	
		  END LOOP;
	END;

	DECLARE
	  CURSOR Create_Syn_Cur IS
		SELECT 'CREATE OR REPLACE SYNONYM $(DbUser).' || object_name || ' FOR ' || owner || '.' || object_name
		  from ALL_PROCEDURES
		  where owner = upper('$(DbSchema)');
	  
	  ls_sqlcmd			VARCHAR(1024);
  
	BEGIN
		  OPEN Create_Syn_Cur;
		  LOOP
			FETCH Create_Syn_Cur INTO ls_sqlcmd;
			EXIT WHEN CREATE_SYN_CUR%NOTFOUND;
	
	--		DBMS_OUTPUT.PUT_LINE(ls_sqlcmd);
			EXECUTE IMMEDIATE ls_sqlcmd;
	
		  END LOOP;
	END;

	DECLARE
	  CURSOR Create_Syn_Cur IS
		SELECT 'CREATE OR REPLACE SYNONYM $(DbUser).' || SEQUENCE_NAME || ' FOR ' || SEQUENCE_OWNER || '.' || SEQUENCE_NAME
		  from ALL_SEQUENCES
		  where SEQUENCE_OWNER = upper('$(DbSchema)');
	  
	  ls_sqlcmd			VARCHAR(1024);
  
	BEGIN
		  OPEN Create_Syn_Cur;
		  LOOP
			FETCH Create_Syn_Cur INTO ls_sqlcmd;
			EXIT WHEN CREATE_SYN_CUR%NOTFOUND;
	
	--		DBMS_OUTPUT.PUT_LINE(ls_sqlcmd);
			EXECUTE IMMEDIATE ls_sqlcmd;
	
		  END LOOP;
	END;
  end if;
END;
/
