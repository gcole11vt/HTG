import Foundation
import SwiftData

@Model
final class Shot {
    @Attribute(.unique) var id: UUID
    var distance: Int
    var date: Date
    var isFromVoice: Bool
    @Relationship(inverse: \RangeSession.shots) var session: RangeSession?

    init(id: UUID = UUID(), distance: Int, date: Date = Date(), isFromVoice: Bool = false, session: RangeSession? = nil) {
        self.id = id
        self.distance = distance
        self.date = date
        self.isFromVoice = isFromVoice
        self.session = session
    }
}
