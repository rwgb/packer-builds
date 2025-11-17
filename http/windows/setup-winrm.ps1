# WinRM Setup Script for Packer
Write-Host "==> Configuring WinRM for Packer..."

# Enable WinRM
Enable-PSRemoting -Force -SkipNetworkProfileCheck

# Configure WinRM
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# Configure firewall
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow
netsh advfirewall firewall add rule name="WinRM-HTTPS" dir=in localport=5986 protocol=TCP action=allow

# Enable HTTPS
$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "packer"
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force

# Restart WinRM
Restart-Service winrm

Write-Host "==> WinRM configured successfully"
