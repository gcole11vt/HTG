import Foundation
import Supabase

/// A row in the shared `sync_deletions` table, which propagates hard-deletes
/// across devices.
struct RemoteDeletionRecord: Codable, Sendable, Equatable {
    let recordID: UUID
    let entityName: String
    let deletedAt: Date

    enum CodingKeys: String, CodingKey {
        case recordID = "record_id"
        case entityName = "entity_name"
        case deletedAt = "deleted_at"
    }
}

/// Remote half of the sync pipeline. Abstracted so SyncService can be tested
/// against an in-memory fake.
protocol SyncRemoteStore: Sendable {
    func fetchChanges<R: SyncRecord>(from table: String, since: Date?) async throws -> [R]
    func upsert<R: SyncRecord>(_ records: [R], into table: String) async throws
    func deleteRows(ids: [UUID], from table: String) async throws
    func fetchDeletions(since: Date?) async throws -> [RemoteDeletionRecord]
    func pushDeletions(_ deletions: [RemoteDeletionRecord]) async throws
}

final class SupabaseRemoteStore: SyncRemoteStore {
    private let client: SupabaseClient

    private static let deletionsTable = "sync_deletions"

    private static let timestampFormat = Date.ISO8601FormatStyle(includingFractionalSeconds: true)

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchChanges<R: SyncRecord>(from table: String, since: Date?) async throws -> [R] {
        let query = client.from(table).select()
        guard let since else {
            return try await query.execute().value
        }
        return try await query
            .gt("updated_at", value: since.formatted(Self.timestampFormat))
            .execute()
            .value
    }

    func upsert<R: SyncRecord>(_ records: [R], into table: String) async throws {
        guard !records.isEmpty else { return }
        do {
            try await client.from(table).upsert(records).execute()
        } catch let error as PostgrestError
            where SyncPayloadStripper.isMissingColumnError(
                code: error.code, message: error.message, columns: R.optionalRemoteColumns
            ) {
            // Remote predates an optional column: retry once without it.
            let data = try SyncPayloadStripper.strip(
                records,
                columns: R.optionalRemoteColumns,
                encoder: PostgrestClient.Configuration.jsonEncoder
            )
            let rows = try JSONDecoder().decode([AnyJSON].self, from: data)
            try await client.from(table).upsert(rows).execute()
        }
    }

    func deleteRows(ids: [UUID], from table: String) async throws {
        guard !ids.isEmpty else { return }
        try await client.from(table)
            .delete()
            .in("id", values: ids.map(\.uuidString))
            .execute()
    }

    func fetchDeletions(since: Date?) async throws -> [RemoteDeletionRecord] {
        let query = client.from(Self.deletionsTable).select()
        guard let since else {
            return try await query.execute().value
        }
        return try await query
            .gt("deleted_at", value: since.formatted(Self.timestampFormat))
            .execute()
            .value
    }

    func pushDeletions(_ deletions: [RemoteDeletionRecord]) async throws {
        guard !deletions.isEmpty else { return }
        try await client.from(Self.deletionsTable).upsert(deletions).execute()
    }
}
