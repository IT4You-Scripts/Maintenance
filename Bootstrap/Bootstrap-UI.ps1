# Bootstrap-UI.ps1

$pwshPath = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwshPath) {
    Write-Host "PowerShell 7+ encontrado."
} else {
    Write-Host "Instalando PowerShell 7+..."
    
    # Tentar Chocolatey
    try {
        choco install powershell-core -y
    } catch {
        Write-Host "Chocolatey falhou. Tentando Winget..."
        
        # Tentar Winget
        try {
            winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements
        } catch {
            Write-Host "Winget falhou. Tentando MSI..."
            
            # Baixar e instalar MSI
            $msiUrl = "https://raw.githubusercontent.com/IT4You-Scripts/Maintenance/main/Installers/PowerShell-7-x64.msi"
            $msiPath = "$env:TEMP\pwsh.msi"
            Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath
            Start-Process msiexec.exe -ArgumentList "/i $msiPath /qn" -Wait
        }
    }
    
    # Re-verificar
    $pwshPath = Get-Command pwsh -ErrorAction SilentlyContinue
    if (-not $pwshPath) {
        throw "Falha ao instalar PowerShell 7+."
    }
}

# Executar UI script
$url = "https://raw.githubusercontent.com/IT4You-Scripts/Maintenance/main/UI/UI.ps1"
& pwsh -NoProfile -ExecutionPolicy Bypass -Command "irm '$url' | iex"