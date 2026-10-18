import Foundation
import Testing
@testable import HTG

/// Pure last-write-wins merge logic between the local SwiftData snapshot and
/// remote (Supabase) changes. No I/O — the engine only decides what to push,
/// what to apply locally, and which deletions propagate in each direction.
@Suite("SyncEngine Tests")
struct SyncEngineTests {

    private struct TestRecord: SyncRecord, Equatable {
        let id: UUID
        var value: String
        var updatedAt: Date
    }

    private let t0 = Date(timeIntervalSince1970: 1_000_000)
    private var t1: Date { t0.addingTimeInterval(100) }
    private var t2: Date { t0.addingTimeInterval(200) }
    private var t3: Date { t0.addingTimeInterval(300) }

    private func merge(
        local: [TestRecord] = [],
        localDeletions: [SyncDeletion] = [],
        remoteChanges: [TestRecord] = [],
        remoteDeletions: [SyncDeletion] = [],
        lastSyncedAt: Date? = nil
    ) -> SyncEngine.MergeResult<TestRecord> {
        SyncEngine.merge(
            local: local,
            localDeletions: localDeletions,
            remoteChanges: remoteChanges,
            remoteDeletions: remoteDeletions,
            lastSyncedAt: lastSyncedAt
        )
    }

    @Test("First sync pushes all local and applies all remote")
    func firstSyncPushesAndAppliesEverything() {
        let localOnly = TestRecord(id: UUID(), value: "local", updatedAt: t1)
        let remoteOnly = TestRecord(id: UUID(), value: "remote", updatedAt: t1)

        let result = merge(local: [localOnly], remoteChanges: [remoteOnly], lastSyncedAt: nil)

        #expect(result.toPush == [localOnly])
        #expect(result.toApply == [remoteOnly])
        #expect(result.idsToDeleteLocally.isEmpty)
        #expect(result.deletionsToPush.isEmpty)
    }

    @Test("Newer local record wins the conflict and is pushed")
    func newerLocalWins() {
        let id = UUID()
        let local = TestRecord(id: id, value: "local", updatedAt: t2)
        let remote = TestRecord(id: id, value: "remote", updatedAt: t1)

        let result = merge(local: [local], remoteChanges: [remote], lastSyncedAt: t0)

        #expect(result.toPush == [local])
        #expect(result.toApply.isEmpty)
    }

    @Test("Newer remote record wins the conflict and is applied")
    func newerRemoteWins() {
        let id = UUID()
        let local = TestRecord(id: id, value: "local", updatedAt: t1)
        let remote = TestRecord(id: id, value: "remote", updatedAt: t2)

        let result = merge(local: [local], remoteChanges: [remote], lastSyncedAt: t0)

        #expect(result.toPush.isEmpty)
        #expect(result.toApply == [remote])
    }

    @Test("Identical timestamps are treated as in sync")
    func equalTimestampsAreInSync() {
        let id = UUID()
        let local = TestRecord(id: id, value: "same", updatedAt: t1)
        let remote = TestRecord(id: id, value: "same", updatedAt: t1)

        let result = merge(local: [local], remoteChanges: [remote], lastSyncedAt: t0)

        #expect(result.toPush.isEmpty)
        #expect(result.toApply.isEmpty)
    }

    @Test("Local records unchanged since last sync are not pushed")
    func unchangedLocalRecordsAreNotPushed() {
        let stale = TestRecord(id: UUID(), value: "old", updatedAt: t1)

        let result = merge(local: [stale], lastSyncedAt: t2)

        #expect(result.toPush.isEmpty)
        #expect(result.toApply.isEmpty)
    }

    @Test("Local record modified after last sync is pushed")
    func modifiedLocalRecordIsPushed() {
        let edited = TestRecord(id: UUID(), value: "new", updatedAt: t2)

        let result = merge(local: [edited], lastSyncedAt: t1)

        #expect(result.toPush == [edited])
    }

    @Test("Remote deletion removes an older local record")
    func remoteDeletionRemovesOlderLocalRecord() {
        let id = UUID()
        let local = TestRecord(id: id, value: "doomed", updatedAt: t1)
        let deletion = SyncDeletion(recordID: id, deletedAt: t2)

        let result = merge(local: [local], remoteDeletions: [deletion], lastSyncedAt: t0)

        #expect(result.idsToDeleteLocally == [id])
        #expect(result.toPush.isEmpty)
    }

    @Test("Local edit newer than remote deletion resurrects the record")
    func localEditBeatsRemoteDeletion() {
        let id = UUID()
        let local = TestRecord(id: id, value: "revived", updatedAt: t3)
        let deletion = SyncDeletion(recordID: id, deletedAt: t2)

        let result = merge(local: [local], remoteDeletions: [deletion], lastSyncedAt: t1)

        #expect(result.idsToDeleteLocally.isEmpty)
        #expect(result.toPush == [local])
    }

    @Test("Local tombstone is pushed as a deletion")
    func localTombstoneIsPushed() {
        let deletion = SyncDeletion(recordID: UUID(), deletedAt: t1)

        let result = merge(localDeletions: [deletion], lastSyncedAt: t0)

        #expect(result.deletionsToPush == [deletion])
    }

    @Test("Remote update newer than local tombstone resurrects the record locally")
    func remoteUpdateBeatsLocalTombstone() {
        let id = UUID()
        let tombstone = SyncDeletion(recordID: id, deletedAt: t1)
        let remote = TestRecord(id: id, value: "revived", updatedAt: t2)

        let result = merge(localDeletions: [tombstone], remoteChanges: [remote], lastSyncedAt: t0)

        #expect(result.toApply == [remote])
        #expect(result.deletionsToPush.isEmpty)
    }

    @Test("Local tombstone newer than remote update pushes the deletion")
    func localTombstoneBeatsRemoteUpdate() {
        let id = UUID()
        let tombstone = SyncDeletion(recordID: id, deletedAt: t2)
        let remote = TestRecord(id: id, value: "stale", updatedAt: t1)

        let result = merge(localDeletions: [tombstone], remoteChanges: [remote], lastSyncedAt: t0)

        #expect(result.toApply.isEmpty)
        #expect(result.deletionsToPush == [tombstone])
    }

    @Test("Deletion already applied remotely is not pushed again")
    func deletionAlreadyRemoteIsNotRepushed() {
        let id = UUID()
        let local = SyncDeletion(recordID: id, deletedAt: t1)
        let remote = SyncDeletion(recordID: id, deletedAt: t1)

        let result = merge(localDeletions: [local], remoteDeletions: [remote], lastSyncedAt: t0)

        #expect(result.deletionsToPush.isEmpty)
        #expect(result.idsToDeleteLocally.isEmpty)
    }
}

@Suite("Sync Record Mapping Tests")
@MainActor
struct SyncRecordMappingTests {

    @Test("ClubRecord round-trips through a model without bumping updatedAt")
    func clubRecordRoundTrip() {
        let timestamp = Date(timeIntervalSince1970: 1_000_000)
        let club = Club(name: "7 Iron", nickname: "Lucky Seven", sortOrder: 3, isArchived: true)
        club.updatedAt = timestamp

        let record = ClubRecord(from: club)
        let target = Club(name: "", sortOrder: 0)
        record.apply(to: target)

        #expect(target.name == "7 Iron")
        #expect(target.nickname == "Lucky Seven")
        #expect(target.sortOrder == 3)
        #expect(target.isArchived == true)
        #expect(target.updatedAt == timestamp)
    }

    @Test("ShotTypeRecord captures the owning club's id")
    func shotTypeRecordCapturesClubID() {
        let club = Club(name: "7 Iron", sortOrder: 0)
        let shotType = ShotType(name: "Full", carryDistance: 165, sortOrder: 0, club: club)

        let record = ShotTypeRecord(from: shotType)

        #expect(record.clubID == club.id)
    }

    @Test("UserProfileRecord round-trips Golf Mode view style without bumping updatedAt")
    func userProfileRecordRoundTripsViewStyle() {
        let timestamp = Date(timeIntervalSince1970: 1_000_000)
        let profile = UserProfile()
        profile.golfModeViewStyle = .ladder
        profile.updatedAt = timestamp

        let record = UserProfileRecord(from: profile)
        let target = UserProfile()
        record.apply(to: target)

        #expect(target.golfModeViewStyle == .ladder)
        #expect(target.updatedAt == timestamp)
    }

    @Test("UserProfileRecord encodes golf_mode_view_style")
    func userProfileRecordEncodesViewStyle() throws {
        let profile = UserProfile()
        profile.golfModeViewStyle = .ladder

        let data = try JSONEncoder().encode(UserProfileRecord(from: profile))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["golf_mode_view_style"] as? String == "ladder")
    }

    @Test("UserProfileRecord decodes a legacy row without golf_mode_view_style")
    func userProfileRecordDecodesLegacyRow() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Greg","handicap":8,"primary_shot_type":"Full",
        "mantra":"Trust","show_pre_shot_routine":true,"show_mantra":true,"updated_at":1000000}
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        let record = try decoder.decode(UserProfileRecord.self, from: Data(json.utf8))

        #expect(record.golfModeViewStyle == nil)
    }

    @Test("Applying a record with nil view style leaves the local value untouched")
    func applyingNilViewStyleKeepsLocalValue() {
        let profile = UserProfile()
        profile.golfModeViewStyle = .ladder
        var record = UserProfileRecord(from: UserProfile())
        record.golfModeViewStyle = nil

        record.apply(to: profile)

        #expect(profile.golfModeViewStyle == .ladder)
    }

    @Test("UserProfileRecord round-trips show swing thoughts")
    func userProfileRecordRoundTripsShowSwingThoughts() {
        let profile = UserProfile()
        profile.showSwingThoughts = false

        let target = UserProfile()
        UserProfileRecord(from: profile).apply(to: target)

        #expect(target.showSwingThoughts == false)
    }

    @Test("UserProfileRecord encodes show_swing_thoughts")
    func userProfileRecordEncodesShowSwingThoughts() throws {
        let profile = UserProfile()
        profile.showSwingThoughts = false

        let data = try JSONEncoder().encode(UserProfileRecord(from: profile))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["show_swing_thoughts"] as? Bool == false)
    }

    @Test("Legacy row without show_swing_thoughts decodes nil and keeps the local value")
    func legacyRowKeepsLocalShowSwingThoughts() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Greg","handicap":8,"primary_shot_type":"Full",
        "mantra":"Trust","show_pre_shot_routine":true,"show_mantra":true,"updated_at":1000000}
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let record = try decoder.decode(UserProfileRecord.self, from: Data(json.utf8))
        #expect(record.showSwingThoughts == nil)

        let profile = UserProfile()
        profile.showSwingThoughts = false
        record.apply(to: profile)

        #expect(profile.showSwingThoughts == false)
    }

    @Test("Payload stripper removes show_swing_thoughts")
    func payloadStripperRemovesShowSwingThoughts() throws {
        let record = UserProfileRecord(from: UserProfile())

        let data = try SyncPayloadStripper.strip([record], columns: ["show_swing_thoughts"])
        let rows = try #require(try JSONSerialization.jsonObject(with: data) as? [[String: Any]])

        #expect(rows[0]["show_swing_thoughts"] == nil)
        #expect(rows[0]["name"] != nil)
        #expect(UserProfileRecord.optionalRemoteColumns.contains("show_swing_thoughts"))
    }

    @Test("Payload stripper removes optional remote columns")
    func payloadStripperRemovesOptionalColumns() throws {
        let record = UserProfileRecord(from: UserProfile())

        let data = try SyncPayloadStripper.strip([record], columns: ["golf_mode_view_style"])
        let rows = try #require(try JSONSerialization.jsonObject(with: data) as? [[String: Any]])

        #expect(rows.count == 1)
        #expect(rows[0]["golf_mode_view_style"] == nil)
        #expect(rows[0]["name"] != nil)
        #expect(UserProfileRecord.optionalRemoteColumns.contains("golf_mode_view_style"))
    }

    @Test("Missing-column detection matches PGRST204 naming an optional column")
    func missingColumnDetection() {
        let message = "Could not find the 'golf_mode_view_style' column of 'user_profiles' in the schema cache"
        let columns: Set<String> = ["golf_mode_view_style"]

        #expect(SyncPayloadStripper.isMissingColumnError(code: "PGRST204", message: message, columns: columns))
        #expect(!SyncPayloadStripper.isMissingColumnError(code: "PGRST204", message: "Could not find the 'other' column", columns: columns))
        #expect(!SyncPayloadStripper.isMissingColumnError(code: "42501", message: message, columns: columns))
        #expect(!SyncPayloadStripper.isMissingColumnError(code: nil, message: message, columns: columns))
        #expect(!SyncPayloadStripper.isMissingColumnError(code: "PGRST204", message: message, columns: []))
    }

    @Test("Records encode with snake_case keys")
    func recordsEncodeWithSnakeCaseKeys() throws {
        let club = Club(name: "7 Iron", sortOrder: 1)
        let record = ClubRecord(from: club)

        let data = try JSONEncoder().encode(record)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json.keys.contains("sort_order"))
        #expect(json.keys.contains("is_archived"))
        #expect(json.keys.contains("updated_at"))
    }
}
