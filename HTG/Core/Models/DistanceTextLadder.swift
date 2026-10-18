import Foundation

/// Unit for distance-driven modes. Golf = yards, Putting = feet.
enum DistanceUnit: String, Sendable, CaseIterable {
    case yards, feet

    var abbreviation: String { self == .yards ? "yd" : "ft" }

    func formatted(_ distance: Int) -> String { "\(distance) \(abbreviation)" }
}

/// Input to the text ladder: one selectable option at one distance.
struct DistanceTextLadderItem: Equatable, Identifiable, Sendable {
    let id: String
    let distance: Int
    /// Golf: club name. Putting: e.g. "Position 3".
    let primaryLabel: String
    /// Golf: shot type. Putting: empty (hidden when empty).
    let secondaryLabel: String
}

/// Output row with highlight flags computed by the service.
struct DistanceTextLadderRow: Equatable, Identifiable, Sendable {
    let item: DistanceTextLadderItem
    let isClosestToTarget: Bool
    let isSelected: Bool

    var id: String { item.id }
}

struct DistanceTextLadder: Equatable, Sendable {
    /// Distance descending.
    let rows: [DistanceTextLadderRow]
    /// Row to centre the scroll on.
    let anchorRowID: String?
    /// nil when a row matches the target exactly; otherwise 0...rows.count.
    let targetMarkerInsertionIndex: Int?
    let targetDistance: Int

    static let empty = DistanceTextLadder(
        rows: [],
        anchorRowID: nil,
        targetMarkerInsertionIndex: nil,
        targetDistance: 0
    )
}
