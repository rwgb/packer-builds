# Windows Cleanup Script
Write-Host "==> Cleaning up Windows..."

# Clear Windows Update cache
Write-Host "Clearing Windows Update cache..."
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Remove-Item C:\Windows\SoftwareDistribution\Download\* -Recurse -Force -ErrorAction SilentlyContinue
Start-Service wuauserv -ErrorAction SilentlyContinue

# Clear temp files
Write-Host "Clearing temp files..."
Remove-Item C:\Windows\Temp\* -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\Users\*\AppData\Local\Temp\* -Recurse -Force -ErrorAction SilentlyContinue

# Clear event logs
Write-Host "Clearing event logs..."
Get-EventLog -LogName * -ErrorAction SilentlyContinue | ForEach-Object { 
    Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue 
}

# Disk cleanup
Write-Host "Running disk cleanup..."
Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -Wait -NoNewWindow -ErrorAction SilentlyContinue

# Defragment drive
Write-Host "Optimizing drive..."
Optimize-Volume -DriveLetter C -Defrag -ErrorAction SilentlyContinue

# Clear PowerShell history
Write-Host "Clearing PowerShell history..."
Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue

Write-Host "==> Cleanup complete"
