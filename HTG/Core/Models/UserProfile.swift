import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var handicap: Int
    var primaryShotType: String

    init(id: UUID = UUID(), name: String = "", handicap: Int = 18, primaryShotType: String = "Full") {
        self.id = id
        self.name = name
        self.handicap = handicap
        self.primaryShotType = primaryShotType
    }
}
