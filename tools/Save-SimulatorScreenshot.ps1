param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    [int]$TimeoutSeconds = 10
)

$ErrorActionPreference = "Stop"

$interopType = @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class SimulatorScreenshotInterop
{
    public delegate bool EnumWindowsCallback(IntPtr window, IntPtr parameter);

    [DllImport("user32.dll")]
    public static extern IntPtr GetMenu(IntPtr window);

    [DllImport("user32.dll")]
    public static extern int GetMenuItemCount(IntPtr menu);

    [DllImport("user32.dll")]
    public static extern IntPtr GetSubMenu(IntPtr menu, int position);

    [DllImport("user32.dll")]
    public static extern uint GetMenuItemID(IntPtr menu, int position);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetMenuString(
        IntPtr menu,
        uint item,
        StringBuilder text,
        int textLength,
        uint flags);

    [DllImport("user32.dll")]
    public static extern bool PostMessage(
        IntPtr window,
        uint message,
        IntPtr wordParameter,
        IntPtr longParameter);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsCallback callback, IntPtr parameter);

    [DllImport("user32.dll")]
    public static extern bool EnumChildWindows(
        IntPtr parent,
        EnumWindowsCallback callback,
        IntPtr parameter);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(
        IntPtr window,
        StringBuilder text,
        int textLength);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetClassName(
        IntPtr window,
        StringBuilder text,
        int textLength);

    [DllImport("user32.dll")]
    public static extern int GetDlgCtrlID(IntPtr window);

    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(
        IntPtr window,
        uint message,
        IntPtr wordParameter,
        IntPtr longParameter);

    [DllImport("user32.dll", CharSet = CharSet.Unicode, EntryPoint = "SendMessageW")]
    public static extern IntPtr SendMessageText(
        IntPtr window,
        uint message,
        IntPtr wordParameter,
        string text);

    public static IntPtr FindChildControl(
        IntPtr parent,
        string expectedClassName,
        int expectedControlId)
    {
        IntPtr match = IntPtr.Zero;
        EnumChildWindows(parent, delegate(IntPtr window, IntPtr parameter)
        {
            StringBuilder className = new StringBuilder(256);
            GetClassName(window, className, className.Capacity);
            if (className.ToString() == expectedClassName &&
                GetDlgCtrlID(window) == expectedControlId)
            {
                match = window;
                return false;
            }

            return true;
        }, IntPtr.Zero);
        return match;
    }
}
"@

if (!("SimulatorScreenshotInterop" -as [type])) {
    Add-Type -TypeDefinition $interopType
}
try {
    Add-Type -AssemblyName System.Drawing.Common -ErrorAction Stop
} catch {
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
}

function Find-MenuCommand {
    param(
        [IntPtr]$Menu,
        [string]$Label
    )

    $itemCount = [SimulatorScreenshotInterop]::GetMenuItemCount($Menu)
    for ($position = 0; $position -lt $itemCount; $position++) {
        $text = New-Object System.Text.StringBuilder 256
        [void][SimulatorScreenshotInterop]::GetMenuString($Menu, [uint32]$position, $text, $text.Capacity, 0x400)
        $normalizedText = ($text.ToString() -replace "&", "" -split "`t")[0]
        $commandId = [SimulatorScreenshotInterop]::GetMenuItemID($Menu, $position)

        if ($normalizedText -eq $Label -and $commandId -ne 0xFFFFFFFF) {
            return $commandId
        }

        $subMenu = [SimulatorScreenshotInterop]::GetSubMenu($Menu, $position)
        if ($subMenu -ne [IntPtr]::Zero) {
            $nestedCommand = Find-MenuCommand -Menu $subMenu -Label $Label
            if ($null -ne $nestedCommand) {
                return $nestedCommand
            }
        }
    }

    return $null
}

function Find-ProcessWindow {
    param(
        [int]$ProcessId,
        [string]$Title
    )

    $script:matchingWindow = [IntPtr]::Zero
    $callback = [SimulatorScreenshotInterop+EnumWindowsCallback] {
        param([IntPtr]$window, [IntPtr]$parameter)

        [uint32]$windowProcessId = 0
        [void][SimulatorScreenshotInterop]::GetWindowThreadProcessId($window, [ref]$windowProcessId)
        if ($windowProcessId -ne $ProcessId) {
            return $true
        }

        $windowTitle = New-Object System.Text.StringBuilder 256
        [void][SimulatorScreenshotInterop]::GetWindowText($window, $windowTitle, $windowTitle.Capacity)
        if ($windowTitle.ToString() -eq $Title) {
            $script:matchingWindow = $window
            return $false
        }

        return $true
    }

    [void][SimulatorScreenshotInterop]::EnumWindows($callback, [IntPtr]::Zero)
    return $script:matchingWindow
}

function Find-SimulatorWindow {
    param([int]$ProcessId)

    $script:simulatorWindow = [IntPtr]::Zero
    $script:simulatorWindowTitle = $null
    $callback = [SimulatorScreenshotInterop+EnumWindowsCallback] {
        param([IntPtr]$window, [IntPtr]$parameter)

        [uint32]$windowProcessId = 0
        [void][SimulatorScreenshotInterop]::GetWindowThreadProcessId($window, [ref]$windowProcessId)
        if ($windowProcessId -ne $ProcessId) {
            return $true
        }

        $windowTitle = New-Object System.Text.StringBuilder 256
        [void][SimulatorScreenshotInterop]::GetWindowText($window, $windowTitle, $windowTitle.Capacity)
        if ($windowTitle.ToString().StartsWith("CIQ Simulator")) {
            $script:simulatorWindow = $window
            $script:simulatorWindowTitle = $windowTitle.ToString()
            return $false
        }

        return $true
    }

    [void][SimulatorScreenshotInterop]::EnumWindows($callback, [IntPtr]::Zero)
    return @($script:simulatorWindow, $script:simulatorWindowTitle)
}

function Find-ChildWindow {
    param(
        [IntPtr]$Parent,
        [string]$ClassName,
        [string]$Title
    )

    $script:matchingChildWindow = [IntPtr]::Zero
    $callback = [SimulatorScreenshotInterop+EnumWindowsCallback] {
        param([IntPtr]$window, [IntPtr]$parameter)

        $windowTitle = New-Object System.Text.StringBuilder 256
        $windowClass = New-Object System.Text.StringBuilder 256
        [void][SimulatorScreenshotInterop]::GetWindowText($window, $windowTitle, $windowTitle.Capacity)
        [void][SimulatorScreenshotInterop]::GetClassName($window, $windowClass, $windowClass.Capacity)
        if ($windowTitle.ToString() -eq $Title -and $windowClass.ToString() -eq $ClassName) {
            $script:matchingChildWindow = $window
            return $false
        }

        return $true
    }

    [void][SimulatorScreenshotInterop]::EnumChildWindows($Parent, $callback, [IntPtr]::Zero)
    return $script:matchingChildWindow
}

function Dismiss-Dialog {
    param(
        [int]$ProcessId,
        [string]$Title
    )

    $window = Find-ProcessWindow -ProcessId $ProcessId -Title $Title
    if ($window -eq [IntPtr]::Zero) {
        return $false
    }

    $okButton = Find-ChildWindow -Parent $window -ClassName "Button" -Title "OK"
    if ($okButton -eq [IntPtr]::Zero) {
        return $true
    }

    [void][SimulatorScreenshotInterop]::SendMessage(
        $okButton,
        0x00F5,
        [IntPtr]::Zero,
        [IntPtr]::Zero)
    return $true
}

$simulator = Get-Process -Name "simulator" -ErrorAction SilentlyContinue |
    Select-Object -First 1
if (!$simulator) {
    throw "The Connect IQ simulator is not running."
}
$simulatorWindow = Find-SimulatorWindow -ProcessId $simulator.Id
$simulatorWindowHandle = $simulatorWindow[0]
if ($simulatorWindowHandle -eq [IntPtr]::Zero) {
    throw "The Connect IQ simulator window could not be found."
}

$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $resolvedOutputPath
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
if (Test-Path -LiteralPath $resolvedOutputPath) {
    throw "The screenshot already exists at '$resolvedOutputPath'. Remove it or choose another path."
}

$menu = [SimulatorScreenshotInterop]::GetMenu($simulatorWindowHandle)
$screenshotCommand = Find-MenuCommand -Menu $menu -Label "Save Screen Capture"
if ($null -eq $screenshotCommand) {
    throw "The simulator's 'Save Screen Capture' command was not found."
}

Write-Host "Requesting a screenshot from $($simulatorWindow[1])..."
if (![SimulatorScreenshotInterop]::PostMessage(
        $simulatorWindowHandle,
        0x0111,
        [IntPtr]$screenshotCommand,
        [IntPtr]::Zero)) {
    throw "Windows could not send the screenshot command to the simulator."
}

$deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
$dialogHandle = [IntPtr]::Zero
do {
    Start-Sleep -Milliseconds 100
    $dialogHandle = Find-ProcessWindow -ProcessId $simulator.Id -Title "Save Screenshot"
} while ($dialogHandle -eq [IntPtr]::Zero -and [DateTime]::UtcNow -lt $deadline)

if ($dialogHandle -eq [IntPtr]::Zero) {
    throw "The simulator did not open its Save Screenshot dialog within $TimeoutSeconds seconds."
}

$fileNameControl = [IntPtr]::Zero
do {
    Start-Sleep -Milliseconds 100
    $fileNameControl = [SimulatorScreenshotInterop]::FindChildControl(
        $dialogHandle,
        "Edit",
        1001)
} while ($fileNameControl -eq [IntPtr]::Zero -and [DateTime]::UtcNow -lt $deadline)
if ($fileNameControl -eq [IntPtr]::Zero) {
    throw "The screenshot filename field could not be found."
}

[void][SimulatorScreenshotInterop]::SendMessageText(
    $fileNameControl,
    0x000C,
    [IntPtr]::Zero,
    $resolvedOutputPath)

# The simulator remembers its previous screenshot directory. Windows may show
# this modal first when that location no longer exists or is unavailable.
$settleDeadline = [DateTime]::UtcNow.AddSeconds(2)
$reportedSimulatorError = $false
do {
    $dismissedDialog = Dismiss-Dialog `
        -ProcessId $simulator.Id `
        -Title "Location is not available"
    if (Dismiss-Dialog -ProcessId $simulator.Id -Title "Simulator Error") {
        if (!$reportedSimulatorError) {
            Write-Warning "The simulator reported an error while opening its screenshot dialog. The script will still attempt the capture."
            $reportedSimulatorError = $true
        }
        $dismissedDialog = $true
    }
    Start-Sleep -Milliseconds 100
} while ($dismissedDialog -and [DateTime]::UtcNow -lt $settleDeadline)

# The common file dialog exposes Save as the standard IDOK command even when
# its button is represented as a UI Automation pane instead of a button.
[void][SimulatorScreenshotInterop]::SendMessage(
    $dialogHandle,
    0x0111,
    [IntPtr]1,
    [IntPtr]::Zero)

do {
    Start-Sleep -Milliseconds 100
} while (!(Test-Path -LiteralPath $resolvedOutputPath) -and [DateTime]::UtcNow -lt $deadline)

$image = $null
do {
    if (Test-Path -LiteralPath $resolvedOutputPath) {
        try {
            $image = [System.Drawing.Image]::FromFile($resolvedOutputPath)
        } catch {
            Start-Sleep -Milliseconds 100
        }
    }
} while ($null -eq $image -and [DateTime]::UtcNow -lt $deadline)

if ($null -eq $image) {
    throw "The simulator did not create a readable PNG at '$resolvedOutputPath' within $TimeoutSeconds seconds."
}

try {
    Write-Host "Saved $($image.Width)x$($image.Height) screenshot: $resolvedOutputPath"
} finally {
    $image.Dispose()
}
