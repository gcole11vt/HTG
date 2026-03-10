# Golf Mode UI Refinements Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve Golf Mode UX with a compact number pad yardage input, centered club detail styling, and an integrated green target tick mark on the yardage ladder.

**Architecture:** Three independent UI changes, each isolated to 1-2 view files. No model or service changes. The yardage input sheet is redesigned in-place as a compact bottom sheet. The club detail is a styling-only change. The green target bar is replaced by extending the existing tick mark component with target state.

**Tech Stack:** SwiftUI, iOS 18+, `@FocusState`

**Spec:** `docs/superpowers/specs/2026-03-09-golf-mode-ui-refinements-design.md`

---

## Chunk 1: Yardage Input + Club Detail Styling

### Task 1: Redesign Yardage Input Sheet

**Files:**
- Modify: `HTG/UIComponents/GolfMode/YardageDisplayView.swift`

- [ ] **Step 1: Replace the yardage edit sheet**

Replace the entire contents of `HTG/UIComponents/GolfMode/YardageDisplayView.swift`. The button action changes to set `editText = ""` (empty, not pre-filled). The sheet becomes a compact bottom sheet with an HStack containing the TextField and mic icon, plus a keyboard toolbar "Go" button.

```swift
import SwiftUI

struct YardageDisplayView: View {
    @Binding var yardage: Int
    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        Button {
            editText = ""
            isEditing = true
        } label: {
            Text("\(yardage)")
                .font(JournalTheme.yardageFont)
                .foregroundStyle(JournalTheme.inkBlue)
                .contentTransition(.numericText())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isEditing) {
            yardageEditSheet
        }
    }

    private var yardageEditSheet: some View {
        VStack(spacing: 16) {
            Spacer()

            HStack(spacing: 12) {
                Spacer()

                TextField("", text: $editText)
                    .font(JournalTheme.yardageFont)
                    .foregroundStyle(JournalTheme.inkBlue)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isTextFieldFocused)
                    .frame(width: 160)

                Image(systemName: "mic.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(JournalTheme.mutedGray)

                Spacer()
            }

            Spacer()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Go") {
                    if let newYardage = Int(editText), newYardage > 0 {
                        yardage = newYardage
                    }
                    isEditing = false
                }
                .foregroundStyle(JournalTheme.redMarker)
                .fontWeight(.semibold)
            }
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var yardage = 150
        var body: some View {
            VStack {
                YardageDisplayView(yardage: $yardage)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    return PreviewWrapper()
}
```

Key changes from current code:
- `editText` starts empty (`""`) instead of pre-filled with current yardage
- `@FocusState` + `.onAppear` auto-focuses the TextField when the sheet opens
- No `NavigationStack` or navigation toolbar — just a clean VStack
- Mic icon is a static visual affordance for system dictation (not wired to SpeechRecognitionService)
- "Go" button in `.toolbar` `ToolbarItemGroup(placement: .keyboard)` replaces Cancel/Done
- `.presentationDetents([.height(320)])` instead of `.medium` for a compact sheet
- Drag-dismiss discards changes (no yardage update)

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add HTG/UIComponents/GolfMode/YardageDisplayView.swift
git commit -m "Redesign yardage input as compact number pad bottom sheet"
```

---

### Task 2: Restyle Club Detail (ShotInfoHeaderView)

**Files:**
- Modify: `HTG/UIComponents/GolfMode/ShotInfoHeaderView.swift`

- [ ] **Step 1: Update alignment and font weights**

Replace the full contents of `HTG/UIComponents/GolfMode/ShotInfoHeaderView.swift`:

```swift
import SwiftUI

struct ShotInfoHeaderView: View {
    let carryDistance: Int
    let clubName: String
    let shotTypeName: String

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("\(carryDistance)")
                .font(JournalTheme.handwritten(size: 24))
                .foregroundStyle(JournalTheme.inkBlue)

            Text(clubName)
                .font(JournalTheme.handwritten(size: 24))
                .foregroundStyle(JournalTheme.inkBlue)

            Text(shotTypeName)
                .font(JournalTheme.handwritten(size: 18))
                .foregroundStyle(JournalTheme.mutedGray)
        }
    }
}

#Preview {
    ShotInfoHeaderView(
        carryDistance: 150,
        clubName: "7 Iron",
        shotTypeName: "Full"
    )
    .padding()
}
```

Changes:
- `VStack(alignment: .leading, spacing: 4)` -> `VStack(alignment: .center, spacing: 4)` (centers content)
- `handwrittenBold(size: 24)` -> `handwritten(size: 24)` for both carryDistance and clubName (removes bold)
- `shotTypeName` line unchanged

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add HTG/UIComponents/GolfMode/ShotInfoHeaderView.swift
git commit -m "Center and un-bold club detail text in ShotInfoHeaderView"
```

---

## Chunk 2: Green Target Tick Mark

### Task 3: Add `isTarget` to LadderTickMarkView

**Files:**
- Modify: `HTG/UIComponents/GolfMode/LadderTickMarkView.swift`

- [ ] **Step 1: Add isTarget parameter and conditional styling**

Replace the full contents of `HTG/UIComponents/GolfMode/LadderTickMarkView.swift`:

```swift
import SwiftUI

struct LadderTickMarkView: View {
    let yardage: Int
    let isMajor: Bool
    var isTarget: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if isMajor {
                Text("\(yardage)")
                    .font(JournalTheme.ladderFont)
                    .foregroundStyle(isTarget ? JournalTheme.targetGreen : JournalTheme.inkBlue)
                    .frame(width: 30, alignment: .trailing)
            } else {
                Spacer()
                    .frame(width: 30)
            }

            Rectangle()
                .fill(isTarget ? JournalTheme.targetGreen : JournalTheme.inkBlue.opacity(0.5))
                .frame(width: isTarget || isMajor ? 12 : 6, height: isTarget ? 3 : 1)
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        LadderTickMarkView(yardage: 160, isMajor: true)
        LadderTickMarkView(yardage: 155, isMajor: false)
        LadderTickMarkView(yardage: 150, isMajor: true, isTarget: true)
        LadderTickMarkView(yardage: 145, isMajor: false)
        LadderTickMarkView(yardage: 140, isMajor: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
```

Changes:
- Added `var isTarget: Bool = false` (defaulted, no existing callers break)
- Rectangle fill: `targetGreen` when `isTarget`, else `inkBlue.opacity(0.5)`
- Rectangle width: always 12pt when `isTarget` (even for minor ticks)
- Rectangle height: 3pt when `isTarget`, else 1pt
- Yardage label color: `targetGreen` when `isTarget && isMajor`
- Preview includes a target example at yardage 150

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add HTG/UIComponents/GolfMode/LadderTickMarkView.swift
git commit -m "Add isTarget styling to LadderTickMarkView"
```

---

### Task 4: Wire target tick mark in YardageLadderView and delete TargetYardageBarView

**Files:**
- Modify: `HTG/UIComponents/GolfMode/YardageLadderView.swift`
- Delete: `HTG/UIComponents/GolfMode/TargetYardageBarView.swift`
- Modify: `HTG.xcodeproj/project.pbxproj` — remove TargetYardageBarView references

- [ ] **Step 1: Update YardageLadderView**

Replace the full contents of `HTG/UIComponents/GolfMode/YardageLadderView.swift`:

```swift
import SwiftUI

struct YardageLadderView: View {
    let targetYardage: Int
    let minYardage: Int
    let maxYardage: Int
    let groupedEntries: [GroupedLadderEntry]
    var onSelectEntry: ((LadderEntry) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                // Tick marks
                ForEach(tickMarks, id: \.yardage) { tick in
                    LadderTickMarkView(
                        yardage: tick.yardage,
                        isMajor: tick.isMajor,
                        isTarget: tick.isTarget
                    )
                    .position(
                        x: geometry.size.width - 25,
                        y: yPosition(for: tick.yardage, in: geometry.size.height)
                    )
                }

                // Grouped club markers
                ForEach(groupedEntries) { group in
                    GroupedLadderClubMarkerView(group: group, onSelect: onSelectEntry)
                        .position(
                            x: geometry.size.width - 80,
                            y: yPosition(for: group.carryDistance, in: geometry.size.height)
                        )
                }
            }
        }
    }

    private var tickMarks: [TickMark] {
        var marks: [TickMark] = []
        let start = (minYardage / 5) * 5
        let end = ((maxYardage / 5) + 1) * 5

        for yardage in stride(from: end, through: start, by: -5) {
            if yardage >= minYardage && yardage <= maxYardage {
                marks.append(TickMark(
                    yardage: yardage,
                    isMajor: yardage % 10 == 0,
                    isTarget: yardage == targetYardage
                ))
            }
        }

        // Insert target tick if it doesn't land on a 5-yard mark
        if !marks.contains(where: { $0.isTarget }) {
            let targetMark = TickMark(yardage: targetYardage, isMajor: true, isTarget: true)
            if let insertIndex = marks.firstIndex(where: { $0.yardage < targetYardage }) {
                marks.insert(targetMark, at: insertIndex)
            } else {
                marks.append(targetMark)
            }
        }

        return marks
    }

    private func yPosition(for yardage: Int, in height: CGFloat) -> CGFloat {
        let range = maxYardage - minYardage
        guard range > 0 else { return height / 2 }

        let padding: CGFloat = 20
        let usableHeight = height - (padding * 2)

        let normalizedPosition = 1.0 - (Double(yardage - minYardage) / Double(range))
        return padding + CGFloat(normalizedPosition) * usableHeight
    }
}

private struct TickMark {
    let yardage: Int
    let isMajor: Bool
    var isTarget: Bool = false
}

#Preview {
    let entries = [
        GroupedLadderEntry(
            carryDistance: 165,
            entries: [
                LadderEntry(clubName: "6 Iron", clubNickname: "6I", shotTypeName: "Full", carryDistance: 165, yardagePosition: 0.7, isSelected: false, isSameClubAsSelected: false, isPrimaryShotType: true)
            ]
        ),
        GroupedLadderEntry(
            carryDistance: 155,
            entries: [
                LadderEntry(clubName: "7 Iron", clubNickname: "7I", shotTypeName: "Full", carryDistance: 155, yardagePosition: 0.55, isSelected: true, isSameClubAsSelected: true, isPrimaryShotType: true)
            ]
        ),
        GroupedLadderEntry(
            carryDistance: 145,
            entries: [
                LadderEntry(clubName: "8 Iron", clubNickname: "8I", shotTypeName: "Full", carryDistance: 145, yardagePosition: 0.4, isSelected: false, isSameClubAsSelected: false, isPrimaryShotType: true)
            ]
        ),
        GroupedLadderEntry(
            carryDistance: 140,
            entries: [
                LadderEntry(clubName: "7 Iron", clubNickname: "7I", shotTypeName: "3/4", carryDistance: 140, yardagePosition: 0.35, isSelected: false, isSameClubAsSelected: true, isPrimaryShotType: false)
            ]
        )
    ]

    return YardageLadderView(
        targetYardage: 153,
        minYardage: 127,
        maxYardage: 172,
        groupedEntries: entries
    ) { entry in
        print("Selected: \(entry.clubName)")
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
```

Changes:
- Removed `TargetYardageBarView` block (lines 25-31 in original)
- Added `isTarget` field to `TickMark` struct (defaults to `false`)
- Each tick mark now gets `isTarget: yardage == targetYardage`
- If `targetYardage` doesn't land on a 5-yard interval, an extra tick mark is inserted at the correct descending-sorted position with `isMajor: true` and `isTarget: true`
- Deduplication: the insert only happens if `!marks.contains(where: { $0.isTarget })`
- Passes `isTarget: tick.isTarget` to `LadderTickMarkView` in the ForEach

- [ ] **Step 2: Delete TargetYardageBarView.swift**

```bash
git rm HTG/UIComponents/GolfMode/TargetYardageBarView.swift
```

- [ ] **Step 3: Remove TargetYardageBarView from project.pbxproj**

```bash
grep -v "TargetYardageBarView" HTG.xcodeproj/project.pbxproj > HTG.xcodeproj/project.pbxproj.tmp && mv HTG.xcodeproj/project.pbxproj.tmp HTG.xcodeproj/project.pbxproj
```

This removes all 4 lines referencing TargetYardageBarView (PBXBuildFile, PBXFileReference, PBXGroup child, PBXSourcesBuildPhase).

- [ ] **Step 4: Build to verify**

Run: `xcodebuild clean build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add HTG/UIComponents/GolfMode/YardageLadderView.swift HTG.xcodeproj/project.pbxproj
git commit -m "Replace TargetYardageBarView with integrated green tick mark"
```

- [ ] **Step 6: Verify no stale references remain**

Run after commit, so deleted file is gone from working tree:
```bash
grep -rn "TargetYardageBarView" HTG/ --include="*.swift"; grep -rn "TargetYardageBarView" HTG.xcodeproj/
```
Expected: No output

---

## Chunk 3: Final Verification

### Task 5: Full Build + Test Verification

- [ ] **Step 1: Clean build**

Run: `xcodebuild clean build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator 2>&1 | tail -5`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Run unit tests**

Run: `xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing HTGTests 2>&1 | tail -20`
Expected: All tests pass
