@echo off
setlocal

:: Copyright (c) 1999, 2009 Tanuki Software, Ltd.
:: http://www.tanukisoftware.com
:: All rights reserved.
::
:: This software is the proprietary information of Tanuki Software.
:: You shall use it only in accordance with the terms of the
:: license agreement you entered into with Tanuki Software.
:: http://wrapper.tanukisoftware.org/doc/english/licenseOverview.html
::
:: Java Service Wrapper general startup script.
:: Optimized for use with version 3.3.6 of the Wrapper.
::

::
:: Resolve the real path of the wrapper.exe
::  For non NT systems, the _REALPATH and _WRAPPER_CONF values
::  can be hard-coded below and the following test ::oved.
::
if "%OS%"=="Windows_NT" goto nt
echo This script only works with NT-based versions of Windows.
goto :eof

:nt
::
:: Find the application home.
::
:: %~dp0 is location of current script under NT
:: set _REALPATH=%~dp0

:: Decide on the wrapper binary.
set _WRAPPER_BASE=wrapper
set _REALPATH=%~dp0
for %%B in (%_REALPATH%.) do set ROOT_DIR=%%~dpB
set _WRAPPER_CONF="%_REALPATH%%_WRAPPER_BASE%\conf\xenv_webui.conf"
set _WRAPPED_APP=xenv_eng
set PLATFORM=windows
::echo Real path is %_REALPATH%
set JAVA_HOME=%ROOT_DIR%jre
set JAVA=%JAVA_HOME%\bin\xenv_eng.exe
set PIDDIR=%_REALPATH%tmp

:: Move any JVM crash logs into the log directory.
IF EXIST %~dp0\hs_pid????.log  move %~dp0\hs_pid????.log %~dp0\log

if NOT EXIST %JAVA% copy /Y %JAVA_HOME%\bin\java.exe %JAVA%


:: Check for Running instances of Application
if not exist %windir%\system32\tasklist.exe goto notask
if not exist %PIDDIR%\%_WRAPPED_APP%.pid goto notask
for /f "tokens=*" %%a in (%PIDDIR%%_WRAPPED_APP%.pid) do set XPID=%%a
tasklist /FI "PID eq %XPID%" |find "%_WRAPPED_APP%.exe"
echo %ERRORLEVEL%
if %ERRORLEVEL% == 0 (
       cls
       ECHO Another Instance of %_WRAPPED_APP% is already running from %_REALPATH%.
       exit /b 3
       goto :eof
       )
if %ERRORLEVEL% == 1 (
       echo Stale pid file detected, pid file removed.
       del %PIDDIR%%_WRAPPED_APP%.pid
       )


:notask

set _WRAPPER_EXE=%_REALPATH%bin\%_WRAPPER_BASE%.exe
if NOT EXIST %_WRAPPER_EXE% goto no_wrapper_exe

if "%1" == "" (
  set COMMAND=console
) else (

  :: Find the requested command.
  for /F %%v in ('echo %1^|findstr "^console$ ^start$ ^stop$ ^restart$ ^install$ ^remove"') do set COMMAND=%%v
)
if "%COMMAND%" == "" (
    echo Usage: %0 { console : start : stop : restart : install : remove }
    echo     %0 console    run the application with a console
    echo     %0 start      start %_WRAPPED_APP% once installed as a Windows service
    echo     %0 restart    restart %_WRAPPED_APP% once installed as a Windows service
    echo     %0 stop       stop %_WRAPPED_APP% once installed as a Windows service
    echo     %0 install    install %_WRAPPED_APP% as a Windows service
    echo     %0 remove     uninstall %_WRAPPED_APP% as a Windows service
    echo     %0 help       show this message
	exit /b 2
    goto :eof
) else (
    shift
)

::
:: Run the application.
:: At runtime, the current directory will be that of Wrapper.exe
::
echo Startup
call :%COMMAND%
if errorlevel 1 exit /b 1
goto :eof

:console
SET my_title=Xenv_Engine Console (%RANDOM%)
"%_WRAPPER_EXE%" -c %_WRAPPER_CONF%
goto :eof

:start
"%_WRAPPER_EXE%" -t %_WRAPPER_CONF%
goto :eof

:stop
"%_WRAPPER_EXE%" -p %_WRAPPER_CONF%
goto :eof

:install
"%_WRAPPER_EXE%" -i %_WRAPPER_CONF%
goto :eof

:remove
"%_WRAPPER_EXE%" -r %_WRAPPER_CONF%
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

:no_wrapper_exe
echo Unable to locate a Wrapper executable at: %_WRAPPER_EXE%

:eof
exit /b 0


