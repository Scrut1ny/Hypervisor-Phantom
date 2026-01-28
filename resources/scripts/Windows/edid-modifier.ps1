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
    # Sum bytes 0-126, calculate complement
    $edid[127] = (256 - (($edid[0..126] | Measure-Object -Sum).Sum % 256)) % 256

    Set-ItemProperty -LiteralPath $item.PSPath -Name EDID -Value $edid -Force

    # Parse Monitor ID from path directly
    $monitorId = $item.PSPath.Split('\')[-3]
    Write-Host "Modified [$monitorId] - Serial number (bytes 12-15) cleared" -ForegroundColor Green
}
