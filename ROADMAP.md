# BowlingStats Roadmap

## Completed

1. Handle game-save failures.
2. Hide unfinished Pin Entry mode.
3. Harden saved-game storage.
4. Reduce View Games memory use with lazy loading.
5. Improve active-game navigation with confirmed abandonment.
6. Document the device-support policy.
7. Create the initial compatibility matrix.
8. Add current high-priority Garmin devices.
10. Make device-support contributions straightforward.
11. Add a GitHub device-request issue template.
12. Automate local compatibility checks.
13. Establish visual regression checks:
   - Add a deterministic, development-only visual gallery.
   - Add a manifest-driven baseline and pixel-diff validator.
   - Capture and commit all nine scenarios for the nine representative devices.
14. Complete release-quality cleanup:
   - Add Monkey C container and method type annotations.
   - Eliminate compiler warnings in application and test builds.
   - Provide correctly sized launcher icons for supported devices.
   - Move visible strings into resources.
   - Expand tenth-frame and storage edge-case tests.
   - Validate application metadata and release packaging.
15. Add a saved-game summary list and detail flow.

## Remaining

9. Evaluate secondary device families.
16. Correct cross-device layout defects found in the initial visual baselines:
   - Keep potential and final scores above the scorecard's bottom border on the
     360x360, 390x390, 416x416, 454x454, and 320x360 profiles.
   - Vertically contain frame numbers and roll symbols within the scorecard
     header and roll areas, especially on the 320x360 rectangular profile.
   - Resize the saved-game detail grid rows or typography so frame numbers,
     rolls, and cumulative scores do not cross separators on the AMOLED and
     rectangular profiles.
   - Keep Saved Games titles, detail headers, and page indicators inside the
     physical and recommended content boundaries on round displays.
   - Separate the saved-game date and score columns on the 320x360 rectangular
     profile so their text cannot overlap.

## Future Features

- Add pin-specific entry using pin masks.
- Evaluate a `ByteArray` storage migration if measurements justify it.
- Separate paid and free features if a paid version is pursued.
