# ========== Cryptography ==========

function Get-RandomGuid {
    return [guid]::NewGuid().ToString()
}

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name 'MachineGuid' -Type String -Value "$(Get-RandomGuid)" -Force

# ==================================



# ========== Install Date + Time ==========

# Generating a random date between Jan 1, 2011, and Dec 31, 2022
$start = [datetime]::new(2011, 1, 1)
$end = [datetime]::new(2022, 12, 31)
$randomDate = $start.AddSeconds((Get-Random -Maximum (($end - $start).TotalSeconds)))

# Converting the DateTime object to Unix timestamp
$unixTimestamp = [int][double]::Parse(($randomDate.ToUniversalTime() - [datetime]'1970-01-01T00:00:00').TotalSeconds)

# Calculating LDAP/FILETIME timestamp directly
$LDAP_FILETIME_timestamp = ($unixTimestamp + 11644473600) * 10000000

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "InstallDate" -Value "$unixTimestamp" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "InstallTime" -Value "$LDAP_FILETIME_timestamp" -Force

if ((Get-Service w32time).Status -eq 'Stopped') {
	Start-Service -Name w32time
}

w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org" /update
Restart-Service -Name w32time -Force ; w32tm /resync

# Set the time format to HH:mm (24-hour format) for ShortTime and HH:mm:ss for LongTime
Set-ItemProperty -Path 'HKCU:\Control Panel\International' -Name 'sTimeFormat' -Value 'HH:mm:ss' -Force
Set-ItemProperty -Path 'HKCU:\Control Panel\International' -Name 'sShortTime' -Value 'HH:mm' -Force

# ==================================



# ========== Device + NetBIOS Names ==========

$RandomString = -join ((48..57) + (65..90) | Get-Random -Count '7' | % {[char]$_})

# Local Computer Name (Device Name)
# [System.Environment]::MachineName
Rename-Computer -NewName "DESKTOP-$RandomString" -Force *>$null

# ==================================



# ========== MAC Address ==========

$newMac = ('{0:X}' -f (Get-Random -Maximum 0xFFFFFFFFFFFF)).PadLeft(12, "0") -replace '^(.)(.)', ('$1' + (Get-Random -InputObject 'A','E','2','6')) -replace '\$', ''
$adapter = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1).Name
Set-NetAdapter -Name "$adapter" -MacAddress "$newMac" -Confirm:$false

# ==================================



# ========== Restart ==========

shutdown /r /t 0

# ==================================