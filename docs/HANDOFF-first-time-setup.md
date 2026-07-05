# Handoff: First Time Set Up (Initial Bag Set Up)

**Date:** 2026-07-04 · **Branch:** `main` · **Status: feature complete, all unit tests green, NOT yet committed.**
One optional loose end: a temporary end-to-end UI test is still in `HTGUITests/HTGUITests.swift` (details in "Loose ends").

## What was built

The backlog item "New Feature: First Time Set Up" (docs/backlog.md): a wizard launched from
**Profile → "First Time Set Up" section → "Initial Bag Set Up"** (bottom of the Profile list,
presented as a `fullScreenCover`).

Flow: Woods (Driver auto-selected) → Hybrids (1–9) → Irons (1–9) → Wedges (P/G/S/L) →
drag-and-drop arrange by carry distance → pre-fill known full yardages → "Estimating other
yardages" (only if blanks remain) → save → "Head to the Range to Dial In Your Yardages".

- Live `x/13` counter with Back/Next arrows at the top of every step; hard cap at 13 clubs
  (unselected rows dim when the bag is full; deselect still works).
- Next is blocked on the Wedges step if 0 clubs are selected.
- Saving **replaces** the whole bag (active + archived clubs deleted with `SyncTombstone`s,
  new clubs get a single "Full" `ShotType`, `sortOrder` = arranged order, nicknames via
  `NicknameGenerator`).
- Estimation (`BagYardageEstimator.estimate(orderedYardages:)`, longest club first):
  linear interpolation between known anchors (rounded to nearest yard), ±10 yd per club
  beyond the known range, clamped to ≥5 yd. Zero yardages entered → catalog defaults
  (`BagSetupCatalog`) are used and everything is marked "Estimated".

## Files

New (all registered in `project.pbxproj` — this project does NOT use synchronized groups;
IDs use the `BG…` prefix):

| File | Role |
|---|---|
| `HTG/Core/Services/BagYardageEstimator.swift` | pure estimation algorithm |
| `HTG/Features/BagSetup/Models/BagSetupCatalog.swift` | selectable clubs per category + default distances |
| `HTG/Features/BagSetup/ViewModels/BagSetupManager.swift` | `@Observable` wizard state machine |
| `HTG/Features/BagSetup/Views/BagSetupView.swift` | container, header (back/counter/next), step switch |
| `HTG/Features/BagSetup/Views/BagSetupSelectionStepView.swift` | category selection screens |
| `HTG/Features/BagSetup/Views/BagSetupArrangeStepView.swift` | drag-to-reorder list |
| `HTG/Features/BagSetup/Views/BagSetupYardageStepView.swift` | yardage entry |
| `HTG/Features/BagSetup/Views/BagSetupFinishStepViews.swift` | estimating + complete screens |
| `HTGTests/BagYardageEstimatorTests.swift` | 9 tests (spec examples verbatim) |
| `HTGTests/BagSetupManagerTests.swift` | 12 tests (selection, cap, navigation, save paths) |

Modified:
- `HTG/Core/Services/ClubDataService.swift` — added `replaceBag(with:)`
- `HTGTests/ClubDataServiceTests.swift` — 4 new `replaceBag` tests
- `HTG/Features/Profile/Views/ProfileView.swift` — entry section + `fullScreenCover`
- `HTG.xcodeproj/project.pbxproj` — file/group/build-phase registrations
- `HTGUITests/HTGUITests.swift` — **temporary** wizard-driving UI test (see below)

## Verification done

- TDD red→green: all new tests written first, confirmed failing, then implemented.
  Full `HTGTests` suite passes (`** TEST SUCCEEDED **`).
- End-to-end in the simulator via a temporary XCUITest that drives the real UI. It reached
  and screenshotted every step (selection with live counter, arrange, yardage typing,
  estimating with "Estimated" chips, complete screen, and the replaced bag on the Clubs tab).
- **Two real product bugs found by this and fixed:**
  1. Selection rows: the `Spacer` between the club name and checkmark wasn't hit-testable —
     taps in the middle of a row did nothing. Fixed with `.contentShape(Rectangle())` and
     the card moved inside the button label (`BagSetupSelectionStepView.optionRow`).
  2. Back/Next arrows were ~24×19 pt (below the 44 pt HIG minimum) and easy to miss.
     Fixed with 44×44 frames + `contentShape` in `BagSetupHeaderView`.
- SwiftLint: not installed on this machine — not run.

## Loose ends / how to resume

1. **UI test file.** `HTGUITests/HTGUITests.swift` currently holds the temporary
   `testInitialBagSetupFlow` (with retry helpers for XCUITest tap flakiness: launch-screen
   fade swallows early taps, taps during the cover animation miss, keyboard-focus races).
   The last hardened version has NOT had a passing full run yet — individual legs all
   passed across runs; remaining failures were test-timing flakes, not app bugs.
   Options: (a) rerun it once and keep it as a regression test, or (b) restore the original
   trivial file, which was exactly:

   ```swift
   import XCTest

   final class HTGUITests: XCTestCase {
       override func setUpWithError() throws {
           continueAfterFailure = false
       }

       @MainActor
       func testAppLaunches() throws {
           let app = XCUIApplication()
           app.launch()
       }
   }
   ```

2. **Commit.** Nothing is committed yet. Suggested: one feature commit
   (`feat: First Time Set Up bag wizard with yardage estimation`), after deciding on (1).

3. **Backlog.** `docs/backlog.md` entry "New Feature: First Time Set Up" (P3, Backlog) is
   user-curated — status not updated; flip it to Done when you're satisfied.

## Useful commands

```bash
# Unit tests ("iPhone 16 Pro" name alone fails — 'latest' OS resolves to 26.2 which has
# no 16 Pro; use the explicit 18.5 device id):
xcodebuild test -project HTG.xcodeproj -scheme HTG \
  -destination 'platform=iOS Simulator,id=77318A23-A031-4967-A674-1D2BCD4C5952' \
  -only-testing HTGTests

# The temporary end-to-end wizard test:
xcodebuild test -project HTG.xcodeproj -scheme HTG \
  -destination 'platform=iOS Simulator,id=77318A23-A031-4967-A674-1D2BCD4C5952' \
  -only-testing:HTGUITests/HTGUITests/testInitialBagSetupFlow
```

## Design decisions (for review)

- Replace-not-merge on save: "initial" setup rebuilds the bag; existing default-seeded clubs
  are tombstoned so sync deletes them remotely. `ContentView`'s `loadDefaultClubsIfNeeded()`
  only seeds an empty bag, so it doesn't fight the wizard.
- Driver is pre-selected but deselectable.
- Re-entering the arrange step keeps the user's manual order for still-selected clubs and
  appends newly selected clubs in catalog order (`BagSetupManager.rebuildArrangement`).
- Catalog default distances: existing `loadDefaultClubs()` values, extended to cover 2–9
  woods, 1–9 hybrids, 1–4 irons (10 yd ladder for irons, interpolated for woods/hybrids).
- Accessibility identifiers added: `bagSetupBackButton`, `bagSetupNextButton`,
  `yardageInput-<Club Name>`.
