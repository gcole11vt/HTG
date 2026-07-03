import Foundation
import SwiftData

/// Orchestrates one full push/pull cycle between the local SwiftData store
/// and the remote. SwiftData stays the offline source of truth; the merge
/// itself is pure logic in `SyncEngine`.
///
/// Entities sync parents before children so pulled child records can resolve
/// their relationships against already-applied parents.
@MainActor
final class SyncService {
    private let modelContext: ModelContext
    private let remoteStore: any SyncRemoteStore
    private let userID: UUID
    private let defaults: UserDefaults

    init(
        modelContext: ModelContext,
        remoteStore: any SyncRemoteStore,
        userID: UUID,
        defaults: UserDefaults = .standard
    ) {
        self.modelContext = modelContext
        self.remoteStore = remoteStore
        self.userID = userID
        self.defaults = defaults
    }

    // MARK: - Last sync bookkeeping

    private var lastSyncedAtKey: String { "HTGSync.lastSyncedAt.\(userID.uuidString)" }

    private(set) var lastSyncedAt: Date? {
        get { defaults.object(forKey: lastSyncedAtKey) as? Date }
        set { defaults.set(newValue, forKey: lastSyncedAtKey) }
    }

    // MARK: - Sync

    func syncAll() async throws {
        let since = lastSyncedAt
        let syncStart = Date()
        let remoteDeletions = try await remoteStore.fetchDeletions(since: since)

        try await syncUserProfiles(since: since, remoteDeletions: remoteDeletions)
        try await syncClubs(since: since, remoteDeletions: remoteDeletions)
        try await syncShotTypes(since: since, remoteDeletions: remoteDeletions)
        try await syncRangeSessions(since: since, remoteDeletions: remoteDeletions)
        try await syncShots(since: since, remoteDeletions: remoteDeletions)
        try await syncPreShotRoutineItems(since: since, remoteDeletions: remoteDeletions)
        try await syncSwingThoughts(since: since, remoteDeletions: remoteDeletions)
        try await syncAppSettings(since: since, remoteDeletions: remoteDeletions)

        lastSyncedAt = syncStart
    }

    // MARK: - Per-entity passes

    private func syncUserProfiles(since: Date?, remoteDeletions: [RemoteDeletionRecord]) async throws {
        try await syncEntity(
            table: "user_profiles",
            entity: .userProfile,
            since: since,
            remoteDeletions: remoteDeletions,
            modelID: { $0.id },
            makeRecord: UserProfileRecord.init(from:),
            applyRecord: { $0.apply(to: $1) },
            insertModel: { record in
                let profile = UserProfile(id: record.id)
                record.apply(to: profile)
                self.modelContext.insert(profile)
            }
        )
    }

    private func syncClubs(since: Date?, remoteDeletions: [RemoteDeletionRecord]) async throws {
        try await syncEntity(
            table: "clubs",
            entity: .club,
            since: since,
            remoteDeletions: remoteDeletions,
            modelID: { $0.id },
            makeRecord: ClubRecord.init(from:),
            applyRecord: { $0.apply(to: $1) },
            insertModel: { record in
                let club = Club(id: record.id, name: record.name, sortOrder: record.sortOrder)
                record.apply(to: club)
                self.modelContext.insert(club)
            }
        )
    }

    private func syncShotTypes(since: Date?, remoteDeletions: [RemoteDeletionRecord]) async throws {
        try await syncEntity(
            table: "shot_types",
            entity: .shotType,
            since: since,
            remoteDeletions: remoteDeletions,
            modelID: { $0.id },
            makeRecord: ShotTypeRecord.init(from:),
            applyRecord: { $0.apply(to: $1) },
            insertModel: { record in
                let shotType = ShotType(
                    id: record.id,
                    name: record.name,
                    carryDistance: record.carryDistance,
                    sortOrder: record.sortOrder
                )
                record.apply(to: shotType)
                self.modelContext.insert(shotType)
                if let clubID = record.clubID {
                    shotType.club = self.fetchClub(id: clubID)
                }
            }
        )
    }

    private func syncRangeSessions(since: Date?, remoteDeletions: [RemoteDeletionRecord]) async throws {
        try await syncEntity(
            table: "range_sessions",
            entity: .rangeSession,
            since: since,
            remoteDeletions: remoteDeletions,
            modelID: { $0.id },
            makeRecord: RangeSessionRecord.init(from:),
            applyRecord: { $0.apply(to: $1) },
            insertModel: { record in
                let session = RangeSession(id: record.id, clubName: record.clubName, shotTypeName: record.shotTypeName)
                record.apply(to: session)
                self.modelContext.insert(session)
            }
        )
    }

    private func syncShots(since: Date?, remoteDeletions: [RemoteDeletionRecord]) async throws {
        try await syncEntity(
            table: "shots",
            entity: .shot,
            since: since,
            remoteDeletions: remoteDeletions,
            modelID: { $0.id },
            makeRecord: ShotRecord.init(from:),
            applyRecord: { $0.apply(to: $1) },
            insertModel: { record in
                let shot = Shot(id: record.id, distance: record.distance)
                record.apply(to: shot)
                self.modelContext.insert(shot)
                if let sessionID = record.sessionID {
                    shot.session = self.fetchRangeSession(id: sessionID)
                }
            }
        )
    }

    private func syncPreShotRoutineItems(since: Date?, remoteDeletions: [RemoteDeletionRecord]) async throws {
        try await syncEntity(
            table: "pre_shot_routine_items",
            entity: .preShotRoutineItem,
            since: since,
            remoteDeletions: remoteDeletions,
            modelID: { $0.id },
            makeRecord: PreShotRoutineItemRecord.init(from:),
            applyRecord: { $0.apply(to: $1) },
            insertModel: { record in
                let item = PreShotRoutineItem(id: record.id, text: record.text, sortOrder: record.sortOrder)
                record.apply(to: item)
                self.modelContext.insert(item)
                if let profileID = record.profileID {
                    item.profile = self.fetchUserProfile(id: profileID)
                }
            }
        )
    }

    private func syncSwingThoughts(since: Date?, remoteDeletions: [RemoteDeletionRecord]) async throws {
        try await syncEntity(
            table: "swing_thoughts",
            entity: .swingThought,
            since: since,
            remoteDeletions: remoteDeletions,
            modelID: { $0.id },
            makeRecord: SwingThoughtRecord.init(from:),
            applyRecord: { $0.apply(to: $1) },
            insertModel: { record in
                let thought = SwingThought(id: record.id, text: record.text)
                record.apply(to: thought)
                self.modelContext.insert(thought)
                if let profileID = record.profileID {
                    thought.profile = self.fetchUserProfile(id: profileID)
                }
            }
        )
    }

    private func syncAppSettings(since: Date?, remoteDeletions: [RemoteDeletionRecord]) async throws {
        try await syncEntity(
            table: "app_settings",
            entity: .appSettings,
            since: since,
            remoteDeletions: remoteDeletions,
            modelID: { $0.id },
            makeRecord: AppSettingsRecord.init(from:),
            applyRecord: { $0.apply(to: $1) },
            insertModel: { record in
                let settings = AppSettings(id: record.id)
                record.apply(to: settings)
                self.modelContext.insert(settings)
            }
        )
    }

    // MARK: - Generic entity sync

    private func syncEntity<M: PersistentModel, R: SyncRecord>(
        table: String,
        entity: SyncEntityName,
        since: Date?,
        remoteDeletions: [RemoteDeletionRecord],
        modelID: (M) -> UUID,
        makeRecord: (M) -> R,
        applyRecord: (R, M) -> Void,
        insertModel: (R) -> Void
    ) async throws {
        var descriptor = FetchDescriptor<M>()
        descriptor.includePendingChanges = true
        let models = try modelContext.fetch(descriptor)
        let modelsByID = Dictionary(models.map { (modelID($0), $0) }, uniquingKeysWith: { first, _ in first })

        let tombstones = try fetchTombstones(for: entity)
        let localDeletions = tombstones.map { SyncDeletion(recordID: $0.recordID, deletedAt: $0.deletedAt) }
        let remoteChanges: [R] = try await remoteStore.fetchChanges(from: table, since: since)
        let entityRemoteDeletions = remoteDeletions
            .filter { $0.entityName == entity.rawValue }
            .map { SyncDeletion(recordID: $0.recordID, deletedAt: $0.deletedAt) }

        let result = SyncEngine.merge(
            local: models.map(makeRecord),
            localDeletions: localDeletions,
            remoteChanges: remoteChanges,
            remoteDeletions: entityRemoteDeletions,
            lastSyncedAt: since
        )

        try await remoteStore.upsert(result.toPush, into: table)

        for record in result.toApply {
            if let model = modelsByID[record.id] {
                applyRecord(record, model)
            } else {
                insertModel(record)
            }
        }

        for id in result.idsToDeleteLocally {
            if let model = modelsByID[id] {
                modelContext.delete(model)
            }
        }

        if !result.deletionsToPush.isEmpty {
            try await remoteStore.pushDeletions(result.deletionsToPush.map {
                RemoteDeletionRecord(recordID: $0.recordID, entityName: entity.rawValue, deletedAt: $0.deletedAt)
            })
            try await remoteStore.deleteRows(ids: result.deletionsToPush.map(\.recordID), from: table)
        }

        // Every tombstone is now reconciled: pushed, already deleted remotely,
        // or superseded by a newer remote edit.
        for tombstone in tombstones {
            modelContext.delete(tombstone)
        }

        try modelContext.save()
    }

    // MARK: - Lookups

    private func fetchTombstones(for entity: SyncEntityName) throws -> [SyncTombstone] {
        let entityName = entity.rawValue
        var descriptor = FetchDescriptor<SyncTombstone>(
            predicate: #Predicate { $0.entityName == entityName }
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor)
    }

    private func fetchClub(id: UUID) -> Club? {
        var descriptor = FetchDescriptor<Club>(predicate: #Predicate { $0.id == id })
        descriptor.includePendingChanges = true
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchRangeSession(id: UUID) -> RangeSession? {
        var descriptor = FetchDescriptor<RangeSession>(predicate: #Predicate { $0.id == id })
        descriptor.includePendingChanges = true
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchUserProfile(id: UUID) -> UserProfile? {
        var descriptor = FetchDescriptor<UserProfile>(predicate: #Predicate { $0.id == id })
        descriptor.includePendingChanges = true
        return try? modelContext.fetch(descriptor).first
    }
}
