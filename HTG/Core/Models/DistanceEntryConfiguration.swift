import Foundation

/// Unit label and valid range for the one-tap distance entry field. Golf = yards, Putting = feet.
struct DistanceEntryConfiguration: Equatable, Sendable {
    let unitLabel: String
    let validRange: ClosedRange<Int>

    var rangeHint: String { "\(validRange.lowerBound)\u{2013}\(validRange.upperBound) \(unitLabel)" }

    static let golfYards = DistanceEntryConfiguration(
        unitLabel: "yards",
        validRange: YardageEntryValidationService.validRange
    )
    static let puttFeet = DistanceEntryConfiguration(
        unitLabel: "feet",
        validRange: PuttingCalibrationRules.puttFeetRange
    )
}
