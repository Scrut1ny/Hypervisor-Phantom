if ([Security.Principal.WindowsIdentity]::GetCurrent().Name -ne "NT AUTHORITY\SYSTEM") {
    Write-Host "ERROR: This script must be run as NT AUTHORITY\SYSTEM." -ForegroundColor Red
    exit 1
}

$regPattern = "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY\*\*\Device Parameters"

foreach ($item in Get-ItemProperty -Path $regPattern -Name EDID -ErrorAction SilentlyContinue) {
    if (-not $item.EDID) { continue }
    $edid = [byte[]]$item.EDID

    # Clear serial number (bytes 12-15)
    $edid[12] = $edid[13] = $edid[14] = $edid[15] = 0

    # Recalculate checksum (byte 127)
    $sum = 0
    for ($i = 0; $i -lt 127; $i++) { $sum += $edid[$i] }
    $edid[127] = (256 - ($sum % 256)) % 256

    # Save to EDID_OVERRIDE for persistence
    Set-ItemProperty -LiteralPath $item.PSPath -Name EDID_OVERRIDE -Value $edid -Force

    # Extract Monitor Name (bytes 5-17 of 'FC' descriptor)
    $monitorName = "Unknown Monitor"
    foreach ($off in 54, 72, 90, 108) {
        if ($edid[$off] -eq 0 -and $edid[$off+1] -eq 0 -and $edid[$off+2] -eq 0 -and $edid[$off+3] -eq 0xFC) {
            $nameBytes = $edid[($off+5)..($off+17)]
            $monitorName = [System.Text.Encoding]::ASCII.GetString($nameBytes).Split([char]0x0A)[0].Trim()
            break
        }
    }

    Write-Host "Created EDID Override for [$monitorName] - Serial cleared" -ForegroundColor Green
}
