@echo off
setlocal
title Low-Budget Repairs Compatibility - Online Launcher
echo Downloads the public experimental compatibility tool and opens its interface.
echo No game patches are applied automatically.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/yethinnanchu/low-budget-repairs-compatibility/main/install.ps1' | iex"
if errorlevel 1 (
  echo Launch failed. Download and extract the ZIP release instead.
  pause
  exit /b 1
)
