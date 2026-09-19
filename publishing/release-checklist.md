# Release Checklist

## Code And Validation

- [ ] Confirm the intended release commit is checked out and the worktree is clean.
- [ ] Update the version and release notes in `store-listing.md`.
- [ ] Run the Monkey C unit tests.
- [ ] Build the full compatibility package with Connect IQ SDK 9.2 or newer.
- [ ] Run the visual regression workflow for every UI-affecting change.
- [ ] Review shape-aware previews for clipping and near-edge content.
- [ ] Complete a game on a physical watch and save it successfully.
- [ ] Verify strikes, spares, tenth-frame bonus rolls, and final scoring.
- [ ] Verify saved-game list, game detail, discard, and clear-data flows.
- [ ] Verify button controls and touch controls where available.
- [ ] Confirm the launcher name and icon on the watch.

## Store Material

- [ ] Review `assets/store-icon-500.png` at full size and thumbnail size.
- [ ] Review `assets/hero-1440x720.png` if the hero image will be uploaded.
- [ ] Capture clean screenshots for the scenarios in `store-listing.md`.
- [ ] Proofread the Store description and What's New text.
- [ ] Confirm the support and privacy links are public after merging to `main`.

## Package And Submission

- [ ] Export a fresh signed `.iq` package from the final commit.
- [ ] Upload the package and resolve all Connect IQ validation messages.
- [ ] Confirm the compatible-device list matches the intended release scope.
- [ ] Fill in category, pricing, availability, and contact fields.
- [ ] Preview the unpublished listing on desktop and mobile.
- [ ] Install the uploaded preview build on a physical watch.
- [ ] Submit the application for Garmin review.
- [ ] Tag the released commit using the Store version, for example `vX.Y.Z`.
