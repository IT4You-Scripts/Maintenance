# UI WinForms (PowerShell 7+) - Usa SUA tela original, com leitura do status.json e fechamento automático
# SALVAR COMO UTF-8 SEM BOM. Executar com: pwsh.exe -NoProfile -STA -File UI.ps1

$ErrorActionPreference = 'SilentlyContinue'

# --- Configurações ---
$StatusPath = 'C:\IT4You\State\status.json'  # arquivo escrito pelo Core
$LogoPath   = 'C:\IT4You\Scripts\Logotipo.png'
$PollIntervalSeconds = 1                     # frequência de leitura do status.json
$FinalDelayMs = 2000                         # ms para a animação final antes de fechar
$MaxRuntimeMinutes = 180                     # failsafe: fecha após X minutos (evita travar para sempre)

# --- DllImport para esconder o caret no RichTextBox ---
$signature = @"
[DllImport("user32.dll")]
public static extern bool HideCaret(IntPtr hWnd);
"@
if (-not ([System.Management.Automation.PSTypeName]'Win32.NativeMethods').Type) {
    Add-Type -MemberDefinition $signature -Name NativeMethods -Namespace Win32
}

# --- Função: sua HUD em WinForms, com fade e cantos arredondados ---
function Show-StartScreen {
    param([hashtable]$SyncData)

    $rs = [RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = 'STA'
    $rs.ThreadOptions  = 'ReuseThread'
    $rs.Open()
    $rs.SessionStateProxy.SetVariable('SyncData', $SyncData)

    $scriptBlock = {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        # DllImport local p/ HUD
        $sig = '[DllImport("user32.dll")] public static extern bool HideCaret(IntPtr hWnd);'
        if (-not ([System.Management.Automation.PSTypeName]'Win32.NativeMethodsHUD').Type) {
            $null = Add-Type -MemberDefinition $sig -Name 'NativeMethodsHUD' -Namespace 'Win32' -PassThru
        }

        function Set-RoundedRegion {
            param($targetForm, [int]$radius)
            $path = New-Object System.Drawing.Drawing2D.GraphicsPath
            $rect = New-Object System.Drawing.Rectangle(0, 0, $targetForm.Width, $targetForm.Height)
            $dim = $radius * 2
            $path.AddArc($rect.X, $rect.Y, $dim, $dim, 180, 90)
            $path.AddArc($rect.Right - $dim, $rect.Y, $dim, $dim, 270, 90)
            $path.AddArc($rect.Right - $dim, $rect.Bottom - $dim, $dim, $dim, 0, 90)
            $path.AddArc($rect.X, $rect.Bottom - $dim, $dim, $dim, 90, 90)
            $path.CloseFigure()
            $targetForm.Region = New-Object System.Drawing.Region($path)
        }

        $primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
        $form = New-Object System.Windows.Forms.Form
        $form.StartPosition   = 'Manual'
        $form.FormBorderStyle = 'None'
        $form.Size     = New-Object System.Drawing.Size(1280, 900)
        $form.Location = New-Object System.Drawing.Point(
            [int](($primaryScreen.Bounds.Width  - 1280) / 2),
            [int](($primaryScreen.Bounds.Height - 900)  / 2)
        )
        $form.BackColor = [System.Drawing.Color]::Black
        $form.TopMost   = $true
        $form.Opacity   = 0

        # Fade-in
        $form.Add_Shown({
            for ($i = 0; $i -le 94; $i += 2) {
                $this.Opacity = $i / 100
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 10
            }
        })

        Set-RoundedRegion -targetForm $form -radius 30

        # 1) Status (rodapé)
        $lblStatus = New-Object System.Windows.Forms.Label
        $lblStatus.Dock = [System.Windows.Forms.DockStyle]::Bottom
        $lblStatus.Height = 60
        $lblStatus.ForeColor = [System.Drawing.Color]::White
        $lblStatus.Font = New-Object System.Drawing.Font('Segoe UI', 12)
        $lblStatus.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $lblStatus.Text = 'INICIALIZANDO...'
        $form.Controls.Add($lblStatus)

        # 2) Container principal
        $mainContainer = New-Object System.Windows.Forms.Panel
        $mainContainer.Dock = [System.Windows.Forms.DockStyle]::Fill
        $form.Controls.Add($mainContainer)

        # 3) Painel do logo
        $logoContainer = New-Object System.Windows.Forms.Panel
        $logoContainer.Dock = [System.Windows.Forms.DockStyle]::Top
        $logoContainer.Height = 180
        $logoContainer.Padding = New-Object System.Windows.Forms.Padding(0, 30, 0, 10)
        $mainContainer.Controls.Add($logoContainer)

        # 4) Painel texto
        $textContainer = New-Object System.Windows.Forms.Panel
        $textContainer.Dock = [System.Windows.Forms.DockStyle]::Fill
        $textContainer.Padding = New-Object System.Windows.Forms.Padding(45, 10, 45, 10)
        $mainContainer.Controls.Add($textContainer)

        # Logo local (opcional)
        try {
            if (Test-Path $using:LogoPath) {
                $pbLogo = New-Object System.Windows.Forms.PictureBox
                $pbLogo.Image = [System.Drawing.Image]::FromFile($using:LogoPath)
                $pbLogo.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
                $pbLogo.Dock = [System.Windows.Forms.DockStyle]::Fill
                $logoContainer.Controls.Add($pbLogo)
            }
        } catch {}

        # Texto rico
        $richTextBox = New-Object System.Windows.Forms.RichTextBox
        $richTextBox.BackColor = [System.Drawing.Color]::Black
        $richTextBox.ForeColor = [System.Drawing.Color]::White
        $richTextBox.Font = New-Object System.Drawing.Font('Segoe UI Emoji', 13)
        $richTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
        $richTextBox.ReadOnly = $true
        $richTextBox.Dock = [System.Windows.Forms.DockStyle]::Fill
        $richTextBox.Add_GotFocus({ [Win32.NativeMethodsHUD]::HideCaret($this.Handle) })

        # Texto de boas-vindas (o seu, com quebras corretas)
        $richTextBox.Text = @"
`n`n`n`n`n`n`nPrezado(a) usuário(a),
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

        # Destaques
        $green = [System.Drawing.Color]::LightGreen
        $highlights = @('Manutenção Preventiva Automatizada','totalmente autônoma','sem qualquer acesso remoto','Inteligência Artificial','(11) 9.7191-1500','suporte@it4you.com.br','Equipe IT4You.')
        foreach ($h in $highlights) {
            $idx = $richTextBox.Text.IndexOf($h)
            if ($idx -ge 0) { $richTextBox.Select($idx, $h.Length); $richTextBox.SelectionColor = $green }
        }
        $richTextBox.Select(0,0)
        $textContainer.Controls.Add($richTextBox)

        # Timer de UI (atualiza status e fecha quando SyncData.Encerrar = $true)
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 500
        $timer.Add_Tick({
            if ($SyncData.Status)   { $lblStatus.Text = $SyncData.Status.ToUpper() }
            if ($SyncData.Encerrar) {
                $timer.Stop()
                for ($i = 94; $i -ge 0; $i -= 2) {
                    $form.Opacity = $i / 100
                    [System.Windows.Forms.Application]::DoEvents()
                    Start-Sleep -Milliseconds 10
                }
                $form.Close()
            }
        })
        $timer.Start()

        [System.Windows.Forms.Application]::Run($form)
    }

    $ps = [PowerShell]::Create().AddScript($scriptBlock)
    $ps.Runspace = $rs
    $global:HUD_Handle = $ps.BeginInvoke()
    return $rs
}

# --- Estado compartilhado entre o poller e a HUD ---
if (-not $global:SyncHash) {
    $global:SyncHash = [hashtable]::Synchronized(@{ Status = 'INICIALIZANDO...'; Encerrar = $false })
}

# --- Exibe sua HUD ---
$hudRunspace = Show-StartScreen -SyncData $global:SyncHash

# --- Polling do status.json (fecha quando última etapa estiver 'completed') ---
$start = Get-Date
while ($true) {
    try {
        if (Test-Path $StatusPath) {
            $s = Get-Content $StatusPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($s -and $s.step -and $s.total -and $s.title) {
                $global:SyncHash.Status = "Etapa $($s.step)/$($s.total) — $($s.title) [$($s.state)]"
                if ($s.step -eq $s.total -and $s.state -eq 'completed') {
                    Start-Sleep -Milliseconds $FinalDelayMs
                    $global:SyncHash.Encerrar = $true
                    break
                }
            } else {
                $global:SyncHash.Status = 'INICIALIZANDO...'
            }
        } else {
            $global:SyncHash.Status = 'INICIALIZANDO...'
        }
    } catch {
        $global:SyncHash.Status = 'INICIALIZANDO...'
    }

    # Failsafe: fecha após MaxRuntimeMinutes
    if (((Get-Date) - $start).TotalMinutes -ge $MaxRuntimeMinutes) {
        $global:SyncHash.Encerrar = $true
        break
    }

    Start-Sleep -Seconds $PollIntervalSeconds
}

# --- Limpa runspace da HUD com segurança ---
try {
    if ($hudRunspace) { $hudRunspace.Close(); $hudRunspace.Dispose() }
} catch {}