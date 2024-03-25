# ==================================================
# Admin Check
# ==================================================


if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$($PWD.Path)' ; & '$($myInvocation.InvocationName)'`"" -Verb RunAs
    Exit
}


# ==================================================
# Registry Hypervisor Artifacts Spoof
# ==================================================


function vbox {
	# DSDT
	Rename-Item -Path "HKLM:\HARDWARE\ACPI\DSDT\VBOX__" -NewName "ALASKA" -Force
	Rename-Item -Path "HKLM:\HARDWARE\ACPI\DSDT\ALASKA\VBOXBIOS" -NewName "A_M_I_" -Force

	# FADT
	Rename-Item -Path "HKLM:\HARDWARE\ACPI\FADT\VBOX__" -NewName "ALASKA" -Force
	Rename-Item -Path "HKLM:\HARDWARE\ACPI\FADT\ALASKA\VBOXFACP" -NewName "A_M_I_" -Force

	# RSDT
	Rename-Item -Path "HKLM:\HARDWARE\ACPI\RSDT\VBOX__" -NewName "ALASKA" -Force
	Rename-Item -Path "HKLM:\HARDWARE\ACPI\RSDT\ALASKA\VBOXXSDT" -NewName "A_M_I_" -Force

	# SSDT
	Rename-Item -Path "HKLM:\HARDWARE\ACPI\SSDT\VBOX__" -NewName "AMD" -Force
	Rename-Item -Path "HKLM:\HARDWARE\ACPI\SSDT\AMD\VBOXCPUT" -NewName "AmdTable" -Force

	# System
	Remove-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System" -Name "SystemBiosDate" -Force
	Remove-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System" -Name "SystemBiosVersion" -Force
	Remove-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System" -Name "VideoBiosVersion" -Force

	# SystemInformation
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation" -Name "BIOSReleaseDate" -Value "02/06/2024" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation" -Name "BIOSVersion" -Value "1.C0" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation" -Name "SystemManufacturer" -Value "Micro-Star International Co., Ltd." -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation" -Name "SystemProductName" -Value "MS-7D78" -Force

	# HardwareConfig
	$lastConfig = Get-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig" -Name "LastConfig"
	$guidValue = $lastConfig.LastConfig
	Set-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig\$guidValue" -Name "SystemBiosVersion" -Value "ALASKA - 1072009", "1.C0", "American Megatrends - 50020" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig\$guidValue" -Name "SystemFamily" -Value "To be filled by O.E.M." -Force
	
	# Monitor
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "DriverDesc" -Value "NVIDIA GeForce RTX 3050" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "HardwareInformation.AdapterString" -Value "NVIDIA GeForce RTX 3050" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "HardwareInformation.BiosString" -Value "Version94.6.37.0.40" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "HardwareInformation.ChipType" -Value "NVIDIA GeForce RTX 3050" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "HardwareInformation.DacType" -Value "Integrated RAMDAC" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "ProviderName" -Value "NVIDIA" -Force

	# Ask the user what they want to do
	$userChoice = Read-Host "  # Would you like to hide or remove Guest Additions? (Type 'hide' or 'remove')"

	# Base action for both choices: Remove uninstall entry
	if (Test-Path $uninstallPath) {
		Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Oracle VM VirtualBox Guest Additions" -Recurse -Force
	}

	if ($userChoice -eq "remove") {
		# Additional removal steps for the 'remove' option
		if (Test-Path $oracleKey) {
			Remove-Item -Path "HKLM:\SOFTWARE\Oracle" -Recurse -Force
		}

		# Stop VBox processes
		$processes = Get-Process | Where-Object { $_.Name -like "VBox*" }
		foreach ($process in $processes) {
			Stop-Process -Id $process.Id -Force
		}
		
		# Remove VBox services
		Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*VBox*" } | ForEach-Object {
			Remove-Item $_.PSPath -Recurse -Force
		}

		# Remove VBox drivers
		Get-ChildItem "$env:windir\System32\drivers\VBox*" -ErrorAction SilentlyContinue | ForEach-Object {
			Remove-Item $_.FullName -Recurse -Force
		}

	} elseif ($userChoice -ne "hide") {
		Write-Host "  # Invalid choice. Please run the script again and type 'hide' or 'remove'."
	}
}

function vmware {
	# System
	Remove-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System" -Name "SystemBiosDate" -Force
	Remove-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System" -Name "SystemBiosVersion" -Force
	
	# BIOS
	Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "BaseBoardManufacturer" -Value "Micro-Star International Co., Ltd." -Force
	Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "BaseBoardProduct" -Value "PRO B650-P WIFI (MS-7D78)" -Force
	Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "BIOSVendor" -Value "American Megatrends International, LLC." -Force
	Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "BIOSVersion" -Value "1.C0" -Force
	Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "SystemFamily" -Value "To be filled by O.E.M." -Force

	# HardwareConfig
	$lastConfig = Get-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig" -Name "LastConfig"
	$guidValue = $lastConfig.LastConfig

	Set-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig\$guidValue" -Name "BIOSVendor" -Value "American Megatrends International, LLC." -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig\$guidValue" -Name "BIOSVersion" -Value "1.C0" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig\$guidValue" -Name "SystemBiosVersion" -Value "ALASKA - 1072009", "1.C0", "American Megatrends - 50020" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig\$guidValue" -Name "SystemFamily" -Value "To be filled by O.E.M." -Force
	
	# Monitor
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "DriverDesc" -Value "NVIDIA GeForce RTX 3050" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "HardwareInformation.AdapterString" -Value "NVIDIA GeForce RTX 3050" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "HardwareInformation.BiosString" -Value "Version94.6.37.0.40" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "HardwareInformation.ChipType" -Value "NVIDIA GeForce RTX 3050" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "HardwareInformation.DacType" -Value "Integrated RAMDAC" -Force
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "ProviderName" -Value "NVIDIA" -Force
}

function QEMU {
	# DSDT
	Rename-Item -Path "HKLM:\HARDWARE\ACPI\DSDT\BOCHS_" -NewName "ALASKA" -Force
	Rename-Item -Path "HKLM:\HARDWARE\ACPI\DSDT\ALASKA\BXPC____" -NewName "A_M_I_" -Force

	# FADT
	Rename-Item -Path "HKLM:\HARDWARE\ACPI\FADT\BOCHS_" -NewName "ALASKA" -Force
	Rename-Item -Path "HKLM:\HARDWARE\ACPI\FADT\ALASKA\BXPC____" -NewName "A_M_I_" -Force

	# RSDT
	Rename-Item -Path "HKLM:\HARDWARE\ACPI\RSDT\BOCHS_" -NewName "ALASKA" -Force
	Rename-Item -Path "HKLM:\HARDWARE\ACPI\RSDT\ALASKA\BXPC____" -NewName "A_M_I_" -Force

 	# System
 	Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System" -Name "SystemBiosVersion" -Value "ALASKA - 1072009", "1.C0", "American Megatrends - 50020" -Force

  	# HardwareConfig
	$lastConfig = Get-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig" -Name "LastConfig"
	$guidValue = $lastConfig.LastConfig
	Set-ItemProperty -Path "HKLM:\SYSTEM\HardwareConfig\$guidValue" -Name "SystemBiosVersion" -Value "ALASKA - 1072009", "1.C0", "American Megatrends - 50020" -Force
}

$userChoice = Read-Host "Are you using VirtualBox, VMware, or QEMU? Please type your choice"

switch ($userChoice.ToLower()) {
    "virtualbox" { vbox }
    "vmware" { vmware }
    "qemu" { QEMU }
    default { Write-Host "  # Invalid choice. Please run the script again and enter a valid option." }
}


# ==================================================
# Host and NetBIOS name Spoof
# ==================================================


$RandomString = -join ((48..57) + (65..90) | Get-Random -Count '7' | % {[char]$_})

# Local Computer Name (Device Name) & Network Computer Name (NetBIOS Name)
Rename-Computer -NewName "DESKTOP-$RandomString" -Force *>$null


# ==================================================
# Legit Install Date & Time Spoof
# ==================================================


try {
    # Generating a random date between Jan 1, 2011, and Dec 31, 2022
    $start = [datetime]::new(2011, 1, 1)
    $end = [datetime]::new(2022, 12, 31)
    $randomDate = $start.AddSeconds((Get-Random -Maximum (($end - $start).TotalSeconds)))

    # Converting the DateTime object to Unix timestamp
    $unixTimestamp = [int][double]::Parse(($randomDate.ToUniversalTime() - [datetime]'1970-01-01T00:00:00').TotalSeconds)

    # Calculating LDAP/FILETIME timestamp directly
    $LDAP_FILETIME_timestamp = ($unixTimestamp + 11644473600) * 10000000

    # Setting custom inputted Date & Time in the registry
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "InstallDate" -Value $unixTimestamp -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "InstallTime" -Value $LDAP_FILETIME_timestamp -Force
} catch {
    Write-Error "Failed to set registry values: $_"
}


# ==================================================
# Device Manager: 'Friendly name' Spoof
# ==================================================


$deviceIDs = (Get-CimInstance Win32_PnPEntity | Where-Object { $_.Name -like '*VBOX*' -or $_.Name -like '*VMware*' -or $_.PNPDeviceID -like '*VBOX*' -or $_.PNPDeviceID -like '*VMware*' }).DeviceID

foreach ($deviceID in $deviceIDs) {
	$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$deviceID"
	Set-ItemProperty -Path "$registryPath" -Name "FriendlyName" -Value "Samsung SSD 980 500GB" -Force
}


# ==================================================
# HKLM:\HARDWARE\DEVICEMAP\Scsi
# ==================================================


function Get-UpperRandomString {
    $Identifier = -join (1..20 | ForEach {[char]((65..90) + (48..57) | Get-Random)})
    return $Identifier
}

# Physical Drives (SATA/NVMe)
foreach ($PortNumber in 0..9) {
    foreach ($BusNumber in 0..9) {
	foreach ($LogicalUnitIdNumber in 0..9) {
		$registryPath = "HKLM:\HARDWARE\DEVICEMAP\Scsi\Scsi Port $PortNumber\Scsi Bus $BusNumber\Target Id 0\Logical Unit Id $LogicalUnitIdNumber"

		if (Test-Path -Path $registryPath) {
			$NewString = Get-UpperRandomString
			Set-ItemProperty -Path "$registryPath" -Name 'Identifier' -Type String -Value "NVMe    Samsung SSD 980 FXO7" -Force
			Set-ItemProperty -Path "$registryPath" -Name 'SerialNumber' -Type String -Value "$NewString" -Force
		}
	}
    }
}


# ==================================================
# Custom DNS
# ==================================================


# Quad9 DNS servers
$Ipv4PrimaryDns = '9.9.9.9'
$Ipv4BackupDns = '149.112.112.112'
$Ipv6PrimaryDns = '2620:fe::fe'
$Ipv6BackupDns = '2620:fe::9'

Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object {
    Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses $Ipv4PrimaryDns, $Ipv4BackupDns, $Ipv6PrimaryDns, $Ipv6BackupDns
}

Clear-DnsClientCache


# ==================================================
# Restart System to Apply changes
# ==================================================


$choice = Read-Host "  # Do you want to restart the computer? (Y/N)"
if ($choice -eq "Y" -or $choice -eq "y") {
    Restart-Computer -Force
} elseif ($choice -eq "N" -or $choice -eq "n") {
    Write-Host "  # Restart aborted."
} else {
    Write-Host "  # Invalid choice. Please enter Y or N."
}
