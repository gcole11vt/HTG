import Foundation
import SwiftData

@Model
final class RangeSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var clubName: String
    var shotTypeName: String
    @Relationship(deleteRule: .cascade) var shots: [Shot]

    init(id: UUID = UUID(), date: Date = Date(), clubName: String, shotTypeName: String, shots: [Shot] = []) {
        self.id = id
        self.date = date
        self.clubName = clubName
        self.shotTypeName = shotTypeName
        self.shots = shots
    }
}
