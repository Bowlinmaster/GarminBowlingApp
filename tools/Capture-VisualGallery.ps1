param(
    [string]$SdkPath,
    [string]$DeveloperKey = $env:GARMIN_DEVELOPER_KEY,
    [string[]]$Device,
    [string[]]$Scenario,
    [switch]$All,
    [switch]$SkipBuild,
    [switch]$Overwrite,
    [string]$OutputRoot,
    [int]$TransitionDelayMilliseconds = 750,
    [switch]$SkipComparison
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $repoRoot "BowlingStats"
$baselineManifestPath = Join-Path $projectRoot "visual-baselines\manifest.json"
$baselineManifest = Get-Content -LiteralPath $baselineManifestPath -Raw | ConvertFrom-Json
$visualDevices = @($baselineManifest.devices | ForEach-Object { $_.id })
$scenarioIds = @($baselineManifest.scenarios | ForEach-Object { $_.id })

if ([string]::IsNullOrWhiteSpace($SdkPath)) {
    $currentSdkFile = Join-Path $env:APPDATA "Garmin\ConnectIQ\current-sdk.cfg"
    if (!(Test-Path -LiteralPath $currentSdkFile)) {
        throw "No current Connect IQ SDK is configured. Pass -SdkPath."
    }
    $SdkPath = (Get-Content -LiteralPath $currentSdkFile -Raw).Trim()
}

if ($All -and $Device) {
    throw "Pass either -Device or -All, not both."
}
if (!$All -and !$Device) {
    throw "Pass -Device <id> for one or more representatives, or pass -All."
}

$selectedDevices = @(if ($All) { $visualDevices } else { $Device })
foreach ($deviceId in $selectedDevices) {
    if ($visualDevices -notcontains $deviceId) {
        throw "Device '$deviceId' is not a visual-gallery representative. Valid devices: $($visualDevices -join ', ')."
    }
}
$selectedScenarios = @(if ($Scenario) { $Scenario } else { $scenarioIds })
foreach ($scenarioId in $selectedScenarios) {
    if ($scenarioIds -notcontains $scenarioId) {
        throw "Scenario '$scenarioId' is not in the visual manifest. Valid scenarios: $($scenarioIds -join ', ')."
    }
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $projectRoot "visual-captures"
} else {
    $OutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
}

if (!$SkipComparison -and
    [System.IO.Path]::GetFullPath($OutputRoot) -ne
        [System.IO.Path]::GetFullPath((Join-Path $projectRoot "visual-captures"))) {
    throw "Baseline comparison only reads BowlingStats\visual-captures. Pass -SkipComparison when using a different -OutputRoot."
}

$connectIqRoot = Split-Path -Parent (Split-Path -Parent $SdkPath)
$deviceRoot = Join-Path $connectIqRoot "Devices"
$screenshotScript = Join-Path $PSScriptRoot "Save-SimulatorScreenshot.ps1"
$launcherScript = Join-Path $PSScriptRoot "Start-VisualGallery.ps1"

$interopType = @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class VisualGalleryInputInterop
{
    public delegate bool EnumWindowsCallback(IntPtr window, IntPtr parameter);

    [StructLayout(LayoutKind.Sequential)]
    public struct Rectangle
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(
        EnumWindowsCallback callback,
        IntPtr parameter);

    [DllImport("user32.dll")]
    public static extern bool EnumChildWindows(
        IntPtr parent,
        EnumWindowsCallback callback,
        IntPtr parameter);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetClassName(
        IntPtr window,
        StringBuilder text,
        int textLength);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(
        IntPtr window,
        StringBuilder text,
        int textLength);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);

    [DllImport("user32.dll")]
    public static extern bool GetClientRect(IntPtr window, out Rectangle rectangle);

    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(
        IntPtr window,
        uint message,
        IntPtr wordParameter,
        IntPtr longParameter);

    public static IntPtr FindDevicePanel(IntPtr parent)
    {
        IntPtr match = IntPtr.Zero;
        EnumChildWindows(parent, delegate(IntPtr window, IntPtr parameter)
        {
            StringBuilder className = new StringBuilder(128);
            StringBuilder title = new StringBuilder(128);
            GetClassName(window, className, className.Capacity);
            GetWindowText(window, title, title.Capacity);
            if (className.ToString() == "wxWindowNR" && title.ToString() == "panel")
            {
                match = window;
                return false;
            }

            return true;
        }, IntPtr.Zero);
        return match;
    }

    public static IntPtr FindSimulatorWindow(uint processId)
    {
        IntPtr match = IntPtr.Zero;
        EnumWindows(delegate(IntPtr window, IntPtr parameter)
        {
            uint windowProcessId;
            GetWindowThreadProcessId(window, out windowProcessId);
            if (windowProcessId != processId)
            {
                return true;
            }

            StringBuilder title = new StringBuilder(256);
            GetWindowText(window, title, title.Capacity);
            if (title.ToString().StartsWith("CIQ Simulator"))
            {
                match = window;
                return false;
            }

            return true;
        }, IntPtr.Zero);
        return match;
    }

    private static IntPtr Coordinates(int x, int y)
    {
        return (IntPtr)((y << 16) | (x & 0xffff));
    }

    public static void Click(IntPtr panel, int x, int y)
    {
        IntPtr coordinates = Coordinates(x, y);
        SendMessage(panel, 0x0201, (IntPtr)1, coordinates);
        SendMessage(panel, 0x0202, IntPtr.Zero, coordinates);
    }

    public static void Swipe(IntPtr panel, int x, int startY, int endY)
    {
        SendMessage(panel, 0x0201, (IntPtr)1, Coordinates(x, startY));
        const int steps = 8;
        for (int step = 1; step <= steps; step++)
        {
            int y = startY + ((endY - startY) * step / steps);
            SendMessage(panel, 0x0200, (IntPtr)1, Coordinates(x, y));
            Thread.Sleep(15);
        }
        SendMessage(panel, 0x0202, IntPtr.Zero, Coordinates(x, endY));
    }
}
"@

if (!("VisualGalleryInputInterop" -as [type])) {
    Add-Type -TypeDefinition $interopType
}
try {
    Add-Type -AssemblyName System.Drawing.Common -ErrorAction Stop
} catch {
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
}

function Get-SimulatorPanel {
    param([int]$TimeoutSeconds = 15)

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    $foundSimulatorWindow = $false
    do {
        $processes = @(Get-Process -Name "simulator" -ErrorAction SilentlyContinue |
            Sort-Object StartTime -Descending)
        foreach ($process in $processes) {
            $simulatorWindow = [VisualGalleryInputInterop]::FindSimulatorWindow($process.Id)
            if ($simulatorWindow -eq [IntPtr]::Zero) {
                continue
            }

            $foundSimulatorWindow = $true
            $panel = [VisualGalleryInputInterop]::FindDevicePanel($simulatorWindow)
            if ($panel -ne [IntPtr]::Zero) {
                return $panel
            }
        }

        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)

    if (!$foundSimulatorWindow) {
        throw "The Connect IQ simulator window could not be found within $TimeoutSeconds seconds. Close any stale simulator processes and try again."
    }

    throw "The simulator opened, but its device panel did not become available within $TimeoutSeconds seconds. Make sure a device is selected in the simulator and try again."
}

function Get-ScaledPoint {
    param(
        [IntPtr]$Panel,
        [int]$ImageWidth,
        [int]$ImageHeight,
        [double]$X,
        [double]$Y
    )

    $client = New-Object VisualGalleryInputInterop+Rectangle
    if (![VisualGalleryInputInterop]::GetClientRect($Panel, [ref]$client)) {
        throw "Could not read the simulator device panel dimensions."
    }

    $panelWidth = $client.Right - $client.Left
    $panelHeight = $client.Bottom - $client.Top
    return @(
        [int][Math]::Round($X * $panelWidth / $ImageWidth),
        [int][Math]::Round($Y * $panelHeight / $ImageHeight)
    )
}

function Invoke-DeviceButton {
    param(
        [IntPtr]$Panel,
        [object]$SimulatorMetadata,
        [int]$ImageWidth,
        [int]$ImageHeight,
        [string]$ButtonId
    )

    $button = @($SimulatorMetadata.keys | Where-Object { $_.id -eq $ButtonId }) | Select-Object -First 1
    if (!$button) {
        throw "Simulator metadata does not define the '$ButtonId' button."
    }

    $point = Get-ScaledPoint `
        -Panel $Panel `
        -ImageWidth $ImageWidth `
        -ImageHeight $ImageHeight `
        -X ($button.location.x + ($button.location.width / 2.0)) `
        -Y ($button.location.y + ($button.location.height / 2.0))
    [VisualGalleryInputInterop]::Click($Panel, $point[0], $point[1])
}

function Invoke-NextMenuItem {
    param(
        [IntPtr]$Panel,
        [object]$SimulatorMetadata,
        [int]$ImageWidth,
        [int]$ImageHeight
    )

    if (@($SimulatorMetadata.keys | Where-Object { $_.id -eq "down" }).Count -gt 0) {
        Invoke-DeviceButton `
            -Panel $Panel `
            -SimulatorMetadata $SimulatorMetadata `
            -ImageWidth $ImageWidth `
            -ImageHeight $ImageHeight `
            -ButtonId "down"
        return
    }

    $display = $SimulatorMetadata.display.location
    $start = Get-ScaledPoint `
        -Panel $Panel `
        -ImageWidth $ImageWidth `
        -ImageHeight $ImageHeight `
        -X ($display.x + ($display.width / 2.0)) `
        -Y ($display.y + ($display.height * 0.72))
    $end = Get-ScaledPoint `
        -Panel $Panel `
        -ImageWidth $ImageWidth `
        -ImageHeight $ImageHeight `
        -X ($display.x + ($display.width / 2.0)) `
        -Y ($display.y + ($display.height * 0.28))
    [VisualGalleryInputInterop]::Swipe($Panel, $start[0], $start[1], $end[1])
}

function Invoke-DisplaySelect {
    param(
        [IntPtr]$Panel,
        [object]$SimulatorMetadata,
        [int]$ImageWidth,
        [int]$ImageHeight
    )

    $display = $SimulatorMetadata.display.location
    $point = Get-ScaledPoint `
        -Panel $Panel `
        -ImageWidth $ImageWidth `
        -ImageHeight $ImageHeight `
        -X ($display.x + ($display.width / 2.0)) `
        -Y ($display.y + ($display.height / 2.0))
    [VisualGalleryInputInterop]::Click($Panel, $point[0], $point[1])
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

$plannedCaptures = foreach ($deviceId in $selectedDevices) {
    foreach ($scenarioId in $selectedScenarios) {
        Join-Path $OutputRoot "$deviceId\$scenarioId.png"
    }
}
$existingCaptures = @($plannedCaptures | Where-Object { Test-Path -LiteralPath $_ })
if ($existingCaptures.Count -gt 0 -and !$Overwrite) {
    throw "$($existingCaptures.Count) capture(s) already exist under '$OutputRoot'. Pass -Overwrite to replace them."
}

foreach ($deviceId in $selectedDevices) {
    Write-Host ""
    Write-Host "=== Capturing $deviceId ==="
    $simulatorMetadataPath = Join-Path $deviceRoot "$deviceId\simulator.json"
    $simulatorMetadata = Get-Content -LiteralPath $simulatorMetadataPath -Raw | ConvertFrom-Json
    $deviceImagePath = Join-Path $deviceRoot "$deviceId\$($simulatorMetadata.image)"
    $deviceImage = [System.Drawing.Image]::FromFile($deviceImagePath)
    try {
        $imageWidth = $deviceImage.Width
        $imageHeight = $deviceImage.Height
    } finally {
        $deviceImage.Dispose()
    }

    foreach ($scenarioId in $selectedScenarios) {
        $scenarioIndex = [Array]::IndexOf($scenarioIds, $scenarioId)
        & $launcherScript `
            -SdkPath $SdkPath `
            -Device $deviceId `
            -SkipBuild `
            -Quiet
        Start-Sleep -Milliseconds ([Math]::Max(2000, $TransitionDelayMilliseconds))

        $panel = Get-SimulatorPanel
        for ($menuIndex = 0; $menuIndex -lt $scenarioIndex; $menuIndex++) {
            Invoke-NextMenuItem `
                -Panel $panel `
                -SimulatorMetadata $simulatorMetadata `
                -ImageWidth $imageWidth `
                -ImageHeight $imageHeight
            Start-Sleep -Milliseconds 150
            $panel = Get-SimulatorPanel
        }

        Write-Host "Opening $scenarioId..."
        $usesDisplaySelect = $simulatorMetadata.display.isTouch -and
            @($simulatorMetadata.keys | Where-Object { $_.id -eq "down" }).Count -eq 0
        if ($usesDisplaySelect) {
            Invoke-DisplaySelect `
                -Panel $panel `
                -SimulatorMetadata $simulatorMetadata `
                -ImageWidth $imageWidth `
                -ImageHeight $imageHeight
        } else {
            Invoke-DeviceButton `
                -Panel $panel `
                -SimulatorMetadata $simulatorMetadata `
                -ImageWidth $imageWidth `
                -ImageHeight $imageHeight `
                -ButtonId "enter"
        }
        Start-Sleep -Milliseconds $TransitionDelayMilliseconds

        $capturePath = Join-Path $OutputRoot "$deviceId\$scenarioId.png"
        if (Test-Path -LiteralPath $capturePath) {
            Remove-Item -LiteralPath $capturePath
        }
        & $screenshotScript -OutputPath $capturePath

        $capture = [System.Drawing.Image]::FromFile($capturePath)
        try {
            $deviceConfig = $baselineManifest.devices |
                Where-Object { $_.id -eq $deviceId } |
                Select-Object -First 1
            if ($capture.Width -ne $deviceConfig.width -or
                $capture.Height -ne $deviceConfig.height) {
                throw "$scenarioId capture is $($capture.Width)x$($capture.Height); expected $($deviceConfig.width)x$($deviceConfig.height)."
            }
        } finally {
            $capture.Dispose()
        }
    }
}

Write-Host ""
Write-Host "Captured $($plannedCaptures.Count) visual scenario(s) under $OutputRoot."
if (!$SkipComparison) {
    & (Join-Path $PSScriptRoot "Test-VisualBaselines.ps1") `
        -Device $selectedDevices `
        -Scenario $selectedScenarios
}
