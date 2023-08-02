::@ECHO OFF
setlocal
set SCRIPT_DIRECTORY=%~dp0
for %%B in (%SCRIPT_DIRECTORY%.) do set ENVIRONMENT_DIRECTORY=%%~dpB
for %%B in (%ENVIRONMENT_DIRECTORY%.) do set ROOT_DIRECTORY=%%~dpB

set LOG_DIR=%ENVIRONMENT_DIRECTORY%\..\xstoredata\environment\log
set LOG_FILE_NAME=update_jre.log
set LOG_FILE=%LOG_DIR%\%LOG_FILE_NAME%

pushd %LOG_DIR%
erase /q %LOG_FILE_NAME%.005
ren %LOG_FILE_NAME%.004 %LOG_FILE_NAME%.005
ren %LOG_FILE_NAME%.003 %LOG_FILE_NAME%.004
ren %LOG_FILE_NAME%.002 %LOG_FILE_NAME%.003
ren %LOG_FILE_NAME%.001 %LOG_FILE_NAME%.002
ren %LOG_FILE_NAME% %LOG_FILE_NAME%.001
popd
call ext\update_jre.bat > %LOG_FILE% 2>&1
endlocal