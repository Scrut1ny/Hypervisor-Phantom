$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] Script must be run as Administrator." -ForegroundColor Red
    exit 1
}

# Get monitors via WMI for full EDID data
$wmiMonitors = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorDescriptorMethods

foreach ($wmiMon in $wmiMonitors) {
    # --- 1. Fetch Full EDID (Base + Extensions) ---
	try {
		$block0 = [byte[]](Invoke-CimMethod -InputObject $wmiMon -MethodName WmiGetMonitorRawEEdidV1Block -Arguments @{ BlockId = 0 }).BlockContent
		if (-not $block0) { continue }
	} catch { continue }

    # Initialize block list
    $edidBlocks = @(,$block0)

	# Fetch extension block if flagged (Byte 126)
	$extCount = $block0[126]
	for ($b = 1; $b -le $extCount; $b++) {
		try {
			$edidBlocks += ,([byte[]](Invoke-CimMethod -InputObject $wmiMon -MethodName WmiGetMonitorRawEEdidV1Block -Arguments @{ BlockId = $b }).BlockContent)
		} catch { }
	}

    # --- 2. Modify Base Block ---
    $targetBlock = $edidBlocks[0]

	# EDID[12–15]: Manufacturer-assigned ID Serial Number zeroed
    $targetBlock[12] = $targetBlock[13] = $targetBlock[14] = $targetBlock[15] = 0

	# EDID[54–125]: Display Descriptor Type 0xFF (Monitor Serial Number) zeroed (18-byte descriptors)
	foreach ($off in 54, 72, 90, 108) {
		if (
			$targetBlock[$off]     -eq 0x00 -and
			$targetBlock[$off + 1] -eq 0x00 -and
			$targetBlock[$off + 2] -eq 0x00 -and
			$targetBlock[$off + 3] -eq 0xFF
		) {
			[Array]::Clear($targetBlock, $off, 18)
		}
	}

	# EDID[127]: Checksum recomputed to satisfy (sum of bytes 0–127) % 256 = 0
	$sum = 0
	for ($i = 0; $i -lt 127; $i++) { $sum += $targetBlock[$i] }
	$targetBlock[127] = (-$sum) -band 0xFF

    # --- 3. Save to Registry ---
    $pnpId = $wmiMon.InstanceName -replace "_0$", ""
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$pnpId\Device Parameters"

    if (-not (Test-Path $regPath)) { continue }

    $overrideKeyPath = Join-Path -Path $regPath -ChildPath "EDID_OVERRIDE"

    if (-not (Test-Path -LiteralPath $overrideKeyPath)) {
        New-Item -Path $overrideKeyPath -Force | Out-Null
    }

    for ($i = 0; $i -lt $edidBlocks.Count; $i++) {
        Set-ItemProperty -LiteralPath $overrideKeyPath -Name $i.ToString() -Value $edidBlocks[$i] -Type Binary -Force
    }
}

# --- 4. Restart Graphics Driver ---
Get-PnpDevice -Class Display | Where-Object { $_.Status -eq 'OK' } |
ForEach-Object {
    Disable-PnpDevice -InstanceId $_.InstanceId -Confirm:$false
    Enable-PnpDevice  -InstanceId $_.InstanceId -Confirm:$false
}
