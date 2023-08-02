-------------------------------------------------------------------------------------------------------------------
--
-- Procedure         : SP_NAME
-- Description       : 
-- Author            : 
-- Version           : 4.0
-------------------------------------------------------------------------------------------------------------------
--                            CHANGE HISTORY                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- WHO DATE      DESCRIPTION                                                                                     --
-------------------------------------------------------------------------------------------------------------------
-- ... .....         Initial Version
-- 
-------------------------------------------------------------------------------------------------------------------
EXEC DBMS_OUTPUT.PUT_LINE('DTV.SP_NAME');


CREATE OR REPLACE PROCEDURE DTV.SP_NAME 
  ( 
   ) 
IS

END SP_NAME;
/

GRANT EXECUTE ON DTV.SP_NAME TO posusers;
GRANT EXECUTE ON DTV.SP_NAME TO dbausers;

 
BEGIN
    FOR l_rec IN (SELECT table_name 
                      FROM all_synonyms
                      WHERE owner = 'PUBLIC'
                        AND table_owner = 'DTV'
                        AND TABLE_NAME = 'SP_NAME'
)
    loop
        EXECUTE IMMEDIATE 'DROP PUBLIC SYNONYM SP_NAME';
        DBMS_OUTPUT.PUT_LINE('Synonym dropped.');
    end loop;
end;
/

CREATE PUBLIC SYNONYM SP_NAME for DTV.SP_NAME;
