# Device Support

Bowling Stats uses explicit device profiles because watches with similar dimensions can still differ in usable screen area, fonts, input controls, and button hints. This document defines what the project means by device support and tracks the current compatibility baseline.

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

- SDK: Connect IQ 9.2.0
- Checked: 2026-09-25
- Result: full release package passed all 120 SDK-expanded builds for the 81 manifest product IDs
- Visual baselines checked: 2026-09-14
- Visual baseline result: all nine scenarios captured for all nine representative screen families
- Expansion regression check: `new-game` and `tenth-frame` remained pixel-identical on the 390x390, 416x416, and 454x454 representatives on 2026-09-25
- MIP expansion check: `new-game`, `tenth-frame`, and `game-detail` passed shape-aware review on new 218x218, 240x240, 260x260, and 280x280 touch/button representatives on 2026-09-25

## Compatibility Matrix

Every row below passed the current release package build. `Visual baseline` means the product's deterministic gallery scenarios were captured and committed. `Pending` means that simulator screenshots or input behavior still need explicit review before the product is promoted to officially supported.

| Product ID | Garmin device family | Part number(s) | Screen | Display | Input | Layout profile | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `approachs50` | Approach S50 | `006-B4656-00` | 390x390 round | AMOLED | Touch + buttons | `approachS50()` | Build verified; visual pending |
| `approachs7042mm` | Approach S70 42mm | `006-B4233-00` | 390x390 round | AMOLED | Touch + buttons | `approachS7042mm()` | Build verified; visual pending |
| `approachs7047mm` | Approach S70 47mm | `006-B4234-00` | 454x454 round | AMOLED | Touch + buttons | `approachS7047mm()` | Build verified; visual pending |
| `d2air` | D2 Air | `006-B2187-00` | 390x390 round | AMOLED | Touch + buttons | `d2Air()` | Build verified; visual pending |
| `d2airx10` | D2 Air X10 | `006-B4125-00` | 416x416 round | AMOLED | Touch + buttons | `d2AirX10()` | Build verified; visual pending |
| `d2mach1` | D2 Mach 1 | `006-B4079-00` | 416x416 round | AMOLED | Touch + buttons | `d2Mach1()` | Build verified; visual pending |
| `d2mach2` | D2 Mach 2 | `006-B4879-00` | 454x454 round | AMOLED | Touch + buttons | `d2Mach2()` | Build verified; visual pending |
| `d2mach2pro` | D2 Mach 2 Pro | `006-B5056-00` | 454x454 round | AMOLED | Touch + buttons | `d2Mach2Pro()` | Build verified; visual pending |
| `descentg2` | Descent G2 | `006-B4588-00` | 390x390 round | AMOLED | Touch + buttons | `descentG2()` | Build verified; visual pending |
| `descentmk2` | Descent Mk2 / Mk2i | `006-B3258-00`, `006-B3702-00` | 280x280 round | MIP | Buttons | `descentMk2()` | Build verified; visual pending |
| `descentmk2s` | Descent Mk2S | `006-B3542-00`, `006-B3930-00` | 240x240 round | MIP | Buttons | `descentMk2S()` | Build verified; visual pending |
| `descentmk343mm` | Descent Mk3 / Mk3i 43mm | `006-B4222-00` | 390x390 round | AMOLED | Touch + buttons | `descentMk343mm()` | Build verified; visual pending |
| `descentmk351mm` | Descent Mk3i 51mm | `006-B4223-00` | 454x454 round | AMOLED | Touch + buttons | `descentMk351mm()` | Build verified; visual pending |
| `enduro3` | Enduro 3 | `006-B4575-00` | 280x280 round | MIP | Touch + buttons | `enduro3()` | Build verified; visual pending |
| `epix2` | epix (Gen 2) / quatix 7 Sapphire | `006-B3943-00`, `006-B3944-00` | 416x416 round | AMOLED | Touch + buttons | `epix2()` | Build verified; visual pending |
| `epix2pro42mm` | epix Pro (Gen 2) 42mm | `006-B4312-00` | 390x390 round | AMOLED | Touch + buttons | `epix2Pro42mm()` | Build verified; visual pending |
| `epix2pro47mm` | epix Pro (Gen 2) 47mm / quatix 7 Pro | `006-B4313-00` | 416x416 round | AMOLED | Touch + buttons | `epix2Pro47mm()` | Build verified; visual pending |
| `epix2pro51mm` | epix Pro (Gen 2) 51mm / D2 Mach 1 Pro / tactix 7 AMOLED | `006-B4314-00`, `006-B4542-00`, `006-B4556-00` | 454x454 round | AMOLED | Touch + buttons | `epix2Pro51mm()` | Build verified; visual pending |
| `fenix6pro` | fenix 6 Pro / Sapphire / Solar / quatix 6 | `006-B3290-00`, `006-B3515-00`, `006-B3782-00`, `006-B3767-00`, `006-B3771-00` | 260x260 round | MIP | Buttons | `fenix6Pro()` | Build verified; visual pending |
| `fenix6spro` | fenix 6S Pro / Sapphire / Solar | `006-B3288-00`, `006-B3513-00`, `006-B3765-00`, `006-B3769-00` | 240x240 round | MIP | Buttons | `fenix6SPro()` | Build verified; visual pending |
| `fenix6xpro` | fenix 6X Pro / Sapphire / Solar / tactix Delta / quatix 6X | `006-B3291-00`, `006-B3516-00`, `006-B3783-00` | 280x280 round | MIP | Buttons | `fenix6XPro()` | Build verified; visual pending |
| `fenix7` | fenix 7 / quatix 7 | `006-B3906-00`, `006-B3909-00` | 260x260 round | MIP | Touch + buttons | `fenix7()` | Build verified; visual baseline |
| `fenix7pro` | fenix 7 Pro | `006-B4375-00` | 260x260 round | MIP | Touch + buttons | `fenix7Pro()` | Build verified; visual pending |
| `fenix7pronowifi` | fenix 7 Pro Solar, no Wi-Fi | `006-B4595-00` | 260x260 round | MIP | Touch + buttons | `fenix7ProNoWifi()` | Build verified; visual pending |
| `fenix7s` | fenix 7S | `006-B3905-00`, `006-B3908-00` | 240x240 round | MIP | Touch + buttons | `fenix7s()` | Build verified; visual baseline |
| `fenix7spro` | fenix 7S Pro | `006-B4374-00` | 240x240 round | MIP | Touch + buttons | `fenix7sPro()` | Build verified; visual pending |
| `fenix7x` | fenix 7X / tactix 7 / quatix 7X Solar / Enduro 2 | `006-B3907-00`, `006-B3910-00`, `006-B4135-00`, `006-B4341-00` | 280x280 round | MIP | Touch + buttons | `fenix7x()` | Official; simulator baseline and physical use reported |
| `fenix7xpro` | fenix 7X Pro | `006-B4376-00` | 280x280 round | MIP | Touch + buttons | `fenix7xPro()` | Build verified; visual pending |
| `fenix7xpronowifi` | fenix 7X Pro Solar, no Wi-Fi | `006-B4596-00` | 280x280 round | MIP | Touch + buttons | `fenix7xProNoWifi()` | Build verified; visual pending |
| `fenix843mm` | fenix 8 43mm | `006-B4534-00` | 416x416 round | AMOLED | Touch + buttons | `fenix843mm()` | Build verified; visual pending |
| `fenix847mm` | fenix 8 / tactix 8 / quatix 8, 47mm and 51mm AMOLED | `006-B4536-00`, `006-B4775-00` | 454x454 round | AMOLED | Touch + buttons | `fenix847mm()` | Build verified; visual pending |
| `fenix8pro47mm` | fenix 8 Pro / quatix 8 Pro 47mm and 51mm | `006-B4631-00` | 454x454 round | AMOLED | Touch + buttons | `fenix8Pro47mm()` | Build verified; visual pending |
| `fenix8solar47mm` | fenix 8 Solar 47mm | `006-B4532-00` | 260x260 round | MIP | Touch + buttons | `fenix8Solar47mm()` | Build verified; visual pending |
| `fenix8solar51mm` | fenix 8 / tactix 8 Solar 51mm | `006-B4533-00`, `006-B4776-00` | 280x280 round | MIP | Touch + buttons | `fenix8Solar51mm()` | Build verified; visual pending |
| `fenix943mm` | fenix 9 43mm | `006-B5133-00` | 416x416 round | AMOLED | Touch + buttons | `fenix943mm()` | Build verified; visual pending |
| `fenix947mm` | fenix 9 47mm / 51mm | `006-B5134-00` | 454x454 round | AMOLED | Touch + buttons | `fenix947mm()` | Build verified; visual pending |
| `fenix9pro43mm` | fenix 9 Pro 43mm | `006-B4952-00` | 416x416 round | AMOLED | Touch + buttons | `fenix9Pro43mm()` | Build verified; visual pending |
| `fenix9pro47mm` | fenix 9 Pro 47mm | `006-B4953-00` | 454x454 round | AMOLED | Touch + buttons | `fenix9Pro47mm()` | Build verified; visual pending |
| `fenix9prosolar47mm` | fenix 9 Pro Solar 47mm | `006-B4955-00` | 260x260 round | MIP | Touch + buttons | `fenix9ProSolar47mm()` | Build verified; visual pending |
| `fenix9prosolar51mm` | fenix 9 Pro Solar 51mm | `006-B4956-00` | 280x280 round | MIP | Touch + buttons | `fenix9ProSolar51mm()` | Build verified; visual pending |
| `fenixe` | fenix E | `006-B4666-00` | 416x416 round | AMOLED | Touch + buttons | `fenixE()` | Build verified; visual pending |
| `fr165` | Forerunner 165 | `006-B4432-00` | 390x390 round | AMOLED | Touch + buttons | `fr165()` | Build verified; visual pending |
| `fr165m` | Forerunner 165 Music | `006-B4433-00` | 390x390 round | AMOLED | Touch + buttons | `fr165Music()` | Build verified; visual pending |
| `fr170` | Forerunner 170 | `006-B4815-00` | 390x390 round | AMOLED | Touch + buttons | `fr170()` | Build verified; visual pending |
| `fr170m` | Forerunner 170 Music | `006-B4814-00` | 390x390 round | AMOLED | Touch + buttons | `fr170Music()` | Build verified; visual pending |
| `fr245m` | Forerunner 245 Music | `006-B3077-00`, `006-B3321-00`, `006-B3913-00` | 240x240 round | MIP | Buttons | `fr245Music()` | Build verified; visual pending |
| `fr255` | Forerunner 255 | `006-B3992-00` | 260x260 round | MIP | Buttons | `fr255()` | Build verified; visual pending |
| `fr255m` | Forerunner 255 Music | `006-B3990-00` | 260x260 round | MIP | Buttons | `fr255Music()` | Build verified; visual pending |
| `fr255s` | Forerunner 255S | `006-B3993-00` | 218x218 round | MIP | Buttons | `fr255s()` | Build verified; visual baseline |
| `fr255sm` | Forerunner 255S Music | `006-B3991-00` | 218x218 round | MIP | Buttons | `fr255sMusic()` | Build verified; visual pending |
| `fr265` | Forerunner 265 | `006-B4257-00` | 416x416 round | AMOLED | Touch + buttons | `fr265()` | Build verified; visual baseline |
| `fr265s` | Forerunner 265S | `006-B4258-00` | 360x360 round | AMOLED | Touch + buttons | `fr265s()` | Build verified; visual baseline |
| `fr57042mm` | Forerunner 570 42mm | `006-B4574-00` | 390x390 round | AMOLED | Touch + buttons | `fr57042mm()` | Build verified; visual pending |
| `fr57047mm` | Forerunner 570 47mm | `006-B4570-00` | 454x454 round | AMOLED | Touch + buttons | `fr57047mm()` | Build verified; visual pending |
| `fr70` | Forerunner 70 | `006-B4916-00`, `006-B5214-00` | 390x390 round | AMOLED | Touch + buttons | `fr70()` | Build verified; visual pending |
| `fr745` | Forerunner 745 | `006-B3589-00`, `006-B3794-00` | 240x240 round | MIP | Buttons | `fr745()` | Build verified; visual pending |
| `fr945` | Forerunner 945 | `006-B3113-00`, `006-B3441-00` | 240x240 round | MIP | Buttons | `fr945()` | Build verified; visual pending |
| `fr945lte` | Forerunner 945 LTE | `006-B3652-00` | 240x240 round | MIP | Buttons | `fr945Lte()` | Build verified; visual pending |
| `fr955` | Forerunner 955 / Solar | `006-B4024-00` | 260x260 round | MIP | Touch + buttons | `fr955()` | Build verified; visual pending |
| `fr965` | Forerunner 965 | `006-B4315-00` | 454x454 round | AMOLED | Touch + buttons | `fr965()` | Build verified; visual pending |
| `fr970` | Forerunner 970 | `006-B4565-00` | 454x454 round | AMOLED | Touch + buttons | `fr970()` | Build verified; visual baseline |
| `instinct3amoled45mm` | Instinct 3 AMOLED 45mm | `006-B4586-00` | 390x390 round | AMOLED | Buttons | `instinct3Amoled45mm()` | Build verified; visual pending |
| `instinct3amoled50mm` | Instinct 3 AMOLED 50mm | `006-B4587-00` | 416x416 round | AMOLED | Buttons | `instinct3Amoled50mm()` | Build verified; visual pending |
| `instinctcrossoveramoled` | Instinct Crossover AMOLED | `006-B4678-00` | 390x390 round | AMOLED | Buttons | `instinctCrossoverAmoled()` | Build verified; visual pending |
| `marq2` | MARQ (Gen 2) | `006-B4105-00`, `006-B4472-00` | 390x390 round | AMOLED | Touch + buttons | `marq2()` | Build verified; visual pending |
| `marq2aviator` | MARQ (Gen 2) Aviator | `006-B4124-00` | 390x390 round | AMOLED | Touch + buttons | `marq2Aviator()` | Build verified; visual pending |
| `venu` | Venu | `006-B3226-00`, `006-B3389-00` | 390x390 round | AMOLED | Touch + buttons | `venu()` | Build verified; visual pending |
| `venu2` | Venu 2 | `006-B3703-00`, `006-B3950-00`, `006-B4171-00`, `006-B4180-00` | 416x416 round | AMOLED | Touch + buttons | `venu2()` | Build verified; visual pending |
| `venu2plus` | Venu 2 Plus | `006-B3851-00`, `006-B4017-00` | 416x416 round | AMOLED | Touch + buttons | `venu2Plus()` | Build verified; visual pending |
| `venu2s` | Venu 2S | `006-B3704-00`, `006-B3949-00`, `006-B4175-00`, `006-B4181-00` | 360x360 round | AMOLED | Touch + buttons | `venu2s()` | Build verified; visual pending |
| `venu3` | Venu 3 | `006-B4260-00` | 454x454 round | AMOLED | Touch + buttons | `venu3()` | Build verified; visual pending |
| `venu3s` | Venu 3S | `006-B4261-00` | 390x390 round | AMOLED | Touch + buttons | `venu3s()` | Build verified; visual pending |
| `venu441mm` | Venu 4 41mm | `006-B4644-00` | 390x390 round | AMOLED | Touch + buttons | `venu441mm()` | Build verified; visual pending |
| `venu445mm` | Venu 4 45mm / D2 Air X15 | `006-B4643-00`, `006-B4944-00` | 454x454 round | AMOLED | Touch + buttons | `venu445mm()` | Build verified; visual pending |
| `venud` | Venu Mercedes-Benz Collection | `006-B3740-00`, `006-B3737-00` | 390x390 round | AMOLED | Touch + buttons | `venuMercedesBenz()` | Build verified; visual pending |
| `venusq2` | Venu Sq 2 | `006-B4115-00` | 320x360 rectangular | AMOLED | Touch + buttons | `venuSq2()` | Build verified; visual baseline |
| `venusq2m` | Venu Sq 2 Music | `006-B4116-00` | 320x360 rectangular | AMOLED | Touch + buttons | `venuSq2Music()` | Build verified; visual pending |
| `vivoactive4` | vivoactive 4 | `006-B3225-00`, `006-B3388-00` | 260x260 round | MIP | Touch + buttons | `vivoactive4()` | Build verified; visual pending |
| `vivoactive4s` | vivoactive 4S | `006-B3224-00`, `006-B3387-00` | 218x218 round | MIP | Touch + buttons | `vivoactive4S()` | Build verified; visual pending |
| `vivoactive5` | vivoactive 5 | `006-B4426-00` | 390x390 round | AMOLED | Touch + buttons | `vivoactive5()` | Build verified; visual pending |
| `vivoactive6` | vivoactive 6 | `006-B4625-00` | 390x390 round | AMOLED | Touch + buttons | `vivoactive6()` | Build verified; visual baseline |

## Known Exclusions

- `approachs62`: Production builds succeed, but the device rejects the app's
  native `Menu2` initial view at runtime with `Native base view is not
  supported`. Keep it out of the manifest unless its navigation is replaced
  with a compatible custom view and the complete flow is retested.

## Representative Visual Matrix

Visual reviews should cover at least one product from every row before a release. A shared profile may be promoted only after its representative passes; exact products can still receive overrides when their rendering differs.

| Screen family | Initial representative | Status |
| --- | --- | --- |
| 218x218 round MIP, buttons | `fr255s` | Verified baseline (9 scenarios) |
| 240x240 round MIP | `fenix7s` | Verified baseline (9 scenarios) |
| 260x260 round MIP | `fenix7` | Verified baseline (9 scenarios) |
| 280x280 round MIP | `fenix7x` | Verified baseline (9 scenarios) |
| 360x360 round AMOLED | `fr265s` | Verified baseline (9 scenarios) |
| 390x390 round AMOLED | `vivoactive6` | Verified baseline (9 scenarios) |
| 416x416 round AMOLED | `fr265` | Verified baseline (9 scenarios) |
| 454x454 round AMOLED | `fr970` | Verified baseline (9 scenarios) |
| 320x360 rectangular AMOLED | `venusq2` | Verified baseline (9 scenarios) |

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

Start by generating the candidate inventory from the active SDK:

```powershell
.\tools\Get-DeviceCandidates.ps1
```

The generated report is advisory. Devices in an existing visual family may use
that profile as their initial values, but every added product still requires an
explicit part-number mapping and named profile so it can be tuned independently.

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
