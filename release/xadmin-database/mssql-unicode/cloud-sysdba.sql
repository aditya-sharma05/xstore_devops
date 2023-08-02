-- Alter XSTORE profile with applicable limits used by other RGBU cloud apps (from RGBU_USERS profile) 
ALTER PROFILE XSTORE LIMIT
   COMPOSITE_LIMIT            UNLIMITED 
   SESSIONS_PER_USER          UNLIMITED 
   CPU_PER_SESSION            UNLIMITED 
   CPU_PER_CALL               UNLIMITED
   LOGICAL_READS_PER_SESSION  UNLIMITED 
   LOGICAL_READS_PER_CALL     UNLIMITED 
   IDLE_TIME                  UNLIMITED
   CONNECT_TIME               UNLIMITED
   PRIVATE_SGA                UNLIMITED
   PASSWORD_LIFE_TIME         365
   PASSWORD_REUSE_TIME        365
   PASSWORD_REUSE_MAX         20
   PASSWORD_LOCK_TIME         1
   PASSWORD_GRACE_TIME        3
   PASSWORD_VERIFY_FUNCTION   ORA12C_VERIFY_FUNCTION;

DECLARE
  v_exist  int;
BEGIN
select count(*) into v_exist from ALL_SCHEDULER_JOBS where owner = upper('$(DbXcenterSchema)') and job_name = upper('REPORT_JOB');
   IF v_exist = 0 THEN
      sys.dbms_scheduler.create_job(
      job_name => '$(DbXcenterSchema).REPORT_JOB',
      job_type => 'PLSQL_BLOCK',
      job_action => '$(DbXcenterSchema).SP_REPORT;',
      repeat_interval => 'FREQ=MINUTELY;INTERVAL = 5; BYSECOND=0',
      start_date => sysdate,
      enabled => true);
      dbms_output.put_line('REPORT_JOB created');
   ELSE
      dbms_output.put_line('REPORT_JOB already exists');
    END IF;
 END;
/
COMMIT;

-- Delete the sp_write_dbms_output_to_file stored procedure
DECLARE
    v_exist  int;
BEGIN
select count(*) into v_exist from dba_objects where object_type = 'PROCEDURE' and object_name = 'SP_WRITE_DBMS_OUTPUT_TO_FILE' AND OWNER = upper('$(DbXcenterSchema)');
   IF v_exist != 0 THEN
      EXECUTE IMMEDIATE ('DROP PROCEDURE $(DbXcenterSchema).SP_WRITE_DBMS_OUTPUT_TO_FILE' ) ;
      dbms_output.put_line('SP_WRITE_DBMS_OUTPUT_TO_FILE Deleted');
   ELSE
      dbms_output.put_line('SP_WRITE_DBMS_OUTPUT_TO_FILE does not exist');
    END IF;
END;
/
COMMIT;

