# Sheet Save Buttons & Keyboard Dismiss Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add visible Save/Go buttons and tap-to-dismiss-keyboard to the Range Mode save sheet and Golf Mode yardage edit sheet.

**Architecture:** Both sheets currently rely on a toolbar "Go" button that doesn't appear with the number pad. Replace the toolbar approach with a visible button in the sheet body, and add a tap gesture to dismiss the keyboard when tapping outside the text field.

**Tech Stack:** SwiftUI, `@FocusState`

---

## File Map

- **Modify:** `HTG/Features/RangeMode/Views/RangeModeView.swift` (save session sheet)
- **Modify:** `HTG/UIComponents/GolfMode/YardageDisplayView.swift` (yardage edit sheet)

---

### Task 1: Range Mode — Add Save button and keyboard dismiss to save session sheet

**Files:**
- Modify: `HTG/Features/RangeMode/Views/RangeModeView.swift:329-375`

- [ ] **Step 1: Replace toolbar with visible Save button and add keyboard dismiss**

Replace the `saveSessionSheet` computed property with this version. Changes:
- Remove the `.toolbar` block (the "Go" button that doesn't appear)
- Add a "Save" button in the sheet body between the input and bottom Spacer
- Add `.contentShape(Rectangle()).onTapGesture` to dismiss keyboard on outside tap

```swift
private var saveSessionSheet: some View {
    VStack(spacing: 16) {
        Spacer()

        Text("Save Carry Distance")
            .font(.headline)

        HStack(spacing: 12) {
            Spacer()

            TextField("", text: $saveDistanceText)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .focused($isSaveFieldFocused)
                .frame(width: 160)

            Spacer()
        }

        Button {
            if let distance = Int(saveDistanceText), distance > 0 {
                Task {
                    await rangeManager?.saveSession(carryDistance: distance)
                    showingSaveSheet = false
                    selectedClub = nil
                    shotTypeSelection = .none
                    customShotTypeName = ""
                }
            }
        } label: {
            Text("Save")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(Int(saveDistanceText) ?? 0 <= 0)
        .padding(.horizontal, 40)

        Spacer()
    }
    .contentShape(Rectangle())
    .onTapGesture {
        isSaveFieldFocused = false
    }
    .presentationDetents([.height(320)])
    .presentationDragIndicator(.visible)
    .onAppear {
        isSaveFieldFocused = true
    }
}
```

- [ ] **Step 2: Build and verify**

Run:
```bash
xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add HTG/Features/RangeMode/Views/RangeModeView.swift
git commit -m "fix: add visible Save button and keyboard dismiss to Range Mode save sheet"
```

---

### Task 2: Golf Mode — Add Go button, keyboard dismiss, and remove mic icon from yardage edit sheet

**Files:**
- Modify: `HTG/UIComponents/GolfMode/YardageDisplayView.swift:25-67`

- [ ] **Step 1: Replace toolbar with visible Go button, add keyboard dismiss, remove mic icon**

Replace the `yardageEditSheet` computed property with this version. Changes:
- Remove the static mic icon (lines 40-42)
- Remove the `.toolbar` block
- Add a "Go" button in the sheet body
- Add `.contentShape(Rectangle()).onTapGesture` to dismiss keyboard

```swift
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

            Spacer()
        }

        Button {
            if let newYardage = Int(editText), newYardage > 0 {
                yardage = newYardage
            }
            isEditing = false
        } label: {
            Text("Go")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(JournalTheme.redMarker)
        .padding(.horizontal, 40)

        Spacer()
    }
    .contentShape(Rectangle())
    .onTapGesture {
        isTextFieldFocused = false
    }
    .presentationDetents([.height(320)])
    .presentationDragIndicator(.visible)
    .onAppear {
        isTextFieldFocused = true
    }
}
```

- [ ] **Step 2: Build and verify**

Run:
```bash
xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add HTG/UIComponents/GolfMode/YardageDisplayView.swift
git commit -m "fix: add visible Go button, keyboard dismiss, and remove mic icon from yardage edit sheet"
```
