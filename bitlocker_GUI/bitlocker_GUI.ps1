<# Manage-bde -status checker
script with GUI for remote check disk encryption in domain network
requaire admin account

#>
Add-Type -AssemblyName PresentationFramework

# Form
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Manage-BDE Status Checker v1.01" Height="300" Width="500" WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Hostname box -->
        <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,10">
            <Label Content="Hostname:" VerticalAlignment="Center" Margin="0,0,10,0"/>
            <TextBox Name="HostnameInput" Width="300"/>
        </StackPanel>

        <!-- Action button -->
        <Button Name="CheckButton" Content="Check enrcryption" Grid.Row="1" Width="150" HorizontalAlignment="Left"/>

        <!-- result fielde -->
        <TextBox Name="OutputBox" Grid.Row="2" Margin="0,10,0,10" VerticalScrollBarVisibility="Auto" IsReadOnly="True" TextWrapping="Wrap"/>

        <!-- status field -->
        <StackPanel Orientation="Horizontal" Grid.Row="3" Margin="0,0,0,10">
            <Label Content="Network Status:" VerticalAlignment="Center" Margin="0,0,10,0"/>
            <TextBox Name="OnlineStatus" Width="100" IsReadOnly="True" Background="LightGray"/>
            <Label Content="Encryption Status:" VerticalAlignment="Center" Margin="20,0,10,0"/>
            <TextBox Name="EncryptionStatus" Width="100" IsReadOnly="True" Background="LightGray"/>
        </StackPanel>
    </Grid>
</Window>
"@

# GUI form load
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Access to controls
$hostnameInput = $window.FindName("HostnameInput")
$outputBox = $window.FindName("OutputBox")
$onlineStatus = $window.FindName("OnlineStatus")
$encryptionStatus = $window.FindName("EncryptionStatus")
$checkButton = $window.FindName("CheckButton")

# Function for first check
$checkAction = {
    $hostname = $hostnameInput.Text
    if ([string]::IsNullOrWhiteSpace($hostname)) {
        [System.Windows.MessageBox]::Show("Proszę wpisać hostname!", "Błąd", "OK", "Error")
        return
    }

    # check the availability of the host on the network
    $ping = Test-Connection -ComputerName $hostname -Count 1 -Quiet
    if ($ping) {
        $onlineStatus.Text = "Online"
        $onlineStatus.Background = "LightGreen"

        # Run manage-bde
        try {
            $output = manage-bde -status -cn "\\$hostname" 2>&1
            $outputBox.Text = $output

            if ($output -match "Percentage Encrypted\s+:\s+100%") {
                $encryptionStatus.Text = "Yes"
                $encryptionStatus.Background = "LightGreen"
            } else {
                $encryptionStatus.Text = "No"
                $encryptionStatus.Background = "LightCoral"
            }
        } catch {
            $outputBox.Text = "Błąd: Nie udało się pobrać statusu manage-bde."
            $encryptionStatus.Text = "Unknown"
            $encryptionStatus.Background = "LightGray"
        }
    } else {
        $onlineStatus.Text = "Offline"
        $onlineStatus.Background = "LightCoral"
        $outputBox.Text = "Komputer jest offline lub nieosiągalny."
        $encryptionStatus.Text = "Unknown"
        $encryptionStatus.Background = "LightGray"
    }
}

<# GEN log

#>


# Przypisanie akcji do przycisku
$checkButton.Add_Click($checkAction)

# Wyświetlenie okna
$window.ShowDialog()
