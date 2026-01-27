# Set execution policy to bypass for the process
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$downloadUrl     = "https://download.sysinternals.com/files/PSTools.zip"
$tempDir         = "$env:TEMP\PSTools"
$zipPath         = "$tempDir.zip"
$psexecPath      = Join-Path $tempDir "PsExec64.exe"
$cleanupScriptPath = Join-Path $tempDir "cleanup.ps1"

# Download and extract PSTools only if PsExec64.exe is missing
if (-not (Test-Path $psexecPath)) {
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir | Out-Null
    }
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
    Remove-Item -Path $zipPath -Force
}

# Cleanup script as a string, executed as SYSTEM via PsExec
$cleanupScript = @'
$enumRoot      = "HKLM:\SYSTEM\CurrentControlSet\Enum"
$scsiRoot      = Join-Path $enumRoot "SCSI"
$searchStrings = @("VEN_1AF4", "DEV_1B36", "SUBSYS_11001AF4")

function Remove-KeysMatching {
    param(
        [string]$Root,
        [string[]]$Patterns
    )
    $keys = Get-ChildItem -Path $Root -Recurse -ErrorAction SilentlyContinue
    foreach ($key in $keys) {
        if ($Patterns | Where-Object { $key.PSPath -like "*$_*" }) {
            try {
                Remove-Item -Path $key.PSPath -Recurse -Force -ErrorAction Stop
                Write-Host "Deleted (match): $($key.PSPath)"
            } catch {
                Write-Host "Failed (match): $($key.PSPath) - $_"
            }
        }
    }
}

function Remove-AllSubKeys {
    param(
        [string]$Root
    )
    $keys = Get-ChildItem -Path $Root -Recurse -ErrorAction SilentlyContinue
    foreach ($key in $keys) {
        try {
            Remove-Item -Path $key.PSPath -Recurse -Force -ErrorAction Stop
            Write-Host "Deleted (SCSI): $($key.PSPath)"
        } catch {
            Write-Host "Failed (SCSI): $($key.PSPath) - $_"
        }
    }
}

# Scan the entire Enum tree for the target PCI signatures
if (Test-Path $enumRoot) {
    Remove-KeysMatching -Root $enumRoot -Patterns $searchStrings
}

# Delete all subkeys under Enum\SCSI
if (Test-Path $scsiRoot) {
    Remove-AllSubKeys -Root $scsiRoot
}
'@

$cleanupScript | Set-Content -Path $cleanupScriptPath -Encoding UTF8

Start-Process -FilePath $psexecPath -ArgumentList "-accepteula -nobanner -s powershell -ExecutionPolicy Bypass -File `"$cleanupScriptPath`"" -WindowStyle Hidden -Wait

# Uncomment if you want to remove the temp folder after execution
# Remove-Item -Path $tempDir -Recurse -Force
