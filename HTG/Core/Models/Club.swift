import Foundation
import SwiftData

@Model
final class Club {
    @Attribute(.unique) var id: UUID
    var name: String
    var nickname: String
    var sortOrder: Int
    var isArchived: Bool
    @Relationship(deleteRule: .cascade) var shotTypes: [ShotType]

    init(id: UUID = UUID(), name: String, nickname: String = "", sortOrder: Int, isArchived: Bool = false, shotTypes: [ShotType] = []) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.shotTypes = shotTypes
    }
}
