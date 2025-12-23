<#
.SYNOPSIS
    Lightweight Browser Setup (Firefox)
    Installs Firefox and configures it to be silent, fast, and allow malware downloads.
#>

Write-Host "--- INSTALLING & CONFIGURING BROWSER ---" -ForegroundColor Cyan

# 1. Install Firefox
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "[*] Installing Firefox via Chocolatey..."
    choco install firefox -y --no-progress --params "/l:en-US"
} else {
    Write-Host "[*] Chocolatey not found. Downloading Firefox installer..."
    $url = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
    $output = "$env:TEMP\firefox_installer.exe"
    (New-Object System.Net.WebClient).DownloadFile($url, $output)
    Start-Process -FilePath $output -ArgumentList "/S" -Wait
}

# 2. Create "user.js" configuration
# This file forces Firefox to disable security features that block malware downloads.
Write-Host "[*] Creating user.js configuration for malware analysis..."

# Locate Firefox Profile Path
$ffPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
# Firefox must run once to create the profile folder.
if (-not (Test-Path $ffPath)) {
    Write-Host "[!] Firefox needs to run once. Starting and killing it..."
    Start-Process "firefox.exe"
    Start-Sleep -Seconds 5
    Stop-Process -Name "firefox" -Force -ErrorAction SilentlyContinue
}

# Find the profile folder (*.default-release)
$profileDir = Get-ChildItem -Path $ffPath | Where-Object { $_.Name -like "*.default-release" } | Select-Object -First 1

if ($profileDir) {
    $userJsPath = Join-Path $profileDir.FullName "user.js"
    
    $config = @'
// --- MALWARE ANALYSIS CONFIG ---
// Disable Safe Browsing (Allow malware domains & downloads)
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);

// Disable Updates (Freeze version)
user_pref("app.update.auto", false);
user_pref("app.update.enabled", false);
user_pref("app.update.silent", false);

// Disable Telemetry & Pocket (Save RAM)
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("extensions.pocket.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);

// Performance Settings
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.startup.page", 1); // Start with blank or home
'@
    
    Set-Content -Path $userJsPath -Value $config
    Write-Host "[*] Configured Firefox at $userJsPath" -ForegroundColor Green
} else {
    Write-Host "[!] Could not find Firefox profile directory. Please run Firefox once manually." -ForegroundColor Red
}

Write-Host "[*] Setup complete. Firefox is ready."
