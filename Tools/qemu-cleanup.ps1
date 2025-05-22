# Set execution policy to bypass for the process
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$downloadUrl = "https://download.sysinternals.com/files/PSTools.zip"
$tempDir = "$env:TEMP\PSTools"
$zipPath = "$tempDir.zip"
$psexecPath = Join-Path $tempDir "PsExec64.exe"

# Download and extract PSTools if it doesn't exist
if (-Not (Test-Path $tempDir)) {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $tempDir
    Remove-Item -Path $zipPath -Force
}

# Cleanup script as a string, embedded directly in the process call
$cleanupScript = @'
# Function to delete registry keys matching specific strings
function Remove-RegistryKeys {
    param (
        [string]$regPath,
        [array]$searchStrings
    )

    # Get all subkeys under the registry path
    $keys = Get-ChildItem -Path $regPath -Recurse

    foreach ($key in $keys) {
        if ($searchStrings | Where-Object { $key.PSPath -like "*$_*" }) {
            try {
                # Forcefully remove the registry key
                Write-Host "Deleting key under $regPath: $($key.PSPath)"
                Remove-Item -Path $key.PSPath -Recurse -Force
            } catch {
                Write-Host "Failed to delete key under $regPath: $($key.PSPath) - $_"
            }
        }
    }
}

# Define the registry paths
$regPaths = @(
    "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI",
    "HKLM:\SYSTEM\CurrentControlSet\Enum\SCSI",
    "HKLM:\SYSTEM\CurrentControlSet\Enum\HDAUDIO"
)

# List of strings to search for in the registry key names
$searchStrings = @("VEN_1AF4", "DEV_1B36", "SUBSYS_11001AF4")

# Loop through each registry path
foreach ($regPath in $regPaths) {
    if ($regPath -eq "HKLM:\SYSTEM\CurrentControlSet\Enum\SCSI") {
        # If the path is SCSI, delete all subkeys
        $keys = Get-ChildItem -Path $regPath -Recurse
        foreach ($key in $keys) {
            try {
                Write-Host "Deleting key under SCSI: $($key.PSPath)"
                Remove-Item -Path $key.PSPath -Recurse -Force
            } catch {
                Write-Host "Failed to delete key under SCSI: $($key.PSPath) - $_"
            }
        }
    }
    else {
        # Use the function to remove keys for PCI and HDAUDIO, based on the search string
        Remove-RegistryKeys -regPath $regPath -searchStrings $searchStrings
    }
}
'@

$cleanupScriptPath = "$tempDir\cleanup.ps1"
$cleanupScript | Set-Content -Path $cleanupScriptPath -Encoding UTF8

Start-Process -FilePath $psexecPath -ArgumentList "-accepteula -nobanner -s powershell -ExecutionPolicy Bypass -File `"$cleanupScriptPath`"" -WindowStyle Hidden -Wait

# Remove-Item -Path $tempDir -Force
