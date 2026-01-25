import Foundation

struct ShotRecommendation: Identifiable, Equatable {
    let id: UUID
    let clubName: String
    let shotTypeName: String
    let carryDistance: Int
    let distanceDifference: Int

    init(id: UUID = UUID(), clubName: String, shotTypeName: String, carryDistance: Int, distanceDifference: Int) {
        self.id = id
        self.clubName = clubName
        self.shotTypeName = shotTypeName
        self.carryDistance = carryDistance
        self.distanceDifference = distanceDifference
    }
}
