# Core de TESTE — 5 etapas com ~8s cada para validar a UI
New-Item -ItemType Directory -Path "C:\IT4You\Logs" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\IT4You\State" -Force | Out-Null

$computerName = $env:COMPUTERNAME
$dateTime = Get-Date -Format "yyyyMMdd_HHmm"
$logDir = "C:\IT4You\Logs\$computerName"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$logFile = "$logDir\${computerName}_${dateTime}.json"

$header = @{type="header"; computer=$computerName; psVersion=$PSVersionTable.PSVersion.ToString()} | ConvertTo-Json -Compress
Add-Content -Path $logFile -Value $header -Encoding UTF8NoBOM

$totalSteps = 5
for ($i = 1; $i -le $totalSteps; $i++) {
  $title = "Etapa de teste $i"
  $state = "running"
  $status = @{step=$i; total=$totalSteps; title=$title; state=$state} | ConvertTo-Json -Compress
  Set-Content -Path "C:\IT4You\State\status.json" -Value $status -Encoding UTF8NoBOM

  $stepLine = @{type="step"; number=$i; key="step$i"; title=$title; status=$state} | ConvertTo-Json -Compress
  Add-Content -Path $logFile -Value $stepLine -Encoding UTF8NoBOM

  Start-Sleep -Seconds 8

  $state = "completed"
  $status = @{step=$i; total=$totalSteps; title=$title; state=$state} | ConvertTo-Json -Compress
  Set-Content -Path "C:\IT4You\State\status.json" -Value $status -Encoding UTF8NoBOM
}

$summary = @{type="summary"; totalSteps=$totalSteps; status="completed"} | ConvertTo-Json -Compress
Add-Content -Path $logFile -Value $summary -Encoding UTF8NoBOM