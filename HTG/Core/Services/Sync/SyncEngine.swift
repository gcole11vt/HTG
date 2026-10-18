import Foundation

/// A flattened, value-type representation of a synced entity. Conforming
/// types mirror one Supabase table row each.
protocol SyncRecord: Codable, Sendable, Identifiable {
    var id: UUID { get }
    var updatedAt: Date { get }
    /// Remote column names that may be absent on an un-migrated backend.
    static var optionalRemoteColumns: Set<String> { get }
}

extension SyncRecord {
    static var optionalRemoteColumns: Set<String> { [] }
}

/// A propagated hard-delete, in either direction.
struct SyncDeletion: Codable, Sendable, Equatable {
    let recordID: UUID
    let deletedAt: Date

    enum CodingKeys: String, CodingKey {
        case recordID = "record_id"
        case deletedAt = "deleted_at"
    }
}

/// Pure last-write-wins merge between the local snapshot and remote changes.
/// No I/O: callers fetch inputs and apply outputs.
enum SyncEngine {
    struct MergeResult<R: SyncRecord> {
        var toPush: [R] = []
        var toApply: [R] = []
        var idsToDeleteLocally: [UUID] = []
        var deletionsToPush: [SyncDeletion] = []
    }

    static func merge<R: SyncRecord>(
        local: [R],
        localDeletions: [SyncDeletion],
        remoteChanges: [R],
        remoteDeletions: [SyncDeletion],
        lastSyncedAt: Date?
    ) -> MergeResult<R> {
        let localByID = Dictionary(local.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let localDeletionByID = Dictionary(localDeletions.map { ($0.recordID, $0) }, uniquingKeysWith: { first, _ in first })
        let remoteByID = Dictionary(remoteChanges.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let remoteDeletionByID = Dictionary(remoteDeletions.map { ($0.recordID, $0) }, uniquingKeysWith: { first, _ in first })

        var result = MergeResult<R>()

        for record in local {
            if let remoteDeletion = remoteDeletionByID[record.id] {
                if record.updatedAt > remoteDeletion.deletedAt {
                    result.toPush.append(record)
                } else {
                    result.idsToDeleteLocally.append(record.id)
                }
                continue
            }
            if let remote = remoteByID[record.id] {
                if record.updatedAt > remote.updatedAt {
                    result.toPush.append(record)
                }
                continue
            }
            let changedSinceLastSync = lastSyncedAt.map { record.updatedAt > $0 } ?? true
            if changedSinceLastSync {
                result.toPush.append(record)
            }
        }

        for remote in remoteChanges {
            if let tombstone = localDeletionByID[remote.id] {
                if remote.updatedAt > tombstone.deletedAt {
                    result.toApply.append(remote)
                }
                continue
            }
            if let localRecord = localByID[remote.id] {
                if remote.updatedAt > localRecord.updatedAt {
                    result.toApply.append(remote)
                }
                continue
            }
            result.toApply.append(remote)
        }

        for deletion in localDeletions {
            if remoteDeletionByID[deletion.recordID] != nil { continue }
            if let remote = remoteByID[deletion.recordID], remote.updatedAt > deletion.deletedAt { continue }
            result.deletionsToPush.append(deletion)
        }

        return result
    }
}
