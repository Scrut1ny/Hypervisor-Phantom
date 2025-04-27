# ========== Cryptography ==========

function Get-RandomGuid {
    return [guid]::NewGuid().ToString()
}

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name 'MachineGuid' -Type String -Value "$(Get-RandomGuid)" -Force

# ==================================



# ========== Install Date + Time ==========

# Generate random date between 2011-01-01 and 2022-12-31
$randomDate = Get-Random -Minimum ([datetime]'2011-01-01').Ticks -Maximum (([datetime]'2022-12-31').Ticks) | ForEach-Object {[datetime]$_}

# Convert to Unix timestamp and LDAP/FILETIME
$unixTimestamp = [int]($randomDate.ToUniversalTime() - [datetime]'1970-01-01').TotalSeconds
$ldapFileTime = [int64](($unixTimestamp + 11644473600) * 1e7)

# Update registry values with proper numeric types
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
Set-ItemProperty -Path $regPath -Name "InstallDate" -Value $unixTimestamp -Force
Set-ItemProperty -Path $regPath -Name "InstallTime" -Value $ldapFileTime -Force

# Ensure time service is running and reconfigure
Get-Service w32time | Where Status -ne Running | Start-Service
w32tm /config /syncfromflags:manual /manualpeerlist:"0.pool.ntp.org,1.pool.ntp.org,2.pool.ntp.org,3.pool.ntp.org" /update
Restart-Service w32time -Force; w32tm /resync

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
