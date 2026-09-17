# Visual Regression Workflow

The visual gallery is a development-only Connect IQ app that renders production views with deterministic data. Its separate manifest and source path keep gallery code out of normal debug and release builds.

Run this workflow whenever a change may affect a rendered screen, including changes to views, drawing code, layout profiles, fonts, strings, menus, dialogs, or visual resources. Capture every affected scenario on each affected representative device before committing the change.

## Automated Capture

The automated workflow builds the development gallery, launches each requested
device and scenario, saves display-only PNGs with the expected names, validates
their dimensions, and runs the baseline and shape-aware comparison:

```powershell
$env:GARMIN_DEVELOPER_KEY = "C:\path\to\developer_key"
.\tools\Capture-VisualGallery.ps1 -All -Overwrite
```

Limit a run while iterating:

```powershell
.\tools\Capture-VisualGallery.ps1 `
    -Device fenix7x,venusq2 `
    -Scenario new-game,tenth-frame,game-detail `
    -Overwrite
```

Use `-SkipBuild` when the gallery PRGs are current. Existing captures are not
replaced unless `-Overwrite` is present. For a dry run that must not touch the
normal capture directory or compare against baselines, use:

```powershell
.\tools\Capture-VisualGallery.ps1 `
    -Device fenix7x `
    -OutputRoot .\BowlingStats\bin\capture-test `
    -SkipBuild `
    -SkipComparison `
    -Overwrite
```

The automation uses Garmin's own **Save Screen Capture** command. The gallery's
development-only 3-by-3 scenario grid provides deterministic button and touch
navigation; it is not included in production builds or baseline screenshots.

## Manual Launch

The shortest path is the gallery launcher. It resolves the SDK selected by
Garmin's `current-sdk.cfg`, builds the requested gallery, starts the simulator
when necessary, launches the matching PRG, and creates its capture directory:

```powershell
.\tools\Start-VisualGallery.ps1 -DeveloperKey C:\path\to\developer_key -Device fenix7x
```

Walk through every representative device in manifest order with one command:

```powershell
.\tools\Start-VisualGallery.ps1 -DeveloperKey C:\path\to\developer_key -All
```

The all-device session pauses after each launch so its screenshots can be
captured before the next device replaces it in the simulator. Add `-SkipBuild`
when the gallery PRGs are already current.

To avoid passing the key on every invocation, set it once for the current
PowerShell session:

```powershell
$env:GARMIN_DEVELOPER_KEY = "C:\path\to\developer_key"
```

Then the launcher only needs `-Device fenix7x` or `-All`.

### Raw SDK commands

The equivalent commands below are useful when diagnosing the launcher. They
also resolve the currently selected SDK, so installing and selecting a newer
SDK does not require hard-coded path changes:

```powershell
$sdk = (Get-Content "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg" -Raw).Trim()
& "$sdk\bin\connectiq.bat"
& "$sdk\bin\monkeyc.bat" -f .\BowlingStats\visual-test.jungle -d fenix7x -o .\BowlingStats\bin\visual-gallery-fenix7x.prg -y C:\path\to\developer_key -w -l 1
& "$sdk\bin\monkeydo.bat" .\BowlingStats\bin\visual-gallery-fenix7x.prg fenix7x
```

For the production app, replace the final two commands with:

```powershell
& "$sdk\bin\monkeyc.bat" -f .\BowlingStats\monkey.jungle -d fenix7x -o .\BowlingStats\bin\BowlingStats.prg -y C:\path\to\developer_key -w -l 1
& "$sdk\bin\monkeydo.bat" .\BowlingStats\bin\BowlingStats.prg fenix7x
```

Build one representative device while iterating:

```powershell
.\tools\Build-VisualGallery.ps1 -DeveloperKey C:\path\to\developer_key -Device fenix7x
```

Omit `-Device` to build all representatives. With the Connect IQ simulator running, launch the generated PRG using the SDK's `monkeydo` command:

```powershell
monkeydo BowlingStats\bin\visual-gallery-fenix7x.prg fenix7x
```

The gallery has one numbered grid cell for every scenario in `manifest.json`.
Use Up or Down and Select on button devices; swipes and a display tap work on
touch-only devices. The gallery uses a different application id, so its seeded
and cleared games do not affect the production app's storage.

## Capture Screenshots

For each device and scenario in `manifest.json`:

1. Open the numbered scenario in the gallery.
2. Use the simulator's screenshot command to capture only the device display.
3. Save the PNG as `BowlingStats/visual-captures/<device>/<scenario>.png`.
4. Confirm the image dimensions match the device dimensions in the manifest.

The `visual-captures` directory is ignored by Git. Do not capture the simulator window, bezel, title bar, or status bar.

## Review Physical Screen Shapes

Generate shape-aware previews without running a baseline comparison:

```powershell
.\tools\New-VisualPreviews.ps1 -Device fenix7x -Scenario tenth-frame
```

The command reads each device's shape and safe inset from `manifest.json` and writes derived images under `BowlingStats/bin/visual-previews`. Round-device previews use a cyan physical boundary and a yellow recommended content boundary. Magenta pixels are content outside the physical display; orange pixels are visible but inside the near-edge caution area. Rectangular devices receive the same yellow safe-area guide without a circular crop. Gallery builds validate the declared shape and dimensions against the configured SDK's `simulator.json` metadata.

Shape findings are warnings by default because native controls and intentional full-screen backgrounds may use edge pixels. Pass `-FailOnClipping` to either preview or comparison script when a workflow requires clipped foreground content to fail the command. Generated previews are review artifacts and must not be committed.

## Compare Or Update

Compare all captures with committed baselines:

```powershell
.\tools\Test-VisualBaselines.ps1
```

Limit a check while iterating:

```powershell
.\tools\Test-VisualBaselines.ps1 -Device fenix7x -Scenario tenth-frame
```

After reviewing intentional changes, update baselines explicitly:

```powershell
.\tools\Test-VisualBaselines.ps1 -UpdateBaselines
```

The comparator validates required files and dimensions, tolerates channel differences of up to 8, and allows at most 0.25 percent changed pixels by default. Failed comparisons create magenta-highlighted images under `BowlingStats/bin/visual-diffs`.

Every comparison also regenerates shape-aware previews and reports clipped or near-edge content. Review both the raw pixel diff and the physical-screen preview before accepting an intentional visual change.

Baseline updates should be committed with the UI change they represent. Never update a baseline solely to make a failing comparison pass.
