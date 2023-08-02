SET SERVEROUTPUT ON SIZE 10000

SPOOL dbcopy.log;

-------------------------------------------------------------------------------------------------------------------
--                                                                                                              
-- Script           : pdbcopy.sql                                                                    
-- Description      : Copies the Xstore Pluggable Database to a new Pluggable Database (i.e. Training, Xcenter,etc).               
-- Author           : Brett C. White
-- DB platform:     : Oracle 12c
-- Version          : 19.0.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                    
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                    
-------------------------------------------------------------------------------------------------------------------
-- ... .....     Initial Version
-------------------------------------------------------------------------------------------------------------------

--
-- Create Training PDB
--
alter session set container = cdb$root;

declare
li_rowcnt int;
begin
select count(*) into li_rowcnt from product_component_version where product like 'Oracle %' and version in ('12.1.0.0.0','12.1.0.1.0');

if li_rowcnt > 0 then
	EXECUTE IMMEDIATE 'alter pluggable database $(DbOriginName) close immediate';
	EXECUTE IMMEDIATE 'alter pluggable database $(DbOriginName) open read only';
end if;
end;
/

create pluggable database $(DbName) from $(DbOriginName)
FILE_NAME_CONVERT =('$(DbOriginDataFilePath)','$(DbDataFilePath)');

alter pluggable database $(DbName) open;
alter pluggable database $(DbName) save state instances=all;

declare
li_rowcnt int;
begin
select count(*) into li_rowcnt from product_component_version where product like 'Oracle %' and version in ('12.1.0.0.0','12.1.0.1.0');

if li_rowcnt > 0 then
	EXECUTE IMMEDIATE 'alter pluggable database $(DbOriginName) close immediate';
	EXECUTE IMMEDIATE 'alter pluggable database $(DbOriginName) open';
end if;
end;
/
--SPOOL OFF;
