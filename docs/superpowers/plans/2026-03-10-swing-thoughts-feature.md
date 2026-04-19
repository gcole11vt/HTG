# Swing Thoughts, Pre-Shot Routine & Mantra Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Pre-Shot Routine, Mantra, and Swing Thoughts features — managed in Profile, displayed in Golf Mode, with Swing Thoughts also addable from Club Detail.

**Architecture:** Two new SwiftData models (`PreShotRoutineItem`, `SwingThought`) with relationships to `UserProfile`. New fields on `UserProfile` for mantra and visibility toggles. Profile UI gets three new sections. Golf Mode left column gets three new display components. A shared `SwingThoughtDataService` handles CRUD for both Profile and Club Detail contexts.

**Tech Stack:** SwiftUI, SwiftData, `@Observable`, Swift Testing

---

## File Map

### New Files
- `HTG/Core/Models/PreShotRoutineItem.swift` — SwiftData model
- `HTG/Core/Models/SwingThought.swift` — SwiftData model
- `HTG/Core/Services/SwingThoughtDataService.swift` — CRUD for pre-shot routine, mantra, swing thoughts
- `HTG/UIComponents/GolfMode/PreShotRoutineView.swift` — Golf Mode display component
- `HTG/UIComponents/GolfMode/MantraView.swift` — Golf Mode display component
- `HTG/UIComponents/GolfMode/SwingThoughtsView.swift` — Golf Mode display component
- `HTGTests/SwingThoughtDataServiceTests.swift` — Tests for the service

### Modified Files
- `HTG/Core/Models/UserProfile.swift` — Add new fields and relationships
- `HTG/App/HTGApp.swift` — Register new models in schema
- `HTG/Core/Services/ProfileDataService.swift` — Seed default routine and mantra
- `HTG/Features/Profile/ViewModels/ProfileManager.swift` — Expose swing thought operations
- `HTG/Features/Profile/Views/ProfileView.swift` — Add three new sections
- `HTG/Features/ClubManagement/Views/ClubListView.swift` — Add swing thoughts to ClubDetailView
- `HTG/Features/GolfMode/ViewModels/GolfModeViewModel.swift` — Load and resolve swing thoughts
- `HTG/Features/GolfMode/Views/GolfModeView.swift` — Pass new data to page view
- `HTG/UIComponents/GolfMode/YardageBookPageView.swift` — Display new components
- `HTGTests/ProfileDataServiceTests.swift` — Update schema for new models

---

### Task 1: Create PreShotRoutineItem and SwingThought models

**Files:**
- Create: `HTG/Core/Models/PreShotRoutineItem.swift`
- Create: `HTG/Core/Models/SwingThought.swift`

- [ ] **Step 1: Create PreShotRoutineItem model**

Create file `HTG/Core/Models/PreShotRoutineItem.swift`:

```swift
import Foundation
import SwiftData

@Model
final class PreShotRoutineItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var sortOrder: Int
    @Relationship(inverse: \UserProfile.preShotRoutineItems) var profile: UserProfile?

    init(id: UUID = UUID(), text: String, sortOrder: Int, profile: UserProfile? = nil) {
        self.id = id
        self.text = text
        self.sortOrder = sortOrder
        self.profile = profile
    }
}
```

- [ ] **Step 2: Create SwingThought model**

Create file `HTG/Core/Models/SwingThought.swift`:

```swift
import Foundation
import SwiftData

@Model
final class SwingThought {
    @Attribute(.unique) var id: UUID
    var text: String
    var tagType: String
    var tagValue: String

    @Relationship(inverse: \UserProfile.swingThoughts) var profile: UserProfile?

    init(id: UUID = UUID(), text: String, tagType: String = "all", tagValue: String = "", profile: UserProfile? = nil) {
        self.id = id
        self.text = text
        self.tagType = tagType
        self.tagValue = tagValue
        self.profile = profile
    }
}
```

- [ ] **Step 3: Update UserProfile with new fields and relationships**

Modify `HTG/Core/Models/UserProfile.swift`. Add new properties and relationships:

```swift
import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var handicap: Int
    var primaryShotType: String
    var mantra: String
    var showPreShotRoutine: Bool
    var showMantra: Bool
    @Relationship(deleteRule: .cascade) var preShotRoutineItems: [PreShotRoutineItem]
    @Relationship(deleteRule: .cascade) var swingThoughts: [SwingThought]

    init(
        id: UUID = UUID(),
        name: String = "",
        handicap: Int = 18,
        primaryShotType: String = "Full",
        mantra: String = "Trust your swing",
        showPreShotRoutine: Bool = true,
        showMantra: Bool = true,
        preShotRoutineItems: [PreShotRoutineItem] = [],
        swingThoughts: [SwingThought] = []
    ) {
        self.id = id
        self.name = name
        self.handicap = handicap
        self.primaryShotType = primaryShotType
        self.mantra = mantra
        self.showPreShotRoutine = showPreShotRoutine
        self.showMantra = showMantra
        self.preShotRoutineItems = preShotRoutineItems
        self.swingThoughts = swingThoughts
    }
}
```

- [ ] **Step 4: Register new models in HTGApp schema**

Modify `HTG/App/HTGApp.swift`. Add `PreShotRoutineItem.self` and `SwingThought.self` to the schema array:

```swift
let schema = Schema([
    Club.self,
    ShotType.self,
    RangeSession.self,
    Shot.self,
    StoredShotType.self,
    UserProfile.self,
    AppSettings.self,
    PreShotRoutineItem.self,
    SwingThought.self
])
```

- [ ] **Step 5: Build and verify**

Run:
```bash
xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Commit**

```bash
git add HTG/Core/Models/PreShotRoutineItem.swift HTG/Core/Models/SwingThought.swift HTG/Core/Models/UserProfile.swift HTG/App/HTGApp.swift
git commit -m "feat: add PreShotRoutineItem and SwingThought models with UserProfile relationships"
```

---

### Task 2: Create SwingThoughtDataService with tests

**Files:**
- Create: `HTG/Core/Services/SwingThoughtDataService.swift`
- Create: `HTGTests/SwingThoughtDataServiceTests.swift`
- Modify: `HTG/Core/Services/ProfileDataService.swift`

- [ ] **Step 1: Write failing tests for SwingThoughtDataService**

Create `HTGTests/SwingThoughtDataServiceTests.swift`:

```swift
import Testing
import SwiftData
@testable import HTG

@Suite("SwingThoughtDataService Tests")
@MainActor
struct SwingThoughtDataServiceTests {

    private func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([UserProfile.self, PreShotRoutineItem.self, SwingThought.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeService(container: ModelContainer) -> SwingThoughtDataService {
        SwingThoughtDataService(modelContext: container.mainContext)
    }

    private func makeProfileService(container: ModelContainer) -> ProfileDataService {
        ProfileDataService(modelContext: container.mainContext)
    }

    // MARK: - Default Seeding

    @Test("Seed defaults creates pre-shot routine items")
    func seedDefaultsCreatesRoutineItems() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let profileService = makeProfileService(container: container)
        let profile = try await profileService.getOrCreateProfile()

        await service.seedDefaultsIfNeeded(for: profile)

        let items = profile.preShotRoutineItems.sorted { $0.sortOrder < $1.sortOrder }
        #expect(items.count == 4)
        #expect(items[0].text == "Pick target")
        #expect(items[1].text == "Visualize shot")
        #expect(items[2].text == "One practice swing")
        #expect(items[3].text == "Commit")
    }

    @Test("Seed defaults does not duplicate on second call")
    func seedDefaultsIdempotent() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let profileService = makeProfileService(container: container)
        let profile = try await profileService.getOrCreateProfile()

        await service.seedDefaultsIfNeeded(for: profile)
        await service.seedDefaultsIfNeeded(for: profile)

        #expect(profile.preShotRoutineItems.count == 4)
    }

    // MARK: - Pre-Shot Routine CRUD

    @Test("Add routine item appends to profile")
    func addRoutineItem() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let profileService = makeProfileService(container: container)
        let profile = try await profileService.getOrCreateProfile()

        try await service.addRoutineItem(to: profile, text: "Breathe")

        #expect(profile.preShotRoutineItems.count == 1)
        #expect(profile.preShotRoutineItems.first?.text == "Breathe")
    }

    @Test("Delete routine item removes from profile")
    func deleteRoutineItem() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let profileService = makeProfileService(container: container)
        let profile = try await profileService.getOrCreateProfile()

        try await service.addRoutineItem(to: profile, text: "Breathe")
        let item = profile.preShotRoutineItems.first!
        try await service.deleteRoutineItem(item)

        #expect(profile.preShotRoutineItems.isEmpty)
    }

    @Test("Reorder routine items updates sortOrder")
    func reorderRoutineItems() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let profileService = makeProfileService(container: container)
        let profile = try await profileService.getOrCreateProfile()

        try await service.addRoutineItem(to: profile, text: "First")
        try await service.addRoutineItem(to: profile, text: "Second")
        let items = profile.preShotRoutineItems.sorted { $0.sortOrder < $1.sortOrder }
        try await service.reorderRoutineItems(Array(items.reversed()))

        let reordered = profile.preShotRoutineItems.sorted { $0.sortOrder < $1.sortOrder }
        #expect(reordered[0].text == "Second")
        #expect(reordered[1].text == "First")
    }

    // MARK: - Swing Thought CRUD

    @Test("Add swing thought tagged to all")
    func addSwingThoughtAll() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let profileService = makeProfileService(container: container)
        let profile = try await profileService.getOrCreateProfile()

        try await service.addSwingThought(to: profile, text: "Push off left foot", tagType: "all", tagValue: "")

        #expect(profile.swingThoughts.count == 1)
        #expect(profile.swingThoughts.first?.tagType == "all")
    }

    @Test("Add swing thought tagged to club")
    func addSwingThoughtClub() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let profileService = makeProfileService(container: container)
        let profile = try await profileService.getOrCreateProfile()

        try await service.addSwingThought(to: profile, text: "Swing fast", tagType: "club", tagValue: "Driver")

        let thought = profile.swingThoughts.first!
        #expect(thought.tagType == "club")
        #expect(thought.tagValue == "Driver")
    }

    @Test("Delete swing thought removes from profile")
    func deleteSwingThought() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let profileService = makeProfileService(container: container)
        let profile = try await profileService.getOrCreateProfile()

        try await service.addSwingThought(to: profile, text: "Test", tagType: "all", tagValue: "")
        let thought = profile.swingThoughts.first!
        try await service.deleteSwingThought(thought)

        #expect(profile.swingThoughts.isEmpty)
    }

    // MARK: - Matching

    @Test("Matching returns thoughts tagged all, matching club, and matching shot type")
    func matchingSwingThoughts() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let profileService = makeProfileService(container: container)
        let profile = try await profileService.getOrCreateProfile()

        try await service.addSwingThought(to: profile, text: "All clubs", tagType: "all", tagValue: "")
        try await service.addSwingThought(to: profile, text: "Driver only", tagType: "club", tagValue: "Driver")
        try await service.addSwingThought(to: profile, text: "Full only", tagType: "shotType", tagValue: "Full")
        try await service.addSwingThought(to: profile, text: "3 Wood only", tagType: "club", tagValue: "3 Wood")

        let matches = service.matchingSwingThoughts(from: profile, clubName: "Driver", shotTypeName: "Full")

        #expect(matches.count == 3)
        #expect(matches.contains { $0.text == "All clubs" })
        #expect(matches.contains { $0.text == "Driver only" })
        #expect(matches.contains { $0.text == "Full only" })
        #expect(!matches.contains { $0.text == "3 Wood only" })
    }

    // MARK: - Mantra & Toggles

    @Test("Update mantra persists")
    func updateMantra() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let profileService = makeProfileService(container: container)
        let profile = try await profileService.getOrCreateProfile()

        try await service.updateMantra(for: profile, text: "Commit to the shot")

        #expect(profile.mantra == "Commit to the shot")
    }

    @Test("Toggle pre-shot routine visibility")
    func togglePreShotRoutine() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let profileService = makeProfileService(container: container)
        let profile = try await profileService.getOrCreateProfile()

        #expect(profile.showPreShotRoutine == true)
        try await service.setShowPreShotRoutine(for: profile, visible: false)
        #expect(profile.showPreShotRoutine == false)
    }

    @Test("Toggle mantra visibility")
    func toggleMantra() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let profileService = makeProfileService(container: container)
        let profile = try await profileService.getOrCreateProfile()

        #expect(profile.showMantra == true)
        try await service.setShowMantra(for: profile, visible: false)
        #expect(profile.showMantra == false)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:
```bash
xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing HTGTests/SwingThoughtDataServiceTests 2>&1 | tail -20
```
Expected: FAIL (SwingThoughtDataService not found)

- [ ] **Step 3: Create SwingThoughtDataService implementation**

Create `HTG/Core/Services/SwingThoughtDataService.swift`:

```swift
import Foundation
import SwiftData

@MainActor
final class SwingThoughtDataService: Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Default Seeding

    func seedDefaultsIfNeeded(for profile: UserProfile) async {
        guard profile.preShotRoutineItems.isEmpty else { return }

        let defaults = ["Pick target", "Visualize shot", "One practice swing", "Commit"]
        for (index, text) in defaults.enumerated() {
            let item = PreShotRoutineItem(text: text, sortOrder: index, profile: profile)
            modelContext.insert(item)
        }
        try? modelContext.save()
    }

    // MARK: - Pre-Shot Routine

    func addRoutineItem(to profile: UserProfile, text: String) async throws {
        let nextOrder = profile.preShotRoutineItems.count
        let item = PreShotRoutineItem(text: text, sortOrder: nextOrder, profile: profile)
        modelContext.insert(item)
        try modelContext.save()
    }

    func deleteRoutineItem(_ item: PreShotRoutineItem) async throws {
        modelContext.delete(item)
        try modelContext.save()
    }

    func reorderRoutineItems(_ items: [PreShotRoutineItem]) async throws {
        for (index, item) in items.enumerated() {
            item.sortOrder = index
        }
        try modelContext.save()
    }

    func updateRoutineItemText(_ item: PreShotRoutineItem, text: String) async throws {
        item.text = text
        try modelContext.save()
    }

    // MARK: - Swing Thoughts

    func addSwingThought(to profile: UserProfile, text: String, tagType: String, tagValue: String) async throws {
        let thought = SwingThought(text: text, tagType: tagType, tagValue: tagValue, profile: profile)
        modelContext.insert(thought)
        try modelContext.save()
    }

    func deleteSwingThought(_ thought: SwingThought) async throws {
        modelContext.delete(thought)
        try modelContext.save()
    }

    func matchingSwingThoughts(from profile: UserProfile, clubName: String, shotTypeName: String) -> [SwingThought] {
        profile.swingThoughts.filter { thought in
            switch thought.tagType {
            case "all":
                return true
            case "club":
                return thought.tagValue == clubName
            case "shotType":
                return thought.tagValue == shotTypeName
            default:
                return false
            }
        }
    }

    // MARK: - Mantra & Toggles

    func updateMantra(for profile: UserProfile, text: String) async throws {
        profile.mantra = text
        try modelContext.save()
    }

    func setShowPreShotRoutine(for profile: UserProfile, visible: Bool) async throws {
        profile.showPreShotRoutine = visible
        try modelContext.save()
    }

    func setShowMantra(for profile: UserProfile, visible: Bool) async throws {
        profile.showMantra = visible
        try modelContext.save()
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing HTGTests/SwingThoughtDataServiceTests 2>&1 | tail -20
```
Expected: All tests PASS

- [ ] **Step 5: Update ProfileDataServiceTests schema**

In `HTGTests/ProfileDataServiceTests.swift`, update `makeTestContainer` to include new models:

```swift
private func makeTestContainer() throws -> ModelContainer {
    let schema = Schema([UserProfile.self, PreShotRoutineItem.self, SwingThought.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}
```

- [ ] **Step 6: Run full test suite to verify nothing broke**

Run:
```bash
xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing HTGTests 2>&1 | tail -30
```
Expected: All tests PASS

- [ ] **Step 7: Commit**

```bash
git add HTG/Core/Services/SwingThoughtDataService.swift HTGTests/SwingThoughtDataServiceTests.swift HTGTests/ProfileDataServiceTests.swift
git commit -m "feat: add SwingThoughtDataService with full test coverage"
```

---

### Task 3: Add Profile UI sections for Pre-Shot Routine, Mantra, and Swing Thoughts

**Files:**
- Modify: `HTG/Features/Profile/ViewModels/ProfileManager.swift`
- Modify: `HTG/Features/Profile/Views/ProfileView.swift`

- [ ] **Step 1: Extend ProfileManager with swing thought operations**

Modify `HTG/Features/Profile/ViewModels/ProfileManager.swift` to add the `SwingThoughtDataService` and expose methods:

```swift
import Foundation
import SwiftData

@MainActor
@Observable
final class ProfileManager {
    private let service: ProfileDataService
    private let clubService: ClubDataService
    private let swingThoughtService: SwingThoughtDataService

    var profile: UserProfile?
    var shotTypeNames: [String] = []
    var clubNames: [String] = []
    var isLoading: Bool = false
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.service = ProfileDataService(modelContext: modelContext)
        self.clubService = ClubDataService(modelContext: modelContext)
        self.swingThoughtService = SwingThoughtDataService(modelContext: modelContext)
    }

    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            profile = try await service.getOrCreateProfile()
            if let profile {
                await swingThoughtService.seedDefaultsIfNeeded(for: profile)
            }
            shotTypeNames = try await clubService.fetchAllUniqueShotTypeNames()
            clubNames = try await clubService.fetchAllClubs().map(\.name)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateProfile(name: String, handicap: Int, primaryShotType: String? = nil) async {
        do {
            try await service.updateProfile(name: name, handicap: handicap, primaryShotType: primaryShotType)
            await loadProfile()
        } catch ProfileDataServiceError.invalidHandicap {
            errorMessage = "Handicap must be between 0 and 54"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Pre-Shot Routine

    func addRoutineItem(text: String) async {
        guard let profile else { return }
        do {
            try await swingThoughtService.addRoutineItem(to: profile, text: text)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteRoutineItem(_ item: PreShotRoutineItem) async {
        do {
            try await swingThoughtService.deleteRoutineItem(item)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reorderRoutineItems(_ items: [PreShotRoutineItem]) async {
        do {
            try await swingThoughtService.reorderRoutineItems(items)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateRoutineItemText(_ item: PreShotRoutineItem, text: String) async {
        do {
            try await swingThoughtService.updateRoutineItemText(item, text: text)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Mantra

    func updateMantra(_ text: String) async {
        guard let profile else { return }
        do {
            try await swingThoughtService.updateMantra(for: profile, text: text)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setShowPreShotRoutine(_ visible: Bool) async {
        guard let profile else { return }
        do {
            try await swingThoughtService.setShowPreShotRoutine(for: profile, visible: visible)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setShowMantra(_ visible: Bool) async {
        guard let profile else { return }
        do {
            try await swingThoughtService.setShowMantra(for: profile, visible: visible)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Swing Thoughts

    func addSwingThought(text: String, tagType: String, tagValue: String) async {
        guard let profile else { return }
        do {
            try await swingThoughtService.addSwingThought(to: profile, text: text, tagType: tagType, tagValue: tagValue)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteSwingThought(_ thought: SwingThought) async {
        do {
            try await swingThoughtService.deleteSwingThought(thought)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

- [ ] **Step 2: Add Pre-Shot Routine, Mantra, and Swing Thoughts sections to ProfileView**

Modify `HTG/Features/Profile/Views/ProfileView.swift`. Add state variables and new sections to the Form. The full updated file:

```swift
import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var profileManager: ProfileManager?
    @State private var nameText: String = ""
    @State private var handicapText: String = ""
    @State private var primaryShotTypeText: String = "Full"
    @State private var isEditing = false
    @State private var newRoutineItemText: String = ""
    @State private var showingAddSwingThought = false
    @State private var newSwingThoughtText: String = ""
    @State private var newSwingThoughtTagType: String = "all"
    @State private var newSwingThoughtTagValue: String = ""

    var body: some View {
        NavigationStack {
            Form {
                if let profile = profileManager?.profile {
                    profileSection(profile: profile)
                    preShotRoutineSection(profile: profile)
                    mantraSection(profile: profile)
                    swingThoughtsSection(profile: profile)
                    statsSection
                } else if profileManager?.isLoading == true {
                    Section {
                        ProgressView("Loading profile...")
                    }
                }
            }
            .navigationTitle("Profile")
            .task {
                if profileManager == nil {
                    profileManager = ProfileManager(modelContext: modelContext)
                    await profileManager?.loadProfile()
                    if let profile = profileManager?.profile {
                        nameText = profile.name
                        handicapText = "\(profile.handicap)"
                        primaryShotTypeText = profile.primaryShotType
                    }
                }
            }
            .alert("Error", isPresented: .init(
                get: { profileManager?.errorMessage != nil },
                set: { if !$0 { profileManager?.errorMessage = nil } }
            )) {
                Button("OK") { profileManager?.errorMessage = nil }
            } message: {
                Text(profileManager?.errorMessage ?? "")
            }
            .sheet(isPresented: $showingAddSwingThought) {
                addSwingThoughtSheet
            }
        }
    }

    // MARK: - Profile Section (existing, unchanged)

    private func profileSection(profile: UserProfile) -> some View {
        Section("Your Information") {
            if isEditing {
                TextField("Name", text: $nameText)
                HStack {
                    Text("Handicap")
                    Spacer()
                    TextField("0-54", text: $handicapText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
                if let shotTypeNames = profileManager?.shotTypeNames, !shotTypeNames.isEmpty {
                    Picker("Primary Shot Type", selection: $primaryShotTypeText) {
                        ForEach(shotTypeNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
                HStack {
                    Button("Cancel") {
                        nameText = profile.name
                        handicapText = "\(profile.handicap)"
                        primaryShotTypeText = profile.primaryShotType
                        isEditing = false
                    }
                    Spacer()
                    Button("Save") {
                        saveProfile()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(profile.name)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Handicap")
                    Spacer()
                    Text("\(profile.handicap)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Primary Shot Type")
                    Spacer()
                    Text(profile.primaryShotType)
                        .foregroundStyle(.secondary)
                }
                Button("Edit Profile") {
                    isEditing = true
                }
            }
        }
    }

    // MARK: - Pre-Shot Routine Section

    private func preShotRoutineSection(profile: UserProfile) -> some View {
        Section("Pre-Shot Routine") {
            Toggle("Show in Golf Mode", isOn: Binding(
                get: { profile.showPreShotRoutine },
                set: { newValue in
                    Task { await profileManager?.setShowPreShotRoutine(newValue) }
                }
            ))

            let sortedItems = profile.preShotRoutineItems.sorted { $0.sortOrder < $1.sortOrder }
            ForEach(sortedItems) { item in
                Text(item.text)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let item = sortedItems[index]
                    Task { await profileManager?.deleteRoutineItem(item) }
                }
            }
            .onMove { from, to in
                var reordered = sortedItems
                reordered.move(fromOffsets: from, toOffset: to)
                Task { await profileManager?.reorderRoutineItems(reordered) }
            }

            HStack {
                TextField("New step", text: $newRoutineItemText)
                Button("Add") {
                    guard !newRoutineItemText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    Task {
                        await profileManager?.addRoutineItem(text: newRoutineItemText)
                        newRoutineItemText = ""
                    }
                }
                .disabled(newRoutineItemText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Mantra Section

    private func mantraSection(profile: UserProfile) -> some View {
        Section("Mantra") {
            Toggle("Show in Golf Mode", isOn: Binding(
                get: { profile.showMantra },
                set: { newValue in
                    Task { await profileManager?.setShowMantra(newValue) }
                }
            ))

            TextField("Your mantra", text: Binding(
                get: { profile.mantra },
                set: { newValue in
                    Task { await profileManager?.updateMantra(newValue) }
                }
            ))
        }
    }

    // MARK: - Swing Thoughts Section

    private func swingThoughtsSection(profile: UserProfile) -> some View {
        Section("Swing Thoughts") {
            if profile.swingThoughts.isEmpty {
                Text("No swing thoughts yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(profile.swingThoughts) { thought in
                    HStack {
                        Text(thought.text)
                        Spacer()
                        Text(swingThoughtTagLabel(thought))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    let thoughts = Array(profile.swingThoughts)
                    for index in indexSet {
                        Task { await profileManager?.deleteSwingThought(thoughts[index]) }
                    }
                }
            }

            Button {
                showingAddSwingThought = true
            } label: {
                Label("Add Swing Thought", systemImage: "plus")
            }
        }
    }

    private func swingThoughtTagLabel(_ thought: SwingThought) -> String {
        switch thought.tagType {
        case "club": return thought.tagValue
        case "shotType": return thought.tagValue
        default: return "All"
        }
    }

    // MARK: - Add Swing Thought Sheet

    private var addSwingThoughtSheet: some View {
        NavigationStack {
            Form {
                TextField("Swing thought", text: $newSwingThoughtText)

                Picker("Applies to", selection: $newSwingThoughtTagType) {
                    Text("All Clubs").tag("all")
                    Text("Specific Club").tag("club")
                    Text("Shot Type").tag("shotType")
                }

                if newSwingThoughtTagType == "club" {
                    Picker("Club", selection: $newSwingThoughtTagValue) {
                        Text("Select Club").tag("")
                        ForEach(profileManager?.clubNames ?? [], id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                } else if newSwingThoughtTagType == "shotType" {
                    Picker("Shot Type", selection: $newSwingThoughtTagValue) {
                        Text("Select Shot Type").tag("")
                        ForEach(profileManager?.shotTypeNames ?? [], id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
            }
            .navigationTitle("Add Swing Thought")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetSwingThoughtForm()
                        showingAddSwingThought = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let tagValue = newSwingThoughtTagType == "all" ? "" : newSwingThoughtTagValue
                        Task {
                            await profileManager?.addSwingThought(
                                text: newSwingThoughtText,
                                tagType: newSwingThoughtTagType,
                                tagValue: tagValue
                            )
                            resetSwingThoughtForm()
                            showingAddSwingThought = false
                        }
                    }
                    .disabled(newSwingThoughtText.trimmingCharacters(in: .whitespaces).isEmpty ||
                              (newSwingThoughtTagType != "all" && newSwingThoughtTagValue.isEmpty))
                }
            }
        }
    }

    private func resetSwingThoughtForm() {
        newSwingThoughtText = ""
        newSwingThoughtTagType = "all"
        newSwingThoughtTagValue = ""
    }

    // MARK: - Existing sections

    private var statsSection: some View {
        Section("About Handicap") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your handicap represents your playing ability.")
                    .font(.subheadline)
                Text("Valid range: 0 (scratch) to 54 (beginner)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func saveProfile() {
        guard let handicap = Int(handicapText) else { return }
        Task {
            await profileManager?.updateProfile(
                name: nameText,
                handicap: handicap,
                primaryShotType: primaryShotTypeText
            )
            isEditing = false
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, Club.self, ShotType.self, PreShotRoutineItem.self, SwingThought.self], inMemory: true)
}
```

- [ ] **Step 3: Build and verify**

Run:
```bash
xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add HTG/Features/Profile/ViewModels/ProfileManager.swift HTG/Features/Profile/Views/ProfileView.swift
git commit -m "feat: add Pre-Shot Routine, Mantra, and Swing Thoughts sections to Profile"
```

---

### Task 4: Add Swing Thoughts section to ClubDetailView

**Files:**
- Modify: `HTG/Features/ClubManagement/Views/ClubListView.swift:129-274`

- [ ] **Step 1: Add swing thoughts state and section to ClubDetailView**

In `ClubDetailView`, add a `@State private var swingThoughtService` and `profileManager` properties, and a new "Swing Thoughts" section at the bottom of the List. Add state for adding new thoughts:

After the existing `@Environment(NavigationCoordinator.self)` line (~line 139), add:

```swift
@State private var swingThoughtService: SwingThoughtDataService?
@State private var profileManager: ProfileManager?
@State private var clubSwingThoughts: [SwingThought] = []
@State private var showingAddClubSwingThought = false
@State private var newClubSwingThoughtText: String = ""
@Environment(\.modelContext) private var modelContext
```

After the archived section in the List (before `.navigationTitle`), add:

```swift
Section("Swing Thoughts") {
    if clubSwingThoughts.isEmpty {
        Text("No swing thoughts for this club")
            .foregroundStyle(.secondary)
    } else {
        ForEach(clubSwingThoughts) { thought in
            Text(thought.text)
        }
        .onDelete { indexSet in
            for index in indexSet {
                let thought = clubSwingThoughts[index]
                Task {
                    await profileManager?.deleteSwingThought(thought)
                    await loadClubSwingThoughts()
                }
            }
        }
    }

    HStack {
        TextField("New swing thought", text: $newClubSwingThoughtText)
        Button("Add") {
            guard !newClubSwingThoughtText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            Task {
                await profileManager?.addSwingThought(
                    text: newClubSwingThoughtText,
                    tagType: "club",
                    tagValue: club.name
                )
                newClubSwingThoughtText = ""
                await loadClubSwingThoughts()
            }
        }
        .disabled(newClubSwingThoughtText.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}
```

Add a `.task` modifier to the List to initialize the service and load thoughts:

```swift
.task {
    if profileManager == nil {
        profileManager = ProfileManager(modelContext: modelContext)
        await profileManager?.loadProfile()
    }
    await loadClubSwingThoughts()
}
```

Add a helper function inside ClubDetailView:

```swift
private func loadClubSwingThoughts() async {
    guard let profile = profileManager?.profile else { return }
    clubSwingThoughts = profile.swingThoughts.filter { $0.tagType == "club" && $0.tagValue == club.name }
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
git add HTG/Features/ClubManagement/Views/ClubListView.swift
git commit -m "feat: add Swing Thoughts section to Club Detail page"
```

---

### Task 5: Create Golf Mode display components

**Files:**
- Create: `HTG/UIComponents/GolfMode/PreShotRoutineView.swift`
- Create: `HTG/UIComponents/GolfMode/MantraView.swift`
- Create: `HTG/UIComponents/GolfMode/SwingThoughtsView.swift`

- [ ] **Step 1: Create PreShotRoutineView**

Create `HTG/UIComponents/GolfMode/PreShotRoutineView.swift`:

```swift
import SwiftUI

struct PreShotRoutineView: View {
    let items: [PreShotRoutineItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pre-Shot Routine")
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(JournalTheme.mutedGray)

            let sorted = items.sorted { $0.sortOrder < $1.sortOrder }
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, item in
                Text("\(index + 1). \(item.text)")
                    .font(JournalTheme.handwritten(size: 16))
                    .foregroundStyle(JournalTheme.inkBlue.opacity(0.7))
            }
        }
    }
}
```

- [ ] **Step 2: Create MantraView**

Create `HTG/UIComponents/GolfMode/MantraView.swift`:

```swift
import SwiftUI

struct MantraView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(JournalTheme.handwritten(size: 18))
            .italic()
            .foregroundStyle(JournalTheme.inkBlue.opacity(0.8))
    }
}
```

- [ ] **Step 3: Create SwingThoughtsView**

Create `HTG/UIComponents/GolfMode/SwingThoughtsView.swift`:

```swift
import SwiftUI

struct SwingThoughtsView: View {
    let thoughts: [SwingThought]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Swing Thoughts")
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(JournalTheme.mutedGray)

            ForEach(thoughts) { thought in
                HStack(alignment: .top, spacing: 4) {
                    Text("\u{2022}")
                    Text(thought.text)
                }
                .font(JournalTheme.handwritten(size: 16))
                .foregroundStyle(JournalTheme.inkBlue.opacity(0.7))
            }
        }
    }
}
```

- [ ] **Step 4: Build and verify**

Run:
```bash
xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add HTG/UIComponents/GolfMode/PreShotRoutineView.swift HTG/UIComponents/GolfMode/MantraView.swift HTG/UIComponents/GolfMode/SwingThoughtsView.swift
git commit -m "feat: add PreShotRoutineView, MantraView, and SwingThoughtsView components"
```

---

### Task 6: Wire Golf Mode to display swing thoughts, routine, and mantra

**Files:**
- Modify: `HTG/Features/GolfMode/ViewModels/GolfModeViewModel.swift`
- Modify: `HTG/Features/GolfMode/Views/GolfModeView.swift`
- Modify: `HTG/UIComponents/GolfMode/YardageBookPageView.swift`

- [ ] **Step 1: Add profile data to GolfModeViewModel**

In `GolfModeViewModel`, add properties and loading logic. Add after the existing `private var primaryShotTypeName` line:

```swift
private let swingThoughtService: SwingThoughtDataService
var profile: UserProfile?
```

Update the `init` to create the service:

```swift
init(modelContext: ModelContext) {
    self.recommendationService = ShotRecommendationService()
    self.clubService = ClubDataService(modelContext: modelContext)
    self.profileService = ProfileDataService(modelContext: modelContext)
    self.swingThoughtService = SwingThoughtDataService(modelContext: modelContext)
}
```

Add computed properties for the display data:

```swift
var sortedRoutineItems: [PreShotRoutineItem] {
    profile?.preShotRoutineItems.sorted { $0.sortOrder < $1.sortOrder } ?? []
}

var showPreShotRoutine: Bool {
    profile?.showPreShotRoutine == true && !sortedRoutineItems.isEmpty
}

var showMantra: Bool {
    profile?.showMantra == true && !(profile?.mantra.isEmpty ?? true)
}

var mantraText: String {
    profile?.mantra ?? ""
}

var matchingSwingThoughts: [SwingThought] {
    guard let profile, let clubShot = displayedClubShot else { return [] }
    return swingThoughtService.matchingSwingThoughts(
        from: profile,
        clubName: clubShot.clubName,
        shotTypeName: clubShot.shotTypeName
    )
}
```

In `loadClubs()`, add profile loading after the existing profile fetch:

```swift
func loadClubs() async {
    isLoading = true
    do {
        clubs = try await clubService.fetchAllClubs()
        let loadedProfile = try await profileService.getOrCreateProfile()
        profile = loadedProfile
        primaryShotTypeName = loadedProfile.primaryShotType
        await swingThoughtService.seedDefaultsIfNeeded(for: loadedProfile)
        if let filter = ShotTypeFilter(rawValue: loadedProfile.primaryShotType) {
            selectedFilter = filter
        }
        updateRecommendations()
    } catch {
        errorMessage = error.localizedDescription
    }
    isLoading = false
}
```

- [ ] **Step 2: Pass new data through GolfModeView to YardageBookPageView**

In `GolfModeView`, update `yardageBookContent` to pass the new properties:

```swift
private func yardageBookContent(viewModel: GolfModeViewModel) -> some View {
    YardageBookPageView(
        targetYardage: Binding(
            get: { viewModel.targetYardage },
            set: { viewModel.setTargetYardage($0) }
        ),
        displayedClubShot: viewModel.displayedClubShot,
        showResetIndicator: viewModel.showResetIndicator,
        ladderMinYardage: viewModel.ladderMinYardage,
        ladderMaxYardage: viewModel.ladderMaxYardage,
        groupedLadderEntries: viewModel.groupedLadderEntries,
        clubs: viewModel.clubs,
        allShotTypeNames: viewModel.shotTypeNamesInBag,
        showPreShotRoutine: viewModel.showPreShotRoutine,
        routineItems: viewModel.sortedRoutineItems,
        showMantra: viewModel.showMantra,
        mantraText: viewModel.mantraText,
        matchingSwingThoughts: viewModel.matchingSwingThoughts,
        onSelectEntry: { entry in
            viewModel.selectClubShot(
                clubName: entry.clubName,
                shotTypeName: entry.shotTypeName,
                distance: entry.carryDistance
            )
        },
        onSelectClubShot: { selection in
            viewModel.selectClubShot(
                clubName: selection.clubName,
                shotTypeName: selection.shotTypeName,
                distance: selection.carryDistance
            )
        },
        onReset: {
            viewModel.resetToRecommendation()
        }
    )
}
```

- [ ] **Step 3: Update YardageBookPageView to accept and display new data**

In `YardageBookPageView`, add new properties after the existing ones:

```swift
var showPreShotRoutine: Bool = false
var routineItems: [PreShotRoutineItem] = []
var showMantra: Bool = false
var mantraText: String = ""
var matchingSwingThoughts: [SwingThought] = []
```

In the left column VStack, after the `ResetIndicatorView` block and before `Spacer()`, add:

```swift
if showPreShotRoutine {
    PreShotRoutineView(items: routineItems)
}

if showMantra {
    MantraView(text: mantraText)
}

if !matchingSwingThoughts.isEmpty {
    SwingThoughtsView(thoughts: matchingSwingThoughts)
}
```

- [ ] **Step 4: Build and verify**

Run:
```bash
xcodebuild build -project HTG.xcodeproj -scheme HTG -sdk iphonesimulator -quiet
```
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Run full test suite**

Run:
```bash
xcodebuild test -project HTG.xcodeproj -scheme HTG -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing HTGTests 2>&1 | tail -30
```
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add HTG/Features/GolfMode/ViewModels/GolfModeViewModel.swift HTG/Features/GolfMode/Views/GolfModeView.swift HTG/UIComponents/GolfMode/YardageBookPageView.swift
git commit -m "feat: display Pre-Shot Routine, Mantra, and Swing Thoughts in Golf Mode"
```
