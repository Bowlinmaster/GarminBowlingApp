param(
    [string]$ManifestPath,
    [string]$BaselineRoot,
    [string]$CandidateRoot,
    [string]$PreviewRoot,
    [string[]]$Device,
    [string[]]$Scenario,
    [double]$MaxChangedPercent = 0.25,
    [int]$ChannelTolerance = 8,
    [switch]$FailOnClipping,
    [switch]$UpdateBaselines
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $repoRoot "BowlingStats"

if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $projectRoot "visual-baselines\manifest.json"
}
if ([string]::IsNullOrWhiteSpace($BaselineRoot)) {
    $BaselineRoot = Join-Path $projectRoot "visual-baselines"
}
if ([string]::IsNullOrWhiteSpace($CandidateRoot)) {
    $CandidateRoot = Join-Path $projectRoot "visual-captures"
}
if ([string]::IsNullOrWhiteSpace($PreviewRoot)) {
    $PreviewRoot = Join-Path $projectRoot "bin\visual-previews"
}

if (!(Test-Path -LiteralPath $ManifestPath)) {
    throw "Visual baseline manifest not found: $ManifestPath"
}
if ($MaxChangedPercent -lt 0 -or $MaxChangedPercent -gt 100) {
    throw "MaxChangedPercent must be between 0 and 100."
}
if ($ChannelTolerance -lt 0 -or $ChannelTolerance -gt 255) {
    throw "ChannelTolerance must be between 0 and 255."
}

Add-Type -AssemblyName System.Drawing
$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
if ($manifest.schemaVersion -ne 2 -or $manifest.devices.Count -eq 0 -or $manifest.scenarios.Count -eq 0) {
    throw "Visual baseline manifest is empty or uses an unsupported schema."
}

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
$diffRoot = Join-Path $projectRoot "bin\visual-diffs"

$previewArguments = @{
    ManifestPath = $ManifestPath
    ImageRoot = $CandidateRoot
    OutputRoot = $PreviewRoot
    ChannelTolerance = $ChannelTolerance
}
if ($Device) {
    $previewArguments.Device = $Device
}
if ($Scenario) {
    $previewArguments.Scenario = $Scenario
}
if ($FailOnClipping) {
    $previewArguments.FailOnClipping = $true
}
& (Join-Path $PSScriptRoot "New-VisualPreviews.ps1") @previewArguments

function Get-VisualImageSize([string]$Path) {
    $image = [System.Drawing.Image]::FromFile($Path)
    try {
        return [PSCustomObject]@{ Width = $image.Width; Height = $image.Height }
    } finally {
        $image.Dispose()
    }
}

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

function Compare-VisualImage([string]$BaselinePath, [string]$CandidatePath, [string]$DiffPath) {
    $baseline = New-Object System.Drawing.Bitmap($BaselinePath)
    $candidate = New-Object System.Drawing.Bitmap($CandidatePath)
    try {
        if ($baseline.Width -ne $candidate.Width -or $baseline.Height -ne $candidate.Height) {
            throw "Image dimensions differ: baseline is $($baseline.Width)x$($baseline.Height), candidate is $($candidate.Width)x$($candidate.Height)."
        }

        $baselineData = Get-BitmapBytes $baseline
        $candidateData = Get-BitmapBytes $candidate
        $diff = New-Object System.Drawing.Bitmap($baseline.Width, $baseline.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $diffBytes = New-Object byte[] ($baseline.Width * $baseline.Height * 4)
        $changedPixels = 0

        for ($y = 0; $y -lt $baseline.Height; $y++) {
            $baselineRow = if ($baselineData.Stride -ge 0) { $y * $baselineData.Stride } else { ($baseline.Height - 1 - $y) * -$baselineData.Stride }
            $candidateRow = if ($candidateData.Stride -ge 0) { $y * $candidateData.Stride } else { ($candidate.Height - 1 - $y) * -$candidateData.Stride }
            $diffRow = $y * $baseline.Width * 4

            for ($x = 0; $x -lt $baseline.Width; $x++) {
                $baselineOffset = $baselineRow + ($x * 4)
                $candidateOffset = $candidateRow + ($x * 4)
                $diffOffset = $diffRow + ($x * 4)
                $different = $false

                for ($channel = 0; $channel -lt 4; $channel++) {
                    if ([Math]::Abs([int]$baselineData.Bytes[$baselineOffset + $channel] - [int]$candidateData.Bytes[$candidateOffset + $channel]) -gt $ChannelTolerance) {
                        $different = $true
                        break
                    }
                }

                if ($different) {
                    $changedPixels++
                    $diffBytes[$diffOffset] = 255
                    $diffBytes[$diffOffset + 1] = 0
                    $diffBytes[$diffOffset + 2] = 255
                    $diffBytes[$diffOffset + 3] = 255
                } else {
                    $diffBytes[$diffOffset] = [byte]($candidateData.Bytes[$candidateOffset] / 4)
                    $diffBytes[$diffOffset + 1] = [byte]($candidateData.Bytes[$candidateOffset + 1] / 4)
                    $diffBytes[$diffOffset + 2] = [byte]($candidateData.Bytes[$candidateOffset + 2] / 4)
                    $diffBytes[$diffOffset + 3] = 255
                }
            }
        }

        if ($changedPixels -gt 0) {
            $rectangle = New-Object System.Drawing.Rectangle(0, 0, $diff.Width, $diff.Height)
            $data = $diff.LockBits($rectangle, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            try {
                [System.Runtime.InteropServices.Marshal]::Copy($diffBytes, 0, $data.Scan0, $diffBytes.Length)
            } finally {
                $diff.UnlockBits($data)
            }

            $diffDirectory = Split-Path -Parent $DiffPath
            New-Item -ItemType Directory -Path $diffDirectory -Force | Out-Null
            $diff.Save($DiffPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }

        $totalPixels = $baseline.Width * $baseline.Height
        return [PSCustomObject]@{
            ChangedPixels = $changedPixels
            ChangedPercent = ($changedPixels * 100.0) / $totalPixels
        }
    } finally {
        if ($null -ne $diff) { $diff.Dispose() }
        $candidate.Dispose()
        $baseline.Dispose()
    }
}

$failures = @()
$checked = 0
$updated = 0

foreach ($deviceEntry in $selectedDevices) {
    foreach ($scenarioEntry in $selectedScenarios) {
        $relativePath = Join-Path $deviceEntry.id ($scenarioEntry.id + ".png")
        $candidatePath = Join-Path $CandidateRoot $relativePath
        $baselinePath = Join-Path $BaselineRoot $relativePath
        $label = "$($deviceEntry.id)/$($scenarioEntry.id)"

        if (!(Test-Path -LiteralPath $candidatePath)) {
            $failures += "$label candidate is missing."
            continue
        }

        try {
            $candidateSize = Get-VisualImageSize $candidatePath
            if ($candidateSize.Width -ne $deviceEntry.width -or $candidateSize.Height -ne $deviceEntry.height) {
                $failures += "$label candidate is $($candidateSize.Width)x$($candidateSize.Height); expected $($deviceEntry.width)x$($deviceEntry.height)."
                continue
            }

            if ($UpdateBaselines) {
                $baselineDirectory = Split-Path -Parent $baselinePath
                New-Item -ItemType Directory -Path $baselineDirectory -Force | Out-Null
                Copy-Item -LiteralPath $candidatePath -Destination $baselinePath -Force
                Write-Host "UPDATED $label"
                $updated++
                continue
            }

            if (!(Test-Path -LiteralPath $baselinePath)) {
                $failures += "$label baseline is missing."
                continue
            }

            $baselineSize = Get-VisualImageSize $baselinePath
            if ($baselineSize.Width -ne $deviceEntry.width -or $baselineSize.Height -ne $deviceEntry.height) {
                $failures += "$label baseline is $($baselineSize.Width)x$($baselineSize.Height); expected $($deviceEntry.width)x$($deviceEntry.height)."
                continue
            }

            $baselineHash = (Get-FileHash -LiteralPath $baselinePath -Algorithm SHA256).Hash
            $candidateHash = (Get-FileHash -LiteralPath $candidatePath -Algorithm SHA256).Hash
            if ($baselineHash -eq $candidateHash) {
                Write-Host "PASS    $label (identical)"
                $checked++
                continue
            }

            $diffPath = Join-Path $diffRoot $relativePath
            $comparison = Compare-VisualImage $baselinePath $candidatePath $diffPath
            if ($comparison.ChangedPercent -gt $MaxChangedPercent) {
                $failures += ("{0} changed by {1:N3}% ({2} pixels); diff: {3}" -f $label, $comparison.ChangedPercent, $comparison.ChangedPixels, $diffPath)
            } else {
                Write-Host ("PASS    {0} ({1:N3}% changed)" -f $label, $comparison.ChangedPercent)
                $checked++
            }
        } catch {
            $failures += "$label could not be compared: $($_.Exception.Message)"
        }
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Host "FAIL    $_" -ForegroundColor Red }
    throw "$($failures.Count) visual baseline check(s) failed."
}

if ($UpdateBaselines) {
    Write-Host "Updated $updated visual baseline(s)."
} else {
    Write-Host "Validated $checked visual baseline(s)."
}
