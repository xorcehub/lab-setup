<#
.SYNOPSIS
    Resets Docker Desktop after VBS/Hypervisor toggle
    Use this if Docker shows 500 errors after running disable-vbs.bat / enable-vbs.bat
#>

Write-Host "--- DOCKER DESKTOP RESET ---" -ForegroundColor Cyan
Write-Host "This will DELETE all Docker containers, images and volumes." -ForegroundColor Yellow
choice /C YN /M "Continue"
if ($LASTEXITCODE -eq 2) { exit }

# 1. Kill Docker processes
Write-Host "[1/4] Stopping Docker Desktop..."
Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "com.docker.backend" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "com.docker.proxy" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# 2. Shut down WSL (Docker Desktop's default backend) and unregister its distros.
#    Deleting the files without unregistering corrupts WSL state.
Write-Host "[2/4] Resetting Docker WSL distros..."
wsl --shutdown
# ponytail: wsl.exe emits UTF-16LE; without this PS 5.1 captures NUL-mangled
# names and the -like match below silently finds nothing.
[Console]::OutputEncoding = [Text.Encoding]::Unicode
foreach ($distro in (wsl --list --quiet | ForEach-Object { $_.Trim() } | Where-Object { $_ -like "docker-desktop*" })) {
    Write-Host "      Unregistering $distro..."
    wsl --unregister $distro
}

# 3. Remove leftover Hyper-V VMs (only relevant for the legacy Hyper-V backend)
Write-Host "[3/4] Removing Docker Hyper-V VMs (if any)..."
if (Get-Command Get-VM -ErrorAction SilentlyContinue) {
    Get-VM | Where-Object { $_.Name -like "*Docker*" } | Stop-VM -Force -ErrorAction SilentlyContinue
    Get-VM | Where-Object { $_.Name -like "*Docker*" } | Remove-VM -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "      Hyper-V module not available - skipping."
}

# 4. Delete leftover Docker data
Write-Host "[4/4] Deleting Docker data..."
Remove-Item "$env:LOCALAPPDATA\Docker\wsl" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Docker\data" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "--- RESET COMPLETE ---" -ForegroundColor Green
Write-Host "Launch Docker Desktop now - it will rebuild its VM from scratch."
