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

$manifestTemplatePath = Join-Path $projectRoot "visual-test-manifest.xml"
$manifest = [xml](Get-Content -LiteralPath (Join-Path $projectRoot "manifest.xml"))
$namespace = New-Object System.Xml.XmlNamespaceManager($manifest.NameTable)
$namespace.AddNamespace("iq", "http://www.garmin.com/xml/connectiq")
$supportedDevices = @($manifest.SelectNodes("//iq:product", $namespace) | ForEach-Object { $_.id })
$galleryManifest = [xml](Get-Content -LiteralPath $manifestTemplatePath)
$galleryNamespace = New-Object System.Xml.XmlNamespaceManager($galleryManifest.NameTable)
$galleryNamespace.AddNamespace("iq", "http://www.garmin.com/xml/connectiq")
$galleryProducts = $galleryManifest.SelectSingleNode("//iq:products", $galleryNamespace)
$galleryProducts.RemoveAll()
foreach ($deviceId in $supportedDevices) {
    $product = $galleryManifest.CreateElement("iq", "product", "http://www.garmin.com/xml/connectiq")
    $product.SetAttribute("id", $deviceId)
    [void]$galleryProducts.AppendChild($product)
}

$generatedManifestPath = Join-Path $projectRoot "visual-test-manifest.generated.xml"
$galleryManifest.Save($generatedManifestPath)
$generatedJunglePath = Join-Path $projectRoot "visual-test.generated.jungle"
[System.IO.File]::WriteAllLines($generatedJunglePath, @(
    "project.manifest = visual-test-manifest.generated.xml",
    "base.sourcePath = source;visual-tests/source"
))

$baselineManifestPath = Join-Path $projectRoot "visual-baselines\manifest.json"
$baselineManifest = Get-Content -LiteralPath $baselineManifestPath -Raw | ConvertFrom-Json
$visualDevices = @($baselineManifest.devices | ForEach-Object { $_.id })
foreach ($visualDevice in $visualDevices) {
    if ($supportedDevices -notcontains $visualDevice) {
        throw "Visual baseline device '$visualDevice' is not in the production manifest."
    }
}

$connectIqRoot = Split-Path -Parent (Split-Path -Parent $SdkPath)
$deviceRoot = Join-Path $connectIqRoot "Devices"
foreach ($deviceEntry in $baselineManifest.devices) {
    $simulatorPath = Join-Path $deviceRoot "$($deviceEntry.id)\simulator.json"
    if (!(Test-Path -LiteralPath $simulatorPath)) {
        throw "Simulator metadata missing for visual-test device '$($deviceEntry.id)'."
    }

    $simulator = Get-Content -LiteralPath $simulatorPath -Raw | ConvertFrom-Json
    if ($simulator.display.shape -ne $deviceEntry.shape -or
        $simulator.display.location.width -ne $deviceEntry.width -or
        $simulator.display.location.height -ne $deviceEntry.height) {
        throw "Visual geometry for '$($deviceEntry.id)' does not match the configured SDK."
    }
}

if (!$Device) {
    $Device = $visualDevices
}

foreach ($deviceId in $Device) {
    if ($supportedDevices -notcontains $deviceId) {
        throw "Device '$deviceId' is not in the production manifest."
    }

    $outputPath = Join-Path $projectRoot "bin\visual-gallery-$deviceId.prg"
    $compilerOutput = @(& $monkeyc -f $generatedJunglePath -d $deviceId -o $outputPath -y $DeveloperKey -w -l 1 2>&1)
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
