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
    "die",       # Packer Detector
    "capa",               # Capability detection (Mandiant)
    "floss",              # Obfuscated String Solver (Mandiant)
    "yara",               # Pattern Matching
    "hxd",                # Hex Editor
    "pebear",            # PE Viewer/Editor
    "reshack",     # Resource Editor

    # --- Debugging & Decompiling ---
    "x64dbg.portable",             # Main Debugger
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

# 4. Create "Malware_Tools" Folder on Desktop
$desktop = [Environment]::GetFolderPath("Desktop")
$toolsDir = Join-Path $desktop "Malware_Tools"
if (-not (Test-Path $toolsDir)) {
    New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
    Write-Host "[*] Created 'Malware_Tools' folder on Desktop." -ForegroundColor Green
}

# 5. Create Shortcuts Logic
Write-Host "[*] Creating Shortcuts for Tools..." -ForegroundColor Cyan

function Create-Shortcut {
    param ($TargetFile, $ShortcutName)
    $WshShell = New-Object -ComObject WScript.Shell
    $ShortcutPath = Join-Path $toolsDir "$ShortcutName.lnk"
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetFile
    $Shortcut.Save()
}

$chocoLib = "$env:ChocolateyInstall\lib"
# Mapping Tool Name -> Probable Path
$toolPaths = @{
    "x64dbg"         = "$chocoLib\x64dbg.portable\tools\release\x64\x64dbg.exe"
    "x32dbg"         = "$chocoLib\x64dbg.portable\tools\release\x32\x32dbg.exe"
    "PEStudio"       = "$chocoLib\PeStudio\tools\pestudio\pestudio.exe"
    "DetectItEasy"   = "$chocoLib\die\tools\die.exe"
    "PE-bear"        = "$chocoLib\pebear\tools\PE-bear.exe"
	"ResourceHacker" = "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe"
    "ProcMon"        = "$chocoLib\sysinternals\tools\Procmon.exe"
    "ProcExp"        = "$chocoLib\sysinternals\tools\procexp.exe"
    "Autoruns"       = "$chocoLib\sysinternals\tools\Autoruns.exe"
    "TCPView"        = "$chocoLib\sysinternals\tools\Tcpview.exe"
    "Wireshark"      = "$env:ProgramFiles\Wireshark\Wireshark.exe"
    "Ghidra"         = "$chocoLib\ghidra\tools\ghidra_12.0_PUBLIC\ghidraRun.bat"
    "dnSpy"          = "$chocoLib\dnspy\tools\dnSpy.exe"
    "HxD"            = "$env:ProgramFiles\HxD\HxD.exe"
    "RegShot"        = "$chocoLib\regshot\bin\Regshot-x64-ANSI.exe"
    "Cmder"          = "C:\tools\Cmder\cmder.exe"
    "ProcessHacker"  = "$env:ProgramFiles\Process Hacker 2\ProcessHacker.exe"
}

foreach ($name in $toolPaths.Keys) {
    $path = $toolPaths[$name]
    if (Test-Path $path) {
        Create-Shortcut -TargetFile $path -ShortcutName $name
        Write-Host " -> Linked $name" -ForegroundColor Green
    } else {
        # Check x86 fallback
        $pathX86 = $path.Replace("ProgramFiles", "ProgramFiles (x86)")
        if (Test-Path $pathX86) {
             Create-Shortcut -TargetFile $pathX86 -ShortcutName $name
             Write-Host " -> Linked $name (x86)" -ForegroundColor Green
        } else {
             Write-Host " -> Binary not found for $name (Path: $path)" -ForegroundColor DarkGray
        }
    }
}

# 6. Set Wallpaper to RED
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
