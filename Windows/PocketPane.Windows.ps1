Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$script:Tools = @{
    adb = $null
    scrcpy = $null
}
$script:Devices = @()
$script:Services = @()
$script:SelectedSerial = $null
$script:IsRefreshingUi = $false
$script:LastConnectAddressPath = Join-Path $env:LOCALAPPDATA "PocketPane\settings.txt"

$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="PocketPane for Windows"
    Width="980"
    Height="720"
    MinWidth="860"
    MinHeight="620"
    WindowStartupLocation="CenterScreen"
    Background="#101722"
    Foreground="#F7FAFC"
    AllowDrop="True">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Margin" Value="0,4,8,4"/>
            <Setter Property="Padding" Value="12,7"/>
            <Setter Property="MinHeight" Value="34"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Margin" Value="0,4,8,4"/>
            <Setter Property="Padding" Value="8,5"/>
        </Style>
        <Style TargetType="PasswordBox">
            <Setter Property="Margin" Value="0,4,8,4"/>
            <Setter Property="Padding" Value="8,5"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Margin" Value="0,4,8,4"/>
            <Setter Property="MinHeight" Value="32"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Margin" Value="0,5,10,5"/>
            <Setter Property="Foreground" Value="#D8E1EC"/>
        </Style>
        <Style TargetType="GroupBox">
            <Setter Property="Margin" Value="0,0,0,14"/>
            <Setter Property="Padding" Value="14"/>
            <Setter Property="Foreground" Value="#F7FAFC"/>
            <Setter Property="BorderBrush" Value="#334155"/>
        </Style>
    </Window.Resources>

    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <DockPanel Grid.Row="0" Margin="0,0,0,18">
            <StackPanel DockPanel.Dock="Left">
                <TextBlock Text="PocketPane" FontSize="28" FontWeight="Bold"/>
                <TextBlock Text="Mirror and control Android from Windows" Foreground="#9FB0C3"/>
            </StackPanel>
            <Button x:Name="RefreshButton" DockPanel.Dock="Right" Content="Refresh" Width="110" HorizontalAlignment="Right"/>
        </DockPanel>

        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="390"/>
            </Grid.ColumnDefinitions>

            <StackPanel Grid.Column="0" Margin="0,0,18,16">
                <GroupBox Header="Devices">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="220"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        <ListBox x:Name="DeviceList" Grid.Row="0" Background="#0B111A" Foreground="#F7FAFC" BorderBrush="#334155"/>
                        <WrapPanel Grid.Row="1" Margin="0,12,0,0">
                            <Button x:Name="MirrorButton" Content="Start mirroring" Width="150"/>
                            <Button x:Name="ScreenshotButton" Content="Save screenshot" Width="150"/>
                            <Button x:Name="RecordButton" Content="Record MP4" Width="120"/>
                            <Button x:Name="DisconnectButton" Content="Disconnect" Width="120"/>
                        </WrapPanel>
                    </Grid>
                </GroupBox>

                <GroupBox Header="Mirroring options">
                    <StackPanel>
                        <UniformGrid Columns="2">
                            <StackPanel Margin="0,0,12,0">
                                <TextBlock Text="Resolution limit" Foreground="#B8C4D2"/>
                                <ComboBox x:Name="MaxSizeBox" SelectedIndex="1">
                                    <ComboBoxItem Content="1280"/>
                                    <ComboBoxItem Content="1920"/>
                                    <ComboBoxItem Content="Native"/>
                                </ComboBox>
                            </StackPanel>
                            <StackPanel>
                                <TextBlock Text="Frame rate" Foreground="#B8C4D2"/>
                                <ComboBox x:Name="MaxFpsBox" SelectedIndex="1">
                                    <ComboBoxItem Content="30"/>
                                    <ComboBoxItem Content="60"/>
                                    <ComboBoxItem Content="120"/>
                                </ComboBox>
                            </StackPanel>
                        </UniformGrid>
                        <WrapPanel Margin="0,8,0,0">
                            <CheckBox x:Name="StayAwakeBox" Content="Keep phone awake" IsChecked="True"/>
                            <CheckBox x:Name="ScreenOffBox" Content="Turn phone screen off"/>
                            <CheckBox x:Name="NoAudioBox" Content="Disable audio"/>
                            <CheckBox x:Name="ShowTouchesBox" Content="Show touches"/>
                            <CheckBox x:Name="BorderlessBox" Content="Borderless window"/>
                        </WrapPanel>
                        <TextBlock Text="Drop files anywhere in this window to send them to Android Downloads." Foreground="#7F91A6" Margin="0,10,0,0"/>
                    </StackPanel>
                </GroupBox>

                <GroupBox Header="Android app launcher">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="150"/>
                        </Grid.RowDefinitions>
                        <DockPanel>
                            <TextBox x:Name="AppSearchBox" DockPanel.Dock="Left" Width="300" Text=""/>
                            <Button x:Name="LoadAppsButton" Content="Load apps" Width="110"/>
                            <Button x:Name="LaunchAppButton" Content="Open selected" Width="130"/>
                        </DockPanel>
                        <ListBox x:Name="AppList" Grid.Row="1" Background="#0B111A" Foreground="#F7FAFC" BorderBrush="#334155"/>
                    </Grid>
                </GroupBox>
            </StackPanel>

            <StackPanel Grid.Column="1" Margin="0,0,0,16">
                <GroupBox Header="First time: pair">
                    <StackPanel>
                        <TextBlock Text="On Android, open Developer options, Wireless debugging, then Pair device with pairing code." TextWrapping="Wrap" Foreground="#B8C4D2"/>
                        <TextBlock Text="After pairing succeeds, close the pairing-code pop-up on the phone. The main Wireless debugging screen shows the separate connection IP and port." TextWrapping="Wrap" Foreground="#7F91A6" Margin="0,8,0,0"/>
                        <TextBox x:Name="PairAddressBox" ToolTip="Pairing IP and port"/>
                        <PasswordBox x:Name="PairCodeBox" ToolTip="Current 6 digit pairing code"/>
                        <WrapPanel>
                            <Button x:Name="FindPairButton" Content="Find pairing address" Width="160"/>
                            <Button x:Name="PairButton" Content="Pair device" Width="120"/>
                        </WrapPanel>
                    </StackPanel>
                </GroupBox>

                <GroupBox Header="Connect">
                    <StackPanel>
                        <TextBlock Text="Use the IP and port from the main Wireless debugging screen. It is different from the pairing port above." TextWrapping="Wrap" Foreground="#B8C4D2"/>
                        <TextBox x:Name="ConnectAddressBox" ToolTip="Connection IP and port"/>
                        <Button x:Name="ConnectButton" Content="Connect over Wi-Fi" Width="170" HorizontalAlignment="Left"/>
                    </StackPanel>
                </GroupBox>

                <GroupBox Header="USB shortcut">
                    <StackPanel>
                        <TextBlock Text="Plug in and authorize the phone once; PocketPane can switch ADB to Wi-Fi." TextWrapping="Wrap" Foreground="#B8C4D2"/>
                        <Button x:Name="UsbWirelessButton" Content="Enable wireless via USB" Width="190" HorizontalAlignment="Left"/>
                    </StackPanel>
                </GroupBox>

                <GroupBox Header="Compatibility">
                    <StackPanel>
                        <TextBlock Text="Android 16: supported by scrcpy and ADB wireless debugging." TextWrapping="Wrap" Foreground="#D8E1EC"/>
                        <TextBlock Text="Galaxy A53 5G: supported when One UI 8 / Android 16 is installed and Wireless debugging is enabled." TextWrapping="Wrap" Foreground="#D8E1EC" Margin="0,6,0,0"/>
                    </StackPanel>
                </GroupBox>
            </StackPanel>
        </Grid>
        </ScrollViewer>

        <Border Grid.Row="2" BorderBrush="#243244" BorderThickness="1,1,0,0" Padding="0,12,0,0">
            <TextBlock x:Name="StatusText" Text="Checking tools..." Foreground="#B8C4D2" TextTrimming="CharacterEllipsis"/>
        </Border>
    </Grid>
</Window>
"@

function Get-NamedElement {
    param([System.Windows.Window]$Window, [string]$Name)
    $element = $Window.FindName($Name)
    if ($null -eq $element) {
        throw "Missing UI element: $Name"
    }
    return $element
}

function Set-Status {
    param([string]$Message)
    $StatusText.Text = $Message
}

function Find-Tool {
    param([string]$Name)

    $roots = New-Object System.Collections.Generic.List[string]
    $scriptDir = Split-Path -Parent $PSCommandPath
    $repoRoot = Split-Path -Parent $scriptDir
    $roots.Add($scriptDir)
    $roots.Add((Join-Path $scriptDir "bin"))
    $roots.Add((Join-Path $repoRoot ".tools"))
    $roots.Add((Join-Path $repoRoot ".tools\scrcpy-win64-v4.0"))
    $roots.Add((Join-Path $repoRoot ".tools\scrcpy-win64-v3.3.3"))

    if ($env:ANDROID_HOME) {
        $roots.Add((Join-Path $env:ANDROID_HOME "platform-tools"))
    }
    if ($env:ANDROID_SDK_ROOT) {
        $roots.Add((Join-Path $env:ANDROID_SDK_ROOT "platform-tools"))
    }

    $roots.Add("$env:LOCALAPPDATA\Android\Sdk\platform-tools")
    $roots.Add("C:\Android\platform-tools")
    $roots.Add("C:\Program Files\scrcpy")
    $roots.Add("C:\Program Files (x86)\scrcpy")

    foreach ($entry in ($env:PATH -split ";")) {
        if (-not [string]::IsNullOrWhiteSpace($entry)) {
            $roots.Add($entry)
        }
    }

    foreach ($root in $roots) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        $candidate = Join-Path $root $Name
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }
    return $null
}

function Locate-Tools {
    $script:Tools.adb = Find-Tool "adb.exe"
    $script:Tools.scrcpy = Find-Tool "scrcpy.exe"
}

function Show-MissingAdbMessage {
    Set-Status "adb.exe not found. Run Windows\Install-Tools-Windows.cmd, then Refresh."
}

function Show-MissingScrcpyMessage {
    Set-Status "scrcpy.exe not found. Run Windows\Install-Tools-Windows.cmd, then Refresh."
}

function Ensure-Adb {
    if (-not $script:Tools.adb) { Locate-Tools }
    if (-not $script:Tools.adb) {
        Show-MissingAdbMessage
        Refresh-UiState
        return $false
    }
    return $true
}

function Ensure-Scrcpy {
    if (-not $script:Tools.scrcpy) { Locate-Tools }
    if (-not $script:Tools.scrcpy) {
        Show-MissingScrcpyMessage
        Refresh-UiState
        return $false
    }
    return $true
}

function Invoke-UiAction {
    param([scriptblock]$Action)

    try {
        & $Action
    } catch {
        Set-Status "Error: $($_.Exception.Message)"
        [System.Windows.MessageBox]::Show(
            $_.Exception.Message,
            "PocketPane error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
}

function Invoke-CommandLine {
    param(
        [string]$FileName,
        [string[]]$Arguments
    )

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo.FileName = $FileName
    $process.StartInfo.Arguments = ($Arguments | ForEach-Object {
        if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
    }) -join " "
    $process.StartInfo.WorkingDirectory = Split-Path -Parent $FileName
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.CreateNoWindow = $true

    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    [pscustomobject]@{
        ExitCode = $process.ExitCode
        Output = (($stdout + "`n" + $stderr).Trim())
        Succeeded = $process.ExitCode -eq 0
    }
}

function Start-External {
    param(
        [string]$FileName,
        [string[]]$Arguments
    )

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo.FileName = $FileName
    $process.StartInfo.Arguments = ($Arguments | ForEach-Object {
        if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
    }) -join " "
    $process.StartInfo.WorkingDirectory = Split-Path -Parent $FileName
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $false
    [void]$process.Start()
}

function Normalize-Endpoint {
    param(
        [string]$InputValue,
        [Nullable[int]]$DefaultPort = $null
    )

    $value = $InputValue.Trim()
    if ([string]::IsNullOrWhiteSpace($value) -or $value -match "\s") {
        return $null
    }

    if ($value.StartsWith("[")) {
        $closing = $value.IndexOf("]")
        if ($closing -lt 1) { return $null }
        $suffix = $value.Substring($closing + 1)
        if ($suffix.Length -eq 0 -and $DefaultPort.HasValue) {
            return "$value`:$($DefaultPort.Value)"
        }
        if ($suffix -notmatch '^:(\d+)$') { return $null }
        $port = [int]$Matches[1]
        if ($port -lt 1 -or $port -gt 65535) { return $null }
        return $value
    }

    $colonCount = ([regex]::Matches($value, ":")).Count
    if ($colonCount -eq 0) {
        if (-not $DefaultPort.HasValue) { return $null }
        return "$value`:$($DefaultPort.Value)"
    }

    if ($colonCount -eq 1) {
        $parts = $value.Split(":")
        if ([string]::IsNullOrWhiteSpace($parts[0]) -or $parts[1] -notmatch '^\d+$') { return $null }
        $port = [int]$parts[1]
        if ($port -lt 1 -or $port -gt 65535) { return $null }
        return $value
    }

    if ($DefaultPort.HasValue) {
        return "[$value]:$($DefaultPort.Value)"
    }
    return $null
}

function Parse-Devices {
    param([string]$Output)

    $devices = @()
    foreach ($line in ($Output -split "\r?\n")) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("List of devices") -or $line.StartsWith("* daemon")) {
            continue
        }
        $fields = $line -split "\s+"
        if ($fields.Count -lt 2) { continue }

        $model = $null
        $product = $null
        if ($fields.Count -gt 2) {
            foreach ($field in $fields[2..($fields.Count - 1)]) {
                if ($field.StartsWith("model:")) { $model = $field.Substring(6) }
                if ($field.StartsWith("product:")) { $product = $field.Substring(8) }
            }
        }

        $serial = $fields[0]
        $displayName = if ($model) { $model.Replace("_", " ") } else { $serial }
        $devices += [pscustomobject]@{
            Serial = $serial
            State = $fields[1]
            Model = $model
            Product = $product
            DisplayName = $displayName
            IsWireless = ($serial.Contains(":") -or $serial.ToLowerInvariant().Contains("._adb-tls-connect._tcp"))
        }
    }
    return $devices
}

function Parse-MdnsServices {
    param([string]$Output)

    $services = @()
    foreach ($line in ($Output -split "\r?\n")) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("List of discovered")) {
            continue
        }
        $fields = $line -split "\s+"
        if ($fields.Count -lt 3) { continue }
        if (-not (Normalize-Endpoint $fields[2])) { continue }

        $kind = "other"
        if ($fields[1].StartsWith("_adb-tls-pairing._tcp")) { $kind = "pairing" }
        elseif ($fields[1].StartsWith("_adb-tls-connect._tcp")) { $kind = "connection" }
        elseif ($fields[1].StartsWith("_adb._tcp")) { $kind = "legacy" }

        $services += [pscustomobject]@{
            Name = $fields[0]
            Type = $fields[1]
            Endpoint = $fields[2]
            Kind = $kind
        }
    }
    return $services
}

function Parse-Apps {
    param([string]$Output)

    $apps = @()
    $pendingName = $null
    $pendingSystem = $false

    foreach ($raw in ($Output -split "\r?\n")) {
        if ($raw.StartsWith("[server]") -or $raw.StartsWith("INFO:") -or $raw.Contains("file pushed")) {
            continue
        }
        $trimmed = $raw.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }

        $markedSystem = $trimmed.StartsWith("* ")
        $markedThirdParty = $trimmed.StartsWith("- ")
        $content = if ($markedSystem -or $markedThirdParty) { $trimmed.Substring(2) } else { $trimmed }
        $columns = @($content -split "\s+" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($columns.Count -eq 0) { continue }
        $package = $columns[-1]

        if (-not $package.Contains(".")) {
            if ($markedSystem -or $markedThirdParty) {
                $pendingName = $content
                $pendingSystem = $markedSystem
            }
            continue
        }

        $isPackageOnlyContinuation = (-not $markedSystem -and -not $markedThirdParty -and $columns.Count -eq 1)
        if ($isPackageOnlyContinuation -and $pendingName) {
            $name = $pendingName
            $isSystem = $pendingSystem
        } else {
            $index = $content.LastIndexOf($package)
            $name = $content.Substring(0, $index).Trim()
            if ([string]::IsNullOrWhiteSpace($name)) { $name = $package }
            $isSystem = $markedSystem
        }

        $apps += [pscustomobject]@{
            Name = $name
            PackageName = $package
            IsSystem = $isSystem
            Label = "$name  ($package)"
        }
        $pendingName = $null
    }

    return $apps | Sort-Object Name
}

function Format-DeviceLabel {
    param($Device)
    $connection = Get-ConnectionEndpoint $Device
    $kind = if ($Device.IsWireless) { "Wi-Fi" } else { "USB" }
    return "$($Device.DisplayName) [$kind] - $($Device.State) - $connection"
}

function Get-ConnectionEndpoint {
    param($Device)
    if ($Device.Serial.Contains(":")) { return $Device.Serial }
    foreach ($service in $script:Services) {
        if ($service.Kind -eq "connection" -and $Device.Serial.StartsWith($service.Name)) {
            return $service.Endpoint
        }
    }
    return $Device.Serial
}

function Save-LastConnectAddress {
    param([string]$Value)
    $dir = Split-Path -Parent $script:LastConnectAddressPath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Set-Content -Path $script:LastConnectAddressPath -Value $Value -Encoding UTF8
}

function Load-LastConnectAddress {
    if (Test-Path $script:LastConnectAddressPath) {
        return (Get-Content $script:LastConnectAddressPath -Raw).Trim()
    }
    return ""
}

function Update-ActionButtons {
    $ready = ($script:Tools.adb -and $script:Tools.scrcpy)
    $hasAdb = ($script:Tools.adb -ne $null)
    $hasDevice = ($script:SelectedSerial -ne $null)
    $FindPairButton.IsEnabled = $hasAdb
    $PairButton.IsEnabled = $hasAdb
    $ConnectButton.IsEnabled = $hasAdb
    $UsbWirelessButton.IsEnabled = $hasAdb
    $MirrorButton.IsEnabled = $ready -and $hasDevice
    $ScreenshotButton.IsEnabled = ($script:Tools.adb -and $hasDevice)
    $RecordButton.IsEnabled = $ready -and $hasDevice
    $DisconnectButton.IsEnabled = ($script:Tools.adb -and $hasDevice)
    $LoadAppsButton.IsEnabled = $ready -and $hasDevice
    $LaunchAppButton.IsEnabled = $ready -and $hasDevice
}

function Refresh-UiState {
    $script:IsRefreshingUi = $true
    try {
        $DeviceList.Items.Clear()
        foreach ($device in $script:Devices) {
            $item = [System.Windows.Controls.ListBoxItem]::new()
            $item.Content = Format-DeviceLabel $device
            $item.Tag = $device.Serial
            [void]$DeviceList.Items.Add($item)
            if ($device.Serial -eq $script:SelectedSerial) {
                $DeviceList.SelectedItem = $item
            }
        }

        if ($DeviceList.SelectedItem -eq $null -and $DeviceList.Items.Count -gt 0) {
            $DeviceList.SelectedIndex = 0
            $script:SelectedSerial = $DeviceList.SelectedItem.Tag
        }
    } finally {
        $script:IsRefreshingUi = $false
    }

    Update-ActionButtons
}

function Refresh-Devices {
    Locate-Tools
    if (-not $script:Tools.adb) {
        Show-MissingAdbMessage
        Refresh-UiState
        return
    }

    if (-not $script:Tools.scrcpy) {
        Show-MissingScrcpyMessage
    } else {
        Set-Status "Looking for Android devices..."
    }

    $mdns = Invoke-CommandLine $script:Tools.adb @("mdns", "services")
    $script:Services = @(Parse-MdnsServices $mdns.Output)
    $pairing = $script:Services | Where-Object { $_.Kind -eq "pairing" } | Select-Object -First 1
    if ($pairing) {
        $PairAddressBox.Text = $pairing.Endpoint
    }

    $result = Invoke-CommandLine $script:Tools.adb @("devices", "-l")
    $script:Devices = @(Parse-Devices $result.Output)
    if ($script:SelectedSerial -and -not ($script:Devices | Where-Object { $_.Serial -eq $script:SelectedSerial })) {
        $script:SelectedSerial = $null
    }
    $firstReady = $script:Devices | Where-Object { $_.State -eq "device" } | Select-Object -First 1
    if (-not $script:SelectedSerial -and $firstReady) {
        $script:SelectedSerial = $firstReady.Serial
    }

    Refresh-UiState

    if ($script:Devices.Count -gt 0) {
        Set-Status "$($script:Devices.Count) device(s) found."
    } elseif ($pairing) {
        Set-Status "Pairing service found. Enter the current 6 digit code."
    } else {
        Set-Status "No devices yet. Enable Wireless debugging on Android."
    }
}

function Get-SelectedDevice {
    if (-not $script:SelectedSerial) { return $null }
    return $script:Devices | Where-Object { $_.Serial -eq $script:SelectedSerial } | Select-Object -First 1
}

function Get-MirrorArguments {
    param($Device)

    $args = @("--serial", $Device.Serial, "--window-title", "PocketPane - $($Device.DisplayName)")

    $maxSize = ([System.Windows.Controls.ComboBoxItem]$MaxSizeBox.SelectedItem).Content.ToString()
    if ($maxSize -ne "Native") {
        $args += @("--max-size", $maxSize)
    }

    $maxFps = ([System.Windows.Controls.ComboBoxItem]$MaxFpsBox.SelectedItem).Content.ToString()
    if ($maxFps) {
        $args += @("--max-fps", $maxFps)
    }

    if ($ScreenOffBox.IsChecked) { $args += "--turn-screen-off" }
    if ($StayAwakeBox.IsChecked) { $args += "--stay-awake" }
    if ($NoAudioBox.IsChecked) { $args += "--no-audio" }
    if ($ShowTouchesBox.IsChecked) { $args += "--show-touches" }
    if ($BorderlessBox.IsChecked) { $args += "--window-borderless" }

    return $args
}

function Restart-Adb-AndRetry {
    param([string[]]$Arguments)

    if (-not (Ensure-Adb)) {
        return [pscustomobject]@{
            ExitCode = -1
            Output = "adb.exe not found."
            Succeeded = $false
        }
    }

    $result = Invoke-CommandLine $script:Tools.adb $Arguments
    if (-not $result.Succeeded -and ($result.Output -match "no route to host|cannot connect to daemon")) {
        Set-Status "Restarting local ADB..."
        [void](Invoke-CommandLine $script:Tools.adb @("kill-server"))
        [void](Invoke-CommandLine $script:Tools.adb @("start-server"))
        $result = Invoke-CommandLine $script:Tools.adb $Arguments
    }
    return $result
}

function Pair-Device {
    if (-not (Ensure-Adb)) { return }

    $endpoint = Normalize-Endpoint $PairAddressBox.Text
    if (-not $endpoint) {
        Set-Status "Enter the pairing IP and port shown on Android."
        return
    }

    $code = ($PairCodeBox.Password -replace "\D", "")
    if ($code.Length -ne 6) {
        Set-Status "The pairing code should contain 6 digits."
        return
    }

    Set-Status "Pairing with $endpoint..."
    $result = Restart-Adb-AndRetry @("pair", $endpoint, $code)
    if (-not $result.Succeeded) {
        Set-Status $(if ($result.Output) { $result.Output } else { "Pairing failed." })
        return
    }

    $PairCodeBox.Clear()
    Set-Status "Paired. Looking for connection service..."
    Start-Sleep -Milliseconds 700
    Refresh-Devices

    $connection = $script:Services | Where-Object { $_.Kind -eq "connection" } | Select-Object -First 1
    if ($connection) {
        $ConnectAddressBox.Text = $connection.Endpoint
        Save-LastConnectAddress $connection.Endpoint
        $connected = Restart-Adb-AndRetry @("connect", $connection.Endpoint)
        Set-Status $(if ($connected.Succeeded) { "Paired and connected." } elseif ($connected.Output) { $connected.Output } else { "Paired. Tap Connect if it does not appear." })
        Refresh-Devices
    } else {
        Set-Status "Paired. On the phone, close the pairing-code pop-up. Then press Refresh or enter the main Wireless debugging IP:port under Connect."
    }
}

function Connect-Device {
    if (-not (Ensure-Adb)) { return }

    $endpoint = Normalize-Endpoint $ConnectAddressBox.Text 5555
    if (-not $endpoint) {
        Set-Status "Enter the Wireless debugging IP address and port."
        return
    }

    Set-Status "Connecting to $endpoint..."
    $result = Restart-Adb-AndRetry @("connect", $endpoint)
    if ($result.Succeeded) {
        $ConnectAddressBox.Text = $endpoint
        Save-LastConnectAddress $endpoint
    }
    Set-Status $(if ($result.Output) { $result.Output } elseif ($result.Succeeded) { "Connected." } else { "Connection failed." })
    Refresh-Devices
}

function Enable-WirelessViaUsb {
    if (-not (Ensure-Adb)) { return }

    Set-Status "Reading Android Wi-Fi address..."
    $route = Invoke-CommandLine $script:Tools.adb @("-d", "shell", "ip", "route")
    if (-not $route.Succeeded -or $route.Output -notmatch "\bsrc\s+(\d{1,3}(?:\.\d{1,3}){3})") {
        Set-Status "Connect one authorized phone by USB and make sure it is on Wi-Fi."
        return
    }

    $ip = $Matches[1]
    Set-Status "Switching ADB to Wi-Fi..."
    $tcpip = Invoke-CommandLine $script:Tools.adb @("-d", "tcpip", "5555")
    if (-not $tcpip.Succeeded) {
        Set-Status $(if ($tcpip.Output) { $tcpip.Output } else { "Could not enable ADB over Wi-Fi." })
        return
    }

    $endpoint = "$ip`:5555"
    $connection = Restart-Adb-AndRetry @("connect", $endpoint)
    if ($connection.Succeeded) {
        $ConnectAddressBox.Text = $endpoint
        Save-LastConnectAddress $endpoint
    }
    Set-Status $(if ($connection.Output) { $connection.Output } elseif ($connection.Succeeded) { "Connected wirelessly. You can unplug the cable." } else { "Wi-Fi connection failed." })
    Refresh-Devices
}

function Start-Mirroring {
    if (-not (Ensure-Adb)) { return }
    if (-not (Ensure-Scrcpy)) { return }

    $device = Get-SelectedDevice
    if (-not $device) {
        Set-Status "Select a connected Android device first."
        return
    }
    if ($device.State -ne "device") {
        Set-Status "This device is not ready. Unlock it and allow USB debugging."
        return
    }

    Start-External $script:Tools.scrcpy (Get-MirrorArguments $device)
    Set-Status "Mirroring $($device.DisplayName)."
}

function Save-Screenshot {
    if (-not (Ensure-Adb)) { return }

    $device = Get-SelectedDevice
    if (-not $device) {
        Set-Status "Select a connected Android device first."
        return
    }

    $dialog = [Microsoft.Win32.SaveFileDialog]::new()
    $dialog.Title = "Save Android Screenshot"
    $dialog.Filter = "PNG image (*.png)|*.png"
    $dialog.FileName = "Android-" + (Get-Date -Format "yyyy-MM-dd-HHmmss") + ".png"
    if ($dialog.ShowDialog() -ne $true) { return }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo.FileName = $script:Tools.adb
    $process.StartInfo.Arguments = "-s `"$($device.Serial)`" exec-out screencap -p"
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.StartInfo.CreateNoWindow = $true
    [void]$process.Start()
    $stream = [System.IO.File]::Open($dialog.FileName, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
    try {
        $process.StandardOutput.BaseStream.CopyTo($stream)
    } finally {
        $stream.Close()
    }
    $errorText = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    if ($process.ExitCode -eq 0) {
        Set-Status "Screenshot saved to $([System.IO.Path]::GetFileName($dialog.FileName))."
    } else {
        Set-Status $(if ($errorText) { $errorText.Trim() } else { "Screenshot failed." })
    }
}

function Start-Recording {
    if (-not (Ensure-Adb)) { return }
    if (-not (Ensure-Scrcpy)) { return }

    $device = Get-SelectedDevice
    if (-not $device) {
        Set-Status "Select a connected Android device first."
        return
    }

    $dialog = [Microsoft.Win32.SaveFileDialog]::new()
    $dialog.Title = "Record Android Presentation"
    $dialog.Filter = "MP4 video (*.mp4)|*.mp4"
    $dialog.FileName = "Android-Presentation-" + (Get-Date -Format "yyyy-MM-dd-HHmmss") + ".mp4"
    if ($dialog.ShowDialog() -ne $true) { return }

    $args = @(Get-MirrorArguments $device)
    $args += @("--record", $dialog.FileName)
    Start-External $script:Tools.scrcpy $args
    Set-Status "Recording presentation. Close the mirror window to finish."
}

function Disconnect-Selected {
    if (-not (Ensure-Adb)) { return }

    $device = Get-SelectedDevice
    if (-not $device) { return }
    $target = Get-ConnectionEndpoint $device
    $result = Invoke-CommandLine $script:Tools.adb @("disconnect", $target)
    Set-Status $(if ($result.Output) { $result.Output } else { "Disconnected." })
    Refresh-Devices
}

function Load-Apps {
    if (-not (Ensure-Adb)) { return }
    if (-not (Ensure-Scrcpy)) { return }

    $device = Get-SelectedDevice
    if (-not $device) {
        Set-Status "Select a connected Android device first."
        return
    }

    Set-Status "Reading apps from $($device.DisplayName)..."
    $result = Invoke-CommandLine $script:Tools.scrcpy @("--serial", $device.Serial, "--list-apps")
    $apps = @(Parse-Apps $result.Output)
    $AppList.Items.Clear()
    foreach ($app in $apps) {
        $item = [System.Windows.Controls.ListBoxItem]::new()
        $item.Content = $app.Label
        $item.Tag = $app
        [void]$AppList.Items.Add($item)
    }
    Set-Status $(if ($apps.Count -gt 0) { "$($apps.Count) apps ready." } else { "No launchable apps found." })
}

function Filter-Apps {
    $query = $AppSearchBox.Text
    foreach ($item in $AppList.Items) {
        $visible = [string]::IsNullOrWhiteSpace($query) -or $item.Content.ToString().ToLowerInvariant().Contains($query.ToLowerInvariant())
        $item.Visibility = if ($visible) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    }
}

function Launch-SelectedApp {
    if (-not (Ensure-Adb)) { return }
    if (-not (Ensure-Scrcpy)) { return }

    $device = Get-SelectedDevice
    $item = $AppList.SelectedItem
    if (-not $device -or -not $item) {
        Set-Status "Select an app first."
        return
    }

    $app = $item.Tag
    $args = @(Get-MirrorArguments $device)
    $args += @("--new-display", "--start-app=+$($app.PackageName)")
    Start-External $script:Tools.scrcpy $args
    Set-Status "Opening $($app.Name) in its own window."
}

function Send-Files {
    param([string[]]$Files)

    if (-not (Ensure-Adb)) { return }

    $device = Get-SelectedDevice
    if (-not $device -or $Files.Count -eq 0) {
        Set-Status "Select a connected Android device before dropping files."
        return
    }

    $args = @("-s", $device.Serial, "push")
    $args += $Files
    $args += "/sdcard/Download/"
    $result = Invoke-CommandLine $script:Tools.adb $args
    Set-Status $(if ($result.Succeeded) { "Sent $($Files.Count) file(s) to Downloads." } elseif ($result.Output) { $result.Output } else { "File transfer failed." })
}

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
$Window = [Windows.Markup.XamlReader]::Load($reader)

$RefreshButton = Get-NamedElement $Window "RefreshButton"
$DeviceList = Get-NamedElement $Window "DeviceList"
$MirrorButton = Get-NamedElement $Window "MirrorButton"
$ScreenshotButton = Get-NamedElement $Window "ScreenshotButton"
$RecordButton = Get-NamedElement $Window "RecordButton"
$DisconnectButton = Get-NamedElement $Window "DisconnectButton"
$MaxSizeBox = Get-NamedElement $Window "MaxSizeBox"
$MaxFpsBox = Get-NamedElement $Window "MaxFpsBox"
$StayAwakeBox = Get-NamedElement $Window "StayAwakeBox"
$ScreenOffBox = Get-NamedElement $Window "ScreenOffBox"
$NoAudioBox = Get-NamedElement $Window "NoAudioBox"
$ShowTouchesBox = Get-NamedElement $Window "ShowTouchesBox"
$BorderlessBox = Get-NamedElement $Window "BorderlessBox"
$AppSearchBox = Get-NamedElement $Window "AppSearchBox"
$LoadAppsButton = Get-NamedElement $Window "LoadAppsButton"
$LaunchAppButton = Get-NamedElement $Window "LaunchAppButton"
$AppList = Get-NamedElement $Window "AppList"
$PairAddressBox = Get-NamedElement $Window "PairAddressBox"
$PairCodeBox = Get-NamedElement $Window "PairCodeBox"
$FindPairButton = Get-NamedElement $Window "FindPairButton"
$PairButton = Get-NamedElement $Window "PairButton"
$ConnectAddressBox = Get-NamedElement $Window "ConnectAddressBox"
$ConnectButton = Get-NamedElement $Window "ConnectButton"
$UsbWirelessButton = Get-NamedElement $Window "UsbWirelessButton"
$StatusText = Get-NamedElement $Window "StatusText"

$ConnectAddressBox.Text = Load-LastConnectAddress

$RefreshButton.Add_Click({ Invoke-UiAction { Refresh-Devices } })
$DeviceList.Add_SelectionChanged({
    Invoke-UiAction {
        if ($script:IsRefreshingUi) { return }
        if ($DeviceList.SelectedItem) {
            $script:SelectedSerial = $DeviceList.SelectedItem.Tag
            Update-ActionButtons
        }
    }
})
$FindPairButton.Add_Click({
    Invoke-UiAction {
        if (-not (Ensure-Adb)) { return }
        Set-Status "Looking for pairing address..."
        $result = Invoke-CommandLine $script:Tools.adb @("mdns", "services")
        $script:Services = @(Parse-MdnsServices $result.Output)
        $pairing = $script:Services | Where-Object { $_.Kind -eq "pairing" } | Select-Object -First 1
        if ($pairing) {
            $PairAddressBox.Text = $pairing.Endpoint
            Set-Status "Pairing address found. Enter the current 6 digit code."
        } else {
            Set-Status "Not found. Keep Pair device with pairing code open, or enter the address manually."
        }
    }
})
$PairButton.Add_Click({ Invoke-UiAction { Pair-Device } })
$ConnectButton.Add_Click({ Invoke-UiAction { Connect-Device } })
$UsbWirelessButton.Add_Click({ Invoke-UiAction { Enable-WirelessViaUsb } })
$MirrorButton.Add_Click({ Invoke-UiAction { Start-Mirroring } })
$ScreenshotButton.Add_Click({ Invoke-UiAction { Save-Screenshot } })
$RecordButton.Add_Click({ Invoke-UiAction { Start-Recording } })
$DisconnectButton.Add_Click({ Invoke-UiAction { Disconnect-Selected } })
$LoadAppsButton.Add_Click({ Invoke-UiAction { Load-Apps } })
$LaunchAppButton.Add_Click({ Invoke-UiAction { Launch-SelectedApp } })
$AppSearchBox.Add_TextChanged({ Invoke-UiAction { Filter-Apps } })
$Window.Add_Drop({
    param($sender, $eventArgs)
    Invoke-UiAction {
        if ($eventArgs.Data.GetDataPresent([Windows.DataFormats]::FileDrop)) {
            $files = [string[]]$eventArgs.Data.GetData([Windows.DataFormats]::FileDrop)
            Send-Files $files
        }
    }
})

Refresh-Devices
[void]$Window.ShowDialog()
