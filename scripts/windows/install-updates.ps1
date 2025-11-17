# Install Windows Updates
Write-Host "==> Installing Windows Updates..."

# Install PSWindowsUpdate module
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PSWindowsUpdate -Force -Confirm:$false

# Import the module
Import-Module PSWindowsUpdate

# Install all available updates
Get-WindowsUpdate -AcceptAll -Install -AutoReboot:$false

Write-Host "==> Windows updates installed"
