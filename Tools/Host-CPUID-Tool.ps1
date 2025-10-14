# VMware: Set Custom CPUID String from Local CPU ID
# https://en.wikipedia.org/wiki/CPUID

# Hex to Binary Map (for fast conversion)
$hexToBinMap = @{
    '0' = '0000'; '1' = '0001'; '2' = '0010'; '3' = '0011'
    '4' = '0100'; '5' = '0101'; '6' = '0110'; '7' = '0111'
    '8' = '1000'; '9' = '1001'; 'A' = '1010'; 'B' = '1011'
    'C' = '1100'; 'D' = '1101'; 'E' = '1110'; 'F' = '1111'
}

# Retrieve Processor ID (64-bit hex string)
$hexProcessorId = (Get-CimInstance Win32_Processor).ProcessorId.ToUpper()

# Split into two 32-bit halves (8 hex chars each)
$edxHex = $hexProcessorId.Substring(0, 8)
$eaxHex = $hexProcessorId.Substring(8, 8)

# Convert each half from hex to binary (32 bits)
$edxBin = ($edxHex.ToCharArray() | ForEach-Object { $hexToBinMap["$_"] }) -join ''
$eaxBin = ($eaxHex.ToCharArray() | ForEach-Object { $hexToBinMap["$_"] }) -join ''

$output = @"
CPU ProcessorId (HEX):  [$hexProcessorId]
EDX (Hex & Binary):     [$edxHex] - [$edxBin]
EAX (Hex & Binary):     [$eaxHex] - [$eaxBin]

Add these lines to your *.vmx config:
cpuid.1.edx = "$edxBin"
cpuid.1.eax = "$eaxBin"
"@

Write-Host $output
