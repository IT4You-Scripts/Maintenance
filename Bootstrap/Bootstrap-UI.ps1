# Força TLS 1.2 e define erros como críticos
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'

# Verifica se o PowerShell 7 (pwsh) está disponível
function Test-PowerShell7 {
    try { Get-Command pwsh -ErrorAction Stop | Out-Null; return $true } catch { return $false }
}

# Instala via Chocolatey
function Install-ViaChocolatey {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) { throw "Chocolatey não está instalado." }
    choco install powershell-core -y
    if ($LASTEXITCODE -ne 0) { throw "Falha na instalação via Chocolatey." }
}

# Instala via Winget
function Install-ViaWinget {
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) { throw "Winget não está instalado." }
    winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "Falha na instalação via Winget." }
}

# Instala via MSI oficial
function Install-ViaMSI {
    $msiUrl = 'https://github.com/PowerShell/PowerShell/releases/latest/download/PowerShell-7.4.6-win-x64.msi'
    $msiPath = Join-Path $env:TEMP 'PowerShell7.msi'
    Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath
    Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /quiet /norestart" -Wait
    if ($LASTEXITCODE -ne 0) { throw "Falha na instalação via MSI." }
    Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
}

# Garante PS7 instalado (Choco -> Winget -> MSI)
if (!(Test-PowerShell7)) {
    try { Install-ViaChocolatey }
    catch {
        try { Install-ViaWinget }
        catch {
            try { Install-ViaMSI }
            catch { throw "Falha em todas as tentativas de instalar o PowerShell 7." }
        }
    }
}

# Executa a UI remota no PS7 COM -STA (crítico para WPF)
& pwsh -NoProfile -ExecutionPolicy Bypass -STA -Command "irm 'https://raw.githubusercontent.com/IT4You-Scripts/Maintenance/main/UI/UI.ps1' | iex"