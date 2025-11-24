# Install Windows Updates
Write-Host "Checking for Windows Updates..."

# Install PSWindowsUpdate module if not present
if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "Installing PSWindowsUpdate module..."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module PSWindowsUpdate -Force
}

Import-Module PSWindowsUpdate

# Install all available updates
Write-Host "Installing Windows Updates (this may take a while)..."
Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot

Write-Host "Windows Updates installation complete!"
