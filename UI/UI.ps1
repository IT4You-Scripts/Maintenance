# Script WPF para exibir status de manutenção preventiva automatizada
# Deve ser executado com -STA (powershell -STA UI.ps1)

# Parâmetros ajustáveis
$MinWelcomeSeconds = 5
$FinalHoldSeconds = 45

# Caminho do arquivo de status
$StatusFile = "C:\IT4You\State\status.json"

# Silenciar preferências
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
$InformationPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# Adicionar assemblies WPF
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# Função para fechar a janela com fade-out
function Close-Window {
    param($Window)
    $fadeOut = [System.Windows.Media.Animation.DoubleAnimation]::new(0.9, 0, [System.TimeSpan]::FromSeconds(2))
    $fadeOut.Completed += {
        $Window.Close()
    }
    $Window.BeginAnimation([System.Windows.Window]::OpacityProperty, $fadeOut)
}

# Criar janela
$Window = New-Object System.Windows.Window
$Window.Title = "Manutenção Preventiva Automatizada"
$Window.Width = 600
$Window.Height = 300
$Window.WindowStyle = "None"
$Window.AllowsTransparency = $true
$Window.Background = [System.Windows.Media.Brushes]::Black
$Window.Opacity = 0.9
$Window.Topmost = $true
$Window.WindowStartupLocation = "CenterScreen"
$Window.ResizeMode = "NoResize"

# Border para cantos arredondados
$Border = New-Object System.Windows.Controls.Border
$Border.CornerRadius = 20
$Border.Background = [System.Windows.Media.Brushes]::Black
$Border.Opacity = 0.9
$Window.Content = $Border

# Grid principal
$Grid = New-Object System.Windows.Controls.Grid
$Border.Child = $Grid

# Linhas do Grid
$Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height = "Auto"}))  # Título
$Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height = "*"}))    # Texto principal
$Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height = "Auto"}))  # Linha secundária
$Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height = "Auto"}))  # Contagem regressiva
$Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height = "Auto"}))  # Botão

# Título
$TitleText = New-Object System.Windows.Controls.TextBlock
$TitleText.Text = "Manutenção Preventiva Automatizada"
$TitleText.FontSize = 18
$TitleText.FontWeight = "Bold"
$TitleText.Foreground = [System.Windows.Media.Brushes]::White
$TitleText.HorizontalAlignment = "Center"
$TitleText.Margin = "10"
[System.Windows.Controls.Grid]::SetRow($TitleText, 0)
$Grid.Children.Add($TitleText)

# Texto principal (Welcome ou Final)
$MainText = New-Object System.Windows.Controls.TextBlock
$MainText.FontSize = 14
$MainText.Foreground = [System.Windows.Media.Brushes]::White
$MainText.HorizontalAlignment = "Center"
$MainText.TextWrapping = "Wrap"
$MainText.Margin = "10"
[System.Windows.Controls.Grid]::SetRow($MainText, 1)
$Grid.Children.Add($MainText)*