import Foundation
import Testing
import SwiftData
@testable import HTG

/// Verifies that every mutating service method refreshes `updatedAt` on the
/// touched entity and that hard-deletes record a `SyncTombstone`, so the
/// Supabase sync layer can detect changed and deleted records.
@Suite("Sync Touch Tests")
@MainActor
struct SyncTouchTests {

    private func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([
            Club.self,
            ShotType.self,
            RangeSession.self,
            Shot.self,
            UserProfile.self,
            AppSettings.self,
            PreShotRoutineItem.self,
            SwingThought.self,
            SyncTombstone.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func fetchTombstones(in context: ModelContext) throws -> [SyncTombstone] {
        var descriptor = FetchDescriptor<SyncTombstone>()
        descriptor.includePendingChanges = true
        return try context.fetch(descriptor)
    }

    private let stale = Date.distantPast
    private var recent: Date { Date().addingTimeInterval(-5) }

    // MARK: - ClubDataService

    @Test("updateClub refreshes updatedAt")
    func updateClubRefreshesUpdatedAt() async throws {
        let container = try makeTestContainer()
        let service = ClubDataService(modelContext: container.mainContext)
        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        club.updatedAt = stale

        try await service.updateClub(club, name: "Seven Iron")

        #expect(club.updatedAt > recent)
    }

    @Test("archiveClub and restoreClub refresh updatedAt")
    func archiveAndRestoreClubRefreshUpdatedAt() async throws {
        let container = try makeTestContainer()
        let service = ClubDataService(modelContext: container.mainContext)
        let club = try await service.addClub(name: "Driver", defaultDistance: 250)

        club.updatedAt = stale
        try await service.archiveClub(club)
        #expect(club.updatedAt > recent)

        club.updatedAt = stale
        try await service.restoreClub(club)
        #expect(club.updatedAt > recent)
    }

    @Test("reorderClubs refreshes updatedAt on every club")
    func reorderClubsRefreshesUpdatedAt() async throws {
        let container = try makeTestContainer()
        let service = ClubDataService(modelContext: container.mainContext)
        let first = try await service.addClub(name: "Driver", defaultDistance: 250)
        let second = try await service.addClub(name: "3 Wood", defaultDistance: 230)
        first.updatedAt = stale
        second.updatedAt = stale

        try await service.reorderClubs([second, first])

        #expect(first.updatedAt > recent)
        #expect(second.updatedAt > recent)
    }

    @Test("updateShotType refreshes shot type updatedAt")
    func updateShotTypeRefreshesUpdatedAt() async throws {
        let container = try makeTestContainer()
        let service = ClubDataService(modelContext: container.mainContext)
        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        let shotType = try #require(club.shotTypes.first)
        shotType.updatedAt = stale

        try await service.updateShotType(shotType, name: "Full", distance: 170)

        #expect(shotType.updatedAt > recent)
    }

    @Test("archiveShotType refreshes shot type updatedAt")
    func archiveShotTypeRefreshesUpdatedAt() async throws {
        let container = try makeTestContainer()
        let service = ClubDataService(modelContext: container.mainContext)
        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        try await service.addShotType(to: club, name: "3/4", distance: 150)
        let shotType = try #require(club.shotTypes.first { $0.name == "3/4" })
        shotType.updatedAt = stale

        try await service.archiveShotType(shotType, from: club)

        #expect(shotType.updatedAt > recent)
    }

    @Test("deleteClub records a Club tombstone")
    func deleteClubRecordsTombstone() async throws {
        let container = try makeTestContainer()
        let service = ClubDataService(modelContext: container.mainContext)
        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        let clubID = club.id

        try await service.deleteClub(club)

        let tombstones = try fetchTombstones(in: container.mainContext)
        #expect(tombstones.contains { $0.entityName == "Club" && $0.recordID == clubID })
    }

    @Test("purgeExpiredShotTypes records ShotType tombstones")
    func purgeExpiredShotTypesRecordsTombstones() async throws {
        let container = try makeTestContainer()
        let service = ClubDataService(modelContext: container.mainContext)
        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        try await service.addShotType(to: club, name: "3/4", distance: 150)
        let shotType = try #require(club.shotTypes.first { $0.name == "3/4" })
        let shotTypeID = shotType.id
        try await service.archiveShotType(shotType, from: club)
        shotType.archivedDate = Calendar.current.date(byAdding: .day, value: -8, to: Date())

        try await service.purgeExpiredShotTypes()

        let tombstones = try fetchTombstones(in: container.mainContext)
        #expect(tombstones.contains { $0.entityName == "ShotType" && $0.recordID == shotTypeID })
    }

    // MARK: - RangeDataService

    @Test("updateShotTypeCarryDistance refreshes shot type updatedAt")
    func updateCarryDistanceRefreshesUpdatedAt() async throws {
        let container = try makeTestContainer()
        let clubService = ClubDataService(modelContext: container.mainContext)
        let rangeService = RangeDataService(modelContext: container.mainContext)
        let club = try await clubService.addClub(name: "7 Iron", defaultDistance: 165)
        let shotType = try #require(club.shotTypes.first)
        shotType.updatedAt = stale

        try await rangeService.updateShotTypeCarryDistance(shotType, distance: 172)

        #expect(shotType.updatedAt > recent)
    }

    @Test("deleteShot records a Shot tombstone")
    func deleteShotRecordsTombstone() async throws {
        let container = try makeTestContainer()
        let service = RangeDataService(modelContext: container.mainContext)
        let session = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")
        try await service.addShot(to: session, distance: 165, isFromVoice: false)
        let shot = try #require(session.shots.first)
        let shotID = shot.id

        try await service.deleteShot(shot, from: session)

        let tombstones = try fetchTombstones(in: container.mainContext)
        #expect(tombstones.contains { $0.entityName == "Shot" && $0.recordID == shotID })
    }

    @Test("deleteSession records a RangeSession tombstone")
    func deleteSessionRecordsTombstone() async throws {
        let container = try makeTestContainer()
        let service = RangeDataService(modelContext: container.mainContext)
        let session = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")
        let sessionID = session.id

        try await service.deleteSession(session)

        let tombstones = try fetchTombstones(in: container.mainContext)
        #expect(tombstones.contains { $0.entityName == "RangeSession" && $0.recordID == sessionID })
    }

    // MARK: - ProfileDataService

    @Test("updateGolfModeViewStyle refreshes profile updatedAt")
    func updateGolfModeViewStyleRefreshesUpdatedAt() async throws {
        let container = try makeTestContainer()
        let service = ProfileDataService(modelContext: container.mainContext)
        let profile = try await service.getOrCreateProfile()
        profile.updatedAt = stale

        try await service.updateGolfModeViewStyle(.ladder)

        #expect(profile.updatedAt > recent)
    }

    @Test("updateProfile refreshes profile updatedAt")
    func updateProfileRefreshesUpdatedAt() async throws {
        let container = try makeTestContainer()
        let service = ProfileDataService(modelContext: container.mainContext)
        let profile = try await service.getOrCreateProfile()
        profile.updatedAt = stale

        try await service.updateProfile(name: "Greg", handicap: 12)

        #expect(profile.updatedAt > recent)
    }

    // MARK: - SwingThoughtDataService

    @Test("updateRoutineItemText refreshes item updatedAt")
    func updateRoutineItemTextRefreshesUpdatedAt() async throws {
        let container = try makeTestContainer()
        let profileService = ProfileDataService(modelContext: container.mainContext)
        let service = SwingThoughtDataService(modelContext: container.mainContext)
        let profile = try await profileService.getOrCreateProfile()
        try await service.addRoutineItem(to: profile, text: "Pick target")
        let item = try #require(profile.preShotRoutineItems.first)
        item.updatedAt = stale

        try await service.updateRoutineItemText(item, text: "Pick a small target")

        #expect(item.updatedAt > recent)
    }

    @Test("reorderRoutineItems refreshes updatedAt on every item")
    func reorderRoutineItemsRefreshesUpdatedAt() async throws {
        let container = try makeTestContainer()
        let profileService = ProfileDataService(modelContext: container.mainContext)
        let service = SwingThoughtDataService(modelContext: container.mainContext)
        let profile = try await profileService.getOrCreateProfile()
        try await service.addRoutineItem(to: profile, text: "One")
        try await service.addRoutineItem(to: profile, text: "Two")
        let items = profile.preShotRoutineItems.sorted { $0.sortOrder < $1.sortOrder }
        items.forEach { $0.updatedAt = stale }

        try await service.reorderRoutineItems(items.reversed())

        #expect(items.allSatisfy { $0.updatedAt > recent })
    }

    @Test("deleteRoutineItem records a PreShotRoutineItem tombstone")
    func deleteRoutineItemRecordsTombstone() async throws {
        let container = try makeTestContainer()
        let profileService = ProfileDataService(modelContext: container.mainContext)
        let service = SwingThoughtDataService(modelContext: container.mainContext)
        let profile = try await profileService.getOrCreateProfile()
        try await service.addRoutineItem(to: profile, text: "Pick target")
        let item = try #require(profile.preShotRoutineItems.first)
        let itemID = item.id

        try await service.deleteRoutineItem(item)

        let tombstones = try fetchTombstones(in: container.mainContext)
        #expect(tombstones.contains { $0.entityName == "PreShotRoutineItem" && $0.recordID == itemID })
    }

    @Test("deleteSwingThought records a SwingThought tombstone")
    func deleteSwingThoughtRecordsTombstone() async throws {
        let container = try makeTestContainer()
        let profileService = ProfileDataService(modelContext: container.mainContext)
        let service = SwingThoughtDataService(modelContext: container.mainContext)
        let profile = try await profileService.getOrCreateProfile()
        try await service.addSwingThought(to: profile, text: "Smooth tempo", tagType: "all", tagValue: "")
        let thought = try #require(profile.swingThoughts.first)
        let thoughtID = thought.id

        try await service.deleteSwingThought(thought)

        let tombstones = try fetchTombstones(in: container.mainContext)
        #expect(tombstones.contains { $0.entityName == "SwingThought" && $0.recordID == thoughtID })
    }

    @Test("updateMantra and visibility toggles refresh profile updatedAt")
    func mantraAndTogglesRefreshProfileUpdatedAt() async throws {
        let container = try makeTestContainer()
        let profileService = ProfileDataService(modelContext: container.mainContext)
        let service = SwingThoughtDataService(modelContext: container.mainContext)
        let profile = try await profileService.getOrCreateProfile()

        profile.updatedAt = stale
        try await service.updateMantra(for: profile, text: "Commit to the shot")
        #expect(profile.updatedAt > recent)

        profile.updatedAt = stale
        try await service.setShowPreShotRoutine(for: profile, visible: false)
        #expect(profile.updatedAt > recent)

        profile.updatedAt = stale
        try await service.setShowMantra(for: profile, visible: false)
        #expect(profile.updatedAt > recent)
    }

    // MARK: - AppSettingsService

    @Test("updateYardageRangePercentage refreshes settings updatedAt")
    func updateYardagePercentageRefreshesUpdatedAt() async throws {
        let container = try makeTestContainer()
        let service = AppSettingsService(modelContext: container.mainContext)
        let settings = try await service.getOrCreateSettings()
        settings.updatedAt = stale

        try await service.updateYardageRangePercentage(20)

        #expect(settings.updatedAt > recent)
    }
}
