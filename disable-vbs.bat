@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: DISABLE VBS & HYPERVISOR SCRIPT
:: Disables Windows virtualization security features for
:: better VirtualBox performance
:: ============================================================

:: Check for admin privileges
fltmc >nul 2>&1
if errorlevel 1 (
    echo.
    echo This script requires administrator privileges.
    echo A UAC prompt will appear. Please click "Yes".
    echo.
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

echo.
echo  ============================================================
echo   DISABLE VBS AND HYPERVISOR
echo  ============================================================
echo.
echo  This will disable:
echo   - Windows Hypervisor
echo   - Virtualization-based Security (VBS)
echo   - Memory Integrity (HVCI)
echo   - Credential Guard
echo   - System Guard Secure Launch
echo   - Windows Hello Device Guard protection
echo.
echo  WARNING: Disable Windows Hello (PIN/fingerprint/face)
echo  before proceeding, or it may stop working!
echo.
echo  ============================================================
echo.

choice /C:YN /N /M "Continue? [Y/N]: "
if errorlevel 2 exit /b

echo.
echo Disabling security features...
echo.

:: Create tracking key for revert script
reg add "HKLM\SOFTWARE\VBSToggle" /ve /d "" /f >nul 2>&1

:: Disable VBS
echo [1/6] Disabling Virtualization-based Security...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (
    echo       Failed!
) else (
    reg add "HKLM\SOFTWARE\VBSToggle" /v VBS /t REG_DWORD /d 1 /f >nul 2>&1
    echo       Done.
)

:: Disable System Guard
echo [2/6] Disabling System Guard...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (
    echo       Failed!
) else (
    reg add "HKLM\SOFTWARE\VBSToggle" /v SystemGuard /t REG_DWORD /d 1 /f >nul 2>&1
    echo       Done.
)

:: Disable Memory Integrity (HVCI)
echo [3/6] Disabling Memory Integrity (HVCI)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (
    echo       Failed!
) else (
    reg add "HKLM\SOFTWARE\VBSToggle" /v HVCI /t REG_DWORD /d 1 /f >nul 2>&1
    echo       Done.
)

:: Disable Credential Guard
:: Record the ORIGINAL LsaCfgFlags value so enable-vbs.bat can restore it exactly
echo [4/6] Disabling Credential Guard...
set "cgOrig=0"
for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags 2^>nul ^| find "LsaCfgFlags"') do set "cgOrig=%%a"
reg add "HKLM\SOFTWARE\VBSToggle" /v CredentialGuard /t REG_DWORD /d !cgOrig! /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (
    echo       Failed!
    reg delete "HKLM\SOFTWARE\VBSToggle" /v CredentialGuard /f >nul 2>&1
) else (
    echo       Done.
)

:: Disable Windows Hello protection
echo [5/6] Disabling Windows Hello Protection...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
if errorlevel 1 (
    echo       Failed!
    reg delete "HKLM\SOFTWARE\VBSToggle" /v WindowsHello /f >nul 2>&1
) else (
    reg add "HKLM\SOFTWARE\VBSToggle" /v WindowsHello /t REG_DWORD /d 1 /f >nul 2>&1
    echo       Done.
)

:: Disable Hypervisor via BCD
echo [6/6] Disabling Windows Hypervisor...
bcdedit /set hypervisorlaunchtype off >nul 2>&1
if errorlevel 1 (
    echo       Failed!
) else (
    reg add "HKLM\SOFTWARE\VBSToggle" /v Hypervisor /t REG_DWORD /d 1 /f >nul 2>&1
    echo       Done.
)

echo.
echo  ============================================================
echo   COMPLETE - Restart required!
echo  ============================================================
echo.
echo  Run enable-vbs.bat to restore security features.
echo.
choice /C:YN /N /M "Restart now? [Y/N]: "
if errorlevel 2 exit /b
shutdown /r /t 3
