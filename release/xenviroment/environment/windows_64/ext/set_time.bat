@ECHO OFF

IF %1. == . GOTO USAGE


ECHO Setting time equal to %1 time...

net time \\%1 /set /yes
GOTO END

:USAGE
echo Usage: set_time.bat {server name}
echo Example -- set_time timeserver

:END
exit
