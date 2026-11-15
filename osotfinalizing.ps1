@echo off
REM ============================================================
REM
REM  TITLE       : Omnissa OS Optimization Tool
REM  DESCRIPTION : Windows 11 25H2 - Horizon Golden Image
REM  VERSION     : 1.0
REM  CREATED BY  : Fabio
REM  CREATED ON  : 13.11.2026
REM
REM ============================================================ 

REM ###############################################################################
REM # SET DYNAMIC VARIABLES
REM ############################################################################### 
set "OSOTFile=OmnissaHorizonOSOptimizationTool-x86_64-1.2.2609.37751670449.exe"
set "OSOTPath=C:\Program Files\Omnissa\OSOptimization"
set "TEMPLATEFile=RUAG-Win11 25H2-V1.0.xml" 

set "OSOT=%OSOTPath%\%OSOTFile%"
set "TEMPLATE=%OSOTPath%\%TEMPLATEFile%"
 

REM ###############################################################################
REM  Check if required file exist
REM ###############################################################################
if not exist "%OSOT%" (
    echo ERROR: OSOT executable not found!
    exit /b 1
)
if not exist "%TEMPLATE%" (
    echo ERROR: XML template not found!
    exit /b 1
)

echo ###############################################################################
echo # Executing Omnissa Horizon OS Optimization Tool....
echo ###############################################################################
"%OSOT%" ^
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
-f 0 1 3 4 5 7 8 9 10 ^ 

@echo off
cls
echo ###############################################################################
echo # Deletes all files in c:\temp
echo ###############################################################################

cd /d C:\temp
del /q /f /s *.*
rd /s /q .

echo ###############################################################################
echo       EMPTY WINDOWS RECYCLE BIN
echo ###############################################################################

echo Cleaning Recycle Bin...

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
"Clear-RecycleBin -Force -ErrorAction SilentlyContinue" 

if errorlevel 1 (
    echo ERROR: Recycle Bin cleanup failed.
    exit /b 1
)

echo.
echo Recycle Bin cleanup completed successfully.
echo.

echo ###############################################################################
echo # Stopping Windows Update Service and Disable
echo ###############################################################################
net stop wuauserv
sc config wuauserv start=disabled 

echo ###############################################################################
echo # Stopping Edge Update Service and Disable
echo ###############################################################################
net stop edgeupdate
sc config edgeupdate start=disabled 

echo ###############################################################################
echo # Begin with Cortex Filescan
echo ###############################################################################
"C:\Program Files\Palo Alto Networks\Traps\cytool.exe" imageprep scan timeout 1 upload 1 path C:\Temp 

echo ###############################################################################
echo # Release IP and Shutdown in 10sec
echo ###############################################################################
ipconfig /release
shutdown /s /t 10 /c "Image Ready"
exit
