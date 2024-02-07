# ==================================================
# Admin Check
# ==================================================


$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
	Write-Host "`n  [92m# Administrator privileges are required.[0m"
	Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	exit
}


# ==================================================
# Random Host and NetBIOS name
# ==================================================


$RandomString = -join ((48..57) + (65..90) | Get-Random -Count '7' | % {[char]$_})

# Local Computer Name (Device Name) & Network Computer Name (NetBIOS Name)
Rename-Computer -NewName "DESKTOP-$RandomString" -Force *>$null


# ==================================================
# Device Manager: 'Friendly name' Spoofing
# ==================================================


$deviceIDs = (Get-CimInstance Win32_PnPEntity | Where-Object { $_.Name -like '*VBOX*' -or $_.Name -like '*VMware*' -or $_.PNPDeviceID -like '*VBOX*' -or $_.PNPDeviceID -like '*VMware*' }).DeviceID

foreach ($deviceID in $deviceIDs) {
	$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$deviceID"
	Set-ItemProperty -Path "$registryPath" -Name "FriendlyName" -Value "Samsung SSD" -Force
	Write-Host "Set FriendlyName for $deviceID to 'Samsung SSD'"
}


# ==================================================
# HKLM:\HARDWARE\ACPI
# ==================================================


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

# Removing/Modifying Identifiers
Remove-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System" -Name "SystemBiosDate" -Force
Remove-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System" -Name "SystemBiosVersion" -Force
Remove-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System" -Name "VideoBiosVersion" -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation" -Name "BIOSReleaseDate" -Value "11/23/2023" -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation" -Name "BIOSVersion" -Value "1.A0" -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation" -Name "SystemManufacturer" -Value "Micro-Star International Co., Ltd." -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation" -Name "SystemProductName" -Value "MS-7D78" -Force


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
				Set-ItemProperty -Path $registryPath -Name 'Identifier' -Type String -Value "NVMe Samsung SSD 980" -Force
				Set-ItemProperty -Path $registryPath -Name 'SerialNumber' -Type String -Value "$NewString" -Force
			}
		}
    }
}


# ==================================================
# Hide Guest Additions (if installed)
# ==================================================


if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Oracle VM VirtualBox Guest Additions") {
    Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Oracle VM VirtualBox Guest Additions" -Recurse -Force
}


# ==================================================
# Remove Flagged/Detected VBox Device form Device Manager
# ==================================================


$devices = Get-PnpDevice | Where-Object { $_.FriendlyName -match "Base System Device|Unknown Device" }

if ($devices) {
    foreach ($device in $devices) {
        $null = pnputil /remove-driver $device.InstanceId /uninstall /force
        Write-Host "Removed device: $($device.FriendlyName)"
    }
} else {
    Write-Host "No devices found with names matching 'Base System Device' or 'Unknown Device'."
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

Restart-Computer -Force
