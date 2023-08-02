
-- **************************************************** --
-- * Always keep Default User Creation at end of file * --
-- **************************************************** --
-- DEFAULT USER

Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_user where USER_NAME='$(OrgID)-1';
IF v_exists = 0 THEN 

  INSERT INTO cfg_user (user_name, first_name, last_name, locale, create_date, create_user_id) VALUES ('$(OrgID)-1', 'Organization $(OrgID)', 'User', 'en_US', SYSDATE, 'BASEDATA');
  INSERT INTO cfg_user_org_role (user_name, organization_id, role_id, create_date, create_user_id) VALUES ('$(OrgID)-1', $(OrgID), 'ADMINISTRATOR', SYSDATE, 'BASEDATA');
  INSERT INTO cfg_user_node (organization_id, user_name, org_scope, create_date, create_user_id) VALUES ($(OrgID), '$(OrgID)-1', '*:*', SYSDATE, 'BASEDATA');
  INSERT INTO cfg_user_password (password_id, user_name, password, effective_date, create_date, create_user_id) VALUES (HIBERNATE_SEQUENCE.nextval, '$(OrgID)-1', 'tZxnvxlqR1gZHkL3ZnDOug==', SYSDATE, SYSDATE, 'BASEDATA');
end if;
end;
/


COMMIT;


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_user_org_role where USER_NAME='1' and organization_id=$(OrgID) ;
IF v_exists = 0 THEN 

  INSERT INTO cfg_user_org_role (user_name, organization_id, role_id, create_date, create_user_id) VALUES ('1', $(OrgID), 'ADMINISTRATOR', SYSDATE, 'BASEDATA');
  INSERT INTO cfg_user_node (organization_id, user_name, org_scope, create_date, create_user_id) VALUES ($(OrgID), '1', '*:*', SYSDATE, 'BASEDATA');
end if;
end;
/


COMMIT;

