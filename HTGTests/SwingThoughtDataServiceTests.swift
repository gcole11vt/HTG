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

    @Test("Toggle swing thoughts visibility")
    func toggleSwingThoughts() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let profileService = makeProfileService(container: container)
        let profile = try await profileService.getOrCreateProfile()

        #expect(profile.showSwingThoughts == true)
        try await service.setShowSwingThoughts(for: profile, visible: false)
        #expect(profile.showSwingThoughts == false)
        try await service.setShowSwingThoughts(for: profile, visible: true)
        #expect(profile.showSwingThoughts == true)
    }
}
