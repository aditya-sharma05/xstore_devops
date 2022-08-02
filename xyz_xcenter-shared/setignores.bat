@echo off
setlocal
setlocal enableextensions
IF ERRORLEVEL 1 echo Unable to enable extensions
pushd %~dp0

svn ps svn:ignore -F ignores.txt .

echo *>~all-ignores.tmp
svn ps svn:ignore -F ~all-ignores.tmp classes
svn ps svn:ignore -F ~all-ignores.tmp gen
del ~all-ignores.tmp
