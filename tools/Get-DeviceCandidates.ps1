param(
    [string]$SdkPath,
    [string]$OutputPath,
    [switch]$IncludeSupported
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

$connectIqRoot = Split-Path -Parent (Split-Path -Parent $SdkPath)
$deviceRoot = Join-Path $connectIqRoot "Devices"
if (!(Test-Path -LiteralPath $deviceRoot)) {
    throw "Garmin device metadata was not found under '$deviceRoot'."
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectRoot "bin\device-support-candidates.md"
} elseif (![System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $repoRoot $OutputPath
}

$manifestPath = Join-Path $projectRoot "manifest.xml"
$profilePath = Join-Path $projectRoot "source\BowlingLayoutProfiles.mc"
$visualManifestPath = Join-Path $projectRoot "visual-baselines\manifest.json"

[xml]$manifest = Get-Content -LiteralPath $manifestPath
$namespace = New-Object System.Xml.XmlNamespaceManager($manifest.NameTable)
$namespace.AddNamespace("iq", "http://www.garmin.com/xml/connectiq")
$manifestProducts = @($manifest.SelectNodes("//iq:product", $namespace) | ForEach-Object { $_.id })
$profileSource = Get-Content -LiteralPath $profilePath -Raw
$visualManifest = Get-Content -LiteralPath $visualManifestPath -Raw | ConvertFrom-Json

$visualFamilies = @{}
foreach ($visualDevice in $visualManifest.devices) {
    $compilerPath = Join-Path $deviceRoot "$($visualDevice.id)\compiler.json"
    if (!(Test-Path -LiteralPath $compilerPath)) {
        continue
    }

    $compiler = Get-Content -LiteralPath $compilerPath -Raw | ConvertFrom-Json
    $familyKey = "$($visualDevice.width)x$($visualDevice.height)|$($visualDevice.shape)|$($compiler.displayType)"
    $visualFamilies[$familyKey] = $visualDevice.id
}

function Escape-MarkdownCell([object]$Value) {
    if ($null -eq $Value) {
        return ""
    }

    return $Value.ToString().Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Get-MaximumVersion($PartNumbers) {
    $versions = @($PartNumbers | ForEach-Object {
        if ($null -ne $_.connectIQVersion) {
            [version]$_.connectIQVersion
        }
    })

    if ($versions.Count -eq 0) {
        return $null
    }

    return $versions | Sort-Object -Descending | Select-Object -First 1
}

$eligible = @()
$installedCount = 0
$wearableCount = 0
$watchAppCount = 0
$minimumApi = [version]"3.0.0"

foreach ($directory in Get-ChildItem -LiteralPath $deviceRoot -Directory) {
    $compilerPath = Join-Path $directory.FullName "compiler.json"
    $simulatorPath = Join-Path $directory.FullName "simulator.json"
    if (!(Test-Path -LiteralPath $compilerPath) -or !(Test-Path -LiteralPath $simulatorPath)) {
        continue
    }

    $installedCount += 1
    $compiler = Get-Content -LiteralPath $compilerPath -Raw | ConvertFrom-Json
    $simulator = Get-Content -LiteralPath $simulatorPath -Raw | ConvertFrom-Json
    if ($compiler.webDocDeviceGroup -ne "Watches/Wearables") {
        continue
    }

    $wearableCount += 1
    $watchApp = @($compiler.appTypes | Where-Object { $_.type -eq "watchApp" })
    if ($watchApp.Count -eq 0) {
        continue
    }

    $watchAppCount += 1
    $maximumVersion = Get-MaximumVersion $compiler.partNumbers
    if ($null -eq $maximumVersion -or $maximumVersion -lt $minimumApi) {
        continue
    }

    $partNumbers = @($compiler.partNumbers | ForEach-Object { $_.number } | Where-Object { $_ })
    $allPartsMapped = $partNumbers.Count -gt 0
    foreach ($partNumber in $partNumbers) {
        if (!$profileSource.Contains($partNumber)) {
            $allPartsMapped = $false
            break
        }
    }

    $width = [int]$simulator.display.location.width
    $height = [int]$simulator.display.location.height
    $shape = $simulator.display.shape
    $displayType = $compiler.displayType
    $familyKey = "${width}x${height}|$shape|$displayType"
    $representative = $visualFamilies[$familyKey]
    $inManifest = $manifestProducts -contains $compiler.deviceId
    $memoryKb = [int]($watchApp[0].memoryLimit / 1024)
    $wave = "Wave 3 - new layout"
    if ($inManifest) {
        $wave = "Supported"
    } elseif ($null -ne $representative -and $memoryKb -ge 256) {
        $wave = "Wave 1 - existing layout"
    } elseif ($null -ne $representative) {
        $wave = "Wave 2 - constrained memory"
    }

    $input = "Buttons"
    if ([bool]$simulator.display.isTouch) {
        $input = "Touch + buttons"
    }

    $eligible += [pscustomobject]@{
        ProductId = $compiler.deviceId
        DisplayName = $compiler.displayName
        PartNumbers = $partNumbers -join ", "
        ConnectIqVersion = $maximumVersion.ToString()
        Width = $width
        Height = $height
        Shape = $shape
        DisplayType = $displayType
        Input = $input
        MemoryKb = $memoryKb
        LauncherIcon = "$($compiler.launcherIcon.width)x$($compiler.launcherIcon.height)"
        FamilyRepresentative = $representative
        InManifest = $inManifest
        ProfileMapped = $allPartsMapped
        Wave = $wave
    }
}

$supported = @($eligible | Where-Object { $_.InManifest } | Sort-Object ProductId)
$candidates = @($eligible | Where-Object { !$_.InManifest })
$waveOne = @($candidates | Where-Object { $_.Wave -like "Wave 1*" } | Sort-Object Width, Height, ProductId)
$waveTwo = @($candidates | Where-Object { $_.Wave -like "Wave 2*" } | Sort-Object Width, Height, ProductId)
$waveThree = @($candidates | Where-Object { $_.Wave -like "Wave 3*" } | Sort-Object Width, Height, ProductId)
$mappingProblems = @($supported | Where-Object { !$_.ProfileMapped })

function Add-DeviceTable([System.Collections.Generic.List[string]]$Lines, [string]$Title, $Devices) {
    $Lines.Add("## $Title")
    $Lines.Add("")
    if ($Devices.Count -eq 0) {
        $Lines.Add("None.")
        $Lines.Add("")
        return
    }

    $Lines.Add("| Product ID | Device | Screen | Display | Input | Memory | CIQ | Part numbers | Visual representative |")
    $Lines.Add("| --- | --- | --- | --- | --- | ---: | --- | --- | --- |")
    foreach ($device in $Devices) {
        $representative = $device.FamilyRepresentative
        if ([string]::IsNullOrWhiteSpace($representative)) {
            $representative = "New family"
        } else {
            $representative = "``$representative``"
        }

        $Lines.Add("| ``$($device.ProductId)`` | $(Escape-MarkdownCell $device.DisplayName) | $($device.Width)x$($device.Height) $($device.Shape) | $($device.DisplayType) | $($device.Input) | $($device.MemoryKb) KB | $($device.ConnectIqVersion) | $(Escape-MarkdownCell $device.PartNumbers) | $representative |")
    }
    $Lines.Add("")
}

$lines = New-Object "System.Collections.Generic.List[string]"
$lines.Add("# Garmin Device Support Candidates")
$lines.Add("")
$lines.Add("Generated from Connect IQ SDK ``$([System.IO.Path]::GetFileName($SdkPath.TrimEnd('\')))`` on $(Get-Date -Format 'yyyy-MM-dd').")
$lines.Add("")
$lines.Add("This report is advisory. A product must still receive an explicit part-number profile, pass packaging and input checks, and complete the required visual review before it is added to the public manifest.")
$lines.Add("")
$lines.Add("## Summary")
$lines.Add("")
$lines.Add("- Installed SDK device definitions: $installedCount")
$lines.Add("- Watch and wearable definitions: $wearableCount")
$lines.Add("- Wearables supporting watch apps: $watchAppCount")
$lines.Add("- Eligible for the project's Connect IQ 3.0 minimum: $($eligible.Count)")
$lines.Add("- Already in the manifest: $($supported.Count)")
$lines.Add("- Candidate products: $($candidates.Count)")
$lines.Add("- Wave 1, existing visual family and at least 256 KB: $($waveOne.Count)")
$lines.Add("- Wave 2, existing visual family below 256 KB: $($waveTwo.Count)")
$lines.Add("- Wave 3, new screen or display family: $($waveThree.Count)")
$lines.Add("")

Add-DeviceTable $lines "Wave 1 - Existing Layout Families" $waveOne
Add-DeviceTable $lines "Wave 2 - Constrained-Memory Devices" $waveTwo
Add-DeviceTable $lines "Wave 3 - New Layout Families" $waveThree

if ($IncludeSupported) {
    Add-DeviceTable $lines "Products Already In The Manifest" $supported
}

if ($mappingProblems.Count -gt 0) {
    $lines.Add("## Current Mapping Problems")
    $lines.Add("")
    foreach ($device in $mappingProblems) {
        $lines.Add("- ``$($device.ProductId)`` does not have every SDK part number in ``BowlingLayoutProfiles.mc``.")
    }
    $lines.Add("")
}

$outputDirectory = Split-Path -Parent $OutputPath
if (!(Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}
$lines | Set-Content -LiteralPath $OutputPath -Encoding UTF8

Write-Host "SDK wearable inventory complete."
Write-Host "  Eligible:  $($eligible.Count)"
Write-Host "  Supported: $($supported.Count)"
Write-Host "  Wave 1:    $($waveOne.Count)"
Write-Host "  Wave 2:    $($waveTwo.Count)"
Write-Host "  Wave 3:    $($waveThree.Count)"
Write-Host "  Report:    $OutputPath"

if ($mappingProblems.Count -gt 0) {
    throw "$($mappingProblems.Count) manifest products are missing explicit part-number mappings."
}
