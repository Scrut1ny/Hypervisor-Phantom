# https://en.wikipedia.org/wiki/CPUID
# VMware Set Custom CPUID String

# Function to convert a single hex character to binary
function Convert-HexCharToBinary {
    param ([char]$hexChar)
    switch ($hexChar) {
        '0' { return '0000' }
        '1' { return '0001' }
        '2' { return '0010' }
        '3' { return '0011' }
        '4' { return '0100' }
        '5' { return '0101' }
        '6' { return '0110' }
        '7' { return '0111' }
        '8' { return '1000' }
        '9' { return '1001' }
        'A' { return '1010' }
        'B' { return '1011' }
        'C' { return '1100' }
        'D' { return '1101' }
        'E' { return '1110' }
        'F' { return '1111' }
        default { return '----' }
    }
}

# Retrieve the Processor ID in hexadecimal
$hexProcessorId = (Get-CimInstance Win32_Processor).ProcessorId

# Convert each hex character to binary and concatenate for the full binary string
$binaryProcessorId = -join ($hexProcessorId.ToCharArray() | ForEach-Object { Convert-HexCharToBinary -hexChar $_ })

# Calculate the midpoint of the binary string
$midPoint = $binaryProcessorId.Length / 2

# Split the binary string into two halves for EDX and EAX
$edx = $binaryProcessorId.Substring(0, [math]::Floor($midPoint))
$eax = $binaryProcessorId.Substring([math]::Floor($midPoint))

# Output the variables to verify
Write-Host "CPU ProcessorId (HEX): $hexProcessorId"
Write-Host "CPU ProcessorId (Binary): $binaryProcessorId"
Write-Host "EDX (first half): $edx"
Write-Host "EAX (second half): $eax"
Write-Host "`nAdd these lines to your *.vmx config:"
Write-Host "cpuid.1.edx = `"$edx`""
Write-Host "cpuid.1.edx = `"$eax`""
