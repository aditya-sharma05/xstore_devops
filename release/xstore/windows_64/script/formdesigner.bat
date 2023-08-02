@echo off
setlocal

::
:: Java Service Wrapper general startup script
::

::
:: Resolve the real path of the Wrapper.exe
::  For non NT systems, the _REALPATH and _WRAPPER_CONF values
::  can be hard-coded below and the following test removed.
::
:: In the following situations, this batch file may return a non-zero error code.  The codes can be cross-referenced to the following values:
:: 1 - An error code of 1 was returned from Xstore
:: 2 - A parameter that wasn't recognized was provided to the batch file. (see the Usage section for supported options)
:: 3 - The application was detected to have already been running (a pid file existed, and the pid matched a running pid for this application).
::
if "%OS%"=="Windows_NT" goto nt
echo This script only works with NT-based versions of Windows.
goto :eof

:nt
::
:: Find the application home.
::
:: %~dp0 is location of current script under NT
set _REALPATH=%~dp0
for %%B in (%_REALPATH%.) do set ROOT_DIR=%%~dpB
set _WRAPPER_CONF="%_REALPATH%wrapper\conf\formdesigner.conf"
set _WRAPPED_APP=formdesigner
set PLATFORM=windows_64
set _PLATFORMPATH=%_REALPATH%%PLATFORM%\
set JAVA_HOME=%ROOT_DIR%jre
set JAVA=%JAVA_HOME%\bin\formdesigner.exe
set PIDDIR=%_REALPATH%tmp\
set OS_ADDITIONAL_PROP_1=wrapper.java.additional.96=-Dlog.dir.name=../xstoredata/xstore/log/formdesigner

:: Move any JVM crash logs into the log directory.
IF EXIST %~dp0\hs_pid????.log  move %~dp0\hs_pid????.log %~dp0\log

if NOT EXIST %JAVA% copy /Y %JAVA_HOME%\bin\java.exe %JAVA%

for /F %%v in ('echo %1^|findstr "^stop$ ^restart$"') do goto notask

:: Check for Running instances of Application
if not exist %windir%\system32\tasklist.exe goto notask
if not exist %PIDDIR%%_WRAPPED_APP%.java.pid goto notask
for /f "tokens=*" %%a in (%PIDDIR%%_WRAPPED_APP%.java.pid) do set XPID=%%a
tasklist /FI "PID eq %XPID%" |find "%_WRAPPED_APP%.exe"
echo %ERRORLEVEL%
if %ERRORLEVEL% == 0 (
       cls
       ECHO Another Instance of %_WRAPPED_APP% is already running from %_REALPATH%.
       exit 3
       goto :eof
       )
if %ERRORLEVEL% == 1 (
       echo Stale pid file detected, pid file removed.
       del %PIDDIR%%_WRAPPED_APP%.java.pid 
       )
 
:notask

set _DEFAULT_WRAPPER_EXE=%_PLATFORMPATH%bin\wrapper.exe
set _WRAPPER_EXE=%_PLATFORMPATH%bin\formdesigner-wrapper.exe
if NOT EXIST %_WRAPPER_EXE% copy /Y %_DEFAULT_WRAPPER_EXE% %_WRAPPER_EXE%
if NOT EXIST %_WRAPPER_EXE% set _WRAPPER_EXE=%_DEFAULT_WRAPPER_EXE%

PATH=%JAVA_HOME%\bin;%_PLATFORMPATH%lib;%PATH%

if "%1" == "" (
  set COMMAND=console
) else (

  :: Find the requested command.
  for /F %%v in ('echo %1^|findstr "^console$ ^start$ ^stop$ ^restart$ ^install$ ^remove"') do set COMMAND=%%v
)
if "%COMMAND%" == "" (
    echo Usage: %0 { console : start : stop : restart : install : remove }
    echo     %0 console    run the application with a console
    echo     %0 start      start Xstore Form Designer once installed as a Windows service
    echo     %0 restart    restart Xstore Form Designer once installed as a Windows service
    echo     %0 stop       stop Xstore Form Designer once installed as a Windows service
    echo     %0 install    install Xstore Form Designer as a Windows service
    echo     %0 remove     uninstall Xstore Form Designer as a Windows service
    echo     %0 help       show this message
      
    exit 2
    goto :eof
) else (
    shift
)

::
:: Run the application.
:: At runtime, the current directory will be that of Wrapper.exe
::
set PARAMS=%1
shift
:parse
if [%1] == [] goto done
set PARAMS=%PARAMS% %1
shift
goto parse

:done
call :%COMMAND% %PARAMS%
if errorlevel 1 exit 1
goto :eof

:console
SET my_title=Xstore Form Designer Console (%RANDOM%)
"%_WRAPPER_EXE%" -c %_WRAPPER_CONF% %OS_ADDITIONAL_PROP_1% wrapper.java.command=%JAVA% %PARAMS%
goto :eof

:start
"%_WRAPPER_EXE%" -t %_WRAPPER_CONF% %OS_ADDITIONAL_PROP_1% wrapper.java.command=%JAVA% %PARAMS%
goto :eof

:stop
"%_WRAPPER_EXE%" -p %_WRAPPER_CONF% %OS_ADDITIONAL_PROP_1% wrapper.java.command=%JAVA% %PARAMS%
goto :eof

:install
"%_WRAPPER_EXE%" -i %_WRAPPER_CONF% %OS_ADDITIONAL_PROP_1% wrapper.java.command=%JAVA% %PARAMS%
goto :eof

:remove
"%_WRAPPER_EXE%" -r %_WRAPPER_CONF% %OS_ADDITIONAL_PROP_1% wrapper.java.command=%JAVA% %PARAMS%
goto :eof

:restart
call :stop
call :start
goto :eof

:exec
%*
goto :eof

:: Move any JVM crash logs into the log directory.
IF EXIST %~dp0\hs_pid????.log  move %~dp0\hs_pid????.log %~dp0\log

:eof
exit
