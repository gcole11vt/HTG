import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var yardageRangePercentage: Int
    var updatedAt: Date = Date()

    init(id: UUID = UUID(), yardageRangePercentage: Int = 15) {
        self.id = id
        self.yardageRangePercentage = yardageRangePercentage
    }
}
