param(
    [string]$SdkPath,
    [string]$DeveloperKey = $env:GARMIN_DEVELOPER_KEY,
    [switch]$RunTests,
    [switch]$Package
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
$monkeydo = Join-Path $SdkPath "bin\monkeydo.bat"
if (!(Test-Path -LiteralPath $monkeyc)) {
    throw "Monkey C compiler not found under $SdkPath."
}

$manifestPath = Join-Path $projectRoot "manifest.xml"
$profilePath = Join-Path $projectRoot "source\BowlingLayoutProfiles.mc"
$manifest = [xml](Get-Content -LiteralPath $manifestPath)
$namespace = New-Object System.Xml.XmlNamespaceManager($manifest.NameTable)
$namespace.AddNamespace("iq", "http://www.garmin.com/xml/connectiq")
$productIds = @($manifest.SelectNodes("//iq:product", $namespace) | ForEach-Object { $_.id })
$profiles = Get-Content -LiteralPath $profilePath -Raw
$connectIqRoot = Split-Path -Parent (Split-Path -Parent $SdkPath)
$deviceRoot = Join-Path $connectIqRoot "Devices"
$configurationErrors = @()

foreach ($productId in $productIds) {
    $compilerJson = Join-Path $deviceRoot "$productId\compiler.json"
    if (!(Test-Path -LiteralPath $compilerJson)) {
        $configurationErrors += "SDK metadata missing for product '$productId'."
        continue
    }

    $device = Get-Content -LiteralPath $compilerJson -Raw | ConvertFrom-Json
    foreach ($partNumber in $device.partNumbers.number) {
        if (!$profiles.Contains($partNumber)) {
            $configurationErrors += "Layout mapping missing for $productId part $partNumber."
        }
    }
}

if ($configurationErrors.Count -gt 0) {
    $configurationErrors | ForEach-Object { Write-Error $_ }
    throw "Manifest and layout-profile validation failed."
}

Write-Host "Validated $($productIds.Count) manifest products and their SDK part numbers."

$representatives = @("fr255s", "fenix7s", "fenix7", "fenix7x", "fr265s", "vivoactive6", "fr265", "fr970", "venusq2")
foreach ($deviceId in $representatives) {
    if ($productIds -notcontains $deviceId) {
        throw "Representative device '$deviceId' is not in the manifest."
    }

    $output = Join-Path $projectRoot "bin\compat-$deviceId.prg"
    & $monkeyc -f (Join-Path $projectRoot "monkey.jungle") -d $deviceId -o $output -y $DeveloperKey -l 1
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed for $deviceId."
    }
}

$testOutput = Join-Path $projectRoot "bin\compat-tests.prg"
& $monkeyc -f (Join-Path $projectRoot "monkey.jungle") -d fenix7x -o $testOutput -y $DeveloperKey -t -w -l 1
if ($LASTEXITCODE -ne 0) {
    throw "Unit-test build failed."
}

if ($RunTests) {
    & $monkeydo $testOutput fenix7x /t
    if ($LASTEXITCODE -ne 0) {
        throw "Unit tests failed."
    }
}

if ($Package) {
    $packageOutput = Join-Path $projectRoot "bin\compatibility-check.iq"
    & $monkeyc -e -f (Join-Path $projectRoot "monkey.jungle") -o $packageOutput -y $DeveloperKey -w -l 1
    if ($LASTEXITCODE -ne 0) {
        throw "Release package build failed."
    }
}

Write-Host "Compatibility checks passed."
