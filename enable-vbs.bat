@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: ENABLE VBS & HYPERVISOR SCRIPT
:: Re-enables Windows virtualization security features that
:: were previously disabled by disable-vbs.bat
::
:: Reads individual tracking values from HKLM\SOFTWARE\VBSToggle
:: and only re-enables features that were actually toggled off.
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
echo   ENABLE VBS AND HYPERVISOR
echo  ============================================================
echo.

:: Check if tracking key exists
reg query "HKLM\SOFTWARE\VBSToggle" >nul 2>&1
if errorlevel 1 goto :no_tracking

echo  Previously disabled features:
set "_count=0"
for %%k in (VBS SystemGuard HVCI CredentialGuard WindowsHello Hypervisor) do (
    reg query "HKLM\SOFTWARE\VBSToggle" /v %%k >nul 2>&1
    if not errorlevel 1 (
        echo     - %%k
        set /a _count+=1
    )
)
echo.
if !_count! equ 0 (
    echo  Tracking key exists but contains no feature entries.
    echo  Nothing to re-enable.
    echo.
    pause
    exit /b
)
goto :proceed

:no_tracking
echo  No previous disable was detected.
echo.
echo  Do you want to force-enable all features anyway?
echo.
choice /C:YN /N /M "[Y/N]: "
if errorlevel 2 exit /b
set "_force=1"

:proceed

echo.
echo Re-enabling security features...
echo.

:: --- VBS ---
if defined _force goto :do_vbs
reg query "HKLM\SOFTWARE\VBSToggle" /v VBS >nul 2>&1
if errorlevel 1 goto :skip_vbs
:do_vbs
echo [1/6] Enabling Virtualization-based Security...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 (
    echo       Failed!
) else (
    reg delete "HKLM\SOFTWARE\VBSToggle" /v VBS /f >nul 2>&1
    echo       Done.
)
goto :step2
:skip_vbs
echo [1/6] Virtualization-based Security - skipped ^(not previously disabled^)

:step2
:: --- System Guard ---
if defined _force goto :do_sg
reg query "HKLM\SOFTWARE\VBSToggle" /v SystemGuard >nul 2>&1
if errorlevel 1 goto :skip_sg
:do_sg
echo [2/6] Enabling System Guard...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 (
    echo       Failed!
) else (
    reg delete "HKLM\SOFTWARE\VBSToggle" /v SystemGuard /f >nul 2>&1
    echo       Done.
)
goto :step3
:skip_sg
echo [2/6] System Guard - skipped ^(not previously disabled^)

:step3
:: --- HVCI ---
if defined _force goto :do_hvci
reg query "HKLM\SOFTWARE\VBSToggle" /v HVCI >nul 2>&1
if errorlevel 1 goto :skip_hvci
:do_hvci
echo [3/6] Enabling Memory Integrity ^(HVCI^)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 (
    echo       Failed!
) else (
    reg delete "HKLM\SOFTWARE\VBSToggle" /v HVCI /f >nul 2>&1
    echo       Done.
)
goto :step4
:skip_hvci
echo [3/6] Memory Integrity (HVCI) - skipped ^(not previously disabled^)

:step4
:: --- Credential Guard ---
if defined _force goto :do_cg
reg query "HKLM\SOFTWARE\VBSToggle" /v CredentialGuard >nul 2>&1
if errorlevel 1 goto :skip_cg
:do_cg
:: Restore the ORIGINAL LsaCfgFlags value recorded by disable-vbs.bat (default 1)
echo [4/6] Enabling Credential Guard...
set "_cgval=1"
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\VBSToggle" /v CredentialGuard 2^>nul ^| find "CredentialGuard"') do set "_cgval=%%a"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d !_cgval! /f >nul 2>&1
if errorlevel 1 (
    echo       Failed!
) else (
    reg delete "HKLM\SOFTWARE\VBSToggle" /v CredentialGuard /f >nul 2>&1
    echo       Done.
)
goto :step5
:skip_cg
echo [4/6] Credential Guard - skipped ^(not previously disabled^)

:step5
:: --- Windows Hello ---
if defined _force goto :do_wh
reg query "HKLM\SOFTWARE\VBSToggle" /v WindowsHello >nul 2>&1
if errorlevel 1 goto :skip_wh
:do_wh
echo [5/6] Enabling Windows Hello Protection...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
if errorlevel 1 (
    echo       Failed!
) else (
    reg delete "HKLM\SOFTWARE\VBSToggle" /v WindowsHello /f >nul 2>&1
    echo       Done.
)
goto :step6
:skip_wh
echo [5/6] Windows Hello Protection - skipped ^(not previously disabled^)

:step6
:: --- Hypervisor ---
if defined _force goto :do_hyp
reg query "HKLM\SOFTWARE\VBSToggle" /v Hypervisor >nul 2>&1
if errorlevel 1 goto :skip_hyp
:do_hyp
echo [6/6] Enabling Windows Hypervisor...
bcdedit /set hypervisorlaunchtype auto >nul 2>&1
if errorlevel 1 (
    echo       Failed!
) else (
    reg delete "HKLM\SOFTWARE\VBSToggle" /v Hypervisor /f >nul 2>&1
    echo       Done.
)
goto :done
:skip_hyp
echo [6/6] Hypervisor - skipped ^(not previously disabled^)

:done
:: Clean up tracking key if empty
reg query "HKLM\SOFTWARE\VBSToggle" >nul 2>&1
if errorlevel 1 goto :cleanup_done
set "_remain=0"
reg query "HKLM\SOFTWARE\VBSToggle" /v VBS >nul 2>&1
if not errorlevel 1 set "_remain=1"
reg query "HKLM\SOFTWARE\VBSToggle" /v SystemGuard >nul 2>&1
if not errorlevel 1 set "_remain=1"
reg query "HKLM\SOFTWARE\VBSToggle" /v HVCI >nul 2>&1
if not errorlevel 1 set "_remain=1"
reg query "HKLM\SOFTWARE\VBSToggle" /v CredentialGuard >nul 2>&1
if not errorlevel 1 set "_remain=1"
reg query "HKLM\SOFTWARE\VBSToggle" /v WindowsHello >nul 2>&1
if not errorlevel 1 set "_remain=1"
reg query "HKLM\SOFTWARE\VBSToggle" /v Hypervisor >nul 2>&1
if not errorlevel 1 set "_remain=1"
if "!_remain!"=="0" reg delete "HKLM\SOFTWARE\VBSToggle" /f >nul 2>&1

:cleanup_done
echo.
echo  ============================================================
echo   COMPLETE - Restart required!
echo  ============================================================
echo.
echo  Run check-vbs.bat to verify all features are re-enabled.
echo.
choice /C:YN /N /M "Restart now? [Y/N]: "
if errorlevel 2 exit /b
shutdown /r /t 3
