# Install QEMU Guest Agent
Write-Host "Installing QEMU Guest Agent..."

$virtioIsoPath = "E:\virtio-win-gt-x64.msi"

if (Test-Path $virtioIsoPath) {
    Write-Host "Installing from provisioning media..."
    Start-Process msiexec.exe -ArgumentList "/i $virtioIsoPath /qn /norestart" -Wait
} else {
    Write-Host "Downloading QEMU Guest Agent..."
    $url = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win-gt-x64.msi"
    $output = "$env:TEMP\virtio-win-gt-x64.msi"
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $output
    
    Write-Host "Installing QEMU Guest Agent..."
    Start-Process msiexec.exe -ArgumentList "/i $output /qn /norestart" -Wait
    
    Remove-Item $output
}

# Start and enable the service
Write-Host "Starting QEMU Guest Agent service..."
Set-Service -Name "QEMU-GA" -StartupType Automatic
Start-Service -Name "QEMU-GA"

Write-Host "QEMU Guest Agent installation complete!"
