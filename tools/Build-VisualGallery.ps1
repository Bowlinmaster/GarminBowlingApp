param(
    [string]$SdkPath,
    [string]$DeveloperKey = $env:GARMIN_DEVELOPER_KEY,
    [string[]]$Device
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $repoRoot "BowlingStats"

if ([string]::IsNullOrWhiteSpace($SdkPath)) {
    $currentSdkFile = Join-Path $env:APPDATA "Garmin\ConnectIQ\current-sdk.cfg"
    if (!(Test-Path -LiteralPath $currentSdkFile)) {
        throw "No current Connect IQ SDK is configured. Pass -SdkPath."
    }
    $SdkPath = (Get-Content -LiteralPath $currentSdkFile -Raw).Trim()
}

if ([string]::IsNullOrWhiteSpace($DeveloperKey) -or !(Test-Path -LiteralPath $DeveloperKey)) {
    throw "Pass a valid -DeveloperKey or set GARMIN_DEVELOPER_KEY."
}

$monkeyc = Join-Path $SdkPath "bin\monkeyc.bat"
if (!(Test-Path -LiteralPath $monkeyc)) {
    throw "Monkey C compiler not found under $SdkPath."
}

$manifestPath = Join-Path $projectRoot "visual-test-manifest.xml"
$manifest = [xml](Get-Content -LiteralPath $manifestPath)
$namespace = New-Object System.Xml.XmlNamespaceManager($manifest.NameTable)
$namespace.AddNamespace("iq", "http://www.garmin.com/xml/connectiq")
$supportedDevices = @($manifest.SelectNodes("//iq:product", $namespace) | ForEach-Object { $_.id })
$baselineManifestPath = Join-Path $projectRoot "visual-baselines\manifest.json"
$baselineManifest = Get-Content -LiteralPath $baselineManifestPath -Raw | ConvertFrom-Json
$visualDevices = @($baselineManifest.devices | ForEach-Object { $_.id })
if (@(Compare-Object $supportedDevices $visualDevices).Count -gt 0) {
    throw "Visual-test manifest products and visual baseline devices do not match."
}

if (!$Device) {
    $Device = $visualDevices
}

foreach ($deviceId in $Device) {
    if ($supportedDevices -notcontains $deviceId) {
        throw "Device '$deviceId' is not a visual-gallery representative."
    }

    $outputPath = Join-Path $projectRoot "bin\visual-gallery-$deviceId.prg"
    $compilerOutput = @(& $monkeyc -f (Join-Path $projectRoot "visual-test.jungle") -d $deviceId -o $outputPath -y $DeveloperKey -w -l 1 2>&1)
    $compilerOutput | ForEach-Object { Write-Host $_ }

    $warnings = @($compilerOutput | Where-Object { $_ -match "WARNING:" })
    if ($LASTEXITCODE -ne 0) {
        throw "Visual gallery build failed for $deviceId."
    }
    if ($warnings.Count -gt 0) {
        throw "Visual gallery build produced $($warnings.Count) warning(s) for $deviceId."
    }

    Write-Host "Built $deviceId gallery: $outputPath"
}
