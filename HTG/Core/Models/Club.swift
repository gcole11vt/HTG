import Foundation
import SwiftData

@Model
final class Club {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortOrder: Int
    @Relationship(deleteRule: .cascade) var shotTypes: [ShotType]

    init(id: UUID = UUID(), name: String, sortOrder: Int, shotTypes: [ShotType] = []) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.shotTypes = shotTypes
    }
}
