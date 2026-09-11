# Device Support

BowlingStats uses explicit device profiles because watches with similar dimensions can still differ in usable screen area, fonts, input controls, and button hints. This document defines what the project means by device support and tracks the current compatibility baseline.

## Support Levels

### Officially supported

A product is officially supported when all of the following are true:

- Its product ID is included in `manifest.xml`.
- Every SDK part number maps to an explicit profile in `BowlingEntryLayoutProfiles.forPartNumber()`.
- A release package builds successfully with the project's supported Connect IQ SDK.
- The main menu, Simple Entry, tenth frame, game completion, saved-game view, and settings flow have been checked in the simulator.
- Text, scorecard lines, selector values, and button hints do not clip or overlap.
- Button input works, and touch input is checked when the device supports it.
- There are no known device-specific crashes or blocking defects.

Physical-watch verification is strongly preferred but is not required when the simulator accurately represents the device. The matrix records physical checks separately.

### Build verified

The product is in the manifest, has an explicit part-number profile, and compiles in the full release package. It is still a candidate until its visual and input checks are complete.

### Fallback only

An unknown product may receive a screen-size fallback profile. A fallback rendering is not considered supported and should not be added to the manifest without completing the support checklist.

## Current Build Baseline

- SDK: Connect IQ 9.1.0
- Checked: 2026-09-11
- Result: full release package passed all 45 SDK-expanded builds for the 31 manifest product IDs
- Visual baseline: `fenix7x`

## Compatibility Matrix

Every row below passed the current release package build. `Pending` means that simulator screenshots and input behavior still need explicit review before the product is promoted to officially supported.

| Product ID | Garmin device family | Part number(s) | Screen | Display | Input | Layout profile | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `enduro3` | Enduro 3 | `006-B4575-00` | 280x280 round | MIP | Touch + buttons | `enduro3()` | Build verified; visual pending |
| `fenix7` | fenix 7 / quatix 7 | `006-B3906-00`, `006-B3909-00` | 260x260 round | MIP | Touch + buttons | `fenix7()` | Build verified; visual pending |
| `fenix7pro` | fenix 7 Pro | `006-B4375-00` | 260x260 round | MIP | Touch + buttons | `fenix7Pro()` | Build verified; visual pending |
| `fenix7pronowifi` | fenix 7 Pro Solar, no Wi-Fi | `006-B4595-00` | 260x260 round | MIP | Touch + buttons | `fenix7ProNoWifi()` | Build verified; visual pending |
| `fenix7s` | fenix 7S | `006-B3905-00`, `006-B3908-00` | 240x240 round | MIP | Touch + buttons | `fenix7s()` | Build verified; visual pending |
| `fenix7spro` | fenix 7S Pro | `006-B4374-00` | 240x240 round | MIP | Touch + buttons | `fenix7sPro()` | Build verified; visual pending |
| `fenix7x` | fenix 7X / tactix 7 / quatix 7X Solar / Enduro 2 | `006-B3907-00`, `006-B3910-00`, `006-B4135-00`, `006-B4341-00` | 280x280 round | MIP | Touch + buttons | `fenix7x()` | Official; simulator baseline and physical use reported |
| `fenix7xpro` | fenix 7X Pro | `006-B4376-00` | 280x280 round | MIP | Touch + buttons | `fenix7xPro()` | Build verified; visual pending |
| `fenix7xpronowifi` | fenix 7X Pro Solar, no Wi-Fi | `006-B4596-00` | 280x280 round | MIP | Touch + buttons | `fenix7xProNoWifi()` | Build verified; visual pending |
| `fenix843mm` | fenix 8 43mm | `006-B4534-00` | 416x416 round | AMOLED | Touch + buttons | `fenix843mm()` | Build verified; visual pending |
| `fenix847mm` | fenix 8 / tactix 8 / quatix 8, 47mm and 51mm AMOLED | `006-B4536-00`, `006-B4775-00` | 454x454 round | AMOLED | Touch + buttons | `fenix847mm()` | Build verified; visual pending |
| `fenix8solar47mm` | fenix 8 Solar 47mm | `006-B4532-00` | 260x260 round | MIP | Touch + buttons | `fenix8Solar47mm()` | Build verified; visual pending |
| `fenix8solar51mm` | fenix 8 / tactix 8 Solar 51mm | `006-B4533-00`, `006-B4776-00` | 280x280 round | MIP | Touch + buttons | `fenix8Solar51mm()` | Build verified; visual pending |
| `fr165` | Forerunner 165 | `006-B4432-00` | 390x390 round | AMOLED | Touch + buttons | `fr165()` | Build verified; visual pending |
| `fr165m` | Forerunner 165 Music | `006-B4433-00` | 390x390 round | AMOLED | Touch + buttons | `fr165Music()` | Build verified; visual pending |
| `fr255` | Forerunner 255 | `006-B3992-00` | 260x260 round | MIP | Buttons | `fr255()` | Build verified; visual pending |
| `fr255m` | Forerunner 255 Music | `006-B3990-00` | 260x260 round | MIP | Buttons | `fr255Music()` | Build verified; visual pending |
| `fr255s` | Forerunner 255S | `006-B3993-00` | 218x218 round | MIP | Buttons | `fr255s()` | Build verified; visual pending |
| `fr255sm` | Forerunner 255S Music | `006-B3991-00` | 218x218 round | MIP | Buttons | `fr255sMusic()` | Build verified; visual pending |
| `fr265` | Forerunner 265 | `006-B4257-00` | 416x416 round | AMOLED | Touch + buttons | `fr265()` | Build verified; visual pending |
| `fr265s` | Forerunner 265S | `006-B4258-00` | 360x360 round | AMOLED | Touch + buttons | `fr265s()` | Build verified; visual pending |
| `fr955` | Forerunner 955 / Solar | `006-B4024-00` | 260x260 round | MIP | Touch + buttons | `fr955()` | Build verified; visual pending |
| `fr965` | Forerunner 965 | `006-B4315-00` | 454x454 round | AMOLED | Touch + buttons | `fr965()` | Build verified; visual pending |
| `venu2` | Venu 2 | `006-B3703-00`, `006-B3950-00`, `006-B4171-00`, `006-B4180-00` | 416x416 round | AMOLED | Touch + buttons | `venu2()` | Build verified; visual pending |
| `venu2plus` | Venu 2 Plus | `006-B3851-00`, `006-B4017-00` | 416x416 round | AMOLED | Touch + buttons | `venu2Plus()` | Build verified; visual pending |
| `venu2s` | Venu 2S | `006-B3704-00`, `006-B3949-00`, `006-B4175-00`, `006-B4181-00` | 360x360 round | AMOLED | Touch + buttons | `venu2s()` | Build verified; visual pending |
| `venu3` | Venu 3 | `006-B4260-00` | 454x454 round | AMOLED | Touch + buttons | `venu3()` | Build verified; visual pending |
| `venu3s` | Venu 3S | `006-B4261-00` | 390x390 round | AMOLED | Touch + buttons | `venu3s()` | Build verified; visual pending |
| `venusq2` | Venu Sq 2 | `006-B4115-00` | 320x360 rectangular | AMOLED | Touch + buttons | `venuSq2()` | Build verified; visual pending |
| `venusq2m` | Venu Sq 2 Music | `006-B4116-00` | 320x360 rectangular | AMOLED | Touch + buttons | `venuSq2Music()` | Build verified; visual pending |
| `vivoactive5` | vivoactive 5 | `006-B4426-00` | 390x390 round | AMOLED | Touch + buttons | `vivoactive5()` | Build verified; visual pending |

## Representative Visual Matrix

Visual reviews should cover at least one product from every row before a release. A shared profile may be promoted only after its representative passes; exact products can still receive overrides when their rendering differs.

| Screen family | Initial representative | Status |
| --- | --- | --- |
| 218x218 round MIP, buttons | `fr255s` | Pending |
| 240x240 round MIP | `fenix7s` | Pending |
| 260x260 round MIP | `fenix7` | Pending |
| 280x280 round MIP | `fenix7x` | Verified baseline |
| 360x360 round AMOLED | `fr265s` | Pending |
| 390x390 round AMOLED | `vivoactive5` | Pending |
| 416x416 round AMOLED | `fr265` | Pending |
| 454x454 round AMOLED | `fr965` | Pending |
| 320x360 rectangular AMOLED | `venusq2` | Pending |

## Validation Checklist

For each representative device:

1. Build the app and launch it in the simulator.
2. Confirm the main menu and settings menu are readable and navigable.
3. Enter an open frame, spare, and strike.
4. Verify scorecard alignment in frames 1-9 and all three tenth-frame roll states.
5. Verify the selector, potential score, confirmation checkmark, and finish/error text do not overlap.
6. Complete and save a game, then inspect it in View Games.
7. Navigate with buttons. Also test taps and swipes on touch-capable devices.
8. Capture screenshots of normal entry, tenth-frame entry, completion, and saved-game detail.
9. Record simulator and physical-watch results in the compatibility matrix.

## Adding A Device

A device-support pull request should include:

- Exact Garmin model and size.
- Connect IQ product ID and all SDK part numbers.
- Resolution, shape, display technology, and supported input methods.
- The `manifest.xml` product entry.
- An explicit part-number mapping and layout profile.
- A successful release build using the supported SDK.
- Simulator screenshots for the states in the validation checklist.
- Physical-watch confirmation when available.
- An update to this compatibility matrix.

Keep device detection inside `BowlingEntryLayoutProfiles`. Do not add product checks to `SimpleEntryView` or other drawing code.
