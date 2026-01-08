;# Bootstrap-Core.ps1 (PowerShell 5.1) – garante PS7 e executa Core
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'

function Test-PowerShell7 {
  try { Get-Command pwsh -ErrorAction Stop | Out-Null; $true } catch { $false }
}

function Install-ViaChocolatey {
  if (!(Get-Command choco -ErrorAction SilentlyContinue)) { throw "Chocolatey não está instalado." }
  choco install powershell-core -y | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Falha na instalação via Chocolatey." }
}

function Install-ViaWinget {
  if (!(Get-Command winget -ErrorAction SilentlyContinue)) { throw "Winget não está instalado." }
  winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Falha na instalação via Winget." }
}

function Install-ViaMSI {
  $msiUrl = 'https://github.com/PowerShell/PowerShell/releases/latest/download/PowerShell-7.4.6-win-x64.msi'
  $msiPath = Join-Path $env:TEMP 'PowerShell7.msi'
  Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing
  Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /quiet /norestart" -Wait
  if ($LASTEXITCODE -ne 0) { throw "Falha na instalação via MSI." }
  Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
}

if (!(Test-PowerShell7)) {
  try { Install-ViaChocolatey }
  catch {
    try { Install-ViaWinget }
    catch { Install-ViaMSI }
  }
  if (!(Test-PowerShell7)) { throw "PowerShell 7 não disponível após instalação." }
}

$coreUrl = 'https://raw.githubusercontent.com/IT4You-Scripts/Maintenance/main/Core/Core.ps1'
& pwsh -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "irm '$coreUrl' | iex"