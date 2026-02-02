import Foundation
import SwiftData

@Model
final class ShotType {
    @Attribute(.unique) var id: UUID
    var name: String
    var carryDistance: Int
    var sortOrder: Int
    var isArchived: Bool = false
    var archivedDate: Date?
    @Relationship(inverse: \Club.shotTypes) var club: Club?

    init(id: UUID = UUID(), name: String, carryDistance: Int, sortOrder: Int, club: Club? = nil) {
        self.id = id
        self.name = name
        self.carryDistance = carryDistance
        self.sortOrder = sortOrder
        self.club = club
    }
}
