import Foundation

enum ClubDistanceResolver {
    static func resolveDisplayDistance(for club: Club, primaryShotType: String) -> Int {
        if let matching = club.shotTypes.first(where: { $0.name == primaryShotType }) {
            return matching.carryDistance
        }
        return club.shotTypes.map(\.carryDistance).max() ?? 0
    }
}
