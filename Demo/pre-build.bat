@ECHO OFF

for %%i in ("%~dp0..") do set "bpdir=%%~fi"

IF !%1==! GOTO SHOWHELP

"%bpdir%\Tools\assetslz.exe" -GZ1 -B1 "%bpdir%\Assets" "%1\Assets.tmp"
"%bpdir%\Tools\resedit.exe" -D "%1\Assets.res" rcdata ASSETS "%1\Assets.tmp"

GOTO :EXIT0

:SHOWHELP
ECHO Embed './Assets' folder into Assets.res file
ECHO.
ECHO Add the next directive to FPC project file:
ECHO.
ECHO "{%BuildCommand pre-build.bat $ProjPath()}"
ECHO.
ECHO Then use the next Lazarus IDE menu to build Assets.res:
ECHO Run / Build File

:EXIT0