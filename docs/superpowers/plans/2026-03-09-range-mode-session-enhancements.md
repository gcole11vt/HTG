# Range Mode Session Enhancements Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add "Other" custom shot type, restructure in-session layout with vertical stats and trash-icon delete, implement continuous hands-free speech dictation with auto-save, and add a "Save Session" flow that persists carry distance to the club's `ShotType`.

**Architecture:** Extend existing `SpeechRecognitionService` with continuous mode, silence timer, TTS readback, and command detection. Extend `RangeManager` to store `Club`/`ShotType` references and handle the new save-session flow (update `ShotType.carryDistance`, conditionally create new shot types). Fully restructure `RangeModeView` layout.

**Tech Stack:** SwiftUI, SwiftData, Speech framework (`SFSpeechRecognizer`, `AVAudioEngine`), `AVSpeechSynthesizer`, Swift Testing

**Spec:** `docs/superpowers/specs/2026-03-09-range-mode-session-enhancements-design.md`

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `HTG/Core/Services/SpeechRecognitionService.swift` | Modify | Add continuous mode, silence timer, TTS, command detection, callbacks |
| `HTG/Core/Services/RangeDataService.swift` | Modify | Add `updateShotTypeCarryDistance` method |
| `HTG/Features/RangeMode/ViewModels/RangeManager.swift` | Modify | Store Club/ShotType refs, `isCustomShotType`, new save session logic, `currentCarryDistance` |
| `HTG/Features/RangeMode/Views/RangeModeView.swift` | Modify | Full layout restructure, "Other" picker, mic wiring, Save/End buttons, trash icons |
| `HTG.xcodeproj/project.pbxproj` | Modify | Add microphone + speech recognition Info.plist keys |
| `HTGTests/SpeechRecognitionServiceTests.swift` | Modify | Add command detection tests |
| `HTGTests/RangeDataServiceTests.swift` | Modify | Add `updateShotTypeCarryDistance` test |

---

## Chunk 1: Service Layer Changes

### Task 1: Add Command Detection to SpeechRecognitionService

Extend the speech service with voice command detection (delete/stop) and the `extractCommand` method. This is pure logic, testable without hardware.

**Files:**
- Test: `HTGTests/SpeechRecognitionServiceTests.swift`
- Modify: `HTG/Core/Services/SpeechRecognitionService.swift`

- [ ] **Step 1: Write failing tests for command detection**

Add to `HTGTests/SpeechRecognitionServiceTests.swift`:

```swift
@Test("Detect delete command from exact utterance")
func detectDeleteCommand() {
    let service = SpeechRecognitionService()

    let result = service.extractCommand(from: "delete")

    #expect(result == .delete)
}

@Test("Detect error command as delete")
func detectErrorAsDelete() {
    let service = SpeechRecognitionService()

    let result = service.extractCommand(from: "error")

    #expect(result == .delete)
}

@Test("Detect stop command")
func detectStopCommand() {
    let service = SpeechRecognitionService()

    let result = service.extractCommand(from: "stop")

    #expect(result == .stop)
}

@Test("Detect done command as stop")
func detectDoneAsStop() {
    let service = SpeechRecognitionService()

    let result = service.extractCommand(from: "done")

    #expect(result == .stop)
}

@Test("Command detection is case insensitive")
func commandDetectionCaseInsensitive() {
    let service = SpeechRecognitionService()

    #expect(service.extractCommand(from: "DELETE") == .delete)
    #expect(service.extractCommand(from: "Stop") == .stop)
}

@Test("Command not detected when number present")
func commandNotDetectedWithNumber() {
    let service = SpeechRecognitionService()

    let result = service.extractCommand(from: "delete 155")

    #expect(result == nil)
}

@Test("Command not detected for plain text")
func commandNotDetectedForPlainText() {
    let service = SpeechRecognitionService()

    let result = service.extractCommand(from: "one fifty five")

    #expect(result == nil)
}

@Test("Command not detected for empty string")
func commandNotDetectedForEmpty() {
    let service = SpeechRecognitionService()

    let result = service.extractCommand(from: "")

    #expect(result == nil)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing HTGTests/SpeechRecognitionServiceTests 2>&1 | tail -20`
Expected: FAIL — `extractCommand` and `VoiceCommand` don't exist yet

- [ ] **Step 3: Implement VoiceCommand enum and extractCommand**

In `HTG/Core/Services/SpeechRecognitionService.swift`, add the enum before the class definition and the method + configurable sets inside the class:

```swift
enum VoiceCommand: Equatable {
    case delete
    case stop
}
```

Inside `SpeechRecognitionService`, add these static properties after the existing static properties (`minimumDistance`, `maximumDistance`):

```swift
nonisolated(unsafe) static var deleteCommands: Set<String> = ["delete", "error"]
nonisolated(unsafe) static var stopCommands: Set<String> = ["stop", "done"]
```

> **Note:** These are `static var` so they can be expanded with additional command words later. Marked `nonisolated(unsafe)` to match the existing pattern for `minimumDistance`/`maximumDistance`, allowing access from `nonisolated` methods.

Add this method after `extractDistance(from:)`:

```swift
nonisolated func extractCommand(from text: String) -> VoiceCommand? {
    let trimmed = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    if Self.deleteCommands.contains(trimmed) {
        return .delete
    }
    if Self.stopCommands.contains(trimmed) {
        return .stop
    }
    return nil
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing HTGTests/SpeechRecognitionServiceTests 2>&1 | tail -20`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add HTGTests/SpeechRecognitionServiceTests.swift HTG/Core/Services/SpeechRecognitionService.swift
git commit -m "feat: add voice command detection to SpeechRecognitionService"
```

---

### Task 2: Add Continuous Mode, Silence Timer, TTS, and Callbacks to SpeechRecognitionService

Extend the service with continuous listening mode, a 2-second silence timer, TTS readback via `AVSpeechSynthesizer`, and callbacks for distance confirmed / delete / stop. Change audio session to `.playAndRecord`.

**Files:**
- Modify: `HTG/Core/Services/SpeechRecognitionService.swift`

- [ ] **Step 1: Add `import AVFoundation` and continuous mode properties and callbacks**

In `HTG/Core/Services/SpeechRecognitionService.swift`, add `import AVFoundation` after the existing imports (needed for `AVSpeechSynthesizer`/`AVSpeechUtterance`).

Then add these properties to the class (after the existing properties and the command sets from Task 1):

```swift
var continuousMode: Bool = false
var onDistanceConfirmed: (@MainActor (Int) -> Void)?
var onDeleteRequested: (@MainActor () -> Void)?
var onStopRequested: (@MainActor () -> Void)?

private var silenceTimerTask: Task<Void, Never>?
private let synthesizer = AVSpeechSynthesizer()
```

- [ ] **Step 2: Add TTS speakBack method**

Add after `stopListening()`:

```swift
func speakBack(_ text: String) async {
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate

    synthesizer.speak(utterance)

    // Wait for speech to finish
    while synthesizer.isSpeaking {
        try? await Task.sleep(for: .milliseconds(100))
    }
}
```

- [ ] **Step 3: Update audio session category**

In `startListening()`, change line 71:

From:
```swift
try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
```

To:
```swift
try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
```

- [ ] **Step 4: Add silence timer reset method**

Add after `speakBack`:

```swift
private func resetSilenceTimer() {
    silenceTimerTask?.cancel()
    guard continuousMode else { return }

    silenceTimerTask = Task { @MainActor in
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        await handleSilenceTimeout()
    }
}

private func handleSilenceTimeout() async {
    guard continuousMode, isListening else { return }

    // Check for command first
    if let command = extractCommand(from: lastRecognizedText) {
        switch command {
        case .delete:
            onDeleteRequested?()
            // Speak confirmation
            stopListening()
            await speakBack("Deleted")
            do {
                try await startListening()
            } catch {
                continuousMode = false
                onStopRequested?()
            }
        case .stop:
            continuousMode = false
            stopListening()
            onStopRequested?()
        }
        lastRecognizedText = ""
        lastExtractedDistance = nil
        return
    }

    // Check for distance
    if let distance = lastExtractedDistance {
        onDistanceConfirmed?(distance)
        stopListening()
        await speakBack("\(distance)")
        lastRecognizedText = ""
        lastExtractedDistance = nil
        do {
            try await startListening()
        } catch {
            continuousMode = false
            onStopRequested?()
        }
    } else {
        // No valid input detected, restart listening
        lastRecognizedText = ""
        stopListening()
        do {
            try await startListening()
        } catch {
            continuousMode = false
            onStopRequested?()
        }
    }
}
```

- [ ] **Step 5: Update recognitionTask handler to reset silence timer on partial results**

Replace the `recognitionTask` assignment in `startListening()` (current lines 93-106):

From:
```swift
recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
    Task { @MainActor in
        guard let self = self else { return }

        if let result = result {
            self.lastRecognizedText = result.bestTranscription.formattedString
            self.lastExtractedDistance = self.extractDistance(from: self.lastRecognizedText)
        }

        if error != nil || result?.isFinal == true {
            self.stopListening()
        }
    }
}
```

To:
```swift
recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
    Task { @MainActor in
        guard let self = self else { return }

        if let result = result {
            self.lastRecognizedText = result.bestTranscription.formattedString
            self.lastExtractedDistance = self.extractDistance(from: self.lastRecognizedText)

            if self.continuousMode {
                self.resetSilenceTimer()
            }
        }

        if error != nil || result?.isFinal == true {
            if !self.continuousMode {
                self.stopListening()
            }
        }
    }
}
```

- [ ] **Step 6: Cancel silence timer in stopListening**

In `stopListening()`, add at the top of the method body:

```swift
silenceTimerTask?.cancel()
silenceTimerTask = nil
```

- [ ] **Step 7: Build to verify compilation**

Run: `xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 8: Commit**

```bash
git add HTG/Core/Services/SpeechRecognitionService.swift
git commit -m "feat: add continuous speech mode with silence timer, TTS readback, and callbacks"
```

---

### Task 3: Add updateShotTypeCarryDistance to RangeDataService

Add a method to update a `ShotType`'s carry distance in the database.

**Files:**
- Test: `HTGTests/RangeDataServiceTests.swift`
- Modify: `HTG/Core/Services/RangeDataService.swift`

- [ ] **Step 1: Write failing test**

Add to `HTGTests/RangeDataServiceTests.swift`. The test container needs `Club.self` and `ShotType.self` in its schema:

```swift
private func makeTestContainerWithClubs() throws -> ModelContainer {
    let schema = Schema([RangeSession.self, Shot.self, StoredShotType.self, Club.self, ShotType.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}

@Test("Update shot type carry distance persists new value")
func updateShotTypeCarryDistancePersists() async throws {
    let container = try makeTestContainerWithClubs()
    let service = makeService(container: container)

    let club = Club(name: "7 Iron", sortOrder: 0)
    let shotType = ShotType(name: "Full", carryDistance: 150, sortOrder: 0, club: club)
    club.shotTypes = [shotType]
    container.mainContext.insert(club)
    try container.mainContext.save()

    try await service.updateShotTypeCarryDistance(shotType, distance: 165)

    #expect(shotType.carryDistance == 165)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing HTGTests/RangeDataServiceTests/updateShotTypeCarryDistancePersists 2>&1 | tail -20`
Expected: FAIL — `updateShotTypeCarryDistance` doesn't exist

- [ ] **Step 3: Implement the method**

Add to `HTG/Core/Services/RangeDataService.swift`, after `deleteSession`:

```swift
func updateShotTypeCarryDistance(_ shotType: ShotType, distance: Int) async throws {
    shotType.carryDistance = distance
    try modelContext.save()
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing HTGTests/RangeDataServiceTests/updateShotTypeCarryDistancePersists 2>&1 | tail -20`
Expected: PASS

- [ ] **Step 5: Run all tests to verify no regressions**

Run: `xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing HTGTests 2>&1 | tail -20`
Expected: All PASS

- [ ] **Step 6: Commit**

```bash
git add HTGTests/RangeDataServiceTests.swift HTG/Core/Services/RangeDataService.swift
git commit -m "feat: add updateShotTypeCarryDistance to RangeDataService"
```

---

## Chunk 2: RangeManager Changes

### Task 4: Extend RangeManager with Club/ShotType References and Save Session Logic

Store `Club` and `ShotType` references at session start, track `isCustomShotType`, add `currentCarryDistance` computed property, and implement the new save session flow.

**Files:**
- Modify: `HTG/Features/RangeMode/ViewModels/RangeManager.swift`

- [ ] **Step 1: Add new properties to RangeManager**

Add after the existing properties (`errorMessage`):

```swift
var sessionClub: Club?
var sessionShotType: ShotType?
var isCustomShotType: Bool = false

var currentCarryDistance: Int? {
    guard let shotType = sessionShotType, shotType.carryDistance > 0 else { return nil }
    return shotType.carryDistance
}
```

Also add a `ClubDataService` reference. Change the `init` to accept both:

```swift
private let service: RangeDataService
private let clubDataService: ClubDataService

init(modelContext: ModelContext) {
    self.service = RangeDataService(modelContext: modelContext)
    self.clubDataService = ClubDataService(modelContext: modelContext)
}
```

- [ ] **Step 2: Update startSession to accept Club and ShotType references**

Replace the existing `startSession` method:

```swift
func startSession(club: Club, shotType: ShotType?, shotTypeName: String, isCustom: Bool) async {
    isLoading = true
    errorMessage = nil
    sessionClub = club
    sessionShotType = shotType
    isCustomShotType = isCustom
    do {
        currentSession = try await service.createSession(clubName: club.name, shotTypeName: shotTypeName)
        updateStats()
    } catch {
        errorMessage = error.localizedDescription
    }
    isLoading = false
}
```

- [ ] **Step 3: Replace saveSessionAsStoredShotType with new saveSession method**

Replace the existing `saveSessionAsStoredShotType` method:

```swift
func saveSession(carryDistance: Int) async {
    guard let club = sessionClub else {
        errorMessage = "No club associated with session"
        return
    }
    guard let session = currentSession else {
        errorMessage = "No active session"
        return
    }

    do {
        if isCustomShotType {
            // Check if a shot type with this name already exists on the club
            let existingMatch = club.shotTypes.first(where: {
                $0.name.lowercased() == session.shotTypeName.lowercased() && !$0.isArchived
            })
            if let existing = existingMatch {
                // Update existing shot type's carry distance
                try await service.updateShotTypeCarryDistance(existing, distance: carryDistance)
            } else {
                // Create new shot type on the club
                try await clubDataService.addShotType(to: club, name: session.shotTypeName, distance: carryDistance)
            }
        } else if let shotType = sessionShotType {
            // Standard shot type — update carry distance
            try await service.updateShotTypeCarryDistance(shotType, distance: carryDistance)
        }

        // Delete the completed session from the database
        try await service.deleteSession(session)

        // Clean up session state
        currentSession = nil
        currentStats = RangeStats()
        sessionClub = nil
        sessionShotType = nil
        isCustomShotType = false
    } catch {
        errorMessage = error.localizedDescription
    }
}
```

- [ ] **Step 4: Update endSession to delete the RangeSession and clean up**

Replace the existing `endSession` method:

```swift
func endSession() async {
    if let session = currentSession {
        do {
            try await service.deleteSession(session)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    currentSession = nil
    currentStats = RangeStats()
    sessionClub = nil
    sessionShotType = nil
    isCustomShotType = false
}
```

- [ ] **Step 5: Add deleteLastShot convenience method for voice commands**

Add after `deleteShot`:

```swift
func deleteLastShot() async {
    guard let session = currentSession,
          let lastShot = session.shots.sorted(by: { $0.date > $1.date }).first else { return }
    await deleteShot(lastShot)
}
```

- [ ] **Step 6: Keep the old startSession signature as a temporary bridge**

To avoid breaking `RangeModeView` before we rewrite it in Task 5, keep the old method as a deprecated wrapper below the new one:

```swift
@available(*, deprecated, message: "Use startSession(club:shotType:shotTypeName:isCustom:) instead")
func startSession(clubName: String, shotTypeName: String) async {
    // Temporary bridge — will be removed when RangeModeView is rewritten in Task 5
    isLoading = true
    errorMessage = nil
    sessionClub = nil
    sessionShotType = nil
    isCustomShotType = false
    do {
        currentSession = try await service.createSession(clubName: clubName, shotTypeName: shotTypeName)
        updateStats()
    } catch {
        errorMessage = error.localizedDescription
    }
    isLoading = false
}
```

- [ ] **Step 7: Build to verify compilation**

Run: `xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 8: Commit**

```bash
git add HTG/Features/RangeMode/ViewModels/RangeManager.swift
git commit -m "feat: extend RangeManager with club/shotType refs, save session, and custom shot type tracking"
```

---

## Chunk 3: View Layer — Full RangeModeView Rewrite

### Task 5: Rewrite RangeModeView — Start Session Screen with "Other" Shot Type

Update the start session view with the "Other" shot type option, custom name TextField, and validation.

**Files:**
- Modify: `HTG/Features/RangeMode/Views/RangeModeView.swift`

- [ ] **Step 1: Add ShotTypeSelection enum and new state properties**

Add a helper enum at the bottom of `RangeModeView.swift` (outside the struct, replacing the old `StatBox`):

```swift
enum ShotTypeSelection: Hashable {
    case none
    case existing(ShotType)
    case other

    var shotType: ShotType? {
        if case .existing(let st) = self { return st }
        return nil
    }

    static func == (lhs: ShotTypeSelection, rhs: ShotTypeSelection) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none), (.other, .other): return true
        case (.existing(let a), .existing(let b)): return a.id == b.id
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .none: hasher.combine(0)
        case .existing(let st): hasher.combine(1); hasher.combine(st.id)
        case .other: hasher.combine(2)
        }
    }
}
```

Add to the existing `@State` properties in `RangeModeView`:

```swift
@State private var shotTypeSelection: ShotTypeSelection = .none
@State private var customShotTypeName: String = ""
@State private var showMaxShotTypesAlert: Bool = false
```

Remove the old `@State private var selectedShotType: ShotType?` property — it's replaced by `shotTypeSelection`.

- [ ] **Step 2: Replace the shot type picker section**

In `startSessionView`, replace the shot type Picker and Start Session button section (lines 55-76) with:

> **Bug fix note:** The original code iterated all `club.shotTypes` including archived ones. This fix filters to active (non-archived) shot types only.

```swift
if let club = selectedClub {
    let activeShotTypes = club.shotTypes.filter { !$0.isArchived }

    Picker("Select Shot Type", selection: $shotTypeSelection) {
        Text("Select Shot Type").tag(ShotTypeSelection.none)
        ForEach(activeShotTypes) { shotType in
            Text(shotType.name).tag(ShotTypeSelection.existing(shotType))
        }
        Text("Other").tag(ShotTypeSelection.other)
    }
    .pickerStyle(.menu)
    .onChange(of: shotTypeSelection) { _, newValue in
        if case .other = newValue {
            let activeCount = activeShotTypes.count
            if activeCount >= ClubDataService.maximumShotTypesPerClub {
                showMaxShotTypesAlert = true
            }
        } else {
            customShotTypeName = ""
        }
    }

    if case .other = shotTypeSelection {
        TextField("Custom shot type name", text: $customShotTypeName)
            .textFieldStyle(.roundedBorder)
    }

    Button("Start Session") {
        Task {
            let club = club
            switch shotTypeSelection {
            case .other:
                // Check if the typed name matches an existing shot type
                let existingMatch = club.shotTypes.first(where: {
                    $0.name.lowercased() == customShotTypeName.lowercased() && !$0.isArchived
                })
                await rangeManager?.startSession(
                    club: club,
                    shotType: existingMatch,
                    shotTypeName: customShotTypeName,
                    isCustom: existingMatch == nil
                )
            case .existing(let shotType):
                await rangeManager?.startSession(
                    club: club,
                    shotType: shotType,
                    shotTypeName: shotType.name,
                    isCustom: false
                )
            case .none:
                break
            }
        }
    }
    .buttonStyle(.borderedProminent)
    .disabled(startSessionDisabled(club: club))
}
```

- [ ] **Step 3: Add validation helper and alert**

Add as a private method:

```swift
private func startSessionDisabled(club: Club) -> Bool {
    switch shotTypeSelection {
    case .none:
        return true
    case .existing:
        return false
    case .other:
        let activeCount = club.shotTypes.filter { !$0.isArchived }.count
        let nameMatchesExisting = club.shotTypes.contains(where: {
            $0.name.lowercased() == customShotTypeName.lowercased() && !$0.isArchived
        })
        // Disabled if: name is empty, OR at max AND name doesn't match existing
        if customShotTypeName.trimmingCharacters(in: .whitespaces).isEmpty { return true }
        if activeCount >= ClubDataService.maximumShotTypesPerClub && !nameMatchesExisting { return true }
        return false
    }
}
```

Add the alert modifier to the `NavigationStack`:

```swift
.alert("Maximum Shot Types", isPresented: $showMaxShotTypesAlert) {
    Button("OK", role: .cancel) {}
} message: {
    Text("This club already has the maximum number of shot types. You can still use an existing shot type name.")
}
```

- [ ] **Step 4: Update applyPreselectionIfNeeded for new startSession signature and shotTypeSelection**

Replace the entirety of `applyPreselectionIfNeeded()`:

```swift
private func applyPreselectionIfNeeded() {
    guard let clubName = navigationCoordinator.rangePreselectedClubName,
          let club = clubManager?.clubs.first(where: { $0.name == clubName }) else { return }
    selectedClub = club
    if let shotTypeName = navigationCoordinator.rangePreselectedShotTypeName,
       let shotType = club.shotTypes.first(where: { $0.name == shotTypeName }) {
        shotTypeSelection = .existing(shotType)
        if navigationCoordinator.rangeAutoStartSession {
            Task {
                await rangeManager?.startSession(
                    club: club,
                    shotType: shotType,
                    shotTypeName: shotType.name,
                    isCustom: false
                )
            }
        }
    }
    navigationCoordinator.clearRangePreselection()
}
```

- [ ] **Step 5: Build to check start session screen compiles**

Run: `xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add HTG/Features/RangeMode/Views/RangeModeView.swift
git commit -m "feat: add Other shot type option to Range Mode start session screen"
```

---

### Task 6: Rewrite RangeModeView — Active Session Layout

Restructure the in-session layout: header, shot entry + mic, End/Save buttons, two-column shots + stats. Add Save Session bottom sheet and End Session confirmation alert.

**Files:**
- Modify: `HTG/Features/RangeMode/Views/RangeModeView.swift`

- [ ] **Step 1: Add new state properties for session controls**

Add to the existing `@State` properties:

```swift
@State private var showingSaveSheet: Bool = false
@State private var saveDistanceText: String = ""
@State private var showingEndConfirmation: Bool = false
@FocusState private var isSaveFieldFocused: Bool
```

- [ ] **Step 2: Replace activeSessionView**

Replace the entire `activeSessionView` method:

```swift
private func activeSessionView(session: RangeSession) -> some View {
    VStack(spacing: 16) {
        // 1. Club name + shot type header
        sessionHeader(session: session)

        // 2. Distance input + Add Shot + Mic
        shotEntrySection

        // 3. End Session + Save Session buttons
        sessionActionButtons

        // 4. Two-column: Shots (left) + Stats (right)
        twoColumnSection(session: session)
    }
    .padding()
    .sheet(isPresented: $showingSaveSheet) {
        saveSessionSheet
    }
    .alert("Discard this session?", isPresented: $showingEndConfirmation) {
        Button("Discard", role: .destructive) {
            Task {
                await rangeManager?.endSession()
                selectedClub = nil
                shotTypeSelection = .none
                customShotTypeName = ""
            }
        }
        Button("Cancel", role: .cancel) {}
    } message: {
        Text("All shot data will be lost.")
    }
}
```

- [ ] **Step 3: Replace sessionHeader (keep centered)**

Already correct, no change needed. Existing implementation works.

- [ ] **Step 4: Update shotEntrySection with mic icon**

Replace `shotEntrySection`:

```swift
private var shotEntrySection: some View {
    HStack(spacing: 12) {
        TextField("Distance", text: $distanceText)
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)
            .frame(width: 100)

        Button("Add Shot") {
            addShot()
        }
        .buttonStyle(.borderedProminent)
        .disabled(distanceText.isEmpty)

        Button {
            toggleSpeechMode()
        } label: {
            Image(systemName: speechService.isListening ? "mic.fill" : "mic")
                .font(.system(size: 22))
                .foregroundStyle(speechService.isListening ? .red : .secondary)
        }
    }
}
```

- [ ] **Step 5: Add session action buttons**

Add new view:

```swift
private var sessionActionButtons: some View {
    HStack(spacing: 12) {
        Button {
            showingEndConfirmation = true
        } label: {
            Text("End Session")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)

        Button {
            saveDistanceText = "\(rangeManager?.currentStats.median ?? 0)"
            showingSaveSheet = true
        } label: {
            Text("Save Session")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled((rangeManager?.currentStats.count ?? 0) == 0)
    }
}
```

- [ ] **Step 6: Add two-column section**

Add new view:

```swift
private func twoColumnSection(session: RangeSession) -> some View {
    HStack(alignment: .top, spacing: 12) {
        // Left: Previous shots (~2/3)
        previousShotsList(session: session)
            .frame(maxWidth: .infinity)

        Divider()

        // Right: Stats (~1/3)
        statsColumn
            .frame(width: 80)
    }
}

private func previousShotsList(session: RangeSession) -> some View {
    VStack(alignment: .leading, spacing: 0) {
        Text("PREVIOUS SHOTS")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)

        let sortedShots = session.shots.sorted(by: { $0.date > $1.date })
        List {
            ForEach(sortedShots) { shot in
                HStack {
                    Text("\(shot.distance) yds")
                        .font(.body)

                    if shot.isFromVoice {
                        Image(systemName: "mic.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        Task { await rangeManager?.deleteShot(shot) }
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let shot = sortedShots[index]
                    Task { await rangeManager?.deleteShot(shot) }
                }
            }
        }
        .listStyle(.plain)
    }
}

private var statsColumn: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("STATS")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)

        if let current = rangeManager?.currentCarryDistance {
            statItem(label: "Current", value: current, color: .green)
        }

        statItem(label: "Count", value: rangeManager?.currentStats.count ?? 0)
        statItem(label: "Median", value: rangeManager?.currentStats.median ?? 0)
        statItem(label: "Max", value: rangeManager?.currentStats.max ?? 0)
        statItem(label: "75th", value: rangeManager?.currentStats.percentile75 ?? 0)
    }
}

private func statItem(label: String, value: Int, color: Color = .primary) -> some View {
    VStack(alignment: .leading, spacing: 2) {
        Text(label)
            .font(.caption2)
            .foregroundStyle(.secondary)
        Text("\(value)")
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(color)
    }
}
```

- [ ] **Step 7: Add Save Session bottom sheet**

Add new view:

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

        Spacer()
    }
    .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Go") {
                if let distance = Int(saveDistanceText), distance > 0 {
                    Task {
                        await rangeManager?.saveSession(carryDistance: distance)
                        showingSaveSheet = false
                        selectedClub = nil
                        shotTypeSelection = .none
                        customShotTypeName = ""
                    }
                }
            }
            .foregroundStyle(.green)
            .fontWeight(.semibold)
        }
    }
    .presentationDetents([.height(320)])
    .presentationDragIndicator(.visible)
    .onAppear {
        isSaveFieldFocused = true
    }
}
```

- [ ] **Step 8: Remove old statsDisplay, shotsList, endSessionButton, StatBox**

Delete these views since they're replaced:
- `statsDisplay` (old horizontal stats)
- `shotsList` (old List-based shots)
- `endSessionButton` (old standalone button)
- `StatBox` struct (replaced by `statItem` helper and `ShotTypeSelection` enum at the bottom of the file)
- `deleteShots(at:from:)` method (replaced by inline `.onDelete` in `previousShotsList`)

Also delete the old deprecated `startSession(clubName:shotTypeName:)` bridge method from `RangeManager.swift` (added in Task 4 Step 6) — it's no longer needed now that all call sites use the new signature.

- [ ] **Step 9: Add speechService placeholder so the build compiles**

Add these temporary placeholder properties and method to `RangeModeView` so it compiles before Task 7 provides the full implementation:

```swift
@State private var speechService = SpeechRecognitionService()
```

And add a placeholder `toggleSpeechMode` method:

```swift
private func toggleSpeechMode() {
    // Placeholder — full implementation in Task 7
}
```

- [ ] **Step 10: Build to verify compilation**

Run: `xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 11: Commit**

```bash
git add HTG/Features/RangeMode/Views/RangeModeView.swift HTG/Features/RangeMode/ViewModels/RangeManager.swift
git commit -m "feat: restructure Range Mode active session layout with two-column design and save sheet"
```

---

### Task 7: Wire Speech Recognition into RangeModeView

Connect the `SpeechRecognitionService` to the mic button with continuous mode, callbacks for auto-save, delete, and stop.

**Files:**
- Modify: `HTG/Features/RangeMode/Views/RangeModeView.swift`

- [ ] **Step 1: Add permission alert state**

The `@State private var speechService = SpeechRecognitionService()` property was already added as a placeholder in Task 6, Step 9. Add the missing alert state:

```swift
@State private var showPermissionDeniedAlert = false
```

- [ ] **Step 2: Replace toggleSpeechMode placeholder with full implementation**

Replace the placeholder `toggleSpeechMode()` method (added in Task 6, Step 9) with the full implementation:

```swift
private func toggleSpeechMode() {
    if speechService.isListening {
        speechService.continuousMode = false
        speechService.stopListening()
        return
    }

    Task {
        let authorized = await speechService.requestAuthorization()
        guard authorized else {
            showPermissionDeniedAlert = true
            return
        }

        // Configure continuous mode callbacks
        speechService.continuousMode = true
        speechService.onDistanceConfirmed = { @MainActor distance in
            Task {
                await rangeManager?.addShot(distance: distance, isFromVoice: true)
            }
        }
        speechService.onDeleteRequested = { @MainActor in
            Task {
                await rangeManager?.deleteLastShot()
            }
        }
        speechService.onStopRequested = { @MainActor in
            // Mic icon state updates automatically via speechService.isListening
        }

        try? await speechService.startListening()
    }
}
```

- [ ] **Step 3: Add permission denied alert**

Add to the `NavigationStack` modifiers:

```swift
.alert("Microphone Access Required", isPresented: $showPermissionDeniedAlert) {
    Button("OK", role: .cancel) {}
} message: {
    Text("HTG needs microphone and speech recognition access to use voice input. Enable these in Settings.")
}
```

- [ ] **Step 4: Build to verify compilation**

Run: `xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Run all tests**

Run: `xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing HTGTests 2>&1 | tail -20`
Expected: All PASS

- [ ] **Step 6: Commit**

```bash
git add HTG/Features/RangeMode/Views/RangeModeView.swift
git commit -m "feat: wire continuous speech recognition into Range Mode session view"
```

---

## Chunk 4: Info.plist Permissions & Final Verification

### Task 8: Add Info.plist Permission Keys

Add microphone and speech recognition usage descriptions to the Xcode project build settings.

**Files:**
- Modify: `HTG.xcodeproj/project.pbxproj`

- [ ] **Step 1: Add permission keys to Debug configuration**

In `HTG.xcodeproj/project.pbxproj`, find the Debug build configuration block (around line 813). After the line:

```
INFOPLIST_KEY_UILaunchScreen_Generation = YES;
```

Add:

```
INFOPLIST_KEY_NSMicrophoneUsageDescription = "HTG uses the microphone to listen for yardage distances you speak aloud.";
INFOPLIST_KEY_NSSpeechRecognitionUsageDescription = "HTG uses speech recognition to convert spoken yardage into a number.";
```

- [ ] **Step 2: Add permission keys to Release configuration**

Same as above but in the Release block (around line 843). After the line:

```
INFOPLIST_KEY_UILaunchScreen_Generation = YES;
```

Add the same two lines:

```
INFOPLIST_KEY_NSMicrophoneUsageDescription = "HTG uses the microphone to listen for yardage distances you speak aloud.";
INFOPLIST_KEY_NSSpeechRecognitionUsageDescription = "HTG uses speech recognition to convert spoken yardage into a number.";
```

- [ ] **Step 3: Build to verify**

Run: `xcodebuild clean build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add HTG.xcodeproj/project.pbxproj
git commit -m "feat: add microphone and speech recognition Info.plist permission keys"
```

---

### Task 9: Final Verification

Run full build and test suite to confirm everything works together.

**Files:** None (verification only)

- [ ] **Step 1: Clean build**

Run: `xcodebuild clean build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Run full test suite**

Run: `xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing HTGTests 2>&1 | tail -20`
Expected: All tests PASS

- [ ] **Step 3: Verify no references to old patterns**

Check that old `saveSessionAsStoredShotType` calls are removed:

Run: `grep -r "saveSessionAsStoredShotType" HTG/`
Expected: No matches (method was replaced by `saveSession(carryDistance:)`)

- [ ] **Step 4: Verify deleted code is clean**

Run: `grep -r "StatBox" HTG/`
Expected: No matches (struct was removed)

- [ ] **Step 5: Final commit if any cleanup needed**

Only if Steps 3-4 found issues. Otherwise, work is complete.
