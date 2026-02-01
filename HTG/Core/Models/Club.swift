import Foundation
import SwiftData

@Model
final class Club {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortOrder: Int
    var isArchived: Bool
    @Relationship(deleteRule: .cascade) var shotTypes: [ShotType]

    init(id: UUID = UUID(), name: String, sortOrder: Int, isArchived: Bool = false, shotTypes: [ShotType] = []) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.shotTypes = shotTypes
    }
}
