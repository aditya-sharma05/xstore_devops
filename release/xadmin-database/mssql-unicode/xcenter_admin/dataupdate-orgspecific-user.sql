
-- **************************************************** --
-- * Always keep Default User Creation at end of file * --
-- **************************************************** --
-- DEFAULT USER

IF NOT EXISTS (SELECT 1 FROM cfg_user where USER_NAME='$(OrgID)-1')
BEGIN

  INSERT INTO cfg_user (user_name, first_name, last_name, locale, create_date, create_user_id) VALUES ('$(OrgID)-1', 'Organization $(OrgID)', 'User', 'en_US', getDate(), 'BASEDATA');
  INSERT INTO cfg_user_org_role (user_name, organization_id, role_id, create_date, create_user_id) VALUES ('$(OrgID)-1', $(OrgID), 'ADMINISTRATOR', getDate(), 'BASEDATA');
  INSERT INTO cfg_user_node (organization_id, user_name, org_scope, create_date, create_user_id) VALUES ($(OrgID), '$(OrgID)-1', '*:*', getDate(), 'BASEDATA');
  INSERT INTO cfg_user_password (user_name, password, effective_date, create_date, create_user_id) VALUES ('$(OrgID)-1', 'tZxnvxlqR1gZHkL3ZnDOug==', getDate(), getDate(), 'BASEDATA');
END

GO


IF NOT EXISTS (SELECT 1 FROM cfg_user_org_role where USER_NAME='1' and organization_id=$(OrgID) )
BEGIN

  INSERT INTO cfg_user_org_role (user_name, organization_id, role_id, create_date, create_user_id) VALUES ('1', $(OrgID), 'ADMINISTRATOR', getDate(), 'BASEDATA');
  INSERT INTO cfg_user_node (organization_id, user_name, org_scope, create_date, create_user_id) VALUES ($(OrgID), '1', '*:*', getDate(), 'BASEDATA');
END

GO

