@echo off
setlocal
title Low-Budget Repairs Compatibility
if not exist "%~dp0UI.ps1" (
  echo Extract the complete ZIP before running Launch.cmd.
  pause
  exit /b 1
)
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0UI.ps1"
if errorlevel 1 pause
