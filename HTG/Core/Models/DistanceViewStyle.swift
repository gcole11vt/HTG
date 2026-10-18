import Foundation

/// How a distance-driven mode (Golf, later Putting) presents its options.
/// Raw values are persisted in SwiftData and synced to Supabase — never rename them.
enum DistanceViewStyle: String, CaseIterable, Identifiable, Codable, Sendable {
    case ladder
    case text

    static let defaultStyle: DistanceViewStyle = .text

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ladder: "Ladder"
        case .text: "Text"
        }
    }

    /// Tolerates unknown values (e.g. written by a newer app version) by falling back to the default.
    static func resolved(from storedValue: String) -> DistanceViewStyle {
        DistanceViewStyle(rawValue: storedValue) ?? defaultStyle
    }
}
