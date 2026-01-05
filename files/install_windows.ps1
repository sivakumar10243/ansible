# Stop on error
$ErrorActionPreference = "Stop"

$LogFile = "C:\Windows\Temp\unattended_install_windows.log"

# Start logging
Start-Transcript -Path $LogFile -Append

Write-Output "=============================="
Write-Output "Windows Installation started: $(Get-Date)"
Write-Output "=============================="

# Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Check if Chocolatey is installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Output "Chocolatey not found, installing..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

Write-Output "Upgrading all Chocolatey packages..."
choco upgrade all -y

# Marker file (idempotency)
New-Item -ItemType File -Path "C:\Windows\Temp\windows_system_upgraded" -Force

Write-Output "Windows Installation finished: $(Get-Date)"

Stop-Transcript
