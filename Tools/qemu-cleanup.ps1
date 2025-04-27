# Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

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
# Define the registry path
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI"

# List of strings to search for in the key names
$searchStrings = @("VEN_1AF4", "DEV_1B36", "SUBSYS_11001AF4")

# Get all subkeys under the PCI path
$keys = Get-ChildItem -Path $regPath -Recurse

# Loop through each key and check if its name contains any of the search strings
foreach ($key in $keys) {
    if ($searchStrings -match $key.PSPath) {
        try {
            # Forcefully remove the registry key
            Write-Host "Deleting key: $($key.PSPath)"
            Remove-Item -Path $key.PSPath -Recurse -Force
        } catch {
            Write-Host "Failed to delete key: $($key.PSPath) - $_"
        }
    }
}
'@

# Execute cleanup script using PsExec
Start-Process -FilePath $psexecPath -ArgumentList "-accepteula -nobanner -s powershell -ExecutionPolicy Bypass -Command `"$cleanupScript`"" -WindowStyle Hidden -Wait
