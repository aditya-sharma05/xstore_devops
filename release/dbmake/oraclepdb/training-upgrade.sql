-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : SP_IMPORT_DATABASE
-- Description       : This procedure is called on the local database to import all of the XStore objects onto a
--                      secondary register or for the local training databases.  It procedure will drop all of the 
--                      procedures, triggers, views, sequences and functions owned by the target owner.  If this a 
--                      production database the public synonyms are also dropped.
-- Version           : 19.0
--
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... ..........         Initial Version
-- PGH 03/17/2010   Added the two parameters and logic to drop public synonyms
-- PGH 03/26/2010   Rewritten the procedure to execute the datadump import via SQL calls instead of the command
--                  line utility.  The procedures now does pre, import and post steps.
-- PGH 08/30/2010   Add a line to ignore the ctl_replication_queue, because there are two copies of this table and
--                  the synoym should not be owned by DTV.
-- BCW 09/08/2015   Changed the public synonyms to user synonyms.
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING FUNCTION SP_IMPORT_DATABASE');

CREATE OR REPLACE FUNCTION SP_IMPORT_DATABASE 
(  
    argImportPath              varchar2,                   -- Import Directory Name
    argProd                    varchar2,                   -- Import Type: PRODUCTION / TRAINING
    argBackupDataFile          varchar2,                   -- Dump File Name
    argOutputFile              varchar2,                   -- Log File Name
    argSourceOwner             varchar2,                   -- Source Owner User Name
    argTargetOwner             varchar2,                   -- Target Owner User Name
    argSourceTablespace        varchar2,                   -- Source Data Tablespace Name
    argTargetTablespace        varchar2,                   -- Target Data Tablespace Name
    argSourceIndexTablespace   varchar2,                   -- Source Index Tablespace Name
    argTargetIndexTablespace   varchar2                    -- Target Index Tablespace Name
)
RETURN INTEGER
IS

sqlStmt                 VARCHAR2(512);
ls_object_type          VARCHAR2(30);
ls_object_name          VARCHAR2(128);
err_count               NUMBER := 0;
status_message          VARCHAR2(30);

-- Varaibles for the Datapump section
h1                      NUMBER;         -- Data Pump job handle
job_state               VARCHAR2(30);   -- To keep track of job state
ind                     NUMBER;         -- loop index
le                      ku$_LogEntry;   -- WIP and error messages
js                      ku$_JobStatus;  -- job status from get_status
jd                      ku$_JobDesc;    -- job description from get_status
sts                     ku$_Status;     -- status object returned by 
rowcnt                  NUMBER;


CURSOR OBJECT_LIST (v_owner  VARCHAR2) IS
SELECT object_type, object_name
  FROM all_objects
  WHERE object_type IN ('PROCEDURE', 'TRIGGER', 'VIEW', 'SEQUENCE', 'FUNCTION', 'TABLE', 'TYPE')
    AND object_name != 'SP_IMPORT_DATABASE'
    AND object_name != 'SP_WRITE_DBMS_OUTPUT_TO_FILE'
    AND object_name != 'CTL_REPLICATION_QUEUE'
    AND owner = v_owner;

BEGIN

    -- Enable Server Output
    DBMS_OUTPUT.ENABLE (buffer_size => NULL);
    DBMS_OUTPUT.PUT_LINE (user || ' is starting SP_IMPORT_DATABASE.');
    sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
    
    --
    -- Checks to see if the Data Pump work table exists and drops it.
    --
    select count(*)
        into rowcnt
        from all_tables
        where owner = upper('$(DbSchema)')
          and table_name = 'XSTORE_IMPORT';
          
    IF rowcnt > 0 THEN
        EXECUTE IMMEDIATE 'DROP TABLE XSTORE_IMPORT';
    END IF;

    -- 
    -- Validate the first parameter is either 'PRODUCTION' OR 'TRAINING', if not raise an error
    --
    IF argProd != 'PRODUCTION' AND argProd != 'TRAINING' THEN
        dbms_output.put_line ('Parameter: argProd - Must be PRODUCTION OR TRAINING');
        Raise_application_error(-20001 , 'Parameter: argProd - Must be PRODUCTION OR TRAINING');
    END IF;

    --
    -- Drops all of the user's objects
    --
    BEGIN
    OPEN OBJECT_LIST (argTargetOwner);
      
    LOOP 
      BEGIN
        FETCH OBJECT_LIST INTO ls_object_type, ls_object_name;
        EXIT WHEN OBJECT_LIST%NOTFOUND;
        
        -- Do not drop the tables, they will be dropped by datapump.
        IF ls_object_type != 'TABLE' THEN
            IF ls_object_type = 'SEQUENCE' AND ls_object_name LIKE '%ISEQ$$%' THEN
              dbms_output.put_line ('FOUND A SYSTEM GENERATED SEQ ' || ls_object_name ||' WILL NOT DROP IT.');
            ELSE
              sqlstmt := 'DROP '|| ls_object_type ||' '|| argTargetOwner || '.' || ls_object_name;
              dbms_output.put_line (sqlstmt);
            END IF;
            IF sqlStmt IS NOT NULL THEN
                  EXECUTE IMMEDIATE sqlStmt;
            END IF;
        END IF;
      EXCEPTION
         WHEN OTHERS THEN
         BEGIN
         DBMS_OUTPUT.PUT_LINE('Error: '|| SQLERRM);
         sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
         err_count := err_count + 1;
         END;
      END;  
    END LOOP;
    CLOSE OBJECT_LIST;
    sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
    EXCEPTION
         WHEN OTHERS THEN
         BEGIN
         CLOSE OBJECT_LIST;
         DBMS_OUTPUT.PUT_LINE('Error: '|| SQLERRM);
         sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
         err_count := err_count + 1;
         END;
    END;  

    --
    -- Import the schema objects using Datapump DBMS package
    -- This is a code block to handel exceptions from Datapump
    --

    BEGIN
            --
        -- Performs a schema level import for the Xstore objects
        --
        h1 := DBMS_DATAPUMP.OPEN('IMPORT','SCHEMA',NULL,'XSTORE_IMPORT','LATEST');
        DBMS_DATAPUMP.METADATA_FILTER(h1, 'SCHEMA_EXPR', 'IN ('''|| argSourceOwner || ''')');

        --
        -- Adds the data and log files
        --
        DBMS_DATAPUMP.ADD_FILE(h1, argBackupDataFile, argImportPath, NULL, DBMS_DATAPUMP.KU$_FILE_TYPE_DUMP_FILE);
        DBMS_DATAPUMP.ADD_FILE(h1, argOutputFile, argImportPath, NULL, DBMS_DATAPUMP.KU$_FILE_TYPE_LOG_FILE);
        
        --
        -- Parameters for the import
        --  1) Do not create user
        --  2) Drop table if they exists
        --  3) Collect metrics as time taken to process object(s)
        --  4) Exclude procedure SP_PREP_FOR_IMPORT
        --  5) If Training, exclude grants
        --  6) Remap Schema
        --  7) Remap Tablespace
        --  8) Inhibit the assignment of the exported OID,a new OID will be assigned.
        --
        --DBMS_DATAPUMP.SET_PARAMETER(h1, 'USER_METADATA', 0);
        DBMS_DATAPUMP.SET_PARAMETER(h1, 'TABLE_EXISTS_ACTION', 'REPLACE');
        DBMS_DATAPUMP.SET_PARAMETER(h1, 'METRICS', 1);
        DBMS_DATAPUMP.METADATA_REMAP(h1, 'REMAP_SCHEMA', argSourceOwner, argTargetOwner);
        DBMS_DATAPUMP.METADATA_FILTER(h1,'NAME_EXPR','!=''SP_IMPORT_DATABASE''', 'FUNCTION');
        DBMS_DATAPUMP.METADATA_FILTER(h1,'NAME_EXPR','!=''SP_WRITE_DBMS_OUTPUT_TO_FILE''', 'PROCEDURE');
        DBMS_DATAPUMP.METADATA_FILTER(h1,'NAME_EXPR','!=''$(DbUser)''', 'USER');
        DBMS_DATAPUMP.METADATA_FILTER(h1,'NAME_EXPR','!=''TRAINING''', 'USER');
        DBMS_DATAPUMP.METADATA_TRANSFORM(h1,'OID',0, 'TYPE');
        IF upper(argProd) = 'TRAINING' THEN
            DBMS_DATAPUMP.METADATA_FILTER(h1, 'EXCLUDE_PATH_EXPR', 'like''%GRANT%''');
        END IF;
        
        DBMS_DATAPUMP.METADATA_REMAP(h1, 'REMAP_TABLESPACE', argSourceTablespace, argTargetTablespace); 
        DBMS_DATAPUMP.METADATA_REMAP(h1, 'REMAP_TABLESPACE', argSourceIndexTablespace, argTargetIndexTablespace); 

        --
        -- Start the job. An exception will be generated if something is not set up
        -- properly.
        --
        dbms_output.put_line('Starting datapump job');
        DBMS_DATAPUMP.START_JOB(h1);

        --
        -- Waits until the job as completed
        --
        DBMS_DATAPUMP.WAIT_FOR_JOB (h1, job_state);

        dbms_output.put_line('Job has completed');
        dbms_output.put_line('Final job state = ' || job_state);

        dbms_datapump.detach(h1);
      sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
      BEGIN
        sqlstmt := 'PURGE RECYCLEBIN';
        EXECUTE IMMEDIATE sqlstmt;
        DBMS_OUTPUT.PUT_LINE(sqlstmt || ' executed');
        sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
      END;
    EXCEPTION
        WHEN OTHERS THEN
        BEGIN
            dbms_datapump.get_status(h1, 
                                        dbms_datapump.ku$_status_job_error, 
                                        -1, 
                                        job_state, 
                                        sts);
            js := sts.job_status;
            le := sts.error;
            IF le IS NOT NULL THEN
              ind := le.FIRST;
              WHILE ind IS NOT NULL LOOP
                dbms_output.put_line(le(ind).LogText);
                ind := le.NEXT(ind);
              END LOOP;
            END IF;
            
            DBMS_DATAPUMP.STOP_JOB (h1, -1, 0, 0);
            dbms_datapump.detach(h1);
        sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
          DBMS_OUTPUT.DISABLE ();
            --Raise_application_error(-20002 , 'Datapump: Data Import Failed');
            return -1;
        END;
    END;  
    
    status_message :=
      CASE err_count
         WHEN 0 THEN 'successfully.'
         ELSE 'with ' || err_count || ' errors.'
      end;
    DBMS_OUTPUT.PUT_LINE (user || ' has executed SP_IMPORT_DATABASE '|| status_message);
    sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
 
    DBMS_OUTPUT.DISABLE ();

    return 0;
EXCEPTION
    WHEN OTHERS THEN
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        err_count := err_count + 1;
        DBMS_OUTPUT.PUT_LINE (user || ' has executed SP_IMPORT_DATABASE with ' || err_count || ' errors.');
        sp_write_dbms_output_to_file('SP_IMPORT_DATABASE');
        DBMS_OUTPUT.DISABLE ();
        RETURN -1;
    END;
END;
/

GRANT EXECUTE ON SP_IMPORT_DATABASE TO dbausers;


-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : SP_WRITE_DBMS_OUTPUT_TO_FILE
-- Description       : 
-- Version           : 19.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....         Initial Version
-------------------------------------------------------------------------------------------------------------------

EXEC DBMS_OUTPUT.PUT_LINE('--- CREATING PROCEDURE sp_write_dbms_output_to_file');

create or replace PROCEDURE sp_write_dbms_output_to_file(logname varchar) AS
   l_line VARCHAR2(255);
   l_done NUMBER;
   l_file utl_file.file_type;
   ext NUMBER;
BEGIN
   ext := INSTR(logname,'.', 1);
   if ext = 0 then
    l_file := utl_file.fopen('EXP_DIR', logname || '.log', 'A');
   else
    l_file := utl_file.fopen('EXP_DIR', logname, 'A');
   end if;
   LOOP
      dbms_output.get_line(l_line, l_done);
      EXIT WHEN l_done = 1;
      utl_file.put_line(l_file, substr(to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS,FF'),1,23) || ' ' || l_line);
   END LOOP;
   utl_file.fflush(l_file);
   utl_file.fclose(l_file);
END sp_write_dbms_output_to_file;
/

GRANT EXECUTE ON sp_write_dbms_output_to_file TO posusers,dbausers;

 
