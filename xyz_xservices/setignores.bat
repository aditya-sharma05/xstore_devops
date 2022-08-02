@echo off
setlocal
setlocal enableextensions
IF ERRORLEVEL 1 echo Unable to enable extensions
pushd %~dp0

svn ps svn:ignore -F ignores.txt .
