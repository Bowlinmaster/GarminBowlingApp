# Bowling Stats Roadmap

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
16. Add bowling statistics:
   - Define per-game first-ball average, strike rate, spare-conversion rate,
     open frames, clean frames, and final-score metrics.
   - Maintain compact lifetime aggregates without enlarging individual saved
     game records or rescanning game history during normal use.
   - Group games completed within the same two-hour session into series and
     track series count, average series, high series, and average games per
     series.
   - Add aggregate and per-game statistics pages to the saved-games flow.
   - Version and migrate existing stored games.

## Remaining

9. Evaluate secondary device families.
17. Implement Pin Entry mode:
   - Represent standing and knocked-down pins with ten-bit masks while keeping
     the scoring engine independent of the entry method.
   - Add a pin-deck entry screen where touch users can toggle the pins left
     standing after each roll.
   - Provide an ergonomic button-only interaction for supported devices that do
     not have touchscreens.
   - Validate legal pin transitions, derive the roll score from the masks, and
     show the same score preview and confirmation feedback as Simple Entry.
   - Extend saved-game encoding and migrations to retain pin-level history only
     for games that use it.
18. Expand support to additional compatible Garmin devices:
   - Inventory Connect IQ watch-app products and exclude devices whose screen,
     input, API level, or memory limits cannot provide a usable experience.
   - Add explicit layout profiles and resource overrides where needed.
   - Require successful packaging, input checks, and representative visual
     baselines before adding each product to the manifest.
   - Track physical-device confirmation separately and use GitHub issues for
     support requests when hardware is unavailable locally.

## Future Features

- Evaluate a `ByteArray` storage migration if measurements justify it.
- Investigate compile-time device-specific layouts using resource qualifiers and
  Jungle-selected source profiles. Compare executable size, runtime heap, and
  graphics-pool usage with the current runtime profile system while retaining
  primitive drawing for dynamic scorecards where it remains more efficient.
- Separate paid and free features if a paid version is pursued.
