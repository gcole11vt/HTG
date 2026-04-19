# Range Mode Keypad Dismiss & Microphone Hide

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the number pad dismissible by tapping outside the distance field, and hide the microphone button from the UI.

**Architecture:** Two small changes to `RangeModeView.swift`. Add a `@FocusState` for the distance TextField and a background tap gesture to dismiss it. Remove the mic button from the view hierarchy (keep all speech code intact).

**Tech Stack:** SwiftUI, `@FocusState`

---

## File Map

- **Modify:** `HTG/Features/RangeMode/Views/RangeModeView.swift`

---

### Task 1: Add keyboard dismiss on outside tap

**Files:**
- Modify: `HTG/Features/RangeMode/Views/RangeModeView.swift`

- [ ] **Step 1: Add @FocusState for distance field**

Add a new `@FocusState` property alongside the existing `isSaveFieldFocused`:

```swift
@FocusState private var isDistanceFieldFocused: Bool
```

Add this at line 19, right before or after the existing `@FocusState private var isSaveFieldFocused: Bool`.

- [ ] **Step 2: Bind focus state to the distance TextField**

In the `shotEntrySection` computed property (~line 199), add the `.focused` modifier to the distance TextField:

```swift
TextField("Distance", text: $distanceText)
    .keyboardType(.numberPad)
    .textFieldStyle(.roundedBorder)
    .frame(width: 100)
    .focused($isDistanceFieldFocused)
```

- [ ] **Step 3: Add tap gesture to dismiss keyboard on the active session view**

In the `activeSessionView` function (~line 160), add a content shape and tap gesture to the outer VStack so tapping anywhere outside the text field dismisses the keyboard:

```swift
private func activeSessionView(session: RangeSession) -> some View {
    VStack(spacing: 16) {
        sessionHeader(session: session)
        shotEntrySection
        sessionActionButtons
        twoColumnSection(session: session)
    }
    .contentShape(Rectangle())
    .onTapGesture {
        isDistanceFieldFocused = false
    }
    .padding()
    // ... rest of modifiers unchanged
```

`.contentShape(Rectangle())` ensures the tap is recognized even on empty space within the VStack.

- [ ] **Step 4: Build and verify**

Run:
```bash
xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add HTG/Features/RangeMode/Views/RangeModeView.swift
git commit -m "fix: dismiss number pad when tapping outside distance field in Range Mode"
```

---

### Task 2: Hide microphone button from UI

**Files:**
- Modify: `HTG/Features/RangeMode/Views/RangeModeView.swift`

- [ ] **Step 1: Remove the mic button from shotEntrySection**

Remove the mic Button block (lines 210-217) from the `shotEntrySection` HStack. The resulting section should be:

```swift
private var shotEntrySection: some View {
    HStack(spacing: 12) {
        TextField("Distance", text: $distanceText)
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)
            .frame(width: 100)
            .focused($isDistanceFieldFocused)

        Button("Add Shot") {
            addShot()
        }
        .buttonStyle(.borderedProminent)
        .disabled(distanceText.isEmpty)
    }
}
```

- [ ] **Step 2: Build and verify no warnings**

Run:
```bash
xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator -quiet
```
Expected: BUILD SUCCEEDED (check for unused variable warnings related to speechService — if any, suppress with `_ = speechService` in an appropriate spot or leave as-is since the property is still declared).

- [ ] **Step 3: Commit**

```bash
git add HTG/Features/RangeMode/Views/RangeModeView.swift
git commit -m "fix: hide microphone button from Range Mode UI (keep speech code for future use)"
```
