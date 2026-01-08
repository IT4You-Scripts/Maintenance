# UI mínima estável — PowerShell 7, STA requerido
# Mantém tela final por X segundos + botão "Fechar agora"
$ErrorActionPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

Add-Type -AssemblyName PresentationFramework, PresentationCore

# Configurações
$MinWelcomeSeconds = 5      # tempo mínimo (boas-vindas) antes de trocar para final
$FinalHoldSeconds  = 45     # tempo da tela final antes de fechar automaticamente

# Textos
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

function Get-ElapsedMinutes([datetime]$start){ [Math]::Ceiling(((Get-Date)-$start).TotalMinutes) }

# Janela WPF (preto, ~90% opaco, borda arredondada, fade)
$win = New-Object Windows.Window
$win.Title='Manutenção IT4You'
$win.WindowStyle='None'
$win.AllowsTransparency=$true
$win.Background=[Windows.Media.Brushes]::Black
$win.Opacity=0.0
$win.Topmost=$true
$win.Width=820; $win.Height=560
$win.WindowStartupLocation='CenterScreen'

$border=New-Object Windows.Controls.Border
$border.CornerRadius=16
$border.Background=(New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromArgb(230,0,0,0))) # ~90%
$border.Padding=20
$win.Content=$border

$stack=New-Object Windows.Controls.StackPanel
$border.Child=$stack

# Título
$title=New-Object Windows.Controls.TextBlock
$title.Text='Manutenção Preventiva Automatizada'
$title.FontSize=22
$title.FontWeight='Bold'
$title.Foreground=[Windows.Media.Brushes]::White
$title.Margin='0,0,0,10'
$stack.Children.Add($title)

# Texto principal dinâmico
$text=New-Object Windows.Controls.TextBlock
$text.TextWrapping='Wrap'
$text.FontSize=16
$text.Foreground=[Windows.Media.Brushes]::White
$text.Margin='0,5,0,0'
$text.Text=$WelcomeText
$stack.Children.Add($text)

# Progresso
$progress=New-Object Windows.Controls.TextBlock
$progress.TextWrapping='Wrap'
$progress.FontSize=14
$progress.Foreground=[Windows.Media.Brushes]::LightGray
$progress.Margin='0,20,0,0'
$progress.Text='Preparando a manutenção...'
$stack.Children.Add($progress)

# Contador de fechamento
$closing = New-Object Windows.Controls.TextBlock
$closing.TextWrapping='Wrap'
$closing.FontSize=12
$closing.Foreground=[Windows.Media.Brushes]::LightGray
$closing.Margin='0,10,0,0'
$closing.Text=''
$stack.Children.Add($closing)

# Botão Fechar agora
$btn = New-Object Windows.Controls.Button
$btn.Content='Fechar agora'
$btn.HorizontalAlignment='Right'
$btn.Margin='0,10,0,0'
$btn.Visibility='Collapsed'
$btn.Add_Click({
  $animOut=New-Object Windows.Media.Animation.DoubleAnimation($win.Opacity,0.0,[TimeSpan]::FromSeconds(2))
  $animOut.Completed={ $win.Close() }
  $win.BeginAnimation([Windows.UIElement]::OpacityProperty,$animOut)
})
$stack.Children.Add($btn)

$StatusPath='C:\IT4You\State\status.json'
$StartTime=Get-Date
$WelcomeDeadline=$StartTime.AddSeconds($MinWelcomeSeconds)

# Timer 1s: lê status.json e atualiza
$timer=New-Object Windows.Threading.DispatcherTimer
$timer.Interval=[TimeSpan]::FromSeconds(1)
$timer.Add_Tick({
  try{
    if(Test-Path $StatusPath){
      $s=Get-Content $StatusPath -Raw | ConvertFrom-Json
      if($s -and $s.step -and $s.total -and $s.title){
        $progress.Text="Etapa $($s.step)/$($s.total) — $($s.title) [$($s.state)]"
        $text.Text=''  # durante execução, mostra só o progresso
        if($s.step -eq $s.total -and $s.state -eq 'completed'){
          $timer.Stop()

          # Garante tempo mínimo de boas-vindas (evita piscar)
          $now=Get-Date
          if($now -lt $WelcomeDeadline){
            Start-Sleep -Seconds ([int]([Math]::Ceiling(($WelcomeDeadline-$now).TotalSeconds)))
          }

          # Monta texto final e inicia contagem para fechar
          $min=Get-ElapsedMinutes $StartTime
          $finalText=$FinalTextTemplate -replace '\$TempoTotal',$min
          $text.Text=$finalText
          $progress.Text=''
          $btn.Visibility='Visible'
          $remaining=$FinalHoldSeconds
          $closing.Text="Fechando em $remaining s..."

          $t2=New-Object Windows.Threading.DispatcherTimer
          $t2.Interval=[TimeSpan]::FromSeconds(1)
          $t2.Add_Tick({
            try{
              $remaining--
              if($remaining -le 0){
                $t2.Stop()
                $animOut=New-Object Windows.Media.Animation.DoubleAnimation($win.Opacity,0.0,[TimeSpan]::FromSeconds(2))
                $animOut.Completed={ $win.Close() }
                $win.BeginAnimation([Windows.UIElement]::OpacityProperty,$animOut)
              } else {
                $closing.Text="Fechando em $remaining s..."
              }
            }catch{}
          })
          $t2.Start()
        }
      }
    } else {
      $text.Text=$WelcomeText
      $progress.Text='Preparando a manutenção...'
    }
  }catch{}
})

# Fade-in 2s e iniciar timer
$win.Add_Loaded({
  $animIn=New-Object Windows.Media.Animation.DoubleAnimation(0.0,0.9,[TimeSpan]::FromSeconds(2))
  $win.BeginAnimation([Windows.UIElement]::OpacityProperty,$animIn)
  $timer.Start()
})

# ESC fecha
$win.Add_KeyDown({ if ($_.Key -eq 'Escape') { $win.Close() } })

$win.ShowDialog() | Out-Null