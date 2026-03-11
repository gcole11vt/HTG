import Foundation
import SwiftData

@Model
final class SwingThought {
    @Attribute(.unique) var id: UUID
    var text: String
    var tagType: String
    var tagValue: String

    @Relationship(inverse: \UserProfile.swingThoughts) var profile: UserProfile?

    init(id: UUID = UUID(), text: String, tagType: String = "all", tagValue: String = "", profile: UserProfile? = nil) {
        self.id = id
        self.text = text
        self.tagType = tagType
        self.tagValue = tagValue
        self.profile = profile
    }
}
