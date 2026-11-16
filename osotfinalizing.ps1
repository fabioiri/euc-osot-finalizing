@echo off
setlocal EnableExtensions
cls

REM ============================================================
REM
REM  TITLE       : Omnissa OS Optimization Tool
REM  DESCRIPTION : Windows 11 25H2 - Horizon Golden Image
REM  VERSION     : 1.1
REM  CREATED BY  : Fabio
REM  CREATED ON  : 13.11.2026
REM
REM ============================================================

REM ###############################################################################
REM # VARIABLES
REM ###############################################################################
set "OSOTFile=OmnissaHorizonOSOptimizationTool-x86_64-1.2.2609.37751670449.exe"
set "OSOTPath=C:\Program Files\Omnissa\OSOptimization"
set "TEMPLATEFile=Win11-25H2-V1.0.xml"
set "TEMPDIR=C:\temp"
set "CYTOOL=C:\Program Files\Palo Alto Networks\Traps\cytool.exe"

set "OSOT=%OSOTPath%\%OSOTFile%"
set "TEMPLATE=%OSOTPath%\%TEMPLATEFile%"

REM ###############################################################################
REM # CHECK ADMIN RIGHTS
REM ###############################################################################
net session >nul 2>&1
if errorlevel 1 (
    echo ERROR: This script must be run as Administrator!
    pause
    exit /b 1
)

REM ###############################################################################
REM # CHECK REQUIRED FILES
REM ###############################################################################
if not exist "%OSOT%" (
    echo ERROR: OSOT executable not found: "%OSOT%"
    pause
    exit /b 1
)
if not exist "%TEMPLATE%" (
    echo ERROR: XML template not found: "%TEMPLATE%"
    pause
    exit /b 1
)
if not exist "%CYTOOL%" (
    echo ERROR: Cortex cytool not found: "%CYTOOL%"
    pause
    exit /b 1
)

REM ###############################################################################
REM # RUN OSOT
REM # "start /wait" makes sure the script waits for OSOT to finish
REM ###############################################################################
echo ###############################################################################
echo # Executing Omnissa Horizon OS Optimization Tool...
echo ###############################################################################
start "" /wait "%OSOT%" ^
 -o ^
 -t "%TEMPLATE%" ^
 -OneDrive disable ^
 -HVCI disable ^
 -Smartscreen disable ^
 -securitycenter disable ^
 -firewall disable ^
 -antivirus disable ^
 -storeapp remove-all --exclude ScreenSketch Calculator Photos ^
 -officeupdate disable ^
 -windowsupdate disable ^
 -notification disable ^
 -visualeffect balanced ^
 -SyncHkcuToHku enable ^
 -background "#4c4a48" ^
 -f 0 1 3 4 5 7 8 9 10

if errorlevel 1 (
    echo ERROR: OSOT finished with errors. Exit code: %errorlevel%
    pause
    exit /b 1
)

REM ###############################################################################
REM # CLEAN TEMP FOLDER (keeps the folder itself, removes its content)
REM ###############################################################################
echo ###############################################################################
echo # Deleting all files in %TEMPDIR%
echo ###############################################################################
if exist "%TEMPDIR%\" (
    pushd "%TEMPDIR%" || (
        echo ERROR: Cannot access %TEMPDIR%
        pause
        exit /b 1
    )
    del /q /f /s "*.*" >nul 2>&1
    for /d %%D in ("%TEMPDIR%\*") do rd /s /q "%%D" >nul 2>&1
    popd
) else (
    echo %TEMPDIR% not found, creating it for the Cortex scan...
    mkdir "%TEMPDIR%"
)

REM ###############################################################################
REM # EMPTY RECYCLE BIN (non-fatal: an already empty bin can raise an error)
REM ###############################################################################
echo ###############################################################################
echo # Emptying Recycle Bin
echo ###############################################################################
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
echo Recycle Bin cleanup done.

REM ###############################################################################
REM # DISABLE UPDATE SERVICES
REM ###############################################################################
echo ###############################################################################
echo # Stopping and disabling Windows Update
echo ###############################################################################
net stop wuauserv
sc config wuauserv start= disabled

echo ###############################################################################
echo # Stopping and disabling Edge Update
echo ###############################################################################
net stop edgeupdate
sc config edgeupdate start= disabled
net stop edgeupdatem
sc config edgeupdatem start= disabled

REM ###############################################################################
REM # CORTEX FILE SCAN
REM ###############################################################################
echo ###############################################################################
echo # Cortex image preparation scan
echo ###############################################################################
"%CYTOOL%" imageprep scan timeout 1 upload 1 path "%TEMPDIR%"
if errorlevel 1 (
    echo WARNING: Cortex scan returned an error. Exit code: %errorlevel%
    echo Check the result before taking the snapshot.
    pause
    exit /b 1
)

REM ###############################################################################
REM # RELEASE IP AND SHUTDOWN
REM ###############################################################################
echo ###############################################################################
echo # Releasing IP and shutting down in 10 seconds
echo ###############################################################################
ipconfig /release
shutdown /s /t 10 /c "Image Ready"
exit /b 0
