
Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_code_value where category = 'OrganizationId' and code = '$(OrgID)';
IF v_exists = 0 THEN 

INSERT INTO cfg_code_value (code_id, category, config_name, code, sub_category, description, sort_order, data1, data2, data3, create_date, create_user_id)
VALUES (HIBERNATE_SEQUENCE.nextval, 'OrganizationId', 'DEFAULT', '$(OrgID)', 'DEFAULT', 'Organization $(OrgID)', 0, null, null, null, SYSDATE, 'BASEDATA');
end if;
end;
/


COMMIT;


-- SEQUENCES
Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_sequence_part where sequence_id = 'EMPLOYEE_MESSAGE' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO cfg_sequence_part (organization_id, sequence_id, prefix, suffix, encode_flag, check_digit_algo, numeric_flag, pad_length, pad_character, initial_value, max_value, value_increment, include_store_id, store_pad_length, include_wkstn_id, wkstn_pad_length, create_date, create_user_id)
values ($(OrgID), 'EMPLOYEE_MESSAGE', NULL, NULL, 0, NULL, 1, 9, '0', 1, 999999, 1, 0, 0, 1, 6, SYSDATE, 'BASEDATA');
end if;
end;
/


COMMIT;


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_sequence_part where sequence_id = 'ASSOCIATE_TASK' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO cfg_sequence_part (organization_id, sequence_id, prefix, suffix, encode_flag, check_digit_algo, numeric_flag, pad_length, pad_character, initial_value, max_value, value_increment, include_store_id, store_pad_length, include_wkstn_id, wkstn_pad_length, create_date, create_user_id)
values ($(OrgID), 'ASSOCIATE_TASK', NULL, NULL, 0, NULL, 1, 9, '0', 1, 999999, 1, 0, 0, 1, 6, SYSDATE, 'BASEDATA');
end if;
end;
/


COMMIT;


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_sequence_part where sequence_id = 'PARTY' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO cfg_sequence_part (organization_id, sequence_id, prefix, suffix, encode_flag, check_digit_algo, numeric_flag, pad_length, pad_character, initial_value, max_value, value_increment, include_store_id, store_pad_length, include_wkstn_id, wkstn_pad_length, create_date, create_user_id)
values ($(OrgID), 'PARTY', NULL, NULL, 0, NULL, 1, 9, '0', 1, 999999, 1, 0, 0, 1, 6, SYSDATE, 'BASEDATA');
end if;
end;
/


COMMIT;


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_sequence_part where sequence_id = 'DEPLOYMENT_ID' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO cfg_sequence_part (organization_id, sequence_id, prefix, suffix, encode_flag, check_digit_algo, numeric_flag, pad_length, pad_character, initial_value, max_value, value_increment, include_store_id, store_pad_length, include_wkstn_id, wkstn_pad_length, create_date, create_user_id)
values ($(OrgID), 'DEPLOYMENT_ID', NULL, NULL, 0, NULL, 1, 9, '0', 1, 99999999, 1, 0, 0, 0, 0, SYSDATE, 'BASEDATA');
end if;
end;
/


COMMIT;


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_sequence_part where sequence_id = 'PLAN_ID' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO cfg_sequence_part (organization_id, sequence_id, prefix, suffix, encode_flag, check_digit_algo, numeric_flag, pad_length, pad_character, initial_value, max_value, value_increment, include_store_id, store_pad_length, include_wkstn_id, wkstn_pad_length, create_date, create_user_id)
values ($(OrgID), 'PLAN_ID', NULL, NULL, 0, NULL, 1, 9, '0', 1, 999999, 1, 0, 0, 0, 0, SYSDATE, 'BASEDATA');
end if;
end;
/


COMMIT;


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_sequence_part where sequence_id = 'TAX_BRACKET_SEQ' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO cfg_sequence_part (organization_id, sequence_id, prefix, suffix, encode_flag, check_digit_algo, numeric_flag, pad_length, pad_character, initial_value, max_value, value_increment, include_store_id, store_pad_length, include_wkstn_id, wkstn_pad_length, create_date, create_user_id)
values ($(OrgID), 'TAX_BRACKET_SEQ', NULL, NULL, 0, NULL, 1, 9, '0', 1000, 99999999, 1, 0, 0, 0, 0, SYSDATE, 'BASEDATA');
end if;
end;
/


COMMIT;


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_sequence_part where sequence_id = 'LANDSCAPE' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO cfg_sequence_part (organization_id, sequence_id, prefix, suffix, encode_flag, check_digit_algo, numeric_flag, pad_length, pad_character, initial_value, max_value, value_increment, include_store_id, store_pad_length, include_wkstn_id, wkstn_pad_length, create_date, create_user_id)
values ($(OrgID), 'LANDSCAPE', NULL, NULL, 0, NULL, 1, 9, '0', 1, 999999, 1, 0, 0, 0, 0, SYSDATE, 'BASEDATA');
end if;
end;
/


COMMIT;


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_sequence_part where sequence_id = 'PERSONALITY' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO cfg_sequence_part (organization_id, sequence_id, prefix, suffix, encode_flag, check_digit_algo, numeric_flag, pad_length, pad_character, initial_value, max_value, value_increment, include_store_id, store_pad_length, include_wkstn_id, wkstn_pad_length, create_date, create_user_id)
values ($(OrgID), 'PERSONALITY', NULL, NULL, 0, NULL, 1, 9, '0', 1, 999999, 1, 0, 0, 0, 0, SYSDATE, 'BASEDATA');
end if;
end;
/


COMMIT;


-- org hierarchy levels
Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM cfg_org_hierarchy_level where org_code = '*' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO cfg_org_hierarchy_level(organization_id, org_code, parent_org_code, description, system_flag, create_date, create_user_id)
values ($(OrgID), '*', NULL, '*', 1, SYSDATE, 'BASEDATA');
end if;
end;
/


COMMIT;


-- authorization tender type categories
DELETE FROM cfg_tender_type_category where organization_id=$(OrgID) and tender_category = 'AUTHORIZATION' and tender_type in ('ACCOUNT_RECEIVABLE', 'HOUSE_ACCOUNT', 'CHECK', 'CREDIT_CARD', 'VOUCHER', 'PAY_BY_LINK','MISCELLANEOUS_EFTLINK','EWALLET');
COMMIT;

INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'AUTHORIZATION', 'CHECK', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'AUTHORIZATION', 'CREDIT_CARD', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'AUTHORIZATION', 'VOUCHER', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'AUTHORIZATION', 'PAY_BY_LINK', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'AUTHORIZATION', 'MISCELLANEOUS_EFTLINK', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'AUTHORIZATION', 'EWALLET', SYSDATE, 'BASEDATA');
COMMIT;


-- count tender type categories
DELETE FROM cfg_tender_type_category where organization_id=$(OrgID) and tender_category = 'COUNT' and tender_type in ('ACCOUNT_CREDIT', 'CHECK', 'COUPON', 'CREDIT_CARD', 'CURRENCY', 'TRAVELERS_CHECK', 'VOUCHER', 'MISCELLANEOUS_VOUCHER', 'MISCELLANEOUS','PAY_BY_LINK','MISCELLANEOUS_EFTLINK','EWALLET');
COMMIT;

INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'COUNT', 'ACCOUNT_CREDIT', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'COUNT', 'CHECK', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'COUNT', 'COUPON', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'COUNT', 'CREDIT_CARD', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'COUNT', 'CURRENCY', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'COUNT', 'TRAVELERS_CHECK', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'COUNT', 'VOUCHER', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'COUNT', 'PAY_BY_LINK', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'COUNT', 'MISCELLANEOUS_EFTLINK', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'COUNT', 'EWALLET', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'COUNT', 'MISCELLANEOUS_VOUCHER', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'COUNT', 'MISCELLANEOUS', SYSDATE, 'BASEDATA');
COMMIT;


-- denomination tender type categories
DELETE FROM cfg_tender_type_category where organization_id=$(OrgID) and tender_category = 'DENOMINATION' and tender_type in ('COUPON', 'CURRENCY', 'TRAVELERS_CHECK', 'VOUCHER', 'MISCELLANEOUS_VOUCHER', 'MISCELLANEOUS');
COMMIT;
 
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'DENOMINATION', 'CURRENCY', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'DENOMINATION', 'TRAVELERS_CHECK', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'DENOMINATION', 'MISCELLANEOUS_VOUCHER', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'DENOMINATION', 'MISCELLANEOUS', SYSDATE, 'BASEDATA');
COMMIT;


-- add new tender type categories
DELETE FROM cfg_tender_type_category where organization_id=$(OrgID) and tender_category = 'ADD_NEW_TENDER' and tender_type in ('CURRENCY', 'CREDIT_CARD', 'MISCELLANEOUS');
COMMIT;
  
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'ADD_NEW_TENDER', 'CURRENCY', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'ADD_NEW_TENDER', 'CREDIT_CARD', SYSDATE, 'BASEDATA');
INSERT INTO cfg_tender_type_category(organization_id, tender_category, tender_type, create_date, create_user_id) values ($(OrgID), 'ADD_NEW_TENDER', 'MISCELLANEOUS', SYSDATE, 'BASEDATA');
COMMIT;


-- CUSTOMER
DELETE FROM cfg_code_category WHERE organization_id = $(OrgID) and category_group = 'CUSTOMER' and category IN ('ADDRESS_TYPE', 'CUST_ACCOUNT_STATE', 'CUSTOMER_CONTACT_PREF', 'CUSTOMER_GROUPS', 'GENDER', 'GIFT_REGISTRY_ADDRESS_TYPE', 'GIFT_REGISTRY_EVENT_TYPE', 'MARITAL_STATUS', 'ORGANIZATION_TYPE', 'PARTY_PROPERTY_DISPLAY');
COMMIT;

INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'CUSTOMER', 'ADDRESS_TYPE', 0, '_addressType', '_addressTypeComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'CUSTOMER', 'CUST_ACCOUNT_STATE', 0, '_customerAccountStatus', '_customerAccountStatusComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'CUSTOMER', 'CUSTOMER_CONTACT_PREF', 0, '_customerContactPreference', '_customerContactPreferenceComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'CUSTOMER', 'CUSTOMER_GROUPS', 0, '_customerGroups', '_customerGroupsComment', 1, 1, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'CUSTOMER', 'GENDER', 0, '_customerGender', '_customerGenderComment', 1, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'CUSTOMER', 'GIFT_REGISTRY_ADDRESS_TYPE', 0, '_giftRegistryAddressType', '_giftRegistryAddressTypeComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'CUSTOMER', 'GIFT_REGISTRY_EVENT_TYPE', 0, '_giftRegistryEventType', '_giftRegistryEventTypeComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'CUSTOMER', 'MARITAL_STATUS', 0, '_customerMaritalStatus', '_customerMaritalStatusComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'CUSTOMER', 'ORGANIZATION_TYPE', 0, '_customerOrganizationType', '_customerOrganizationTypeComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'CUSTOMER', 'PARTY_PROPERTY_DISPLAY', 0, '_customerPartyPropertyDisplay', '_customerPartyPropertyDisplayComment', 0, 0, SYSDATE, 'BASEDATA');
COMMIT;


-- EMPLOYEE
DELETE FROM cfg_code_category WHERE organization_id = $(OrgID) and category_group = 'EMPLOYEE' and category IN ('EMPLOYEE_CHALLENGE', 'EMPLOYEE_GROUP', 'EMPLOYEE_ROLE', 'EMPLOYEE_STATUS', 'EMPLOYEE_TASK_TYPE', 'EMPLOYEE_TYPE', 'PAY_STATUS', 'RESTRICTED_TASK_TYPE', 'EMPLOYEE_TASK_VISIBILITY');
COMMIT;

INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EMPLOYEE', 'EMPLOYEE_CHALLENGE', 0, '_employeeChallengeQuestions', '_employeeChallengeQuestionsComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EMPLOYEE', 'EMPLOYEE_GROUP', 0, '_employeeGroup', '_employeeGroupComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EMPLOYEE', 'EMPLOYEE_ROLE', 0, '_employeeRole', '_employeeRoleComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EMPLOYEE', 'EMPLOYEE_STATUS', 0, '_employeeStatus', '_employeeStatusComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EMPLOYEE', 'EMPLOYEE_TASK_TYPE', 0, '_employeeTaskType', '_employeeTaskTypeComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EMPLOYEE', 'EMPLOYEE_TASK_VISIBILITY', 0, '_employeeTaskVisibility', '_employeeTaskVisibilityComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EMPLOYEE', 'RESTRICTED_TASK_TYPE', 0, '_employeeRestrictedTaskType', '_employeeRestrictedTaskTypeComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EMPLOYEE', 'EMPLOYEE_TYPE', 0, '_employeeType', '_employeeTypeComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EMPLOYEE', 'PAY_STATUS', 0, '_employeePayStatus', '_employeePayStatusComment', 0, 0, SYSDATE, 'BASEDATA');
COMMIT;


-- INVENTORY
DELETE FROM cfg_code_category WHERE organization_id = $(OrgID) and category_group = 'INVENTORY' and category IN ('INVENTORY_ACTION_CODES', 'INV_BUCKET', 'INV_BUCKET_SYSTEM', 'INV_BUCKET_TRACKING_METHOD', 'INVENTORY_LOCATOR_DISTANCES', 'ITEM_GROUP', 'ITEM_MATRIX_COLOR_CLASS', 'ITEM_MATRIX_COLOR_DEPT', 'ITEM_MATRIX_COLOR_ITEM', 'ITEM_MATRIX_COLOR_SUBDEPT', 'ITEM_MATRIX_COLOR_SUBCLASS', 'ITEM_PROP_GROUP');
COMMIT;

INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'INVENTORY', 'INVENTORY_ACTION_CODES', 0, '_inventoryActionCodes', '_inventoryActionCodesComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'INVENTORY', 'INV_BUCKET', 0, '_inventoryBucketType', '_inventoryBucketTypeComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'INVENTORY', 'INV_BUCKET_SYSTEM', 0, '_inventoryBucketSystem', '_inventoryBucketSystemComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'INVENTORY', 'INV_BUCKET_TRACKING_METHOD', 0, '_inventoryBucketTrackingMethod', '_inventoryBucketTrackingMethodComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'INVENTORY', 'ITEM_GROUP', 0, '_inventoryItemGroup', '_inventoryItemGroupComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'INVENTORY', 'ITEM_MATRIX_COLOR_CLASS', 0, '_itemMatrixColorClass', '_itemMatrixColorClassComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'INVENTORY', 'ITEM_MATRIX_COLOR_DEPT', 0, '_itemMatrixColorDepartment', '_itemMatrixColorDepartmentComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'INVENTORY', 'ITEM_MATRIX_COLOR_ITEM', 0, '_itemMatrixColorItem', '_itemMatrixColorItemComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'INVENTORY', 'ITEM_MATRIX_COLOR_SUBDEPT', 0, '_itemMatrixColorSubDepartment', '_itemMatrixColorSubDepartmentComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'INVENTORY', 'ITEM_MATRIX_COLOR_SUBCLASS', 0, '_itemMatrixColorSubClass', '_itemMatrixColorSubClassComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'INVENTORY', 'ITEM_PROP_GROUP', 1, '_itemPropertyGroup', '', 0, 0, SYSDATE, 'BASEDATA');
COMMIT;


-- EXTENDED_TRANSACTION
DELETE FROM cfg_code_category WHERE organization_id = $(OrgID) and category_group = 'EXTENDED_TRANSACTION' and category IN ('INSURANCE_PLAN', 'MODULE_NAME', 'PRIVATE_CREDIT_ACCOUNT_TYPE', 'PRIVATE_CREDIT_PRIMARY_ID_TYPE', 'PRIVATE_CREDIT_SECOND_ID_TYPE', 'WORK_ORDER_PRIORITIES', 'LOCATE_ITEM_DISTANCES');
COMMIT;

INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EXTENDED_TRANSACTION', 'INSURANCE_PLAN', 0, '_extTransInsurancePlan', '_extTransInsurancePlanComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EXTENDED_TRANSACTION', 'MODULE_NAME', 0, '_extTransModuleName', '_extTransModuleNameComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EXTENDED_TRANSACTION', 'PRIVATE_CREDIT_ACCOUNT_TYPE', 0, '_extTransPrivateCreditAccountType', '_extTransPrivateCreditAccountTypeComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EXTENDED_TRANSACTION', 'PRIVATE_CREDIT_PRIMARY_ID_TYPE', 0, '_extTransPrivateCreditPrimaryType', '_extTransPrivateCreditPrimaryTypeComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EXTENDED_TRANSACTION', 'PRIVATE_CREDIT_SECOND_ID_TYPE', 0, '_extTransPrivateCreditSecondTypeId', '_extTransPrivateCreditSecondTypeIdComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EXTENDED_TRANSACTION', 'WORK_ORDER_PRIORITIES', 0, '_extTransWorkOrderPriorities', '_extTransWorkOrderPrioritiesComment', 0, 0, SYSDATE, 'BASEDATA');
INSERT INTO cfg_code_category (organization_id, category_group, category, internal_flag, description, comments, uses_image_url, uses_rank, create_date, create_user_id)
values ($(OrgID), 'EXTENDED_TRANSACTION', 'LOCATE_ITEM_DISTANCES', 0, '_extTransLocateItemDistances', '_extTransLocateItemDistancesComment', 0, 0, SYSDATE, 'BASEDATA');
COMMIT;


-- REASON_CODE_TYPES
DELETE FROM cfg_reason_code_type WHERE organization_id = $(OrgID);
COMMIT;

INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'CHANGE_FLOAT', '_reasonCodeType_CHANGE_FLOAT', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'DISCOUNT', '_reasonCodeType_DISCOUNT', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'INVENTORY_ADJUSTMENT', '_reasonCodeType_INVENTORY_ADJUSTMENT', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'ITEM_TRANSFER', '_reasonCodeType_ITEM_TRANSFER', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'NO_SALE', '_reasonCodeType_NO_SALE', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'ORDER_CANCEL', '_reasonCodeType_ORDER_CANCEL', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'ORDER_CANCEL_BACKOFFICE', '_reasonCodeType_ORDER_CANCEL_BACKOFFICE', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'ORDER_REJECT', '_reasonCodeType_ORDER_REJECT', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'PAID_IN', '_reasonCodeType_PAID_IN', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'PAID_OUT', '_reasonCodeType_PAID_OUT', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'PAYMENT_REVERSAL', '_reasonCodeType_PAYMENT_REVERSAL', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'POST_VOID', '_reasonCodeType_POST_VOID', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'PRICE_CHANGE', '_reasonCodeType_PRICE_CHANGE', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'REPLENISHMENT_HEADER', '_reasonCodeType_REPLENISHMENT_HEADER', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'REPLENISHMENT_ITEM', '_reasonCodeType_REPLENISHMENT_ITEM', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'RETURN', '_reasonCodeType_RETURN', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'TAX_CHANGE', '_reasonCodeType_TAX_CHANGE', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'TAX_EXEMPT', '_reasonCodeType_TAX_EXEMPT', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'TILL_COUNT_DISCREPANCY', '_reasonCodeType_TILL_COUNT_DISCREPANCY', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'TIME_OFF_REAS_CODE', '_reasonCodeType_TIME_OFF_REAS_CODE', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'TRANSACTION_CANCEL', '_reasonCodeType_TRANSACTION_CANCEL', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'VOID_LINE_ITEM', '_reasonCodeType_VOID_LINE_ITEM', SYSDATE, 'BASEDATA');
INSERT INTO cfg_reason_code_type (organization_id, reason_code_type, description, create_date, create_user_id) VALUES ($(OrgID), 'CUSTOMER_NOT_PRESENT_PAYMENT', '_reasonCodeType_CUSTOMER_NOT_PRESENT_PAYMENT', SYSDATE, 'BASEDATA');
COMMIT;


-- ocds_subtask_details
Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'RETAIL_LOCATION' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'RETAIL_LOCATION', '2_retailLoc', '1', '0', 'ALL', 'STORE_CLOSE','0', 'RETAIL_LOCATION', '/v1/location/retailstore', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'ORG_HIERARCHY' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'ORG_HIERARCHY', '1_orgHier', '1', '0', 'ALL', 'STORE_CLOSE','0', 'ORG_HIERARCHY', '/v1/orghier', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'MERCH_HIERARCHY' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'MERCH_HIERARCHY', '2_merchHier', '0', '0', 'ALL', 'STORE_CLOSE','0', 'MERCH_HIERARCHY', '/v1/merchhier', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'ENTERPRISE_ITEM' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'ENTERPRISE_ITEM', '3_itemCorp', '0', '0', 'XCENTER_ONLY', null,'0', 'ITEM', '/v2/item', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'ITEM' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'ITEM', '3_item', '0', '1', 'XSTORE_ONLY', 'STORE_CLOSE','0', 'ITEM', '/v2/item', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'ITEM_UPC' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'ITEM_UPC', '3_itemUPC', '0', '1', 'XSTORE_ONLY', 'STORE_CLOSE','0', 'ITEM', '/v2/item/upc', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'ENTERPRISE_ITEM_LOC' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'ENTERPRISE_ITEM_LOC', '4_itemLocCorp', '0', '1', 'XCENTER_ONLY', null,'0', 'ITEM', '/v2/item/itemlocation', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'ITEM_LOC' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'ITEM_LOC', '4_itemLoc', '0', '1', 'ALL', 'STORE_CLOSE','0', 'ITEM', '/v2/item/itemlocation', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'RELATED_ITEM' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'RELATED_ITEM', '4_relatedItem', '0', '1', 'ALL', 'STORE_CLOSE','0', 'RELATED_ITEM', '/v1/item/relateditem', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'DIMENSION_TYPE' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'DIMENSION_TYPE', '2_dimensionType', '0', '0', 'ALL', 'STORE_CLOSE','0', 'DIMENSION', '/v1/item/dimensiontype', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'DIMENSION_VALUE' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'DIMENSION_VALUE', '2_dimensionValue', '0', '0', 'ALL', 'STORE_CLOSE','0', 'DIMENSION', '/v2/item/dimensionvalue', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'PRICE' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'PRICE', '5_price', '0', '1', 'ALL', 'IMMEDIATE','1', 'PRICE', '/v2/item/price?pricetype=INITIAL', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'REGULAR_PRICE_CHANGE' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'REGULAR_PRICE_CHANGE', '5_regpc', '0', '1', 'ALL', 'IMMEDIATE','1', 'PRICE', '/v2/item/price?pricetype=REGULAR', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'CLEARANCE_PRICE_CHANGE' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'CLEARANCE_PRICE_CHANGE', '5_clrpc', '0', '1', 'ALL', 'IMMEDIATE','1', 'PRICE', '/v2/item/price?pricetype=CLEARANCE', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'PROMOTION' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'PROMOTION', '5_promo', '0', '1', 'XSTORE_ONLY', 'STORE_CLOSE','0', 'PROMOTION', '/v1/item/promotion', SYSDATE, 'BASEDATA');
end if;
end;
/


Declare v_exists NUMBER(1,0);
begin
SELECT DECODE(COUNT(*),0,0,1) INTO v_exists FROM ocds_subtask_details where subtask_id = 'VAT' and organization_id = $(OrgID);
IF v_exists = 0 THEN 

INSERT INTO ocds_subtask_details (organization_id, subtask_id, filename_prefix, query_by_chain, query_by_org_node, destination, download_time, apply_immediately, family, path, create_date, create_user_id) VALUES ($(OrgID), 'VAT', '2_vat', '0', '0', 'ALL', 'STORE_CLOSE','0', 'VAT', '/v1/vat', SYSDATE, 'BASEDATA');
end if;
end;
/


DELETE FROM ocds_subtask_details where subtask_id = 'ITEM_NODE' and organization_id = $(OrgID);
-- Set path values for ocds_subtasks_details for RICS-based OCDS
UPDATE ocds_subtask_details SET path = '/v1/location/retailstore' where subtask_id = 'RETAIL_LOCATION';
UPDATE ocds_subtask_details SET path = '/v1/orghier' where subtask_id = 'ORG_HIERARCHY';
UPDATE ocds_subtask_details SET path = '/v1/merchhier' where subtask_id = 'MERCH_HIERARCHY';
UPDATE ocds_subtask_details SET path = '/v2/item' where subtask_id = 'ENTERPRISE_ITEM';
UPDATE ocds_subtask_details SET path = '/v2/item' where subtask_id = 'ITEM';
UPDATE ocds_subtask_details SET path = '/v2/item/upc' where subtask_id = 'ITEM_UPC';
UPDATE ocds_subtask_details SET path = '/v2/item/itemlocation' where subtask_id = 'ENTERPRISE_ITEM_LOC';
UPDATE ocds_subtask_details SET path = '/v2/item/itemlocation' where subtask_id = 'ITEM_LOC';
UPDATE ocds_subtask_details SET path = '/v1/item/relateditem' where subtask_id = 'RELATED_ITEM';
UPDATE ocds_subtask_details SET path = '/v1/item/dimensiontype' where subtask_id = 'DIMENSION_TYPE';
UPDATE ocds_subtask_details SET path = '/v2/item/dimensionvalue' where subtask_id = 'DIMENSION_VALUE';
UPDATE ocds_subtask_details SET path = '/v2/item/price?pricetype=INITIAL' where subtask_id = 'PRICE';
UPDATE ocds_subtask_details SET path = '/v2/item/price?pricetype=REGULAR' where subtask_id = 'REGULAR_PRICE_CHANGE';
UPDATE ocds_subtask_details SET path = '/v2/item/price?pricetype=CLEARANCE' where subtask_id = 'CLEARANCE_PRICE_CHANGE';
UPDATE ocds_subtask_details SET path = '/v1/item/promotion' where subtask_id = 'PROMOTION';
UPDATE ocds_subtask_details SET path = '/v1/vat' where subtask_id = 'VAT';
COMMIT;


-- **************************************************** --
-- * Always keep Default User Creation at end of file * --
-- **************************************************** --
-- DEFAULT USER
-- Since this file is copied and used when creating organizations through the Xadmin UI, the default users that were created
-- here have been moved to their own file, dataupdate-orgspecific-user.sql, so that the default users will only be created by
-- creating a new database and now when a new organization is created through the Xadmin UI

-- Always rebuild the Administrator role so that any new privileges that were added automatically get assigned.
  DELETE FROM cfg_role WHERE role_id = 'ADMINISTRATOR' and organization_id = $(OrgID);
COMMIT;

  INSERT INTO cfg_role (organization_id, role_id, role_desc, system_role_flag, xadmin_rank, xstore_rank, create_date, create_user_id) VALUES ( $(OrgID), 'ADMINISTRATOR', 'Administrator', 1, 150, 150, SYSDATE, 'BASEDATA');

  DELETE FROM cfg_role_privilege WHERE role_id = 'ADMINISTRATOR' and organization_id = $(OrgID) and privilege_id NOT IN ('ADMN_STORE_AUTH_MANAGER','ADMN_STORE_ENROLL', 'ADMN_XOFFICE_CS_STORE_ENROLL', 'ADMN_CREDENTIALS_STORAGE');
COMMIT;

  INSERT INTO cfg_role_privilege (organization_id, role_id, privilege_id, create_date, create_user_id)
  SELECT $(OrgID), 'ADMINISTRATOR', privilege_id, SYSDATE, 'BASEDATA' FROM cfg_privilege WHERE privilege_id NOT IN ('ADMN_STORE_AUTH_MANAGER','ADMN_STORE_ENROLL', 'ADMN_XOFFICE_CS_STORE_ENROLL', 'ADMN_CREDENTIALS_STORAGE');
COMMIT;


-- Always rebuild the Receipt viewer for XBRi role so that any new privileges that were added automatically gets assigned.
  DELETE FROM cfg_role WHERE role_id = 'ReceiptViewer' and organization_id = $(OrgID);
COMMIT;

  INSERT INTO cfg_role (organization_id, role_id, role_desc, system_role_flag, xadmin_rank, xstore_rank, create_date, create_user_id) VALUES ( $(OrgID), 'ReceiptViewer', 'Receipt Viewer/Electronic Journal Access', 0, 100, 100, SYSDATE, 'BASEDATA');

  DELETE FROM cfg_role_privilege WHERE role_id = 'ReceiptViewer' and organization_id = $(OrgID);
COMMIT;

  INSERT INTO cfg_role_privilege (organization_id, role_id, privilege_id, create_date, create_user_id) VALUES ( $(OrgID), 'ReceiptViewer', 'SPT_EJOURNAL', SYSDATE, 'BASEDATA');
  INSERT INTO cfg_role_privilege (organization_id, role_id, privilege_id, create_date, create_user_id) VALUES ( $(OrgID), 'ReceiptViewer', 'BASIC_ACCESS', SYSDATE, 'BASEDATA');
COMMIT;


  DELETE FROM cfg_alert_severity_threshold WHERE alert_type = 'MISTORE_CRASH' and organization_id = $(OrgID);
COMMIT;

  DELETE FROM cfg_alert_severity_threshold WHERE alert_type = 'MISTORE_LOW_MEMORY' and organization_id = $(OrgID);
COMMIT;

