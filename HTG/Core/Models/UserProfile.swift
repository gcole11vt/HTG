import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var handicap: Int
    var primaryShotType: String
    var mantra: String
    var showPreShotRoutine: Bool
    var showMantra: Bool
    var updatedAt: Date = Date()
    /// Raw `DistanceViewStyle` value. Declaration default is required for lightweight migration.
    var golfModeViewStyleRawValue: String = DistanceViewStyle.defaultStyle.rawValue
    @Relationship(deleteRule: .cascade) var preShotRoutineItems: [PreShotRoutineItem]
    @Relationship(deleteRule: .cascade) var swingThoughts: [SwingThought]

    init(
        id: UUID = UUID(),
        name: String = "",
        handicap: Int = 18,
        primaryShotType: String = "Full",
        mantra: String = "Trust your swing",
        showPreShotRoutine: Bool = true,
        showMantra: Bool = true,
        preShotRoutineItems: [PreShotRoutineItem] = [],
        swingThoughts: [SwingThought] = []
    ) {
        self.id = id
        self.name = name
        self.handicap = handicap
        self.primaryShotType = primaryShotType
        self.mantra = mantra
        self.showPreShotRoutine = showPreShotRoutine
        self.showMantra = showMantra
        self.preShotRoutineItems = preShotRoutineItems
        self.swingThoughts = swingThoughts
    }
}

extension UserProfile {
    var golfModeViewStyle: DistanceViewStyle {
        get { DistanceViewStyle.resolved(from: golfModeViewStyleRawValue) }
        set { golfModeViewStyleRawValue = newValue.rawValue }
    }
}
