# Bootstrap-Core.ps1
# Ensure PowerShell 7+ (pwsh.exe) is installed

$pwshPath = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwshPath) {
    Write-Host "PowerShell 7+ found."
} else {
    # Try Chocolatey
    try {
        choco install powershell-core -y
    } catch {
        # Try Winget
        try {
            winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements
        } catch {
            # Try MSI
            try {
                Invoke-WebRequest -Uri "https://raw.githubusercontent.com/IT4You-Scripts/Maintenance/main/Installers/PowerShell-7-x64.msi" -OutFile "$env:TEMP\pwsh.msi"
                Start-Process msiexec.exe -ArgumentList "/i $env:TEMP\pwsh.msi /qn" -Wait
            } catch {
                throw "Failed to install PowerShell 7+."
            }
        }
    }
    # Re-check
    $pwshPath = Get-Command pwsh -ErrorAction SilentlyContinue
    if (-not $pwshPath) {
        throw "PowerShell 7+ still not found after installation attempts."
    }
}

# Execute Core script
& pwsh -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/IT4You-Scripts/Maintenance/main/Core/Core.ps1' | iex"