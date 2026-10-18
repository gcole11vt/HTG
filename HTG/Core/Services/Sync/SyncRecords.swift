import Foundation

// One Codable struct per Supabase table. `user_id` is intentionally absent:
// the database fills it from `auth.uid()` and row-level security scopes all
// reads and writes to the signed-in user.

struct ClubRecord: SyncRecord, Equatable {
    let id: UUID
    var name: String
    var nickname: String
    var sortOrder: Int
    var isArchived: Bool
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case nickname
        case sortOrder = "sort_order"
        case isArchived = "is_archived"
        case updatedAt = "updated_at"
    }
}

struct ShotTypeRecord: SyncRecord, Equatable {
    let id: UUID
    var clubID: UUID?
    var name: String
    var carryDistance: Int
    var sortOrder: Int
    var isArchived: Bool
    var archivedDate: Date?
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case clubID = "club_id"
        case name
        case carryDistance = "carry_distance"
        case sortOrder = "sort_order"
        case isArchived = "is_archived"
        case archivedDate = "archived_date"
        case updatedAt = "updated_at"
    }
}

struct RangeSessionRecord: SyncRecord, Equatable {
    let id: UUID
    var date: Date
    var clubName: String
    var shotTypeName: String
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case clubName = "club_name"
        case shotTypeName = "shot_type_name"
        case updatedAt = "updated_at"
    }
}

struct ShotRecord: SyncRecord, Equatable {
    let id: UUID
    var sessionID: UUID?
    var distance: Int
    var date: Date
    var isFromVoice: Bool
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sessionID = "session_id"
        case distance
        case date
        case isFromVoice = "is_from_voice"
        case updatedAt = "updated_at"
    }
}

struct UserProfileRecord: SyncRecord, Equatable {
    let id: UUID
    var name: String
    var handicap: Int
    var primaryShotType: String
    var mantra: String
    var showPreShotRoutine: Bool
    var showMantra: Bool
    var updatedAt: Date
    /// Optional so legacy rows (and remotes lacking the column) decode, and nil is omitted on encode.
    var golfModeViewStyle: String?
    var showSwingThoughts: Bool?

    /// Columns that may not exist on an un-migrated remote; pushes retry without them.
    static var optionalRemoteColumns: Set<String> { ["golf_mode_view_style", "show_swing_thoughts"] }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case handicap
        case primaryShotType = "primary_shot_type"
        case mantra
        case showPreShotRoutine = "show_pre_shot_routine"
        case showMantra = "show_mantra"
        case updatedAt = "updated_at"
        case golfModeViewStyle = "golf_mode_view_style"
        case showSwingThoughts = "show_swing_thoughts"
    }
}

struct PreShotRoutineItemRecord: SyncRecord, Equatable {
    let id: UUID
    var profileID: UUID?
    var text: String
    var sortOrder: Int
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case profileID = "profile_id"
        case text
        case sortOrder = "sort_order"
        case updatedAt = "updated_at"
    }
}

struct SwingThoughtRecord: SyncRecord, Equatable {
    let id: UUID
    var profileID: UUID?
    var text: String
    var tagType: String
    var tagValue: String
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case profileID = "profile_id"
        case text
        case tagType = "tag_type"
        case tagValue = "tag_value"
        case updatedAt = "updated_at"
    }
}

struct AppSettingsRecord: SyncRecord, Equatable {
    let id: UUID
    var yardageRangePercentage: Int
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case yardageRangePercentage = "yardage_range_percentage"
        case updatedAt = "updated_at"
    }
}

// MARK: - Model mapping

extension ClubRecord {
    init(from club: Club) {
        self.init(
            id: club.id,
            name: club.name,
            nickname: club.nickname,
            sortOrder: club.sortOrder,
            isArchived: club.isArchived,
            updatedAt: club.updatedAt
        )
    }

    /// Applies remote fields to the model. Copies `updatedAt` verbatim so an
    /// applied pull is not mistaken for a fresh local edit on the next sync.
    func apply(to club: Club) {
        club.name = name
        club.nickname = nickname
        club.sortOrder = sortOrder
        club.isArchived = isArchived
        club.updatedAt = updatedAt
    }
}

extension ShotTypeRecord {
    init(from shotType: ShotType) {
        self.init(
            id: shotType.id,
            clubID: shotType.club?.id,
            name: shotType.name,
            carryDistance: shotType.carryDistance,
            sortOrder: shotType.sortOrder,
            isArchived: shotType.isArchived,
            archivedDate: shotType.archivedDate,
            updatedAt: shotType.updatedAt
        )
    }

    func apply(to shotType: ShotType) {
        shotType.name = name
        shotType.carryDistance = carryDistance
        shotType.sortOrder = sortOrder
        shotType.isArchived = isArchived
        shotType.archivedDate = archivedDate
        shotType.updatedAt = updatedAt
    }
}

extension RangeSessionRecord {
    init(from session: RangeSession) {
        self.init(
            id: session.id,
            date: session.date,
            clubName: session.clubName,
            shotTypeName: session.shotTypeName,
            updatedAt: session.updatedAt
        )
    }

    func apply(to session: RangeSession) {
        session.date = date
        session.clubName = clubName
        session.shotTypeName = shotTypeName
        session.updatedAt = updatedAt
    }
}

extension ShotRecord {
    init(from shot: Shot) {
        self.init(
            id: shot.id,
            sessionID: shot.session?.id,
            distance: shot.distance,
            date: shot.date,
            isFromVoice: shot.isFromVoice,
            updatedAt: shot.updatedAt
        )
    }

    func apply(to shot: Shot) {
        shot.distance = distance
        shot.date = date
        shot.isFromVoice = isFromVoice
        shot.updatedAt = updatedAt
    }
}

extension UserProfileRecord {
    init(from profile: UserProfile) {
        self.init(
            id: profile.id,
            name: profile.name,
            handicap: profile.handicap,
            primaryShotType: profile.primaryShotType,
            mantra: profile.mantra,
            showPreShotRoutine: profile.showPreShotRoutine,
            showMantra: profile.showMantra,
            updatedAt: profile.updatedAt,
            golfModeViewStyle: profile.golfModeViewStyleRawValue,
            showSwingThoughts: profile.showSwingThoughts
        )
    }

    func apply(to profile: UserProfile) {
        profile.name = name
        profile.handicap = handicap
        profile.primaryShotType = primaryShotType
        profile.mantra = mantra
        profile.showPreShotRoutine = showPreShotRoutine
        profile.showMantra = showMantra
        if let golfModeViewStyle {
            profile.golfModeViewStyleRawValue = golfModeViewStyle
        }
        if let showSwingThoughts {
            profile.showSwingThoughts = showSwingThoughts
        }
        profile.updatedAt = updatedAt
    }
}

extension PreShotRoutineItemRecord {
    init(from item: PreShotRoutineItem) {
        self.init(
            id: item.id,
            profileID: item.profile?.id,
            text: item.text,
            sortOrder: item.sortOrder,
            updatedAt: item.updatedAt
        )
    }

    func apply(to item: PreShotRoutineItem) {
        item.text = text
        item.sortOrder = sortOrder
        item.updatedAt = updatedAt
    }
}

extension SwingThoughtRecord {
    init(from thought: SwingThought) {
        self.init(
            id: thought.id,
            profileID: thought.profile?.id,
            text: thought.text,
            tagType: thought.tagType,
            tagValue: thought.tagValue,
            updatedAt: thought.updatedAt
        )
    }

    func apply(to thought: SwingThought) {
        thought.text = text
        thought.tagType = tagType
        thought.tagValue = tagValue
        thought.updatedAt = updatedAt
    }
}

extension AppSettingsRecord {
    init(from settings: AppSettings) {
        self.init(
            id: settings.id,
            yardageRangePercentage: settings.yardageRangePercentage,
            updatedAt: settings.updatedAt
        )
    }

    func apply(to settings: AppSettings) {
        settings.yardageRangePercentage = yardageRangePercentage
        settings.updatedAt = updatedAt
    }
}
