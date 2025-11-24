# Setup WinRM for Packer
Write-Host "Setting up WinRM for Packer..."

# Enable WinRM
Write-Host "Enabling WinRM..."
Enable-PSRemoting -Force

# Configure WinRM
Write-Host "Configuring WinRM..."
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'

# Configure firewall
Write-Host "Configuring firewall..."
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow
netsh advfirewall firewall add rule name="WinRM-HTTPS" dir=in localport=5986 protocol=TCP action=allow

# Create self-signed certificate for HTTPS
Write-Host "Creating self-signed certificate..."
$cert = New-SelfSignedCertificate -DnsName "packer" -CertStoreLocation "Cert:\LocalMachine\My"

# Enable HTTPS listener
Write-Host "Enabling HTTPS listener..."
New-Item -Path WSMan:\Localhost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $cert.Thumbprint -Force

# Restart WinRM service
Write-Host "Restarting WinRM service..."
Restart-Service WinRM

# Set network profile to Private
Write-Host "Setting network profile to Private..."
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

Write-Host "WinRM setup complete!"
