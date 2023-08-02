-- ***************************************************************************
-- XOCS Upgrade Pre Script
-- This script should run before the upgrade script 
--
-- Product:         XStore
-- Version:         23.0.0
-- DB platform:     Oracle 19c
-- ***************************************************************************

SET SERVEROUTPUT ON SIZE 100000
SPOOL cloud-upgrade-pre.log;

EXEC DBMS_OUTPUT.put_line('--- XOCS Pre Upgrade Script ---');
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

EXEC DBMS_OUTPUT.put_line('...Disabling Xcenter Report Job');
DECLARE
   v_job_exists number;
BEGIN
   SELECT count(*) into v_job_exists
   FROM all_scheduler_jobs
   WHERE owner = 'XCENTER_USER_1' AND job_name = 'REPORT_JOB';
   IF v_job_exists = 1 THEN
      DBMS_SCHEDULER.disable(name=>'"XCENTER_USER_1"."REPORT_JOB"');
      DBMS_OUTPUT.put_line('...XCENTER_USER_1.REPORT_JOB is disabled.');
   END IF;
END;
/
COMMIT;

-- ***************************************************************************

SPOOL OFF
SET SERVEROUTPUT OFF
