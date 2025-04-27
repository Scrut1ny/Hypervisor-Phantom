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
# Define the registry paths
$regPaths = @(
    "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI",  # For searching specific strings
    "HKLM:\SYSTEM\CurrentControlSet\Enum\SCSI"  # For deleting all subkeys
)

# List of strings to search for in the PCI key names
$searchStrings = @("VEN_1AF4", "DEV_1B36", "SUBSYS_11001AF4")

# Loop through each registry path
foreach ($regPath in $regPaths) {
    # Get all subkeys under the registry path
    $keys = Get-ChildItem -Path $regPath -Recurse

    # If the path is SCSI, delete all subkeys (no search strings needed)
    if ($regPath -eq "HKLM:\SYSTEM\CurrentControlSet\Enum\SCSI") {
        foreach ($key in $keys) {
            try {
                # Forcefully remove the registry key
                Write-Host "Deleting key under SCSI: $($key.PSPath)"
                Remove-Item -Path $key.PSPath -Recurse -Force
            } catch {
                Write-Host "Failed to delete key under SCSI: $($key.PSPath) - $_"
            }
        }
    } else {
        # For PCI, only delete keys that match the search strings
        foreach ($key in $keys) {
            if ($searchStrings | Where-Object { $key.PSPath -like "*$_*" }) {
                try {
                    # Forcefully remove the registry key
                    Write-Host "Deleting key under PCI: $($key.PSPath)"
                    Remove-Item -Path $key.PSPath -Recurse -Force
                } catch {
                    Write-Host "Failed to delete key under PCI: $($key.PSPath) - $_"
                }
            }
        }
    }
}
'@

$cleanupScriptPath = "$tempDir\cleanup.ps1"
$cleanupScript | Set-Content -Path $cleanupScriptPath -Encoding UTF8

Start-Process -FilePath $psexecPath -ArgumentList "-accepteula -nobanner -s powershell -ExecutionPolicy Bypass -File `"$cleanupScriptPath`"" -WindowStyle Hidden -Wait
