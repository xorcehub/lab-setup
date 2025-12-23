<#
.SYNOPSIS
    Windows 11 VM Optimization & Hardening Script
    Disables bloatware, telemetry, and security features that interfere with malware analysis.
#>

Write-Host "--- OPTIMIZING WINDOWS 11 FOR MALWARE ANALYSIS ---" -ForegroundColor Cyan

# 1. Start Menu Alignment (Left is best)
Write-Host "[*] Moving Start Menu to Left (Classic Style)..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0

# 2. Performance: Disable Visual Effects
Write-Host "[*] Disabling Visual Effects (Animation, Shadows, Transparency)..."
# Set 'Adjust for best performance' equivalent
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
# Disable Transparency (saves GPU resources)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0
# Disable Animations via UserPreferencesMask
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))

# 3. Disable Windows Defender (Soft-Disable)
# NOTE: For a permanent hard-disable, use 'Defender Control' (dControl) tool manually.
Write-Host "[*] Disabling Windows Defender Real-Time Protection..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1

# 4. Disable Updates & Annoyances
Write-Host "[*] Disabling Windows Updates & Tips..."
# Disable Update Service
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Set-Service wuauserv -StartupType Disabled
# Disable "Get Tips and Suggestions"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0

# 5. Explorer Settings (Visibility is key)
Write-Host "[*] Enabling File Extensions & Hidden Files..."
# Show extensions for known file types (Essential to spot .exe.pdf)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
# Show hidden files
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1
# Show system files (super hidden)
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSuperHidden" -Value 1

# 6. Taskbar Cleanup
Write-Host "[*] Removing Widgets & Chat icons..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 # Widgets
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0 # Chat

# 7. Disable Screen Lock
Write-Host "[*] Disabling Screen Lock..."
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "ScreenSaveActive" -Value "0"
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value 1

Write-Host "--- OPTIMIZATION COMPLETE ---" -ForegroundColor Green
Write-Host "Please RESTART the VM to apply UI changes."
