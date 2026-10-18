import Foundation
import SwiftData

/// One Align Speed calibration. The newest by `createdAt` is the active one. Device-only (not synced).
@Model
final class PuttingCalibration {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var positionCount: Int
    var updatedAt: Date = Date()
    @Relationship(deleteRule: .cascade) var putts: [PuttingCalibrationPutt]

    init(id: UUID = UUID(), createdAt: Date = Date(), positionCount: Int, putts: [PuttingCalibrationPutt] = []) {
        self.id = id
        self.createdAt = createdAt
        self.positionCount = positionCount
        self.putts = putts
    }
}

@Model
final class PuttingCalibrationPutt {
    @Attribute(.unique) var id: UUID
    var position: Int
    /// Entry order within the position (relationship arrays are unordered).
    var sequence: Int
    var distanceFeet: Double
    var updatedAt: Date = Date()
    @Relationship(inverse: \PuttingCalibration.putts) var calibration: PuttingCalibration?

    init(
        id: UUID = UUID(),
        position: Int,
        sequence: Int,
        distanceFeet: Double,
        calibration: PuttingCalibration? = nil
    ) {
        self.id = id
        self.position = position
        self.sequence = sequence
        self.distanceFeet = distanceFeet
        self.calibration = calibration
    }
}

/// A user-chosen name for a backswing position, keyed by position number so it carries across
/// recalibrations. Only custom names are stored; no row means the default "Position N".
/// Device-only (not synced), like PuttingCalibration.
@Model
final class PuttingPositionName {
    @Attribute(.unique) var position: Int
    var name: String
    var updatedAt: Date = Date()

    init(position: Int, name: String) {
        self.position = position
        self.name = name
    }
}

/// Immutable lookup of position names with default fallback.
struct PuttingPositionNames: Equatable, Sendable {
    static let defaults = PuttingPositionNames(custom: [:])

    let custom: [Int: String]

    static func defaultName(for position: Int) -> String { "Position \(position)" }

    func name(for position: Int) -> String {
        custom[position] ?? Self.defaultName(for: position)
    }

    func isCustom(_ position: Int) -> Bool { custom[position] != nil }
}
