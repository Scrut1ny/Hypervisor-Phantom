# ---- SYSTEM privilege check ----
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
if ($identity.Name -ne "NT AUTHORITY\SYSTEM") {
    Write-Host "ERROR: This script must be run as NT AUTHORITY\SYSTEM." -ForegroundColor Red
    exit 1
}

# Automatically find all monitor EDID registry entries
$edidKeys = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\DISPLAY" -Recurse |
            Where-Object { Test-Path "$($_.PSPath)\Device Parameters" } |
            ForEach-Object {
                Get-ItemProperty "$($_.PSPath)\Device Parameters" -Name EDID -ErrorAction SilentlyContinue
            } |
            Where-Object { $_.EDID }

foreach ($monitor in $edidKeys) {
    $regPath = $monitor.PSPath
    $edid = [byte[]]$monitor.EDID

    # Clear serial number (bytes 12–15)
    for ($i = 12; $i -le 15; $i++) {
        $edid[$i] = 0
    }

    # Recalculate checksum (byte 127)
    $edid[127] = (256 - (($edid[0..126] | Measure-Object -Sum).Sum % 256)) % 256

    # Write modified EDID back to registry
    Set-ItemProperty -Path $regPath -Name EDID -Value $edid

    # Extract clean monitor ID (manufacturer/model only)
    $monitorId = ($regPath -split '\\')[-3]

    Write-Host "Spoofed [$monitorId] - serial (bytes 12-15) cleared" -ForegroundColor Green
}
