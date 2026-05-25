@echo off
setlocal EnableDelayedExpansion

:: ============================================================
:: VBS STATUS AUDIT SCRIPT
:: Checks the current state of all virtualization security
:: features and displays a summary
:: ============================================================

:: Check for admin privileges
fltmc >nul 2>&1
if errorlevel 1 (
    echo.
    echo Some checks require admin privileges.
    echo Re-launching with elevation...
    echo.
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

echo.
echo  ============================================================
echo   VBS AND HYPERVISOR STATUS CHECK
echo  ============================================================
echo.

:: --- Feature checks ---

:: 1. VBS
set "vbs=UNKNOWN"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity 2^>nul ^| find "EnableVirtualizationBasedSecurity"') do (
        if "%%a"=="0x1" set "vbs=ENABLED"
        if "%%a"=="0x0" set "vbs=DISABLED"
    )
)

:: 2. System Guard
set "sg=UNKNOWN"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\SystemGuard" /v Enabled 2^>nul ^| find "Enabled"') do (
        if "%%a"=="0x1" set "sg=ENABLED"
        if "%%a"=="0x0" set "sg=DISABLED"
    )
)

:: 3. HVCI (Memory Integrity)
set "hvci=UNKNOWN"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled 2^>nul ^| find "Enabled"') do (
        if "%%a"=="0x1" set "hvci=ENABLED"
        if "%%a"=="0x0" set "hvci=DISABLED"
    )
)

:: 4. Credential Guard
set "cg=UNKNOWN"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags 2^>nul ^| find "LsaCfgFlags"') do (
        if "%%a"=="0x0" set "cg=DISABLED"
        if "%%a"=="0x1" set "cg=ENABLED (UEFI)"
        if "%%a"=="0x2" set "cg=ENABLED (Locked)"
    )
)

:: 5. Windows Hello Protection
set "wh=UNKNOWN"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" /v Enabled >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\WindowsHello" /v Enabled 2^>nul ^| find "Enabled"') do (
        if "%%a"=="0x1" set "wh=ENABLED"
        if "%%a"=="0x0" set "wh=DISABLED"
    )
)

:: 6. Hypervisor
set "hyp=NOT CONFIGURED"
bcdedit /enum >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=2 delims= " %%a in ('bcdedit /enum 2^>nul ^| findstr /i "hypervisorlaunchtype"') do (
        if /i "%%a"=="Off" set "hyp=DISABLED"
        if /i "%%a"=="Auto" set "hyp=ENABLED"
    )
)

:: --- Display results ---
echo   Feature                  Status
echo   -----------------------  -----------------
echo   Virtualization Security  !vbs!
echo   System Guard             !sg!
echo   Memory Integrity (HVCI)  !hvci!
echo   Credential Guard         !cg!
echo   Windows Hello Protection !wh!
echo   Hypervisor               !hyp!
echo.

:: --- Count disabled features ---
set /a disabled=0
if /i "!vbs!"=="DISABLED" set /a disabled+=1
if /i "!sg!"=="DISABLED" set /a disabled+=1
if /i "!hvci!"=="DISABLED" set /a disabled+=1
if /i "!cg!"=="DISABLED" set /a disabled+=1
if /i "!wh!"=="DISABLED" set /a disabled+=1
if /i "!hyp!"=="DISABLED" set /a disabled+=1
if /i "!hyp!"=="NOT CONFIGURED" set /a disabled+=1

:: --- Check tracking key ---
set "tracked=NO"
reg query "HKLM\SOFTWARE\VBSToggle" >nul 2>&1
if not errorlevel 1 (
    set "tracked=YES"
    echo   Tracking key found. Features previously disabled:
    for %%k in (VBS SystemGuard HVCI CredentialGuard WindowsHello Hypervisor) do (
        reg query "HKLM\SOFTWARE\VBSToggle" /v %%k >nul 2>&1
        if not errorlevel 1 (
            echo     - %%k
        )
    )
    echo.
)

:: --- Summary ---
echo  ============================================================
if !disabled! equ 0 (
    echo   MODE: NORMAL - All features enabled
) else if !disabled! equ 6 (
    echo   MODE: LAB - All features disabled ^(best VM performance^)
) else (
    echo   MODE: MIXED - !disabled!/6 features disabled
)
echo  ============================================================
echo.
pause
