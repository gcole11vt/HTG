# Decide the Shot — Variant A Redesign

Re-skin of `GolfModeView` to match the "Decide the Shot — Variant A" wireframe from the Claude Design handoff bundle (`htg-golf-mode/project/handoff/`). Structural skeleton (two-column layout, section order, `GolfModeViewModel` data flow) is preserved; visual treatment and the carry ladder representation change.

## Scope

In-scope views (under `HTG/UIComponents/GolfMode/`):
- `YardageBookPageView` — re-layout + title treatment
- `YardageDisplayView` — add −/+ stepper beside the big number
- `ShotInfoHeaderView` → replaced by new `RecommendedShotCard`
- `PreShotRoutineView` — dashed-circle numerals + eyebrow header
- `MantraView` — serif italic + accent left-bar + tinted bg
- `SwingThoughtsView` — accent-color bullets + eyebrow header
- `YardageLadderView` — rebuilt as a bordered-card rung list

Out of scope:
- Data model changes (no changes to `LadderEntry`, `GroupedLadderEntry`, `GolfModeViewModel`)
- Tab bar (already matches intent)
- Adding Fraunces font to the bundle — use `.system(.serif)` as substitute
- Pre-shot routine / mantra / swing thoughts editors (wireframe is read-only here)

## Interaction requirements (non-negotiable)

Tapping a yardage or club rung in the carry ladder MUST continue to drive:
1. `viewModel.selectClubShot(clubName:shotTypeName:distance:)` — same as today
2. Update of the Recommended card (club, carry, shot-type chips) — reacts to `displayedClubShot`
3. Update of the yardage display — reacts to `targetYardage`
4. Update of matching swing thoughts — reacts to `matchingSwingThoughts`
5. Reset indicator appears when user selection differs from recommendation

The existing ViewModel already implements this; keep the callback wiring.

## Section treatments

### Title
- Text: "Decide the Shot!"
- Font: `.system(size: 26, weight: .semibold, design: .serif)`
- Color: `GTCColor.primary`
- Letter spacing: -0.4

### Section headers (eyebrow, reusable)
Introduce a shared `SectionEyebrow` style used by Yardage, Recommended, Pre-Shot Routine, Mantra, Swing Thoughts.
- Font: `.system(size: 12, weight: .semibold)`
- Color: `GTCColor.secondary`
- Uppercase, tracking ≈ 0.6
- Bottom padding: 6pt

### 1. Yardage
- Large number: `.system(size: 72, weight: .heavy, design: .serif)`, `GTCColor.primary`, letterSpacing -2
- "yds" label beside it: 14pt `GTCColor.secondary`
- `−` / `+` buttons on the trailing edge:
  - 32×32 rounded rect (8pt radius), 1pt border `GTCColor.border`, white fill, primary glyph
  - 44pt hit target (use `.contentShape`)
  - Step size: 1 yard
  - Min: 50, Max: 400 (clamp in ViewModel — use existing `setTargetYardage`)
- Big number remains tappable → existing keypad sheet

### 2. Recommended shot card (new `RecommendedShotCard`)
Replaces `ShotInfoHeaderView`. Only renders when `displayedClubShot != nil`.
- Outer: 1.5pt `GTCColor.primary` border, 14pt corner radius, 10pt vertical × 12pt horizontal padding
- Background: `GTCColor.secondary.opacity(0.08)`
- Row 1 (between): dashed "recommended" pill (see Tag) · right-aligned caption "based on {targetYardage} yd" (11pt secondary)
- Row 2: club name `system(.serif) size 28 weight 600 primary` + carry `system(.serif) size 18 text` — baseline-aligned
- Row 3: shot-type chips — one chip per shot-type name in `viewModel.shotTypeNamesInBag` up to 3, with the displayed shot type styled accent, others secondary
- Entire card tappable → opens `ClubSelectorSheetView` (preserve existing behavior)

Tag pill:
- 11pt font, 1pt dashed border in the color passed in, `GTCColor.background` fill, 2pt×8pt padding, 999 corner radius

### 3. Pre-Shot Routine (`PreShotRoutineView`)
- Eyebrow "PRE-SHOT ROUTINE"
- Each row: 18×18 circle with 1pt dashed `GTCColor.border` stroke, numeral (11pt secondary) centered; 8pt gap; step label (14pt `GTCColor.text`)
- Row spacing: 4pt
- Reads `routineItems` (already sorted)

### 4. Mantra (`MantraView`)
- Eyebrow "MANTRA"
- Quote rendered as `"{text}"` — 18pt `.serif` italic, `GTCColor.primary`
- 2pt leading border in `GTCColor.accent`
- Background: `GTCColor.accent.opacity(0.04)`
- Padding: 6pt vertical × 10pt horizontal, corner radius `0,8,8,0` (leading square / trailing rounded)

### 5. Swing Thoughts (`SwingThoughtsView`)
- Eyebrow "SWING THOUGHTS"
- Each row: `•` in `GTCColor.accent` + text 13pt `GTCColor.text`
- Row spacing: 3pt
- Reads `matchingSwingThoughts`

### 6. Carry Ladder (rebuilt `YardageLadderView`)
**Structure change:** from positioned vertical chart to a bordered-card rung list.

Container:
- `GTCColor.surface` fill, 1pt `GTCColor.border`, 14pt corner radius, padding `8,4,8,8` (top, leading, bottom, trailing)
- Right-aligned "carry ladder" caption (11pt secondary) at the top inside

Rows (one per `GroupedLadderEntry`, sorted by `carryDistance` descending):
- Min height 22pt
- Bottom border 1pt `GTCColor.border` when distance is a "major rung" (divisible by 10 and within the primary band 130–180)
- Layout (HStack trailing-aligned):
  - Club pills stack (VStack, trailing alignment, 2pt gap): one per `LadderEntry` in the group
    - Each pill: 6pt dot + club label (e.g. "8I", "7I Hard")
    - Selected or recommended: dot + text colored `GTCColor.swipe`, pill bg `GTCColor.swipe.opacity(0.12)`, 1×7pt padding, 999 radius
    - Default: dot `GTCColor.secondary`, text `GTCColor.text`, no pill background
  - Yardage number: 28pt wide right-aligned label, 11pt, `GTCColor.primary` & weight 700 if `targetYardage == carryDistance`; weight 500 if major; else 400
  - Tick: 10×1pt line, color `GTCColor.primary` if target row, else `GTCColor.text` if major, else `GTCColor.border`

Interactions:
- Each club pill is its own tap target → `onSelectEntry(LadderEntry)` → existing `viewModel.selectClubShot(...)`
- No swipe, no scroll linking beyond natural list scroll

Rendering:
- Use `ScrollView` + `LazyVStack`; ladder may exceed viewport on small devices.

## Two-column layout

- `HStack(alignment: .top, spacing: 10)` inside a 20pt-horizontal padded scroll view
- Left column: `VStack(spacing: 18)` — Yardage, Recommended (conditional), Reset indicator (existing), Pre-Shot Routine (conditional), Mantra (conditional), Swing Thoughts (conditional)
- Right column: CarryLadder
- Widths: both `.frame(maxWidth: .infinity)` — natural 50/50. (Current 55/45 split is abandoned to match wireframe's `1fr 1fr`.)

## Files to touch

| File | Change |
|---|---|
| `HTG/UIComponents/GolfMode/YardageBookPageView.swift` | Layout + title swap + new column split |
| `HTG/UIComponents/GolfMode/PageTitleView.swift` | Font change to `.system(.serif)` |
| `HTG/UIComponents/GolfMode/YardageDisplayView.swift` | Add stepper + "yds" label + eyebrow |
| `HTG/UIComponents/GolfMode/ShotInfoHeaderView.swift` | Replace by `RecommendedShotCard` (new file) |
| `HTG/UIComponents/GolfMode/RecommendedShotCard.swift` | NEW |
| `HTG/UIComponents/GolfMode/PreShotRoutineView.swift` | Eyebrow + dashed circle numerals |
| `HTG/UIComponents/GolfMode/MantraView.swift` | Accent left-bar, tinted bg, serif italic, eyebrow |
| `HTG/UIComponents/GolfMode/SwingThoughtsView.swift` | Eyebrow + accent bullets |
| `HTG/UIComponents/GolfMode/YardageLadderView.swift` | Rebuild as card+list |
| `HTG/UIComponents/GolfMode/GroupedLadderClubMarkerView.swift` | Replaced inline by new pill view (keep file? delete if unused) |
| `HTG/UIComponents/GolfMode/LadderTickMarkView.swift` | Likely unused after rebuild — delete if so |
| `HTG/UIComponents/Theme/SectionEyebrow.swift` | NEW — shared eyebrow view modifier or wrapper |

## Testing

- `xcodebuild test … -only-testing HTGTests` — existing tests should still pass; `GolfModeViewModel` unchanged.
- No new unit tests required — purely presentational. (If any existing test depended on removed views' identifiers, update those.)
- Manual verification: launch on simulator, tap a ladder rung, confirm Recommended card updates; tap −/+ steppers; confirm reset indicator appears; confirm mantra/routine/thoughts render from profile.

## Non-goals / YAGNI

- No Fraunces font in bundle — system serif is the substitute.
- No new animations beyond what already exists.
- No swipe-to-mark-as-hit in the ladder (wireframe shows hit-styling for one entry; the existing ViewModel has no "hit" concept — leave hit styling out).
- No horizontal reflow on iPad — match wireframe (designed for iPhone 390pt width).
