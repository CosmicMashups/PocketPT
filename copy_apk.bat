@echo off
REM Batch file to copy APK files to Flutter's expected build directory
REM This script should be run after each Flutter build

echo Copying APK files to Flutter build directory...

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0copy_apk.ps1"

echo APK copy process completed.
pause









