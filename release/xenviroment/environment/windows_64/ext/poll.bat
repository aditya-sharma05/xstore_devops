@ECHO OFF
TITLE Polling
if "%1"=="REPOLL" GOTO %1
if "%1"=="CLOSE1" GOTO %1
if "%1"=="CLOSE2" GOTO %1
if "%1"=="TRICKLE" GOTO %1
GOTO :EOF

:CLOSE1
REM Insert POLL1 logic here.

GOTO :EOF

:CLOSE2
REM Insert POLL2 logic here.

GOTO :EOF

:REPOLL
REM Insert REPOLL logic here.

GOTO :EOF

:TRICKLE
REM Insert TRICKLE logic here.

GOTO :EOF
