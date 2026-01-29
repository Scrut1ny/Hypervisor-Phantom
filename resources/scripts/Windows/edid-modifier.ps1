if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(544)) {
    Write-Host "[!] Script must be run as Administrator." -ForegroundColor Red
    exit 1
}

# Get monitors via WMI for full EDID data
$wmiMonitors = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorDescriptorMethods

foreach ($wmiMon in $wmiMonitors) {
    # --- 1. Fetch Full EDID (Base + Extensions) ---
    try {
        $block0Result = Invoke-CimMethod -InputObject $wmiMon -MethodName WmiGetMonitorRawEEdidV1Block -Arguments @{BlockId=0}
        $block0 = [byte[]]$block0Result.BlockContent
    } catch { continue }

    if (-not $block0) { continue }

    # Initialize block list
    $edidBlocks = @(,$block0)

    # Fetch extension block if flagged (Byte 126)
    if ($block0[126] -gt 0) {
        try {
            $extResult = Invoke-CimMethod -InputObject $wmiMon -MethodName WmiGetMonitorRawEEdidV1Block -Arguments @{BlockId=1}
            $edidBlocks += ,([byte[]]$extResult.BlockContent)
        } catch { }
    }

    # --- 2. Modify Base Block ---
    $targetBlock = $edidBlocks[0]

    # Clear serial number (bytes 12-15)
    $targetBlock[12] = $targetBlock[13] = $targetBlock[14] = $targetBlock[15] = 0

    # Recalculate checksum (byte 127)
    $sum = 0
    for ($i = 0; $i -lt 127; $i++) { $sum += $targetBlock[$i] }
    $targetBlock[127] = (256 - ($sum % 256)) % 256
    
    $edidBlocks[0] = $targetBlock

    # --- 3. Save to Registry ---
    # Map WMI ID to Registry path
    $pnpId = $wmiMon.InstanceName -replace "_0$", ""
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$pnpId\Device Parameters"

    if (-not (Test-Path $regPath)) { continue }

    $overrideKeyPath = Join-Path -Path $regPath -ChildPath "EDID_OVERRIDE"
    
    if (-not (Test-Path -LiteralPath $overrideKeyPath)) {
        New-Item -Path $overrideKeyPath -Force | Out-Null
    }

    # Write blocks 0 and 1
    for ($i = 0; $i -lt $edidBlocks.Count; $i++) {
        Set-ItemProperty -LiteralPath $overrideKeyPath -Name $i.ToString() -Value $edidBlocks[$i] -Type Binary -Force
    }

    # Extract Monitor Name (bytes 5-17 of 'FC' descriptor)
    $monitorName = "Unknown Monitor"
    foreach ($off in 54, 72, 90, 108) {
        if ($targetBlock[$off] -eq 0 -and $targetBlock[$off+1] -eq 0 -and $targetBlock[$off+2] -eq 0 -and $targetBlock[$off+3] -eq 0xFC) {
            $nameBytes = $targetBlock[($off+5)..($off+17)]
            $monitorName = [System.Text.Encoding]::ASCII.GetString($nameBytes).Split([char]0x0A)[0].Trim()
            break
        }
    }

    Write-Host "[+] EDID_OVERRIDE created for: $monitorName" -ForegroundColor Green
    Write-Host "[+] Block 0: Bytes 12-15 zeroed" -ForegroundColor Green
}

# --- 4. Restart Graphics Driver
# Filter for Display class devices that are currently OK (active)
$displayAdapters = Get-PnpDevice -Class Display | Where-Object { $_.Status -eq 'OK' }

if ($displayAdapters) {
    foreach ($gpu in $displayAdapters) {
        Write-Host "[*] Restarting Display adapter: $($gpu.FriendlyName)" -ForegroundColor Cyan
        try {
            Disable-PnpDevice -InstanceId $gpu.InstanceId -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 2
            Enable-PnpDevice -InstanceId $gpu.InstanceId -Confirm:$false -ErrorAction Stop
            Write-Host "[+] Display adapter restarted successfully." -ForegroundColor Green
        }
        catch {
            Write-Host "[!] Failed to restart Display adapter: $($gpu.FriendlyName)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "[!] No active Display adapters found." -ForegroundColor Yellow
}
