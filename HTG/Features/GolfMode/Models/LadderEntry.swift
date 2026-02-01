import Foundation

struct LadderEntry: Identifiable, Equatable {
    let id: UUID
    let clubName: String
    let clubNickname: String
    let shotTypeName: String
    let carryDistance: Int
    let yardagePosition: CGFloat
    let isSelected: Bool
    let isSameClubAsSelected: Bool
    let isPrimaryShotType: Bool

    init(
        id: UUID = UUID(),
        clubName: String,
        clubNickname: String = "",
        shotTypeName: String,
        carryDistance: Int,
        yardagePosition: CGFloat,
        isSelected: Bool,
        isSameClubAsSelected: Bool,
        isPrimaryShotType: Bool = false
    ) {
        self.id = id
        self.clubName = clubName
        self.clubNickname = clubNickname
        self.shotTypeName = shotTypeName
        self.carryDistance = carryDistance
        self.yardagePosition = yardagePosition
        self.isSelected = isSelected
        self.isSameClubAsSelected = isSameClubAsSelected
        self.isPrimaryShotType = isPrimaryShotType
    }
}
