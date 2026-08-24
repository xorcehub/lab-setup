@echo off
echo [*] Launching Malware Lab Setup...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_lab.ps1"
pause
