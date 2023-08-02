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
for %%B in (%_REALPATH%..) do set ROOT_DIR=%%~dpB
set _WRAPPER_CONF="%_REALPATH%\wrapper.conf"
set _WRAPPED_APP=xservices
set PLATFORM=windows
::echo Real path is %_REALPATH%
set JAVA_HOME=%ROOT_DIR%jre
set JAVA=%JAVA_HOME%\bin\xservices.exe
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

set _WRAPPER_EXE=%_REALPATH%\\..\%PLATFORM%\bin\%_WRAPPER_BASE%.exe
if NOT EXIST %_WRAPPER_EXE% goto no_wrapper_exe

set COMMAND=console

::
:: Run the application.
:: At runtime, the current directory will be that of Wrapper.exe
::
echo Startup

:console
SET my_title=Xservices (%RANDOM%)
"%_WRAPPER_EXE%" -c %_WRAPPER_CONF%
if errorlevel 1 exit /b 1
goto :eof

:: Move any JVM crash logs into the log directory.
IF EXIST %~dp0\hs_pid????.log  move %~dp0\hs_pid????.log %~dp0\log

:no_wrapper_exe
echo Unable to locate a Wrapper executable at: %_WRAPPER_EXE%

:eof
exit /b 0


