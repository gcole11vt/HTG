import Foundation
import Testing
import SwiftData
@testable import HTG

/// In-memory stand-in for Supabase. Rows are stored JSON-encoded per table so
/// one fake serves every record type.
@MainActor
private final class FakeRemoteStore: SyncRemoteStore {
    var tables: [String: [UUID: Data]] = [:]
    var deletions: [RemoteDeletionRecord] = []
    var upsertedRecordCount = 0

    func seed<R: SyncRecord>(_ records: [R], into table: String) throws {
        for record in records {
            tables[table, default: [:]][record.id] = try JSONEncoder().encode(record)
        }
    }

    func rowIDs(in table: String) -> Set<UUID> {
        Set(tables[table, default: [:]].keys)
    }

    func fetchChanges<R: SyncRecord>(from table: String, since: Date?) async throws -> [R] {
        try tables[table, default: [:]].values.compactMap { data in
            let record = try JSONDecoder().decode(R.self, from: data)
            if let since, record.updatedAt <= since { return nil }
            return record
        }
    }

    func upsert<R: SyncRecord>(_ records: [R], into table: String) async throws {
        upsertedRecordCount += records.count
        try seed(records, into: table)
    }

    func deleteRows(ids: [UUID], from table: String) async throws {
        for id in ids {
            tables[table]?[id] = nil
        }
    }

    func fetchDeletions(since: Date?) async throws -> [RemoteDeletionRecord] {
        deletions.filter { deletion in
            since.map { deletion.deletedAt > $0 } ?? true
        }
    }

    func pushDeletions(_ newDeletions: [RemoteDeletionRecord]) async throws {
        deletions.append(contentsOf: newDeletions)
    }
}

@Suite("SyncService Tests")
@MainActor
struct SyncServiceTests {

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

    private func makeService(container: ModelContainer, store: FakeRemoteStore, defaults: UserDefaults? = nil) -> SyncService {
        SyncService(
            modelContext: container.mainContext,
            remoteStore: store,
            userID: UUID(),
            defaults: defaults ?? UserDefaults(suiteName: "SyncServiceTests-\(UUID().uuidString)")!
        )
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "SyncServiceTests-\(UUID().uuidString)")!
    }

    @Test("Pushes local clubs to the remote store")
    func pushesLocalClubs() async throws {
        let container = try makeTestContainer()
        let store = FakeRemoteStore()
        let service = makeService(container: container, store: store)
        let club = Club(name: "7 Iron", sortOrder: 0)
        container.mainContext.insert(club)
        try container.mainContext.save()

        try await service.syncAll()

        #expect(store.rowIDs(in: "clubs").contains(club.id))
    }

    @Test("Pulls remote clubs into the local store")
    func pullsRemoteClubs() async throws {
        let container = try makeTestContainer()
        let store = FakeRemoteStore()
        let service = makeService(container: container, store: store)
        let remoteID = UUID()
        try store.seed(
            [ClubRecord(id: remoteID, name: "Driver", nickname: "Big Dog", sortOrder: 0, isArchived: false, updatedAt: Date())],
            into: "clubs"
        )

        try await service.syncAll()

        let clubs = try container.mainContext.fetch(FetchDescriptor<Club>())
        let pulled = try #require(clubs.first { $0.id == remoteID })
        #expect(pulled.name == "Driver")
        #expect(pulled.nickname == "Big Dog")
    }

    @Test("Newer remote edit overwrites the local record")
    func appliesNewerRemoteEdit() async throws {
        let container = try makeTestContainer()
        let store = FakeRemoteStore()
        let service = makeService(container: container, store: store)
        let club = Club(name: "Old Name", sortOrder: 0)
        club.updatedAt = Date(timeIntervalSinceNow: -1000)
        container.mainContext.insert(club)
        try container.mainContext.save()
        try store.seed(
            [ClubRecord(id: club.id, name: "New Name", nickname: "", sortOrder: 0, isArchived: false, updatedAt: Date())],
            into: "clubs"
        )

        try await service.syncAll()

        #expect(club.name == "New Name")
    }

    @Test("Pushes local tombstones as remote deletions and clears them")
    func pushesLocalTombstones() async throws {
        let container = try makeTestContainer()
        let store = FakeRemoteStore()
        let service = makeService(container: container, store: store)
        let deadClubID = UUID()
        try store.seed(
            [ClubRecord(id: deadClubID, name: "Doomed", nickname: "", sortOrder: 0, isArchived: false, updatedAt: Date(timeIntervalSinceNow: -1000))],
            into: "clubs"
        )
        container.mainContext.insert(SyncTombstone(entity: .club, recordID: deadClubID))
        try container.mainContext.save()

        try await service.syncAll()

        #expect(!store.rowIDs(in: "clubs").contains(deadClubID))
        #expect(store.deletions.contains { $0.recordID == deadClubID && $0.entityName == "Club" })
        let tombstones = try container.mainContext.fetch(FetchDescriptor<SyncTombstone>())
        #expect(tombstones.isEmpty)
    }

    @Test("Applies remote deletions locally")
    func appliesRemoteDeletions() async throws {
        let container = try makeTestContainer()
        let store = FakeRemoteStore()
        let service = makeService(container: container, store: store)
        let club = Club(name: "Doomed", sortOrder: 0)
        club.updatedAt = Date(timeIntervalSinceNow: -1000)
        container.mainContext.insert(club)
        try container.mainContext.save()
        store.deletions = [RemoteDeletionRecord(recordID: club.id, entityName: "Club", deletedAt: Date())]

        try await service.syncAll()

        let clubs = try container.mainContext.fetch(FetchDescriptor<Club>())
        #expect(clubs.isEmpty)
    }

    @Test("Pulled shot types attach to their local club")
    func pulledShotTypesAttachToClub() async throws {
        let container = try makeTestContainer()
        let store = FakeRemoteStore()
        let service = makeService(container: container, store: store)
        let clubID = UUID()
        let shotTypeID = UUID()
        try store.seed(
            [ClubRecord(id: clubID, name: "7 Iron", nickname: "", sortOrder: 0, isArchived: false, updatedAt: Date())],
            into: "clubs"
        )
        try store.seed(
            [ShotTypeRecord(id: shotTypeID, clubID: clubID, name: "Full", carryDistance: 165, sortOrder: 0, isArchived: false, archivedDate: nil, updatedAt: Date())],
            into: "shot_types"
        )

        try await service.syncAll()

        let clubs = try container.mainContext.fetch(FetchDescriptor<Club>())
        let club = try #require(clubs.first { $0.id == clubID })
        #expect(club.shotTypes.contains { $0.id == shotTypeID && $0.carryDistance == 165 })
    }

    @Test("A second sync with no changes pushes nothing")
    func secondSyncPushesNothing() async throws {
        let container = try makeTestContainer()
        let store = FakeRemoteStore()
        let service = makeService(container: container, store: store)
        let club = Club(name: "7 Iron", sortOrder: 0)
        container.mainContext.insert(club)
        try container.mainContext.save()

        try await service.syncAll()
        let pushedAfterFirstSync = store.upsertedRecordCount

        try await service.syncAll()

        #expect(store.upsertedRecordCount == pushedAfterFirstSync)
    }

    // MARK: - First-sync seeded defaults

    @Test("First sync discards untouched seeded default clubs when the remote already has a bag")
    func firstSyncDiscardsSeededDefaults() async throws {
        let container = try makeTestContainer()
        let store = FakeRemoteStore()
        let defaults = makeDefaults()
        let clubService = ClubDataService(modelContext: container.mainContext, defaults: defaults)
        try await clubService.loadDefaultClubs()
        let remoteID = UUID()
        try store.seed(
            [ClubRecord(id: remoteID, name: "My 7 Iron", nickname: "Seven", sortOrder: 0, isArchived: false, updatedAt: Date())],
            into: "clubs"
        )
        let service = makeService(container: container, store: store, defaults: defaults)

        try await service.syncAll()

        let clubs = try container.mainContext.fetch(FetchDescriptor<Club>())
        #expect(clubs.count == 1)
        #expect(clubs.first?.id == remoteID)
        #expect(store.rowIDs(in: "clubs") == [remoteID])
    }

    @Test("First sync keeps seeded default clubs when the remote has no bag")
    func firstSyncKeepsSeededDefaultsWhenRemoteEmpty() async throws {
        let container = try makeTestContainer()
        let store = FakeRemoteStore()
        let defaults = makeDefaults()
        let clubService = ClubDataService(modelContext: container.mainContext, defaults: defaults)
        try await clubService.loadDefaultClubs()
        let service = makeService(container: container, store: store, defaults: defaults)

        try await service.syncAll()

        let clubs = try container.mainContext.fetch(FetchDescriptor<Club>())
        #expect(clubs.count == 13)
        #expect(store.rowIDs(in: "clubs").count == 13)
    }

    @Test("First sync keeps a seeded club the user has modified")
    func firstSyncKeepsModifiedSeededClub() async throws {
        let container = try makeTestContainer()
        let store = FakeRemoteStore()
        let defaults = makeDefaults()
        let clubService = ClubDataService(modelContext: container.mainContext, defaults: defaults)
        try await clubService.loadDefaultClubs()
        let clubs = try container.mainContext.fetch(FetchDescriptor<Club>())
        let modified = try #require(clubs.first { $0.name == "Driver" })
        modified.name = "My Custom Driver"
        modified.updatedAt = Date(timeIntervalSinceNow: 3600)
        try container.mainContext.save()
        let remoteID = UUID()
        try store.seed(
            [ClubRecord(id: remoteID, name: "My 7 Iron", nickname: "Seven", sortOrder: 0, isArchived: false, updatedAt: Date())],
            into: "clubs"
        )
        let service = makeService(container: container, store: store, defaults: defaults)

        try await service.syncAll()

        let remaining = try container.mainContext.fetch(FetchDescriptor<Club>())
        #expect(remaining.count == 2)
        #expect(remaining.contains { $0.id == modified.id && $0.name == "My Custom Driver" })
        #expect(remaining.contains { $0.id == remoteID })
    }

    // MARK: - Profile identity

    @Test("Sync consolidates duplicate profiles, keeping the personalized one")
    func syncConsolidatesDuplicateProfiles() async throws {
        let container = try makeTestContainer()
        let store = FakeRemoteStore()
        let service = makeService(container: container, store: store)
        let real = UserProfile(name: "Greg", handicap: 8)
        real.updatedAt = Date(timeIntervalSinceNow: -1000)
        let pristine = UserProfile()
        let strayItem = PreShotRoutineItem(text: "Pick target", sortOrder: 0, profile: pristine)
        container.mainContext.insert(real)
        container.mainContext.insert(pristine)
        container.mainContext.insert(strayItem)
        try container.mainContext.save()

        try await service.syncAll()

        let profiles = try container.mainContext.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.count == 1)
        #expect(profiles.first?.name == "Greg")
        #expect(profiles.first?.handicap == 8)
        let items = try container.mainContext.fetch(FetchDescriptor<PreShotRoutineItem>())
        #expect(items.isEmpty)
        #expect(!store.rowIDs(in: "user_profiles").contains(pristine.id))
        #expect(store.deletions.contains { $0.recordID == pristine.id && $0.entityName == "UserProfile" })
    }

    @Test("Fresh install pulls the remote profile without duplicating it")
    func freshInstallPullsRemoteProfileWithoutDuplicating() async throws {
        let container = try makeTestContainer()
        let store = FakeRemoteStore()
        let service = makeService(container: container, store: store)
        let autoCreated = UserProfile()
        let seededItem = PreShotRoutineItem(text: "Pick target", sortOrder: 0, profile: autoCreated)
        container.mainContext.insert(autoCreated)
        container.mainContext.insert(seededItem)
        try container.mainContext.save()
        let remoteProfileID = UUID()
        let remoteItemID = UUID()
        try store.seed(
            [UserProfileRecord(id: remoteProfileID, name: "Greg", handicap: 8, primaryShotType: "Full", mantra: "Trust your swing", showPreShotRoutine: true, showMantra: true, updatedAt: Date())],
            into: "user_profiles"
        )
        try store.seed(
            [PreShotRoutineItemRecord(id: remoteItemID, profileID: remoteProfileID, text: "Breathe", sortOrder: 0, updatedAt: Date())],
            into: "pre_shot_routine_items"
        )

        try await service.syncAll()

        let profiles = try container.mainContext.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.count == 1)
        let profile = try #require(profiles.first)
        #expect(profile.id == remoteProfileID)
        #expect(profile.name == "Greg")
        #expect(profile.handicap == 8)
        let items = try container.mainContext.fetch(FetchDescriptor<PreShotRoutineItem>())
        #expect(items.count == 1)
        #expect(items.first?.text == "Breathe")
        #expect(items.first?.profile?.id == remoteProfileID)
        #expect(!store.rowIDs(in: "user_profiles").contains(autoCreated.id))
    }

    @Test("Pulled remote profile applies its Golf Mode view style")
    func pulledProfileAppliesViewStyle() async throws {
        let container = try makeTestContainer()
        let store = FakeRemoteStore()
        let service = makeService(container: container, store: store)
        try store.seed(
            [UserProfileRecord(id: UUID(), name: "Greg", handicap: 8, primaryShotType: "Full", mantra: "Trust your swing", showPreShotRoutine: true, showMantra: true, updatedAt: Date(), golfModeViewStyle: "ladder")],
            into: "user_profiles"
        )

        try await service.syncAll()

        let profiles = try container.mainContext.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.first?.golfModeViewStyle == .ladder)
    }

    @Test("Local Golf Mode view style change is pushed to the remote")
    func localViewStyleIsPushed() async throws {
        let container = try makeTestContainer()
        let store = FakeRemoteStore()
        let service = makeService(container: container, store: store)
        let profileService = ProfileDataService(modelContext: container.mainContext)
        try await profileService.updateProfile(name: "Greg", handicap: 8)
        try await profileService.updateGolfModeViewStyle(.ladder)

        try await service.syncAll()

        let profileID = try #require(try container.mainContext.fetch(FetchDescriptor<UserProfile>()).first?.id)
        let data = try #require(store.tables["user_profiles", default: [:]][profileID])
        let record = try JSONDecoder().decode(UserProfileRecord.self, from: data)
        #expect(record.golfModeViewStyle == "ladder")
    }
}
