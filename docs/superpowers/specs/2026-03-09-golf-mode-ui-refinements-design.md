# Golf Mode UI Refinements Design

## Overview

Three targeted UI improvements to Golf Mode: redesign yardage input, restyle club detail display, and fix the green target bar on the yardage ladder.

---

## Change 1: Yardage Input — Compact Number Pad Sheet

### Current Behavior
Tapping the yardage number opens a `.sheet` with a NavigationStack containing a "Target Yardage" title, a TextField pre-filled with the current value, and Cancel/Done toolbar buttons.

### New Behavior
- Tapping the yardage number opens a compact bottom sheet (`.presentationDetents([.height(320)])`) with no navigation chrome
- Sheet contains a centered, **empty** TextField (not pre-filled) with `.keyboardType(.numberPad)`
- TextField auto-focuses on appear via `@FocusState` set to `true` in `.onAppear`
- TextField uses `JournalTheme.yardageFont` and `JournalTheme.inkBlue` (matching current styling)
- A mic icon (`Image(systemName: "mic.fill")`) in `mutedGray` sits to the right of the TextField in an HStack, as a visual affordance hinting at system dictation
- A "Go" button in `.toolbar` `ToolbarItemGroup(placement: .keyboard)` above the number pad confirms the entry. Styled in `redMarker` with `.semibold` weight (matching current "Done" button style)
- On "Go": parse text, update yardage binding if valid (> 0), dismiss
- On drag-dismiss or tap outside: discard changes (no update)
- `.presentationDragIndicator(.visible)` and `.interactiveDismissDisabled(false)`

### Files Changed
- `HTG/UIComponents/GolfMode/YardageDisplayView.swift` — replace `yardageEditSheet`

---

## Change 2: Club Detail Styling

### Current Behavior
`ShotInfoHeaderView` uses a left-aligned VStack with bold fonts for carry distance and club name.

### New Behavior
- VStack alignment: `.leading` -> `.center`
- `carryDistance`: `.handwrittenBold(size: 24)` -> `.handwritten(size: 24)` (remove bold)
- `clubName`: `.handwrittenBold(size: 24)` -> `.handwritten(size: 24)` (remove bold)
- `shotTypeName`: unchanged (`.handwritten(size: 18)`, mutedGray)

### Files Changed
- `HTG/UIComponents/GolfMode/ShotInfoHeaderView.swift` — alignment and font weight only

---

## Change 3: Green Target Bar -> Green Tick Mark

### Current Behavior
A separate `TargetYardageBarView` (12pt wide, 3pt tall green rectangle) overlays the yardage ladder at the target position, visually striking through the yardage labels.

### New Behavior
- `LadderTickMarkView` gains `var isTarget: Bool = false` parameter
- When `isTarget == true`:
  - Rectangle color: `targetGreen` instead of `inkBlue.opacity(0.5)`
  - Rectangle height: 3pt instead of 1pt (thicker, matching current target bar thickness)
  - Width forced to major size (12pt) regardless of `isMajor` flag
  - Yardage label (if `isMajor`) also renders in `targetGreen`
- `YardageLadderView` removes the `TargetYardageBarView` block entirely
- In the tick mark ForEach, passes `isTarget: tick.yardage == targetYardage` to each `LadderTickMarkView`
- If `targetYardage` doesn't land on an existing 5-yard tick mark, an extra `TickMark` is inserted into the `tickMarks` array at the correct sorted position with `isMajor: true` and tagged as target. Deduplication: only insert if no existing tick mark has the same yardage.
- `TargetYardageBarView.swift` is deleted

### Files Changed
- `HTG/UIComponents/GolfMode/LadderTickMarkView.swift` — add `isTarget` parameter and conditional styling
- `HTG/UIComponents/GolfMode/YardageLadderView.swift` — remove TargetYardageBarView usage, pass isTarget to tick marks, handle non-5-yard targets
- `HTG/UIComponents/GolfMode/TargetYardageBarView.swift` — delete
- `HTG.xcodeproj/project.pbxproj` — remove TargetYardageBarView reference
