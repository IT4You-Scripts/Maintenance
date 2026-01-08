New-Item -ItemType Directory -Path "C:\IT4You\Logs" -Force
New-Item -ItemType Directory -Path "C:\IT4You\State" -Force

$computerName = $env:COMPUTERNAME
$dateTime = Get-Date -Format "yyyyMMdd_HHmm"
$logDir = "C:\IT4You\Logs\$computerName"
New-Item -ItemType Directory -Path $logDir -Force
$logFile = "$logDir\${computerName}_${dateTime}.json"
$psVersion = $PSVersionTable.PSVersion.ToString()

$header = @{type="header"; computer=$computerName; psVersion=$psVersion} | ConvertTo-Json -Compress
Add-Content -Path $logFile -Value $header -Encoding UTF8NoBOM

$totalSteps = 3
for ($i = 1; $i -le $totalSteps; $i++) {
    $title = "Step $i"
    $state = "running"
    $status = @{step=$i; total=$totalSteps; title=$title; state=$state} | ConvertTo-Json -Compress
    Set-Content -Path "C:\IT4You\State\status.json" -Value $status -Encoding UTF8NoBOM
    $stepLine = @{type="step"; number=$i; key="step$i"; title=$title; status=$state} | ConvertTo-Json -Compress
    Add-Content -Path $logFile -Value $stepLine -Encoding UTF8NoBOM
    Start-Sleep -Seconds 1
    $state = "completed"
    $status = @{step=$i; total=$totalSteps; title=$title; state=$state} | ConvertTo-Json -Compress
    Set-Content -Path "C:\IT4You\State\status.json" -Value $status -Encoding UTF8NoBOM
}

$summary = @{type="summary"; totalSteps=$totalSteps; status="completed"} | ConvertTo-Json -Compress
Add-Content -Path $logFile -Value $summary -Encoding UTF8NoBOM