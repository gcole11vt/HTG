import Foundation
import Testing
import SwiftData
@testable import HTG

@Suite("ProfileDataService Tests")
@MainActor
struct ProfileDataServiceTests {

    private func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([UserProfile.self, PreShotRoutineItem.self, SwingThought.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeService(container: ModelContainer) -> ProfileDataService {
        ProfileDataService(modelContext: container.mainContext)
    }

    @Test("Get or create profile creates new profile when none exists")
    func getOrCreateProfileCreatesNew() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let profile = try await service.getOrCreateProfile()

        #expect(profile.name == "")
        #expect(profile.handicap == 18)
    }

    @Test("Get or create profile returns existing profile")
    func getOrCreateProfileReturnsExisting() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let profile1 = try await service.getOrCreateProfile()
        try await service.updateProfile(name: "John Doe", handicap: 12)

        let profile2 = try await service.getOrCreateProfile()

        #expect(profile1.id == profile2.id)
        #expect(profile2.name == "John Doe")
        #expect(profile2.handicap == 12)
    }

    @Test("Update profile changes name")
    func updateProfileChangesName() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        _ = try await service.getOrCreateProfile()
        try await service.updateProfile(name: "Jane Doe", handicap: 18)

        let profile = try await service.getOrCreateProfile()
        #expect(profile.name == "Jane Doe")
    }

    @Test("Update profile changes handicap")
    func updateProfileChangesHandicap() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        _ = try await service.getOrCreateProfile()
        try await service.updateProfile(name: "", handicap: 10)

        let profile = try await service.getOrCreateProfile()
        #expect(profile.handicap == 10)
    }

    @Test("Update profile validates handicap minimum of 0")
    func updateProfileValidatesHandicapMinimum() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        _ = try await service.getOrCreateProfile()

        await #expect(throws: ProfileDataServiceError.invalidHandicap) {
            try await service.updateProfile(name: "", handicap: -1)
        }
    }

    @Test("Update profile validates handicap maximum of 54")
    func updateProfileValidatesHandicapMaximum() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        _ = try await service.getOrCreateProfile()

        await #expect(throws: ProfileDataServiceError.invalidHandicap) {
            try await service.updateProfile(name: "", handicap: 55)
        }
    }

    @Test("Update profile accepts handicap at boundary 0")
    func updateProfileAcceptsHandicapZero() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        _ = try await service.getOrCreateProfile()
        try await service.updateProfile(name: "", handicap: 0)

        let profile = try await service.getOrCreateProfile()
        #expect(profile.handicap == 0)
    }

    @Test("Update profile accepts handicap at boundary 54")
    func updateProfileAcceptsHandicapMax() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        _ = try await service.getOrCreateProfile()
        try await service.updateProfile(name: "", handicap: 54)

        let profile = try await service.getOrCreateProfile()
        #expect(profile.handicap == 54)
    }

    @Test("New profile defaults primaryShotType to Full")
    func newProfileDefaultsPrimaryShotTypeToFull() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let profile = try await service.getOrCreateProfile()

        #expect(profile.primaryShotType == "Full")
    }

    @Test("Update profile changes primaryShotType")
    func updateProfileChangesPrimaryShotType() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        _ = try await service.getOrCreateProfile()
        try await service.updateProfile(name: "", handicap: 18, primaryShotType: "3/4")

        let profile = try await service.getOrCreateProfile()
        #expect(profile.primaryShotType == "3/4")
    }

    @Test("Get or create profile prefers a personalized profile over a pristine duplicate")
    func getOrCreateProfilePrefersPersonalized() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let pristine = UserProfile()
        let named = UserProfile(name: "Greg", handicap: 8)
        named.updatedAt = Date(timeIntervalSinceNow: -1000)
        container.mainContext.insert(pristine)
        container.mainContext.insert(named)
        try container.mainContext.save()

        let profile = try await service.getOrCreateProfile()

        #expect(profile.id == named.id)
        #expect(profile.name == "Greg")
    }

    // MARK: - Golf Mode View Style

    @Test("New profile defaults Golf Mode view style to Text")
    func newProfileDefaultsViewStyleToText() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let profile = try await service.getOrCreateProfile()

        #expect(profile.golfModeViewStyle == .text)
        #expect(profile.golfModeViewStyleRawValue == "text")
    }

    @Test("Update Golf Mode view style persists Ladder")
    func updateViewStylePersistsLadder() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        try await service.updateGolfModeViewStyle(.ladder)
        let profile = try await service.getOrCreateProfile()

        #expect(profile.golfModeViewStyle == .ladder)
        #expect(profile.golfModeViewStyleRawValue == "ladder")
    }

    @Test("Golf Mode view style falls back to Text for an unrecognized stored value")
    func unrecognizedViewStyleFallsBackToText() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)
        let profile = try await service.getOrCreateProfile()

        profile.golfModeViewStyleRawValue = "bogus"

        #expect(profile.golfModeViewStyle == .text)
    }
}
