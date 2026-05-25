<#
.SYNOPSIS
    Resets Docker Desktop after VBS/Hypervisor toggle
    Use this if Docker shows 500 errors after running disable-vbs.bat / enable-vbs.bat
#>

Write-Host "--- DOCKER DESKTOP RESET ---" -ForegroundColor Cyan

# 1. Kill Docker processes
Write-Host "[1/4] Stopping Docker Desktop..."
Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "com.docker.backend" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "com.docker.proxy" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# 2. Stop Docker services
Write-Host "[2/4] Stopping Docker services..."
Stop-Service -Name "com.docker*" -Force -ErrorAction SilentlyContinue

# 3. Remove Docker VMs from Hyper-V
Write-Host "[3/4] Removing Docker Hyper-V VMs..."
Get-VM | Where-Object { $_.Name -like "*Docker*" } | Stop-VM -Force -ErrorAction SilentlyContinue
Get-VM | Where-Object { $_.Name -like "*Docker*" } | Remove-VM -Force -ErrorAction SilentlyContinue

# 4. Delete Docker VM data
Write-Host "[4/4] Deleting Docker VM data..."
Remove-Item "$env:LOCALAPPDATA\Docker\wsl" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Docker\data" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "--- RESET COMPLETE ---" -ForegroundColor Green
Write-Host "Launch Docker Desktop now — it will rebuild its VM from scratch."
