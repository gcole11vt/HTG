import Foundation
import SwiftData

@Model
final class StoredShotType {
    @Attribute(.unique) var id: UUID
    var clubName: String
    var shotTypeName: String
    var distance: Int
    var date: Date

    init(id: UUID = UUID(), clubName: String, shotTypeName: String, distance: Int, date: Date = Date()) {
        self.id = id
        self.clubName = clubName
        self.shotTypeName = shotTypeName
        self.distance = distance
        self.date = date
    }
}
