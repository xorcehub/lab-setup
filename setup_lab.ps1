<#
.SYNOPSIS
    Automated Malware Analysis Lab Installer

.DESCRIPTION
    Installs Chocolatey package manager and the following tools:
    - Monitoring: Sysinternals, Process Hacker 2, RegShot
    - Network: Wireshark
    - Static: PEStudio, Detect It Easy, Capa, Floss, YARA
    - Debug/Decompile: x64dbg, Ghidra, dnSpy, HxD, PE-bear, Resource Hacker
    - Utils: Cmder, Notepad++, 7-Zip, Python3
#>

Write-Host "--- STARTING MALWARE LAB SETUP ---" -ForegroundColor Cyan

# 1. Install Chocolatey if not present
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "[*] Chocolatey not found. Installing..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh Environment Variables so 'choco' works immediately
    Write-Host "[*] Refreshing Environment Variables..." -ForegroundColor Green
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "[*] Chocolatey is already installed." -ForegroundColor Green
}

# Double check if choco is runnable now
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Error: 'choco' command not found even after install." -ForegroundColor Red
    Write-Host "    Please close this window, open a new Admin PowerShell, and run the script again."
    exit 1
}

# 2. Define Tool List
$tools = @(
    # --- System Monitoring ---
    "sysinternals",       # ProcMon, ProcExp, Autoruns, TCPView
    "processhacker",      # Powerful Task Manager replacement
    "regshot",            # Registry/Filesystem Diffing

    # --- Network ---
    "wireshark",          # Packet Capture
    # Note: FakeNet-NG is better installed manually or via pip, see below

    # --- Static Analysis ---
    "pestudio",           # Initial Triage
    "detectiteasy",       # Packer Detector
    "capa",               # Capability detection (Mandiant)
    "floss",              # Obfuscated String Solver (Mandiant)
    "yara",               # Pattern Matching
    "hxd",                # Hex Editor
    "pe-bear",            # PE Viewer/Editor
    "resourcehacker",     # Resource Editor

    # --- Debugging & Decompiling ---
    "x64dbg",             # Main Debugger
    "ghidra",             # Decompiler (Java dependency handled by choco)
    "dnspy",              # .NET Decompiler/Debugger

    # --- Utilities ---
    "cmder",              # Better Console
    "notepadplusplus.install", # Editor
    "7zip",               # Archives
    "python"              # Python 3
)

# 3. Install Tools Loop
Write-Host "[*] Starting installation of tools..." -ForegroundColor Cyan
foreach ($tool in $tools) {
    Write-Host " -> Installing $tool..." -ForegroundColor Yellow
    # Added --ignore-checksums because sometimes older packages break on hash check
    choco install $tool -y --no-progress --ignore-checksums
}

# 4. Create "Tools" Folder
$desktop = [Environment]::GetFolderPath("Desktop")
$toolsDir = Join-Path $desktop "Malware_Tools"
if (-not (Test-Path $toolsDir)) {
    New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
    Write-Host "[*] Created 'Malware_Tools' folder on Desktop." -ForegroundColor Green
}

# 5. Set Wallpaper to Solid RED (Safety Warning)
Write-Host "[*] Setting Warning Wallpaper..." -ForegroundColor Yellow
try {
    $code = @'
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", CharSet=CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
'@
    Add-Type $code -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name "Background" -Value "255 0 0"
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallPaper" -Value ""
    [Wallpaper]::SystemParametersInfo(20, 0, "", 3) | Out-Null
} catch {
    Write-Host "[!] Could not set wallpaper programmatically. Please set it to RED manually." -ForegroundColor Red
}

Write-Host "--- SETUP COMPLETE ---" -ForegroundColor Cyan
Write-Host "1. Please RESTART the VM now."
Write-Host "2. Perform the Manual Steps listed in the chat."
Write-Host "3. Take a SNAPSHOT after everything is configured."
