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
set _REALPATH=%~dp0%
set _REALPATH=%_REALPATH%
for %%B in (%_REALPATH%.) do set ROOT_DIR=%%~dpB
::echo Real path is %_REALPATH%
set JRE_HOME=%ROOT_DIR%jre
set JAVA=%JRE_HOME%\bin\xenv_ui.exe

if NOT EXIST %JAVA% copy /Y %JRE_HOME%\bin\java.exe %JAVA%

set _WRAPPER_EXE=%_REALPATH%\bin\%_WRAPPER_BASE%.exe
if exist "%_WRAPPER_EXE%" goto conf

echo Unable to locate a Wrapper executable at: %_WRAPPER_EXE%
goto :eof

::
:: Find the wrapper.conf
::
:conf

:ENV_WRAPPER
set _WRAPPER_CONF="%_REALPATH%\wrapper\conf\xenv_ui.conf"

:copyexe
COPY /Y %JRE_HOME%\bin\java.exe %JRE_HOME%\bin\xenv_ui.exe

::
:: Start the Wrapper
::
:startup
echo Startup
"%_WRAPPER_EXE%" -c %_WRAPPER_CONF%
if not errorlevel 1 goto :eof
pause

