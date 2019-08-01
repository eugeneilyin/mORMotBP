@ECHO OFF

IF "%~1"=="" GOTO MANUAL
GOTO RUN

:MANUAL

echo.
echo   Deletes "DVCLAL", "PACKAGEINFO", "MAINICON", and "1" ICON resources from
echo   Resource files (*.res) or PE files (*.exe, *.dll, etc.)
echo.
echo   Use this file with the next IDE "Post-build Event":
echo.
echo   "$(PROJECTDIR)\post-build.bat" "$(PROJECTDIR)\$(OUTPUTDIR)$(PROJECTNAME).exe"

GOTO END

:RUN

SET APPLICATION="%~1"
SET TEMP_FILE="%~1.tmp"
SET RESEDIT="%~dp0resedit.exe"
COPY %APPLICATION% %TEMP_FILE% > nul
%RESEDIT% %TEMP_FILE% RCDATA DVCLAL
%RESEDIT% %TEMP_FILE% RCDATA PACKAGEINFO
%RESEDIT% %TEMP_FILE% GROUPICON MAINICON
%RESEDIT% %TEMP_FILE% ICON 1
COPY %TEMP_FILE% %APPLICATION% > nul
DEL %TEMP_FILE%

:END