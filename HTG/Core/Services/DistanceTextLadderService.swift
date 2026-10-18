import Foundation

/// Pure, unit-agnostic ladder math for the text-style distance views.
enum DistanceTextLadderService {

    /// Golf adapter: reuses the print By-Yardage data so the screen matches the printed card.
    static func golfItems(from clubs: [Club]) -> [DistanceTextLadderItem] {
        YardageSheetBuilder.entriesByYardage(from: clubs).map { entry in
            DistanceTextLadderItem(
                id: golfItemID(clubName: entry.clubName, shotTypeName: entry.shotTypeName),
                distance: entry.carryDistance,
                primaryLabel: entry.clubName,
                secondaryLabel: entry.shotTypeName
            )
        }
    }

    /// Single source for the golf row key. Must equal `YardageSheetEntry.id`.
    static func golfItemID(clubName: String, shotTypeName: String) -> String {
        "\(clubName)-\(shotTypeName)"
    }

    static func ladder(
        items: [DistanceTextLadderItem],
        targetDistance: Int,
        selectedItemID: String?
    ) -> DistanceTextLadder {
        let sorted = items.sorted(by: isOrderedBefore)
        guard let closestDistance = closestDistance(in: sorted, to: targetDistance) else {
            return DistanceTextLadder(
                rows: [],
                anchorRowID: nil,
                targetMarkerInsertionIndex: nil,
                targetDistance: targetDistance
            )
        }
        let rows = sorted.map { item in
            DistanceTextLadderRow(
                item: item,
                isClosestToTarget: item.distance == closestDistance,
                isSelected: item.id == selectedItemID
            )
        }
        let closestGroup = rows.filter(\.isClosestToTarget)
        return DistanceTextLadder(
            rows: rows,
            anchorRowID: closestGroup[closestGroup.count / 2].id,
            targetMarkerInsertionIndex: closestDistance == targetDistance
                ? nil
                : (rows.firstIndex { $0.item.distance < targetDistance } ?? rows.count),
            targetDistance: targetDistance
        )
    }

    private static func isOrderedBefore(_ lhs: DistanceTextLadderItem, _ rhs: DistanceTextLadderItem) -> Bool {
        if lhs.distance != rhs.distance { return lhs.distance > rhs.distance }
        if lhs.primaryLabel != rhs.primaryLabel { return lhs.primaryLabel < rhs.primaryLabel }
        return lhs.secondaryLabel < rhs.secondaryLabel
    }

    /// Nearest distance to the target; on an equidistant tie the longer distance wins.
    private static func closestDistance(in sortedItems: [DistanceTextLadderItem], to target: Int) -> Int? {
        // Sorted descending, so `min` keeps the first (longer) of equal gaps.
        var best: Int?
        for item in sortedItems {
            guard let current = best else { best = item.distance; continue }
            if abs(item.distance - target) < abs(current - target) { best = item.distance }
        }
        return best
    }
}
