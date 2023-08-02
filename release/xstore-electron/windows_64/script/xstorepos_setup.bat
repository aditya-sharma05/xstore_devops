@echo off
REM 

REG ADD "HKEY_CURRENT_USER\Software\Classes\xstorepos" /f /ve /d "URL:xstorepos Protocol"
REG ADD "HKEY_CURRENT_USER\Software\Classes\xstorepos" /f /v "URL Protocol" /d ""
REG ADD "HKEY_CURRENT_USER\Software\Classes\xstorepos\shell" /f 
REG ADD "HKEY_CURRENT_USER\Software\Classes\xstorepos\shell\open" /f

REM Make the registry contain something that looks like this:  
REM     C:\xstore\windows_64\electron\xstore-electron.exe 'xst-props-file=C:\xstore\xstore.properties' 'anchorfiles-dir=C:\xstore\tmp' '"%1"' 

REG ADD "HKEY_CURRENT_USER\Software\Classes\xstorepos\shell\open\command" /f /ve /d "@@XSTORE_ELECTRON_EXECUTABLE@@ 'install-dir=@@INSTALL_DIR@@' '\"%%1\"' "