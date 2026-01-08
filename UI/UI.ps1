# UI.ps1 – PowerShell 7 (executar em STA)
Add-Type -AssemblyName PresentationFramework, PresentationCore
$ErrorActionPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

# Textos (Boas-vindas e Finalização)
$WelcomeText = @"
Prezado(a) usuário(a),
Estamos iniciando a Manutenção Preventiva Automatizada em seu sistema operacional, conforme estabelecido em nosso contrato de manutenção.
Este procedimento é realizado de forma totalmente autônoma, diretamente no seu computador, sem qualquer acesso remoto por parte de nossa equipe técnica. A execução segue rigorosamente o calendário de vistorias previamente agendado e comunicado por e-mail à sua empresa, garantindo segurança, transparência e eficiência.
Para aprimorar ainda mais este processo, utilizamos recursos avançados de Inteligência Artificial, que permitem analisar o estado do sistema com maior precisão, identificar possíveis inconsistências e aplicar soluções automatizadas, adaptadas às necessidades específicas do seu equipamento.
Durante a execução, solicitamos que evite utilizar o computador, a fim de assegurar a integridade da manutenção e prevenir interferências.
Nossa equipe de desenvolvimento trabalha continuamente para evoluir este script, incorporando melhorias e atualizações que asseguram que seu computador esteja sempre preparado para os desafios tecnológicos mais recentes.
Em caso de dúvidas, estamos à disposição pelos canais oficiais:
Telefone/WhatsApp: (11) 9.7191-1500
E-mail: suporte@it4you.com.br
Atenciosamente, Equipe IT4You.
"@

$FinalTextTemplate = @"
A Manutenção Preventiva Automatizada foi finalizada com Sucesso!
Agradecemos imensamente sua paciência e compreensão durante o processo, que durou $TempoTotal minutos e exigiu que você aguardasse sem poder utilizar seu computador. Entendemos que esse tempo de espera pode ter causado algum inconveniente, mas gostaríamos de ressaltar a importância dessa manutenção para garantir o bom funcionamento e a longevidade do seu equipamento.
Durante a manutenção preventiva, foram realizadas diversas tarefas importantes, tais como:
• Inventário (com alertas C: e saúde SSD)
• Verificação/reparo SFC/DISM (quando necessário)
• Otimização de energia
• Otimização de rede (TCP/IP/DNS)
• Limpeza de cache dos navegadores
• Esvaziamento de lixeiras
• Limpeza de temporários + manutenção leve DISM
• Limpeza do cache do Windows Update
• Bloqueio de updates do QGIS
• Atualização via Winget
• Atualização via Chocolatey
• Atualização do Windows (WUA/COM)
• Remoção de temporários de componentes (atualizações antigas)
• Otimização para SSDs
• Desfragmentação de HDDs elegíveis
• Varredura rápida antimalware
• Diagnóstico da bateria (notebooks)
• Validação do Macrium Reflect
• Limpeza do histórico “Arquivos recentes”
• Centralização do log mais recente no servidor

Agora que a manutenção foi concluída, você já pode retomar suas atividades normalmente.
Em caso de dúvidas, estamos à disposição pelos canais oficiais:
Telefone/WhatsApp: (11) 9.7191-1500
E-mail: suporte@it4you.com.br
Atenciosamente, Equipe IT4You.
"@

# Utilitário: minutos decorridos arredondando para cima
function Get-ElapsedMinutes([datetime]$start){ [Math]::Ceiling(((Get-Date) - $start).TotalMinutes) }

# Janela WPF com visual solicitado
$win = New-Object Windows.Window
$win.Title = "Manutenção IT4You"
$win.Width = 800; $win.Height = 560
$win.WindowStartupLocation = 'CenterScreen'
$win.WindowStyle = 'None'
$win.AllowsTransparency = $true
$win.Background = [Windows.Media.Brushes]::Black
$win.Opacity = 0.0
$win.Topmost = $true

# Container arredondado
$border = New-Object Windows.Controls.Border
$border.CornerRadius = 16
$border.Background = (New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(230,0,0,0))) # ~90% opaco
$border.Padding = 20
$win.Content = $border

# Layout
$stack = New-Object Windows.Controls.StackPanel
$stack.HorizontalAlignment = 'Stretch'
$stack.VerticalAlignment = 'Stretch'
$border.Child = $stack

# Logo
$logo = New-Object Windows.Controls.Image
$logo.Width = 220; $logo.Height = 80
try {
  $logo.Source = New-Object Windows.Media.Imaging.BitmapImage([Uri]'https://raw.githubusercontent.com/IT4You-Scripts/Maintenance/main/UI/Assets/logo.png')
} catch {}
$logo.HorizontalAlignment = 'Center'
$logo.Margin = '0,0,0,10'
$stack.Children.Add($logo)

# Texto (dinâmico)
$text = New-Object Windows.Controls.TextBlock
$text.TextWrapping = 'Wrap'
$text.FontSize = 16
$text.Foreground = [Windows.Media.Brushes]::White
$text.Margin = '0,10,0,0'
$text.Text = $WelcomeText
$stack.Children.Add($text)

# Barra de status (opcional simples)
$progress = New-Object Windows.Controls.TextBlock
$progress.TextWrapping = 'Wrap'
$progress.FontSize = 14
$progress.Foreground = [Windows.Media.Brushes]::LightGray
$progress.Margin = '0,20,0,0'
$stack.Children.Add($progress)

$startTime = Get-Date
$statusPath = 'C:\IT4You\State\status.json'

# Timer 1s para ler status.json e alternar modos
$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)
$timer.Add_Tick({
  try {
    if (Test-Path $statusPath) {
      $s = Get-Content $statusPath -Raw | ConvertFrom-Json
      if ($s -and $s.step -and $s.total -and $s.title) {
        $progress.Text = "Etapa $($s.step)/$($s.total) — $($s.title) [$($s.state)]"
        $text.Text = ""
        if ($s.step -eq $s.total -and $s.state -eq 'completed') {
          $timer.Stop()
          $min = Get-ElapsedMinutes $startTime
          $finalText = $FinalTextTemplate -replace '\$TempoTotal', $min
          $text.Text = $finalText
          $progress.Text = ""
          Start-Sleep -Seconds 3
          # Fade-out 2s
          $animOut = New-Object Windows.Media.Animation.DoubleAnimation($win.Opacity,0.0,[TimeSpan]::FromSeconds(2))
          $animOut.Completed = { $win.Close() }
          $win.BeginAnimation([Windows.UIElement]::OpacityProperty,$animOut)
        }
      }
    } else {
      # Ainda em boas-vindas
      $text.Text = $WelcomeText
      $progress.Text = "Preparando a manutenção..."
    }
  } catch {
    # Silencia erros para evitar mensagens em vermelho
  }
})

# Fade-in 2s ao carregar
$win.Add_Loaded({
  $animIn = New-Object Windows.Media.Animation.DoubleAnimation(0.0,0.9,[TimeSpan]::FromSeconds(2))
  $win.BeginAnimation([Windows.UIElement]::OpacityProperty,$animIn)
  $timer.Start()
})

# Fecha com ESC
$win.Add_KeyDown({ if ($_.Key -eq 'Escape') { $win.Close() } })

# Exibe
$win.ShowDialog() | Out-Null