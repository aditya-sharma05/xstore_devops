@echo off
setlocal
setlocal enableextensions
IF ERRORLEVEL 1 echo Unable to enable extensions
pushd %~dp0

:: Apply ignores to the project root from the ignores file.
svn ps svn:ignore -F ignores.txt .

:: Certain directories need to exist, but their contents must not be in source control.
echo *>~all-ignores.tmp
svn ps svn:ignore -F ~all-ignores.tmp gen
del ~all-ignores.tmp

:: Ignore localconfig.
echo localconfig>~ignores.tmp
svn ps svn:ignore -F ~ignores.tmp cust_config
del ~ignores.tmp
