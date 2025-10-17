# VMware: Set Custom CPUID String from Local CPU ID
# https://en.wikipedia.org/wiki/CPUID

# Get and split the 64-bit Processor ID
$processorId = (Get-CimInstance Win32_Processor).ProcessorId.ToUpper()
$edxHex = $processorId.Substring(0, 8)
$eaxHex = $processorId.Substring(8, 8)

# Convert hex to 32-bit binary
$edxBin = [Convert]::ToString([Convert]::ToUInt32($edxHex, 16), 2).PadLeft(32, '0')
$eaxBin = [Convert]::ToString([Convert]::ToUInt32($eaxHex, 16), 2).PadLeft(32, '0')

# Output
Write-Host @"
CPU ProcessorId (HEX):  [$processorId]
EDX (Hex & Binary):     [$edxHex] - [$edxBin]
EAX (Hex & Binary):     [$eaxHex] - [$eaxBin]

Add these lines to your *.vmx config:
cpuid.1.edx = "$edxBin"
cpuid.1.eax = "$eaxBin"
"@
