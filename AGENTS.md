# Repository Instructions

## Visual Regression Checks

Treat changes to views, drawing code, layout profiles, fonts, strings, menus,
dialogs, and visual resources as potentially affecting simulator screenshots.

Before completing a UI-affecting change:

1. Identify the affected scenarios and representative devices in
   `BowlingStats/visual-baselines/manifest.json`.
2. Build the visual gallery with `tools/Build-VisualGallery.ps1`.
3. Ask the user to capture the affected screens into
   `BowlingStats/visual-captures/<device>/<scenario>.png` when fresh simulator
   screenshots are not already available.
4. Run `tools/Test-VisualBaselines.ps1` for the affected devices and scenarios,
   then inspect the generated shape-aware previews under
   `BowlingStats/bin/visual-previews` for clipped or near-edge content.
5. Update committed baselines with `-UpdateBaselines` only after the visual
   differences have been reviewed and confirmed as intentional.

In the final response, state which visual checks passed. If screenshots could
not be captured during the task, explicitly remind the user that visual
verification is still required before committing the UI change.

Do not commit `BowlingStats/visual-captures` or generated visual diff files.
Commit intentional changes under `BowlingStats/visual-baselines` with the UI
change that caused them.
