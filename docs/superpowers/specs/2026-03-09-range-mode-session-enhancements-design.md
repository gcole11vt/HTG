# Range Mode Session Enhancements Design

## Overview

Four enhancements to Range Mode sessions: custom "Other" shot type with conditional persistence, restructured session layout with vertical stats and trash-icon delete, continuous hands-free speech dictation with auto-save and voice commands, and a "Save Session" flow that persists carry distance.

**Out of scope:** Putting section (separate spec).

---

## Change 1: "Other" Custom Shot Type

### Shot Type Picker
- The shot type `Picker` in `startSessionView` gets an "Other" option appended after the club's existing shot types
- When "Other" is selected, a TextField appears for the user to type a custom name (e.g., "Punch", "Flop")
- New state: `@State private var isOtherShotType: Bool` and `@State private var customShotTypeName: String`

### Validation
- If the club already has 5 shot types (the max), selecting "Other" shows an alert: "This club already has the maximum number of shot types." The "Start Session" button is disabled.
- "Start Session" is also disabled if "Other" is selected but the custom name field is empty
- If the user types a name that already exists as a shot type on the club, it should use the existing shot type (not create a duplicate)

### Session Behavior
- The custom name is passed as `shotTypeName` to `RangeManager.startSession()`. The `RangeSession` stores it as a plain string.
- `RangeManager` tracks `isCustomShotType: Bool` to distinguish "Other" sessions from standard ones. This flag is set when starting the session and used at save time.

### Persistence Rules
- **Save Session:** Only creates a new `ShotType` when `isCustomShotType == true` AND no existing `ShotType` on the club matches the name. Created via `ClubDataService.addShotType(to:, name:, distance:)` with the saved carry distance.
- **Save Session (existing shot type):** Updates `ShotType.carryDistance` with the chosen value. No new `ShotType` created.
- **End Session (discard):** No `ShotType` is created or updated. The custom name disappears.

### Files Changed
- `HTG/Features/RangeMode/Views/RangeModeView.swift` — add "Other" option to picker, custom name TextField, validation
- `HTG/Features/RangeMode/ViewModels/RangeManager.swift` — track `isCustomShotType` flag

---

## Change 2: Session Layout Restructure

### New Layout (top to bottom)
1. **Club name + shot type header** — centered (same as current)
2. **Distance TextField + "Add Shot" button + Mic icon** — horizontal row
3. **"End Session" + "Save Session" buttons** — side by side. End is bordered/gray. Save is green/prominent.
4. **Two-column section:**
   - **Left (~2/3 width):** Previous shots list, most recent at top. Each row: distance + voice icon (if `isFromVoice`) + trash icon on far right
   - **Right (~1/3 width):** Stats stacked vertically: Current (green, only if `ShotType.carryDistance > 0`), Count, Median, Max, 75th

### Shot Delete
- Each shot row gets a `Button` with `trash` system image on the trailing side
- Tapping calls `rangeManager.deleteShot()` — same as existing swipe delete
- Swipe-to-delete (`.onDelete`) remains functional alongside the trash icon
- Both methods coexist

### Save Session Flow
- Tapping "Save Session" opens a compact bottom sheet (same style as Golf Mode yardage input)
- Pre-filled with the session's median value
- User can tap to edit the number, then "Go" to confirm
- On confirm:
  - Updates `ShotType.carryDistance` with the chosen value
  - If custom "Other" shot type (`isCustomShotType == true`): creates a new `ShotType` on the club with that carry distance (only if no matching name exists)
  - Dismisses and navigates back to the start screen
- **Note:** This replaces the existing `RangeManager.saveSessionAsStoredShotType()` flow. `StoredShotType` remains in the codebase for historical data but is not used by the new save flow.

### End Session
- Shows a confirmation alert: "Discard this session? All shot data will be lost."
- On confirm: deletes the `RangeSession` and its shots, navigates back to start screen
- No `ShotType` changes

### "Current" Stat
- Shows `ShotType.carryDistance` for the club/shot type combo being trained
- Lookup: `RangeManager` receives the `Club` and `ShotType` references at session start (from the picker selection) and stores them. For custom "Other" types, `currentCarryDistance` is `nil` (no existing shot type yet).
- Only visible if a previously saved value exists (carryDistance > 0)
- Displayed in green to distinguish from session stats

### Files Changed
- `HTG/Features/RangeMode/Views/RangeModeView.swift` — full layout restructure
- `HTG/Features/RangeMode/ViewModels/RangeManager.swift` — add save session logic (update `ShotType.carryDistance`), store club/shotType references, `isCustomShotType` flag
- `HTG/Core/Services/RangeDataService.swift` — add method to update shot type carry distance

---

## Change 3: Continuous Speech Dictation Mode

### Activation
- User taps mic icon next to "Add Shot"
- Icon toggles to filled/active state (red color)
- `SpeechRecognitionService` starts listening in continuous mode
- First-time use triggers system permission dialog for microphone + speech recognition

### Continuous Loop
1. User speaks a yardage (e.g., "155")
2. `extractDistance()` parses the number from the transcription
3. A 2-second silence timer resets on each partial transcription update and triggers after 2 seconds of no new transcription updates
4. After 2 seconds of silence: phone speaks the number back via `AVSpeechSynthesizer`
5. Shot is auto-saved to the session (`addShot(distance:, isFromVoice: true)`)
6. Recognition restarts automatically — mic stays hot for the next yardage
7. Stats and previous shots list update in real-time

### Voice Commands
Detected in recognized text before extracting a number. A command is only matched when it is the **entire recognized utterance** (no numbers alongside it) to avoid false positives. Designed as configurable sets for easy expansion:

```
deleteCommands: Set<String> = ["delete", "error"]
stopCommands: Set<String> = ["stop", "done"]
```

- **Delete commands:** Remove the most recent shot from the session, speak "Deleted" as confirmation, keep listening. If no shots exist, ignore silently.
- **Stop commands:** Exit speech mode, stop listening, mic icon returns to inactive state

### Manual Exit
- Tapping the mic icon while active also stops listening

### Audio Session Handling
- Change audio session category from `.record` to `.playAndRecord` to support both recording and TTS playback
- When speaking back (TTS), temporarily pause recognition
- After TTS finishes, restart recording for next input

### SpeechRecognitionService Changes
- Add `var continuousMode: Bool = false` flag
- Add silence timer (2-second `Task.sleep` that resets on each partial transcription update)
- Add `func speakBack(_ text: String)` using `AVSpeechSynthesizer`
- Add `var onDistanceConfirmed: (@MainActor (Int) -> Void)?` callback for auto-saving
- Add `var onDeleteRequested: (@MainActor () -> Void)?` callback for delete commands
- Add `var onStopRequested: (@MainActor () -> Void)?` callback for stop commands
- Add `deleteCommands: Set<String>` and `stopCommands: Set<String>` as configurable properties
- Change audio session category to `.playAndRecord` (from `.record`)
- Modify `recognitionTask` handler: check if full utterance matches a command before extracting distances
- After readback completes, restart recognition cycle (`stopListening()` then `startListening()`)

### Files Changed
- `HTG/Core/Services/SpeechRecognitionService.swift` — continuous mode, silence timer, TTS, command detection, `.playAndRecord` audio session
- `HTG/Features/RangeMode/Views/RangeModeView.swift` — mic button wiring, speech state display

---

## Change 4: Info.plist Permissions

### Build Settings (project.pbxproj)
Add to both Debug and Release configurations:
- `INFOPLIST_KEY_NSMicrophoneUsageDescription = "HTG uses the microphone to listen for yardage distances you speak aloud."`
- `INFOPLIST_KEY_NSSpeechRecognitionUsageDescription = "HTG uses speech recognition to convert spoken yardage into a number."`

### Authorization Flow
- First mic tap: `requestAuthorization()` prompts system dialog
- If denied: show alert explaining the requirement, mic icon remains inactive
- If permissions revoked mid-session: speech mode automatically disables, manual entry remains available
- `AVSpeechSynthesizer` (TTS) requires no permissions

### Files Changed
- `HTG.xcodeproj/project.pbxproj` — add Info.plist permission keys
