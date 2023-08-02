
INSERT INTO ctl_version_history (
    organization_id, seq, base_schema_version, customer_schema_version, base_schema_date, 
    create_user_id, create_date, update_user_id, update_date)
VALUES (
    $(OrgID), CTL_VERSION_HISTORY_SEQUENCE.NEXTVAL, '22.0.0.0.20230127185818', '0.0.0 - 0.0', SYSDATE, 
    'Oracle', SYSDATE, 'Oracle', SYSDATE);

COMMIT;
