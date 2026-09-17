# Repository Instructions

## Visual Regression Checks

Treat changes to views, drawing code, layout profiles, fonts, strings, menus,
dialogs, and visual resources as potentially affecting simulator screenshots.

Before completing a UI-affecting change:

1. Identify the affected scenarios and representative devices in
   `BowlingStats/visual-baselines/manifest.json`.
2. Run `tools/Capture-VisualGallery.ps1` for those devices and scenarios. This
   builds the gallery, captures display-only PNGs, validates their dimensions,
   and runs the baseline comparison. Use manual simulator captures only when
   the automation cannot complete on the current host.
3. Inspect the generated diffs and shape-aware previews under
   `BowlingStats/bin/visual-previews` for clipped or near-edge content.
4. Update committed baselines with `-UpdateBaselines` only after the visual
   differences have been reviewed and confirmed as intentional.

In the final response, state which visual checks passed. If automated and
manual screenshots could not be captured during the task, explicitly remind
the user that visual verification is still required before committing the UI
change.

Do not commit `BowlingStats/visual-captures` or generated visual diff files.
Commit intentional changes under `BowlingStats/visual-baselines` with the UI
change that caused them.
