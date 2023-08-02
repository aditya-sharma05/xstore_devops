::@ECHO OFF
setlocal

IF "%selfWrapped%"=="" (
  SET selfWrapped=true
  %ComSpec% /s /c ""%~0" %*"
  GOTO :EOF
)

:: Copies a new JRE into place.  Expects a decompressed JRE directory that can simply be moved into place.
::

set SCRIPT_DIRECTORY=%~dp0
for %%B in (%SCRIPT_DIRECTORY%.) do set ENVIRONMENT_DIRECTORY=%%~dpB
for %%B in (%ENVIRONMENT_DIRECTORY%.) do set ROOT_DIRECTORY=%%~dpB
SET ENV_DATA_DIR=%ENVIRONMENT_DIRECTORY%..\xstoredata\environment
set JRE_DIRECTORY=%ROOT_DIRECTORY%jre
set JAVA_HOME=%JRE_DIRECTORY%
set JRE_UPDATE_DIRECTORY=%ENV_DATA_DIR%\jre_update
set PREVIOUS_JRE_DIRECTORY=%ENV_DATA_DIR%\jre_previous
set ENV_MARKER_DIRECTORY=%ENV_DATA_DIR%\marker
set ERR_MARKER_FILE=%ENV_MARKER_DIRECTORY%\jre_update.err
set JRE_UPDATE_APPLIED_MARKER=%ENV_MARKER_DIRECTORY%\jre_update_applied.xst
SET ENV_UPDATE_APPLIED_MARKER=%ENV_MARKER_DIRECTORY%\env_upgrade_applied.xst
set ENV_UPDATE_DIRECTORY=%ENV_DATA_DIR%\prestart_updates
set ENV_UPDATE_DIRECTORY_OLD=%ENVIRONMENT_DIRECTORY%prestart_updates
set LOG_DIR=%ENV_DATA_DIR%\log
set LOG_FILE_NAME=update_jre.log
set LOG_FILE=%LOG_DIR%\%LOG_FILE_NAME%

GOTO :START

:HANDLE_ERROR
IF %1 NEQ 0 (
  CALL :LOG %*
  echo JRE update failed > %ERR_MARKER_FILE%
  echo %* >> %ERR_MARKER_FILE%
  exit %1
)
GOTO :EOF

:HANDLE_ROBOCOPY_ERROR
IF %1 GTR 7 (
  CALL :HANDLE_ERROR %*
)
GOTO :EOF

:LOG
echo [%date% %time%] %* >> %LOG_FILE%
GOTO :EOF

:START

DEL /Q %LOG_FILE%

IF NOT DEFINED JRE_UPDATE_DIRECTORY CALL :HANDLE_ERROR 1 JRE Update directory not defined.
IF NOT DEFINED JRE_DIRECTORY CALL :HANDLE_ERROR 1 JRE Update directory not defined.
IF NOT EXIST %JRE_DIRECTORY% CALL :HANDLE_ERROR 1 JRE Directory %JRE_DIRECTORY% does not exist.

ECHO JRE Directory: %JRE_DIRECTORY%
ECHO JRE Update Directory: %JRE_UPDATE_DIRECTORY%

IF NOT EXIST "%JRE_UPDATE_DIRECTORY%" (
  CALL :LOG JRE update directory %JRE_UPDATE_DIRECTORY% does not exist.
  GOTO :XENV_UPGRADE
  GOTO :EOF
)

IF NOT EXIST "%JRE_UPDATE_DIRECTORY%\jre" (
  CALL :LOG No JRE to apply in %JRE_UPDATE_DIRECTORY%\jre.
  GOTO :XENV_UPGRADE
  GOTO :EOF
)

MKDIR "%PREVIOUS_JRE_DIRECTORY%"

CALL :LOG ==========================================
CALL :LOG BACKING UP PREVIOUS JRE
CALL :LOG ==========================================

FOR /D %%i IN (%PREVIOUS_JRE_DIRECTORY%\*) DO RD /S /Q "%%i"
DEL /Q %PREVIOUS_JRE_DIRECTORY%\*.*
XCOPY %JRE_DIRECTORY%\*.* %PREVIOUS_JRE_DIRECTORY% /E /Y

CALL :LOG ==========================================
CALL :LOG INSTALLING NEW JRE
CALL :LOG ==========================================

FOR /D %%i IN (%JRE_DIRECTORY%\*) DO RD /S /Q "%%i"
DEL /Q %JRE_DIRECTORY%\*.*
XCOPY %JRE_UPDATE_DIRECTORY%\jre\*.* %JRE_DIRECTORY% /E /Y

if NOT EXIST %JAVA_HOME%\bin\xenv_eng.exe copy /Y %JRE_DIRECTORY%\bin\java.exe %JAVA_HOME%\bin\xenv_eng.exe
if NOT EXIST %JAVA_HOME%\bin\xenv_ui.exe copy /Y %JRE_DIRECTORY%\bin\java.exe %JAVA_HOME%\bin\xenv_ui.exe

RD /S/Q "%JRE_UPDATE_DIRECTORY%\jre"

IF EXIST "%JRE_UPDATE_DIRECTORY%\jre" (
 CALL :HANDLE_ERROR 1 Unable to delete %JRE_UPDATE_DIRECTORY%\jre!
)
MOVE %JRE_UPDATE_DIRECTORY%\*.applyTrack %ENV_MARKER_DIRECTORY%
echo.>"%JRE_UPDATE_APPLIED_MARKER%"

:XENV_UPGRADE
:: Install any pending Xenvironment updates
CALL :LOG ==========================================
CALL :LOG Looking for Xenvironment upgrades...
CALL :LOG ==========================================

FOR %%I IN (%ENV_UPDATE_DIRECTORY_OLD%\*.jar) DO (
  SET CURRENT_JAR_FILE=%%I
  GOTO PREPAREJAR
)

FOR %%I IN (%ENV_UPDATE_DIRECTORY%\*.jar) DO (
  SET CURRENT_JAR_FILE=%%I
  GOTO PREPAREJAR
)

POPD

GOTO :END

:PREPAREJAR
MKDIR %LOCALAPPDATA%\temp\xenvupgrade
DEL /Q %LOCALAPPDATA%\temp\xenvupgrade\*.*
COPY /Y %ENVIRONMENT_DIRECTORY%\ext\util\sleep.exe %LOCALAPPDATA%\temp\xenvupgrade
CALL :LOG ====================================================================
CALL :LOG Running Xenvironment update %CURRENT_JAR_FILE%
CALL :LOG ====================================================================
MOVE %CURRENT_JAR_FILE% %LOCALAPPDATA%\temp\xenvupgrade
MOVE %CURRENT_JAR_FILE%.applyTrack %ENV_MARKER_DIRECTORY%

echo.>%ENV_UPDATE_APPLIED_MARKER%

FOR %%I IN (%LOCALAPPDATA%\temp\xenvupgrade\*.jar) DO (
  SET JAR_TO_EXECUTE=%%I
  GOTO APPLYJAR
)

:APPLYJAR
CD %LOCALAPPDATA%\temp\xenvupgrade
START %JAVA_HOME%\bin\java -Dreboot.when.finished=true -Ddont.launch.xenvironment=true -jar %JAR_TO_EXECUTE%
del %ENVIRONMENT_DIRECTORY%\tmp\*.anchor
:: Wait until we get killed
::%LOCALAPPDATA%\temp\xenvupgrade\sleep 60
EXIT 11
GOTO :END

DEL /Q "%ERR_MARKER_FILE%"

:END
endlocal

