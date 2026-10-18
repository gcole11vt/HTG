import Foundation

/// Pure helpers for pushing records to a remote that may lack optional columns.
enum SyncPayloadStripper {
    /// PostgREST error code for "column not found in the schema cache".
    private static let missingColumnCode = "PGRST204"

    /// Encodes `records` as a JSON array with the given top-level keys removed.
    static func strip<R: Encodable>(
        _ records: [R],
        columns: Set<String>,
        encoder: JSONEncoder = JSONEncoder()
    ) throws -> Data {
        let encoded = try encoder.encode(records)
        guard let rows = try JSONSerialization.jsonObject(with: encoded) as? [[String: Any]] else {
            return encoded
        }
        let stripped = rows.map { row in row.filter { !columns.contains($0.key) } }
        return try JSONSerialization.data(withJSONObject: stripped)
    }

    /// True when the error is PGRST204 and its message names one of `columns`.
    static func isMissingColumnError(code: String?, message: String, columns: Set<String>) -> Bool {
        guard code == missingColumnCode else { return false }
        return columns.contains { message.contains("'\($0)'") }
    }
}
