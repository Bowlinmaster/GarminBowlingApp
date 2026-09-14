# Contributing to BowlingStats

## Device Support

Read [`BowlingStats/SUPPORTED_DEVICES.md`](BowlingStats/SUPPORTED_DEVICES.md) before adding a product. A device-support pull request must include:

- The exact Garmin model, size, Connect IQ product ID, and SDK part numbers.
- A manifest product entry.
- An explicit part-number mapping and named layout profile.
- Resolution, shape, display technology, and input capabilities.
- A successful compatibility check and release package build.
- Simulator screenshots for the entry, tenth-frame, completion, and history screens.
- Button and touch results when both input methods are available.
- A compatibility-matrix update.

Use the device-support issue form when requesting support for hardware you cannot test yourself.

## Local Verification

Run the compatibility script from the repository root:

```powershell
.\tools\Test-Compatibility.ps1 -DeveloperKey C:\path\to\developer_key
```

Add `-RunTests` when the Connect IQ simulator is already running. Add `-Package` before a release or after changing the manifest.

The script uses Garmin's configured current SDK by default. Pass `-SdkPath` to test against a specific SDK installation.

## Visual Verification

Use the development-only visual gallery and baseline comparator for layout changes. The full capture, comparison, and intentional-update workflow is documented in [`BowlingStats/visual-baselines/README.md`](BowlingStats/visual-baselines/README.md).

Build a gallery for one representative device with:

```powershell
.\tools\Build-VisualGallery.ps1 -DeveloperKey C:\path\to\developer_key -Device fenix7x
```

After capturing the scenarios listed in the visual manifest, run:

```powershell
.\tools\Test-VisualBaselines.ps1 -Device fenix7x
```
