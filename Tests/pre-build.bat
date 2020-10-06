@ECHO OFF

IF "%~1"=="" GOTO MANUAL
GOTO RUN

:MANUAL

echo.
echo Embed './Assets' folder into Assets.res file
echo.
echo Add the next directive to FPC project file:
echo.
echo   {%BuildCommand pre-build.bat "$ProjPath()"}
echo.
echo Then use the next Lazarus IDE menu to build Assets.res:
echo.
echo   Run / Build File

GOTO END

:RUN

SET PROJECT_PATH=%~1
"%PROJECT_PATH%..\Tools\assetslz" -GZ1 -B1 "%PROJECT_PATH%\Assets" "%PROJECT_PATH%Assets.tmp"
"%PROJECT_PATH%..\Tools\resedit" -D "%PROJECT_PATH%Assets.res" rcdata ASSETS "%PROJECT_PATH%Assets.tmp"

:END