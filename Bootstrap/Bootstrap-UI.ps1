# Bootstrap-UI.ps1 (runs in Windows PowerShell 5.1)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'

# URL do UI remoto
$UiUrl = "https://raw.githubusercontent.com/IT4You-Scripts/Maintenance/main/UI/UI.ps1"

# Garantir pasta de estado
$StatePath = "C:\IT4You\State"
if (-not (Test-Path $StatePath)) { New-Item -ItemType Directory -Path $StatePath -Force | Out-Null }

function Test-Pwsh { try { Get-Command pwsh -ErrorAction Stop | Out-Null; $true } catch { $false } }
function Install-Choco {
  if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  }
  choco install powershell-core -y
}
function Install-Winget {
  winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements | Out-Null
}
function Install-MSI {
  $url='https://github.com/PowerShell/PowerShell/releases/latest/download/PowerShell-7.4.6-win-x64.msi'
  $msi=Join-Path $env:TEMP 'PowerShell7.msi'
  Invoke-WebRequest -Uri $url -OutFile $msi -UseBasicParsing
  Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet /norestart" -Wait
  Remove-Item $msi -ErrorAction SilentlyContinue
}

# Garante PS7
if (-not (Test-Pwsh)) {
  try { Install-Choco } catch { try { Install-Winget } catch { Install-MSI } }
  if (-not (Test-Pwsh)) { throw 'PowerShell 7 nao disponivel apos tentativas de instalacao.' }
}

# Baixar UI e remover BOM
$resp = Invoke-WebRequest -Uri $UiUrl -UseBasicParsing
$bytes = [Text.Encoding]::UTF8.GetBytes($resp.Content)
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
  $bytes = $bytes[3..($bytes.Length-1)]
}
$tempUi = Join-Path $env:TEMP 'IT4You-UI.ps1'
[IO.File]::WriteAllBytes($tempUi,$bytes)

# Executar pwsh -STA com logs (console visivel para diagnostico)
$log = Join-Path $StatePath 'ui_boot.log'
$err = Join-Path $StatePath 'ui_boot.err'
Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -File `"$tempUi`"" -WindowStyle Normal -RedirectStandardOutput $log -RedirectStandardError $err -Wait

Remove-Item $tempUi -ErrorAction SilentlyContinue