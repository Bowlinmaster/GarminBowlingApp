param(
    [string]$SdkPath,
    [string]$DeveloperKey = $env:GARMIN_DEVELOPER_KEY,
    [string]$Device,
    [switch]$All,
    [switch]$SkipBuild,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $repoRoot "BowlingStats"
$visualManifestPath = Join-Path $projectRoot "visual-baselines\manifest.json"
$visualManifest = Get-Content -LiteralPath $visualManifestPath -Raw | ConvertFrom-Json
$visualDevices = @($visualManifest.devices | ForEach-Object { $_.id })
$scenarioIds = @($visualManifest.scenarios | ForEach-Object { $_.id })

if ([string]::IsNullOrWhiteSpace($SdkPath)) {
    $currentSdkFile = Join-Path $env:APPDATA "Garmin\ConnectIQ\current-sdk.cfg"
    if (!(Test-Path -LiteralPath $currentSdkFile)) {
        throw "No current Connect IQ SDK is configured. Pass -SdkPath."
    }
    $SdkPath = (Get-Content -LiteralPath $currentSdkFile -Raw).Trim()
}

$simulator = Join-Path $SdkPath "bin\simulator.exe"
$monkeydo = Join-Path $SdkPath "bin\monkeydo.bat"
if (!(Test-Path -LiteralPath $simulator) -or !(Test-Path -LiteralPath $monkeydo)) {
    throw "Connect IQ simulator tools were not found under '$SdkPath'."
}

if ($All -and ![string]::IsNullOrWhiteSpace($Device)) {
    throw "Pass either -Device or -All, not both."
}
if (!$All -and [string]::IsNullOrWhiteSpace($Device)) {
    throw "Pass -Device <id> for one representative or -All for every representative."
}

$selectedDevices = @(if ($All) { $visualDevices } else { $Device })
foreach ($deviceId in $selectedDevices) {
    if ($visualDevices -notcontains $deviceId) {
        throw "Device '$deviceId' is not a visual-gallery representative. Valid devices: $($visualDevices -join ', ')."
    }
}

if (!$SkipBuild) {
    if ([string]::IsNullOrWhiteSpace($DeveloperKey) -or !(Test-Path -LiteralPath $DeveloperKey)) {
        throw "Pass a valid -DeveloperKey or set GARMIN_DEVELOPER_KEY."
    }

    & (Join-Path $PSScriptRoot "Build-VisualGallery.ps1") `
        -SdkPath $SdkPath `
        -DeveloperKey $DeveloperKey `
        -Device $selectedDevices
}

if (!(Get-Process -Name "simulator" -ErrorAction SilentlyContinue)) {
    if (!$Quiet) {
        Write-Host "Starting the Connect IQ simulator from SDK $([System.IO.Path]::GetFileName($SdkPath.TrimEnd('\')))..."
    }
    Start-Process -FilePath $simulator

    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    do {
        Start-Sleep -Milliseconds 250
        $simulatorProcess = Get-Process -Name "simulator" -ErrorAction SilentlyContinue
    } while (!$simulatorProcess -and [DateTime]::UtcNow -lt $deadline)

    if (!$simulatorProcess) {
        throw "The Connect IQ simulator did not start within 15 seconds."
    }
}

foreach ($deviceId in $selectedDevices) {
    $programPath = Join-Path $projectRoot "bin\visual-gallery-$deviceId.prg"
    if (!(Test-Path -LiteralPath $programPath)) {
        throw "Gallery build not found at '$programPath'. Run without -SkipBuild first."
    }

    $captureRoot = Join-Path $projectRoot "visual-captures\$deviceId"
    New-Item -ItemType Directory -Path $captureRoot -Force | Out-Null

    if (!$Quiet) {
        Write-Host ""
        Write-Host "Launching visual gallery for $deviceId..."
    }
    $runner = Start-Process `
        -FilePath $monkeydo `
        -ArgumentList @("`"$programPath`"", $deviceId) `
        -WindowStyle Hidden `
        -PassThru
    Start-Sleep -Seconds 1
    if ($runner.HasExited -and $runner.ExitCode -ne 0) {
        throw "Could not launch the $deviceId gallery in the simulator."
    }

    if (!$Quiet) {
        Write-Host "Save display-only screenshots under:"
        Write-Host "  $captureRoot"
        Write-Host "Expected files:"
        foreach ($scenarioId in $scenarioIds) {
            Write-Host "  $scenarioId.png"
        }
    }

    if ($All -and $deviceId -ne $selectedDevices[-1]) {
        Read-Host "Press Enter after capturing $deviceId to launch the next device"
    }
}

if (!$Quiet) {
    Write-Host ""
    Write-Host "Capture launch sequence complete. Compare available captures with:"
    Write-Host "  .\tools\Test-VisualBaselines.ps1"
}
