Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

$window = New-Object System.Windows.Window
$window.Title = "IT4You UI"
$window.Width = 800
$window.Height = 600
$window.WindowStyle = 'None'
$window.AllowsTransparency = $true
$window.Background = [System.Windows.Media.Brushes]::Black
$window.Opacity = 0.9
$window.BorderThickness = 10
$window.BorderBrush = [System.Windows.Media.Brushes]::Black
$window.CornerRadius = 20

$grid = New-Object System.Windows.Controls.Grid
$window.Content = $grid

$textBlock = New-Object System.Windows.Controls.TextBlock
$textBlock.HorizontalAlignment = 'Center'
$textBlock.VerticalAlignment = 'Center'
$textBlock.FontSize = 24
$textBlock.Foreground = [System.Windows.Media.Brushes]::White
$textBlock.TextWrapping = 'Wrap'
$grid.Children.Add($textBlock)

$image = New-Object System.Windows.Controls.Image
$image.HorizontalAlignment = 'Center'
$image.VerticalAlignment = 'Top'
$image.Width = 200
$image.Height = 100
$image.Source = New-Object System.Windows.Media.Imaging.BitmapImage([System.Uri]::new('https://raw.githubusercontent.com/IT4You-Scripts/Maintenance/main/UI/Assets/logo.png'))
$grid.Children.Add($image)

$startTime = Get-Date

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)
$timer.Add_Tick({
    if (Test-Path 'C:\IT4You\State\status.json') {
        $s = Get-Content 'C:\IT4You\State\status.json' -Raw | ConvertFrom-Json
        $image.Visibility = 'Collapsed'
        $textBlock.Text = "Etapa $($s.step)/$($s.total) — $($s.title) [$($s.state)]"
        if ($s.step -eq $s.total -and $s.state -eq 'completed') {
            # Fade-out em 2s e fechar
            $animOut = New-Object System.Windows.Media.Animation.DoubleAnimation($window.Opacity,0.0,[TimeSpan]::FromSeconds(2))
            $animOut.Completed = { $window.Close() }
            $window.BeginAnimation([System.Windows.UIElement]::OpacityProperty,$animOut)
        }
    } else {
        $image.Visibility = 'Visible'
        $textBlock.Text = "Bem-vindo! A manutenção será iniciada em instantes..."
    }
})
$timer.Start()

# Fade-in 2s
$fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
$fadeIn.From = 0
$fadeIn.To = 0.9
$fadeIn.Duration = [System.Windows.Duration]::new([TimeSpan]::FromSeconds(2))
$window.BeginAnimation([System.Windows.Window]::OpacityProperty, $fadeIn)

$window.ShowDialog() | Out-Null