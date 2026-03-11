import Foundation
import SwiftData

@Model
final class PreShotRoutineItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var sortOrder: Int
    @Relationship(inverse: \UserProfile.preShotRoutineItems) var profile: UserProfile?

    init(id: UUID = UUID(), text: String, sortOrder: Int, profile: UserProfile? = nil) {
        self.id = id
        self.text = text
        self.sortOrder = sortOrder
        self.profile = profile
    }
}
