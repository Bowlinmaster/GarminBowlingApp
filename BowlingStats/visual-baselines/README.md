# Visual Regression Workflow

The visual gallery is a development-only Connect IQ app that renders production views with deterministic data. Its separate manifest and source path keep gallery code out of normal debug and release builds.

Run this workflow whenever a change may affect a rendered screen, including changes to views, drawing code, layout profiles, fonts, strings, menus, dialogs, or visual resources. Capture every affected scenario on each affected representative device before committing the change.

## Build The Gallery

Build one representative device while iterating:

```powershell
.\tools\Build-VisualGallery.ps1 -DeveloperKey C:\path\to\developer_key -Device fenix7x
```

Omit `-Device` to build all representatives. With the Connect IQ simulator running, launch the generated PRG using the SDK's `monkeydo` command:

```powershell
monkeydo BowlingStats\bin\visual-gallery-fenix7x.prg fenix7x
```

The gallery has one numbered menu item for every scenario in `manifest.json`. Back returns to the gallery menu. The gallery uses a different application id, so its seeded and cleared games do not affect the production app's storage.

## Capture Screenshots

For each device and scenario in `manifest.json`:

1. Open the numbered scenario in the gallery.
2. Use the simulator's screenshot command to capture only the device display.
3. Save the PNG as `BowlingStats/visual-captures/<device>/<scenario>.png`.
4. Confirm the image dimensions match the device dimensions in the manifest.

The `visual-captures` directory is ignored by Git. Do not capture the simulator window, bezel, title bar, or status bar.

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

Baseline updates should be committed with the UI change they represent. Never update a baseline solely to make a failing comparison pass.
