# Windows Cleanup Script
Write-Host "Cleaning up Windows..."

# Clear Windows Update cache
Write-Host "Clearing Windows Update cache..."
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
Remove-Item C:\Windows\SoftwareDistribution\Download\* -Recurse -Force -ErrorAction SilentlyContinue
Start-Service wuauserv

# Clear temp files
Write-Host "Clearing temporary files..."
Remove-Item $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\Windows\Temp\* -Recurse -Force -ErrorAction SilentlyContinue

# Clear Windows logs
Write-Host "Clearing event logs..."
Get-EventLog -LogName * | ForEach-Object { Clear-EventLog $_.Log -ErrorAction SilentlyContinue }

# Clear PowerShell history
Write-Host "Clearing PowerShell history..."
Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue

# Disk cleanup
Write-Host "Running Disk Cleanup..."
Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -Wait -ErrorAction SilentlyContinue

# Defragment drive
Write-Host "Optimizing drive..."
Optimize-Volume -DriveLetter C -Defrag -ErrorAction SilentlyContinue

# Zero out free space (optional - reduces image size)
Write-Host "Zeroing free space (this may take a while)..."
$FilePath = "C:\zero.tmp"
$Volume = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
$ArraySize = 64kb
$SpaceToLeave = $Volume.Size * 0.05
$FileSize = $Volume.FreeSpace - $SpaceToLeave
$ZeroArray = New-Object byte[]($ArraySize)

$Stream = [io.File]::OpenWrite($FilePath)
try {
    $CurFileSize = 0
    while ($CurFileSize -lt $FileSize) {
        $Stream.Write($ZeroArray, 0, $ZeroArray.Length)
        $CurFileSize += $ZeroArray.Length
    }
}
finally {
    if ($Stream) { $Stream.Close() }
    Remove-Item $FilePath -Force -ErrorAction SilentlyContinue
}

Write-Host "Windows cleanup complete!"
