# Set up variables
$downloadUrl = "https://download.sysinternals.com/files/PSTools.zip"
$tempDir = "$env:TEMP\PSTools"
$zipPath = "$tempDir\PSTools.zip"

# Create directory if it doesn't exist
if (-Not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# Download PSTools.zip
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

# Extract the zip file
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempDir)

# Set PsExec64 path
$psexecPath = Join-Path $tempDir "PsExec64.exe"

# Create the cleanup PowerShell command
$cleanupScript = @'
$patterns = @(
    "HKLM\SYSTEM\CurrentControlSet\Enum\PCI\VEN_1AF4",
    "HKLM\SYSTEM\CurrentControlSet\Enum\PCI\VEN_1B36",
    "HKLM\SYSTEM\CurrentControlSet\Enum\SCSI\Disk&Ven_"
)

foreach ($pattern in $patterns) {
    $keys = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue
    foreach ($key in $keys) {
        try {
            Remove-Item -Path $key.PSPath -Recurse -Force -ErrorAction Stop
            Write-Host "Deleted: $($key.PSPath)"
        } catch {
            Write-Warning "Failed to delete: $($key.PSPath) - $_"
        }
    }
}
'@

# Save cleanup script to a temporary .ps1 file
$cleanupScriptPath = "$tempDir\cleanup.ps1"
$cleanupScript | Set-Content -Path $cleanupScriptPath -Encoding UTF8

# Execute cleanup script with PsExec64 as SYSTEM
Start-Process -FilePath $psexecPath -ArgumentList "-accepteula -s powershell -ExecutionPolicy Bypass -File `"$cleanupScriptPath`"" -Wait
