# UI WinForms (PowerShell 7+) — Simulação 100% via GitHub (sem usar C:)
# EXECUÇÃO: pwsh.exe -NoProfile -STA -Command "irm 'https://raw.githubusercontent.com/IT4You-Scripts/Maintenance/main/UI/UI.ps1' | iex"
# Requisitos: salvar este arquivo em UTF-8 sem BOM no repositório

$ErrorActionPreference = 'SilentlyContinue'

# --- CONFIG ---
$LogoUrl = 'https://raw.githubusercontent.com/IT4You-Scripts/Maintenance/main/UI/Assets/logo.png'
$SequenceUrl = 'https://raw.githubusercontent.com/IT4You-Scripts/Maintenance/main/UI/Sim/status-sequence.json'
$FinalDelayMs = 1200            # respiro antes de fechar após a última etapa
$MaxRuntimeMinutes = 240        # failsafe
$PollTickMs = 1000              # atualização de status (1s)

# --- Estado compartilhado entre UI e loop de simulação ---
$SyncHash = [hashtable]::Synchronized(@{
  Status   = 'INICIALIZANDO...'
  Encerrar = $false
})

# --- Runspace da UI (STA) ---
$Runspace = [runspacefactory]::CreateRunspace()
$Runspace.ApartmentState = 'STA'
$Runspace.ThreadOptions  = 'ReuseThread'
$Runspace.Open()

$PS = [powershell]::Create()
$PS.Runspace = $Runspace

$UIScript = {
  param($SyncHash, $LogoUrl)

  Add-Type -AssemblyName System.Windows.Forms, System.Drawing

  # DllImport para esconder o cursor no RichTextBox
  $sig = '[DllImport("user32.dll")] public static extern bool HideCaret(IntPtr hWnd);'
  if (-not ([System.Management.Automation.PSTypeName]'Win32.NativeMethodsHUD').Type) {
    $null = Add-Type -MemberDefinition $sig -Name 'NativeMethodsHUD' -Namespace 'Win32' -PassThru
  }

  function New-RoundedRegion([int]$W,[int]$H,[int]$R){
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $R*2
    $p.AddArc(0,0,$d,$d,180,90)
    $p.AddArc($W-$d,0,$d,$d,270,90)
    $p.AddArc($W-$d,$H-$d,$d,$d,0,90)
    $p.AddArc(0,$H-$d,$d,$d,90,90)
    $p.CloseFigure()
    [System.Drawing.Region]::new($p)
  }

  # Form base
  $screen = [System.Windows.Forms.Screen]::PrimaryScreen
  $Form = New-Object System.Windows.Forms.Form
  $Form.FormBorderStyle = 'None'
  $Form.BackColor = [System.Drawing.Color]::Black
  $Form.TopMost = $true
  $Form.Size = New-Object System.Drawing.Size(1280,900)
  $Form.StartPosition = 'Manual'
  $Form.Location = New-Object System.Drawing.Point(
    [int](($screen.Bounds.Width-1280)/2),
    [int](($screen.Bounds.Height-900)/2)
  )
  $Form.Opacity = 0
  $Form.Region = New-RoundedRegion 1280 900 30

  # Fade-in
  $Form.Add_Shown({
    for($i=0;$i -le 94;$i+=2){
      if($this.IsDisposed){break}
      $this.Opacity = $i/100
      [System.Windows.Forms.Application]::DoEvents()
      Start-Sleep -Milliseconds 10
    }
  })

  # Rodapé de status
  $lblStatus = New-Object System.Windows.Forms.Label
  $lblStatus.Dock = 'Bottom'
  $lblStatus.Height = 60
  $lblStatus.TextAlign = 'MiddleCenter'
  $lblStatus.Font = New-Object System.Drawing.Font('Segoe UI',12)
  $lblStatus.ForeColor = [System.Drawing.Color]::White
  $lblStatus.Text = 'INICIALIZANDO...'
  $Form.Controls.Add($lblStatus)

  # Container principal
  $main = New-Object System.Windows.Forms.Panel
  $main.Dock = 'Fill'
  $Form.Controls.Add($main)

  # Painel do logo
  $pLogo = New-Object System.Windows.Forms.Panel
  $pLogo.Dock = 'Top'
  $pLogo.Height = 180
  $pLogo.Padding = New-Object System.Windows.Forms.Padding(0,30,0,10)
  $main.Controls.Add($pLogo)

  # Logo do GitHub
  $pb = New-Object System.Windows.Forms.PictureBox
  $pb.Dock = 'Fill'
  $pb.SizeMode = 'Zoom'
  $pLogo.Controls.Add($pb)
  try{
    $resp = Invoke-WebRequest -Uri $LogoUrl -UseBasicParsing
    $ms = New-Object IO.MemoryStream($resp.Content)
    $pb.Image = [System.Drawing.Image]::FromStream($ms)
    $ms.Close()
  }catch{}

  # Painel texto
  $pText = New-Object System.Windows.Forms.Panel
  $pText.Dock = 'Fill'
  $pText.Padding = New-Object System.Windows.Forms.Padding(45,10,45,10)
  $main.Controls.Add($pText)

  # RichText
  $rtb = New-Object System.Windows.Forms.RichTextBox
  $rtb.Dock = 'Fill'
  $rtb.ReadOnly = $true
  $rtb.BorderStyle = 'None'
  $rtb.BackColor = [System.Drawing.Color]::Black
  $rtb.ForeColor = [System.Drawing.Color]::White
  $rtb.Font = New-Object System.Drawing.Font('Segoe UI Emoji',13)
  $rtb.Add_GotFocus({ [Win32.NativeMethodsHUD]::HideCaret($this.Handle) })
  $pText.Controls.Add($rtb)

  $rtb.Text = @"
`n`n`n`n`n`n`n`n`nPrezado(a) usuário(a),
`nEstamos iniciando a Manutenção Preventiva Automatizada em seu sistema operacional, conforme estabelecido em nosso contrato de manutenção.
`nEste procedimento é realizado de forma totalmente autônoma, diretamente no seu computador, sem qualquer acesso remoto por parte de nossa equipe técnica. A execução segue rigorosamente o calendário de vistorias previamente agendado e comunicado por e-mail à sua empresa, garantindo segurança, transparência e eficiência.
`nPara aprimorar ainda mais este processo, utilizamos recursos avançados de Inteligência Artificial, que permitem analisar o estado do sistema com maior precisão, identificar possíveis inconsistências e aplicar soluções automatizadas, adaptadas às necessidades específicas do seu equipamento.
`nDurante a execução, solicitamos que evite utilizar o computador, a fim de assegurar a integridade da manutenção e prevenir interferências.
`nNossa equipe de desenvolvimento trabalha continuamente para evoluir este script, incorporando melhorias e atualizações que asseguram que seu computador esteja sempre preparado para os desafios tecnológicos mais recentes.
`nEm caso de dúvidas, estamos à disposição pelos canais oficiais:
`nTelefone/WhatsApp: (11) 9.7191-1500
`nE-mail: suporte@it4you.com.br
`nAtenciosamente, Equipe IT4You.
"@
  $hi = @('Manutenção Preventiva Automatizada','totalmente autônoma','sem qualquer acesso remoto','Inteligência Artificial','(11) 9.7191-1500','suporte@it4you.com.br','Equipe IT4You.')
  $green = [System.Drawing.Color]::LightGreen
  foreach($h in $hi){ $i=$rtb.Text.IndexOf($h); if($i -ge 0){ $rtb.Select($i,$h.Length); $rtb.SelectionColor=$green } }
  $rtb.Select(0,0)

  # Timer de UI com remoção de handler (evita PipelineStoppedException)
  $timer = New-Object System.Windows.Forms.Timer
  $timer.Interval = 500
  $tickHandler = {
    try{
      if($Form.IsDisposed -or -not $Form.IsHandleCreated){return}
      if($SyncHash.Status){ $lblStatus.Text = $SyncHash.Status.ToUpper() }
      if($SyncHash.Encerrar){
        $timer.Stop()
        $timer.remove_Tick($tickHandler)
        for($i=94;$i -ge 0;$i-=2){
          if($Form.IsDisposed){break}
          $Form.Opacity=$i/100
          [System.Windows.Forms.Application]::DoEvents()
          Start-Sleep -Milliseconds 10
        }
        if(-not $Form.IsDisposed){ $Form.Close() }
      }
    }catch{}
  }
  $timer.add_Tick($tickHandler)
  $timer.Start()

  # ESC fecha
  $Form.Add_KeyDown({ if($_.KeyCode -eq 'Escape'){ $SyncHash.Encerrar=$true } })

  [System.Windows.Forms.Application]::Run($Form)
}

$PS.AddScript($UIScript).AddArgument($SyncHash).AddArgument($LogoUrl)
$AsyncHandle = $PS.BeginInvoke()

# --- Carrega sequência de simulação do GitHub e executa localmente (NENHUMA escrita em C:) ---
function Get-RemoteSequence {
  try{
    $raw = (Invoke-WebRequest -Uri $SequenceUrl -UseBasicParsing).Content
    if([int]$raw[0] -eq 0xFEFF){ $raw = $raw.Substring(1) } # remove BOM se houver
    return $raw | ConvertFrom-Json
  }catch{
    return $null
  }
}

$seq = Get-RemoteSequence
if(-not $seq -or -not $seq.steps -or -not $seq.total){
  # fallback: sequência padrão se JSON remoto não existir
  $seq = @{
    total = 5
    steps = @(
      @{ title='Preparando ambiente'; durationSec=5 }
      @{ title='Otimização de disco'; durationSec=6 }
      @{ title='Atualizações de software'; durationSec=8 }
      @{ title='Limpeza de temporários'; durationSec=5 }
      @{ title='Validações finais'; durationSec=4 }
    )
  }
}

$start = Get-Date
$stepIndex = 0
foreach($st in $seq.steps){
  $stepIndex++
  $dur = [int]($st.durationSec)
  if($dur -le 0){ $dur = 5 }
  for($s=1; $s -le $dur; $s++){
    $SyncHash.Status = "Etapa $stepIndex/$($seq.total) — $($st.title) [running]"
    Start-Sleep -Milliseconds $PollTickMs
    if(((Get-Date)-$start).TotalMinutes -ge $MaxRuntimeMinutes){ break }
  }
  # marca step como concluído ao final do período
  $SyncHash.Status = "Etapa $stepIndex/$($seq.total) — $($st.title) [completed]"
  Start-Sleep -Milliseconds 300
}

# Final da sequência: pequeno respiro e fechar
Start-Sleep -Milliseconds $FinalDelayMs
$SyncHash.Encerrar = $true

# Aguarda UI concluir (evita PipelineStoppedException)
try{
  if($AsyncHandle -and $AsyncHandle.AsyncWaitHandle){
    $null = $AsyncHandle.AsyncWaitHandle.WaitOne(15000)
  }
}catch{}

# Cleanup
try{ $PS.EndInvoke($AsyncHandle) }catch{}
try{ $PS.Dispose() }catch{}
try{ $Runspace.Close(); $Runspace.Dispose() }catch{}