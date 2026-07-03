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

    private func makeService(container: ModelContainer, store: FakeRemoteStore) -> SyncService {
        SyncService(
            modelContext: container.mainContext,
            remoteStore: store,
            userID: UUID(),
            defaults: UserDefaults(suiteName: "SyncServiceTests-\(UUID().uuidString)")!
        )
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
}
