# ========== Cryptography ==========

function Get-RandomGuid {
    return [guid]::NewGuid().ToString()
}

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name 'MachineGuid' -Type String -Value "$(Get-RandomGuid)" -Force

# ==================================



# ========== Install Date + Time ==========

# Define start and end dates
$startDate = [datetime]::new(2016, 1, 1)
$endDate = [datetime]::new(2023, 12, 31)

# Try to generate a random date, convert to Unix timestamp and LDAP/FILETIME
try {
    # Generate a random date within the defined range
    $randomDate = $startDate.AddSeconds((Get-Random -Maximum ($endDate - $startDate).TotalSeconds))

    # Convert the random date to Unix timestamp and then to LDAP/FILETIME
    $unixTimestamp = [int][double]::Parse(($randomDate.ToUniversalTime() - [datetime]'1970-01-01').TotalSeconds)
    $ldapFileTime = ($unixTimestamp + 11644473600) * 1e7  # Use scientific notation for clarity
} catch {
    Write-Error "Failed to generate the random date or convert it: $_"
    return
}

# Try to set the InstallDate and InstallTime in the registry
try {
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    Set-ItemProperty -Path $registryPath -Name "InstallDate" -Value "$unixTimestamp" -Force
    Set-ItemProperty -Path $registryPath -Name "InstallTime" -Value "$ldapFileTime" -Force
} catch {
    Write-Error "Failed to update registry with InstallDate or InstallTime: $_"
    return
}

# Try to ensure the Windows Time service is running and configure NTP
try {
    # Start the Windows Time service if it's not running
    if ((Get-Service w32time).Status -ne 'Running') {
        Start-Service w32time
    }

    # Configure the NTP settings and resync
    $ntpServers = "0.pool.ntp.org,1.pool.ntp.org,2.pool.ntp.org,3.pool.ntp.org"
    w32tm /config /syncfromflags:manual /manualpeerlist:$ntpServers /update
    Restart-Service w32time -Force
    w32tm /resync
} catch {
    Write-Error "Failed to manage Windows Time service or configure NTP: $_"
}

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
