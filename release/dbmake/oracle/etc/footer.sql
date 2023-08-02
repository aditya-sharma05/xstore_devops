declare
vcnt int;
begin
	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY TRIGGER';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY TRIGGER FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE PUBLIC SYNONYM';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE PUBLIC SYNONYM FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY VIEW';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY VIEW FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY DIRECTORY';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY DIRECTORY FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY SEQUENCE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY SEQUENCE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY PROCEDURE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY PROCEDURE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY TABLE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY TABLE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY JOB';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY JOB FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='DROP ANY TRIGGER';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE DROP ANY TRIGGER FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='DROP PUBLIC SYNONYM';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE DROP PUBLIC SYNONYM FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='DROP ANY VIEW';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE DROP ANY VIEW FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='DROP ANY DIRECTORY';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE DROP ANY DIRECTORY FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='DROP ANY SEQUENCE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE DROP ANY SEQUENCE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='DROP ANY PROCEDURE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE DROP ANY PROCEDURE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='DROP ANY TABLE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE DROP ANY TABLE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_ROLE_PRIVS where GRANTEE=upper('$(DbSchema)') and GRANTED_ROLE='EXP_FULL_DATABASE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE EXP_FULL_DATABASE FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='SELECT ANY DICTIONARY';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE SELECT ANY DICTIONARY FROM $(DbSchema)';
	end if;


	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='CREATE ANY SYNONYM';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'REVOKE CREATE ANY SYNONYM FROM $(DbSchema)';
	end if;

	select count(*) into vcnt from DBA_SYS_PRIVS where GRANTEE=upper('$(DbSchema)') and PRIVILEGE='GRANT ANY PRIVILEGE';

	if vcnt>0 then
		EXECUTE IMMEDIATE 'GRANT CREATE TRIGGER TO $(DbSchema)';
		EXECUTE IMMEDIATE 'GRANT CREATE VIEW TO $(DbSchema)';
		EXECUTE IMMEDIATE 'GRANT CREATE SEQUENCE TO $(DbSchema)';
		EXECUTE IMMEDIATE 'GRANT CREATE PROCEDURE TO $(DbSchema)';
		EXECUTE IMMEDIATE 'GRANT CREATE TABLE TO $(DbSchema)';
		EXECUTE IMMEDIATE 'GRANT CREATE TYPE TO $(DbSchema)';
		EXECUTE IMMEDIATE 'GRANT CREATE JOB TO $(DbSchema)';
		EXECUTE IMMEDIATE 'GRANT CREATE SYNONYM TO $(DbUser)';
		EXECUTE IMMEDIATE 'GRANT UNLIMITED TABLESPACE TO $(DbUser)';
		EXECUTE IMMEDIATE 'GRANT UNLIMITED TABLESPACE TO $(DbBackup)';

		EXECUTE IMMEDIATE 'REVOKE GRANT ANY PRIVILEGE FROM $(DbSchema)';
	end if;
end;
/

SPOOL OFF;
