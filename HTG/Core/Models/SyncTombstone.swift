import Foundation
import SwiftData

/// Canonical names for entities that sync to Supabase.
enum SyncEntityName: String, CaseIterable {
    case club = "Club"
    case shotType = "ShotType"
    case rangeSession = "RangeSession"
    case shot = "Shot"
    case userProfile = "UserProfile"
    case preShotRoutineItem = "PreShotRoutineItem"
    case swingThought = "SwingThought"
    case appSettings = "AppSettings"
}

/// Records a local hard-delete so the sync service can propagate it to Supabase.
/// Rows are removed after the delete has been pushed successfully.
@Model
final class SyncTombstone {
    @Attribute(.unique) var id: UUID
    var entityName: String
    var recordID: UUID
    var deletedAt: Date

    init(id: UUID = UUID(), entityName: String, recordID: UUID, deletedAt: Date = Date()) {
        self.id = id
        self.entityName = entityName
        self.recordID = recordID
        self.deletedAt = deletedAt
    }

    convenience init(entity: SyncEntityName, recordID: UUID) {
        self.init(entityName: entity.rawValue, recordID: recordID)
    }
}
