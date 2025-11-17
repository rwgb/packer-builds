# Install QEMU Guest Agent
Write-Host "==> Installing QEMU Guest Agent..."

# Check if running in QEMU/KVM environment
$virtioIso = "E:\"
if (Test-Path $virtioIso) {
    # Install from VirtIO ISO
    $agentPath = "$virtioIso\guest-agent\qemu-ga-x86_64.msi"
    
    if (Test-Path $agentPath) {
        Write-Host "Installing QEMU Guest Agent from VirtIO ISO..."
        Start-Process msiexec.exe -ArgumentList "/i `"$agentPath`" /qn /norestart" -Wait -NoNewWindow
        
        # Start the service
        Start-Service QEMU-GA
        Set-Service QEMU-GA -StartupType Automatic
        
        Write-Host "==> QEMU Guest Agent installed and started"
    } else {
        Write-Host "QEMU Guest Agent installer not found on VirtIO ISO"
    }
} else {
    Write-Host "VirtIO ISO not found, skipping QEMU Guest Agent installation"
}
