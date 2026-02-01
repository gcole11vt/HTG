import Foundation

struct GroupedLadderEntry: Identifiable, Equatable {
    let id: UUID
    let carryDistance: Int
    let entries: [LadderEntry]

    var displayLabel: String {
        if entries.count > 1 {
            return entries.map { $0.clubNickname }.joined(separator: " / ")
        }
        guard let entry = entries.first else { return "" }
        if entry.isPrimaryShotType {
            return entry.clubNickname
        }
        return "\(entry.clubNickname) \(entry.shotTypeName)"
    }

    var isAnySelected: Bool {
        entries.contains { $0.isSelected }
    }

    var isAnySameClubAsSelected: Bool {
        entries.contains { $0.isSameClubAsSelected }
    }

    var isPrimaryFontSize: Bool {
        entries.count == 1 && (entries.first?.isPrimaryShotType ?? false)
    }

    init(id: UUID = UUID(), carryDistance: Int, entries: [LadderEntry]) {
        self.id = id
        self.carryDistance = carryDistance
        // Sort: primary first
        self.entries = entries.sorted { lhs, rhs in
            if lhs.isPrimaryShotType != rhs.isPrimaryShotType {
                return lhs.isPrimaryShotType
            }
            return lhs.clubName < rhs.clubName
        }
    }
}
