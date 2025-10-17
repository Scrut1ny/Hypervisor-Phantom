# VMware: Set Custom CPUID String from Local CPU ID
# https://en.wikipedia.org/wiki/CPUID

# Get the 64-bit Processor ID in uppercase
$hexProcessorId = (Get-CimInstance Win32_Processor).ProcessorId.ToUpper()

# Split into two 32-bit halves (8 hex chars each)
$edxHex = $hexProcessorId.Substring(0, 8)
$eaxHex = $hexProcessorId.Substring(8, 8)

# Function: Convert 8-digit hex string to 32-bit binary string
function Convert-HexToBinary32($hex) {
    return [Convert]::ToString([Convert]::ToUInt32($hex, 16), 2).PadLeft(32, '0')
}

# Convert to binary
$edxBin = Convert-HexToBinary32 $edxHex
$eaxBin = Convert-HexToBinary32 $eaxHex

# Build the output
$output = @"
CPU ProcessorId (HEX):  [$hexProcessorId]
EDX (Hex & Binary):     [$edxHex] - [$edxBin]
EAX (Hex & Binary):     [$eaxHex] - [$eaxBin]

Add these lines to your *.vmx config:
cpuid.1.edx = "$edxBin"
cpuid.1.eax = "$eaxBin"
"@

Write-Host $output
