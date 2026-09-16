param(
    [string]$ManifestPath,
    [string]$ImageRoot,
    [string]$OutputRoot,
    [string[]]$Device,
    [string[]]$Scenario,
    [int]$ChannelTolerance = 8,
    [switch]$FailOnClipping
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $repoRoot "BowlingStats"

if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $projectRoot "visual-baselines\manifest.json"
}
if ([string]::IsNullOrWhiteSpace($ImageRoot)) {
    $ImageRoot = Join-Path $projectRoot "visual-captures"
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $projectRoot "bin\visual-previews"
}
if ($ChannelTolerance -lt 0 -or $ChannelTolerance -gt 255) {
    throw "ChannelTolerance must be between 0 and 255."
}

Add-Type -AssemblyName System.Drawing
$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
if ($manifest.schemaVersion -ne 2 -or $manifest.devices.Count -eq 0 -or $manifest.scenarios.Count -eq 0) {
    throw "Visual baseline manifest is empty or uses an unsupported schema."
}
if ($manifest.backgroundColor -notmatch '^[0-9A-Fa-f]{6}$') {
    throw "Visual baseline manifest backgroundColor must be a six-digit RGB value."
}

$backgroundRed = [Convert]::ToInt32($manifest.backgroundColor.Substring(0, 2), 16)
$backgroundGreen = [Convert]::ToInt32($manifest.backgroundColor.Substring(2, 2), 16)
$backgroundBlue = [Convert]::ToInt32($manifest.backgroundColor.Substring(4, 2), 16)
$knownDevices = @($manifest.devices | ForEach-Object { $_.id })
$knownScenarios = @($manifest.scenarios | ForEach-Object { $_.id })

foreach ($requestedDevice in @($Device | Where-Object { ![string]::IsNullOrWhiteSpace($_) })) {
    if ($knownDevices -notcontains $requestedDevice) {
        throw "Unknown visual-test device '$requestedDevice'."
    }
}
foreach ($requestedScenario in @($Scenario | Where-Object { ![string]::IsNullOrWhiteSpace($_) })) {
    if ($knownScenarios -notcontains $requestedScenario) {
        throw "Unknown visual-test scenario '$requestedScenario'."
    }
}

$selectedDevices = @($manifest.devices | Where-Object { !$Device -or $Device -contains $_.id })
$selectedScenarios = @($manifest.scenarios | Where-Object { !$Scenario -or $Scenario -contains $_.id })

function Get-BitmapBytes([System.Drawing.Bitmap]$Bitmap) {
    $rectangle = New-Object System.Drawing.Rectangle(0, 0, $Bitmap.Width, $Bitmap.Height)
    $pixelFormat = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    $data = $Bitmap.LockBits($rectangle, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, $pixelFormat)
    try {
        $length = [Math]::Abs($data.Stride) * $Bitmap.Height
        $bytes = New-Object byte[] $length
        [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $length)
        return [PSCustomObject]@{ Bytes = $bytes; Stride = $data.Stride }
    } finally {
        $Bitmap.UnlockBits($data)
    }
}

function Test-ContentPixel($bytes, [int]$offset) {
    return [Math]::Abs([int]$bytes[$offset] - $backgroundBlue) -gt $ChannelTolerance -or
        [Math]::Abs([int]$bytes[$offset + 1] - $backgroundGreen) -gt $ChannelTolerance -or
        [Math]::Abs([int]$bytes[$offset + 2] - $backgroundRed) -gt $ChannelTolerance
}

function New-ShapePreview($deviceEntry, [string]$sourcePath, [string]$outputPath) {
    if ($deviceEntry.shape -ne "round" -and $deviceEntry.shape -ne "rectangle") {
        throw "Device '$($deviceEntry.id)' has unsupported shape '$($deviceEntry.shape)'."
    }
    if ($deviceEntry.safeInset -lt 0 -or ($deviceEntry.safeInset * 2) -ge [Math]::Min($deviceEntry.width, $deviceEntry.height)) {
        throw "Device '$($deviceEntry.id)' has invalid safeInset '$($deviceEntry.safeInset)'."
    }

    $source = New-Object System.Drawing.Bitmap($sourcePath)
    $preview = $null
    try {
        if ($source.Width -ne $deviceEntry.width -or $source.Height -ne $deviceEntry.height) {
            throw "Image is $($source.Width)x$($source.Height); expected $($deviceEntry.width)x$($deviceEntry.height)."
        }

        $sourceData = Get-BitmapBytes $source
        $preview = New-Object System.Drawing.Bitmap($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $rectangle = New-Object System.Drawing.Rectangle(0, 0, $preview.Width, $preview.Height)
        $previewData = $preview.LockBits($rectangle, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $previewBytes = New-Object byte[] ([Math]::Abs($previewData.Stride) * $preview.Height)
            $centerX = ($source.Width - 1) / 2.0
            $centerY = ($source.Height - 1) / 2.0
            $radius = ([Math]::Min($source.Width, $source.Height) / 2.0) - 0.5
            $safeRadius = $radius - $deviceEntry.safeInset
            $clippedPixels = 0
            $unsafePixels = 0

            for ($y = 0; $y -lt $source.Height; $y++) {
                $sourceRow = if ($sourceData.Stride -ge 0) { $y * $sourceData.Stride } else { ($source.Height - 1 - $y) * -$sourceData.Stride }
                $previewRow = if ($previewData.Stride -ge 0) { $y * $previewData.Stride } else { ($preview.Height - 1 - $y) * -$previewData.Stride }

                for ($x = 0; $x -lt $source.Width; $x++) {
                    $sourceOffset = $sourceRow + ($x * 4)
                    $previewOffset = $previewRow + ($x * 4)
                    $isContent = Test-ContentPixel $sourceData.Bytes $sourceOffset

                    if ($deviceEntry.shape -eq "round") {
                        $distanceSquared = (($x - $centerX) * ($x - $centerX)) + (($y - $centerY) * ($y - $centerY))
                        $insidePhysical = $distanceSquared -le ($radius * $radius)
                        $insideSafe = $distanceSquared -le ($safeRadius * $safeRadius)
                    } else {
                        $insidePhysical = $true
                        $insideSafe = $x -ge $deviceEntry.safeInset -and
                            $x -lt ($source.Width - $deviceEntry.safeInset) -and
                            $y -ge $deviceEntry.safeInset -and
                            $y -lt ($source.Height - $deviceEntry.safeInset)
                    }

                    if (!$insidePhysical) {
                        if ($isContent) {
                            # Magenta marks content that the physical display clips completely.
                            $previewBytes[$previewOffset] = 255
                            $previewBytes[$previewOffset + 1] = 0
                            $previewBytes[$previewOffset + 2] = 255
                            $clippedPixels++
                        } else {
                            $checker = if (([Math]::Floor($x / 8) + [Math]::Floor($y / 8)) % 2 -eq 0) { 28 } else { 44 }
                            $previewBytes[$previewOffset] = $checker
                            $previewBytes[$previewOffset + 1] = $checker
                            $previewBytes[$previewOffset + 2] = $checker
                        }
                        $previewBytes[$previewOffset + 3] = 255
                    } elseif (!$insideSafe -and $isContent) {
                        # Orange marks visible content that is inside the display but near its edge.
                        $previewBytes[$previewOffset] = 0
                        $previewBytes[$previewOffset + 1] = 165
                        $previewBytes[$previewOffset + 2] = 255
                        $previewBytes[$previewOffset + 3] = 255
                        $unsafePixels++
                    } else {
                        for ($channel = 0; $channel -lt 4; $channel++) {
                            $previewBytes[$previewOffset + $channel] = $sourceData.Bytes[$sourceOffset + $channel]
                        }
                    }
                }
            }

            [System.Runtime.InteropServices.Marshal]::Copy($previewBytes, 0, $previewData.Scan0, $previewBytes.Length)
        } finally {
            $preview.UnlockBits($previewData)
        }

        $graphics = [System.Drawing.Graphics]::FromImage($preview)
        try {
            $physicalPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Cyan, 1)
            $safePen = New-Object System.Drawing.Pen([System.Drawing.Color]::Yellow, 1)
            try {
                if ($deviceEntry.shape -eq "round") {
                    $graphics.DrawEllipse($physicalPen, 0, 0, $preview.Width - 1, $preview.Height - 1)
                    $inset = [int]$deviceEntry.safeInset
                    $graphics.DrawEllipse($safePen, $inset, $inset, $preview.Width - 1 - (2 * $inset), $preview.Height - 1 - (2 * $inset))
                } else {
                    $inset = [int]$deviceEntry.safeInset
                    $graphics.DrawRectangle($safePen, $inset, $inset, $preview.Width - 1 - (2 * $inset), $preview.Height - 1 - (2 * $inset))
                }
            } finally {
                $physicalPen.Dispose()
                $safePen.Dispose()
            }
        } finally {
            $graphics.Dispose()
        }

        $outputDirectory = Split-Path -Parent $outputPath
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
        $preview.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

        return [PSCustomObject]@{
            ClippedPixels = $clippedPixels
            UnsafePixels = $unsafePixels
        }
    } finally {
        if ($null -ne $preview) { $preview.Dispose() }
        $source.Dispose()
    }
}

$failures = @()
$clippingFailures = @()
$generated = 0
$clippedPreviews = 0
$nearEdgePreviews = 0

foreach ($deviceEntry in $selectedDevices) {
    foreach ($scenarioEntry in $selectedScenarios) {
        $relativePath = Join-Path $deviceEntry.id ($scenarioEntry.id + ".png")
        $sourcePath = Join-Path $ImageRoot $relativePath
        $outputPath = Join-Path $OutputRoot $relativePath
        $label = "$($deviceEntry.id)/$($scenarioEntry.id)"

        if (!(Test-Path -LiteralPath $sourcePath)) {
            $failures += "$label source image is missing."
            continue
        }

        try {
            $result = New-ShapePreview $deviceEntry $sourcePath $outputPath
            $generated++
            if ($result.ClippedPixels -gt 0) {
                $clippedPreviews++
                Write-Host "WARN    $label has $($result.ClippedPixels) clipped and $($result.UnsafePixels) near-edge content pixels; preview: $outputPath" -ForegroundColor Yellow
                if ($FailOnClipping) {
                    $clippingFailures += "$label has $($result.ClippedPixels) clipped content pixels."
                }
            } elseif ($result.UnsafePixels -gt 0) {
                $nearEdgePreviews++
                Write-Host "WARN    $label has $($result.UnsafePixels) near-edge content pixels; preview: $outputPath" -ForegroundColor Yellow
            } else {
                Write-Host "PREVIEW $label"
            }
        } catch {
            $failures += "$label preview failed: $($_.Exception.Message)"
        }
    }
}

if ($failures.Count -gt 0 -or $clippingFailures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "FAIL    $_" -ForegroundColor Red }
    $clippingFailures | ForEach-Object { Write-Host "FAIL    $_" -ForegroundColor Red }
    throw "$($failures.Count + $clippingFailures.Count) visual shape check(s) failed."
}

Write-Host "Generated $generated shape-aware visual preview(s) under $OutputRoot."
Write-Host "$clippedPreviews preview(s) contain clipped content; $nearEdgePreviews additional preview(s) contain near-edge content."
