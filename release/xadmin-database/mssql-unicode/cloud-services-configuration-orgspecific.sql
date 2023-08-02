-- system manager menu
Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_role_privilege where role_id = 'ADMINISTRATOR' AND privilege_id = 'SYSTEM_MANAGER' AND organization_id = '$(OrgID)';
IF v_exists = 0 THEN 

INSERT INTO cfg_role_privilege (organization_id, role_id, privilege_id) 
  VALUES ($(OrgID), 'ADMINISTRATOR', 'SYSTEM_MANAGER');
end if;
end;
/


COMMIT;


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_role_privilege where role_id = 'ADMINISTRATOR' AND privilege_id = 'ADMN_VIEW_LOGS' AND organization_id = '$(OrgID)';
IF v_exists = 0 THEN 

INSERT INTO cfg_role_privilege (organization_id, role_id, privilege_id) 
  VALUES ($(OrgID), 'ADMINISTRATOR', 'ADMN_VIEW_LOGS');
end if;
end;
/


COMMIT;

Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_role_privilege where role_id = 'ADMINISTRATOR' AND privilege_id = 'ADMN_EXPORT_LOGS' AND organization_id = '$(OrgID)';
IF v_exists = 0 THEN 

INSERT INTO cfg_role_privilege (organization_id, role_id, privilege_id) 
  VALUES ($(OrgID), 'ADMINISTRATOR', 'ADMN_EXPORT_LOGS');
end if;
end;
/


COMMIT;



-- Default user for cloud
Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_user_node where user_name = UPPER(q'[$(UserName)]') AND organization_id = '$(OrgID)';
IF v_exists = 0 THEN 

INSERT INTO cfg_user_node (organization_id,user_name,org_scope) VALUES ($(OrgID), UPPER(q'[$(UserName)]'),'*:*');
end if;
end;
/


COMMIT;


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_user_org_role where user_name = UPPER(q'[$(UserName)]') AND organization_id = '$(OrgID)';
IF v_exists = 0 THEN 

INSERT INTO cfg_user_org_role (user_name,organization_id,role_id,is_dashboard_homepage)
  VALUES (UPPER(q'[$(UserName)]'),$(OrgID),'ADMINISTRATOR',0);
end if;
end;
/


COMMIT;

--Remove any existing cloud provisioned xadmin users from database
DELETE FROM cfg_user_node WHERE user_name IN (SELECT user_name FROM cfg_user WHERE user_status IS NULL);

DELETE FROM cfg_user_org_role WHERE user_name IN (SELECT user_name FROM cfg_user WHERE user_status IS NULL);

DELETE FROM cfg_user WHERE user_status IS NULL;

DELETE FROM cfg_user_org_role WHERE user_name NOT IN ( SELECT user_name FROM cfg_user );

DELETE FROM cfg_user_node WHERE user_name NOT IN ( SELECT user_name FROM cfg_user );

--Remove passwords from database
DELETE FROM cfg_user_password;

COMMIT;