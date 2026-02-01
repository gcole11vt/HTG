import Foundation

struct LadderEntry: Identifiable, Equatable {
    let id: UUID
    let clubName: String
    let shotTypeName: String
    let carryDistance: Int
    let yardagePosition: CGFloat
    let isSelected: Bool
    let isSameClubAsSelected: Bool

    init(
        id: UUID = UUID(),
        clubName: String,
        shotTypeName: String,
        carryDistance: Int,
        yardagePosition: CGFloat,
        isSelected: Bool,
        isSameClubAsSelected: Bool
    ) {
        self.id = id
        self.clubName = clubName
        self.shotTypeName = shotTypeName
        self.carryDistance = carryDistance
        self.yardagePosition = yardagePosition
        self.isSelected = isSelected
        self.isSameClubAsSelected = isSameClubAsSelected
    }
}
