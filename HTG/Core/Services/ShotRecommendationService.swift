import Foundation

enum ShotTypeFilter: String, CaseIterable, Sendable {
    case all = "All"
    case full = "Full"
    case threeQuarter = "3/4"
    case hard = "Hard"
    case half = "1/2"
    case punch = "Punch"
}

final class ShotRecommendationService: Sendable {
    private static let maxRecommendations = 5

    func getRecommendations(targetYardage: Int, clubs: [Club], filter: ShotTypeFilter) -> [ShotRecommendation] {
        var allOptions: [ShotRecommendation] = []

        for club in clubs {
            for shotType in club.shotTypes {
                // Apply filter
                if filter != .all && shotType.name != filter.rawValue {
                    continue
                }

                let difference = abs(shotType.carryDistance - targetYardage)
                let recommendation = ShotRecommendation(
                    clubName: club.name,
                    shotTypeName: shotType.name,
                    carryDistance: shotType.carryDistance,
                    distanceDifference: difference
                )
                allOptions.append(recommendation)
            }
        }

        // Sort by distance difference (ascending) and take top 5
        let sorted = allOptions.sorted { $0.distanceDifference < $1.distanceDifference }
        return Array(sorted.prefix(Self.maxRecommendations))
    }
}
