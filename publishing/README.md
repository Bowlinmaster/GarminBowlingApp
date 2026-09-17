# Bowling Stats Publishing Bundle

This directory contains the material used to publish Bowling Stats in the
Garmin Connect IQ Store. None of these files are included in the watch app.

## Upload Assets

- `assets/store-icon-500.png`: primary 500x500 Connect IQ Store icon.
- `assets/store-icon.svg`: editable source for the Store icon.
- `assets/hero-1440x720.png`: optional Store hero image.
- `assets/hero.svg`: editable source for the hero image.

## Listing Content

- `store-listing.md`: Store name, descriptions, release notes, and links.
- `privacy-policy.md`: public privacy policy for the app.
- `support.md`: support instructions and issue-reporting details.
- `release-checklist.md`: final validation and submission checklist.

## Public URLs

After these files are merged into `main`, use the following URLs in the Store
listing:

- Privacy policy: https://github.com/Bowlinmaster/GarminBowlingApp/blob/main/publishing/privacy-policy.md
- Support: https://github.com/Bowlinmaster/GarminBowlingApp/blob/main/publishing/support.md

Before uploading a release, regenerate any affected visual baselines according
to `AGENTS.md`, review the previews, and export a fresh signed `.iq` package
from the final commit.
