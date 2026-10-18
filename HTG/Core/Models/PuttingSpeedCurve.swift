import Foundation

enum PuttingCalibrationRules {
    static let positionCountRange = 3...8
    static let defaultPositionCount = 5
    static let puttFeetRange = 1...99
    static let defaultTargetFeet = 10
}

struct PuttingCalibrationPoint: Equatable, Sendable {
    let position: Int
    let averageFeet: Double
    let puttCount: Int
}

struct PuttingCalibrationSnapshot: Equatable, Sendable, Identifiable {
    let id: UUID
    let createdAt: Date
    let positionCount: Int
    let puttsByPosition: [Int: [Double]]
}

struct PuttStrokeSuggestion: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case position(Int)
        case between(lower: Int, upper: Int)
        case shorterThanCalibrated(shortest: Int)
        case longerThanCalibrated(longest: Int)
    }

    let kind: Kind
    let targetFeet: Double

    var highlightedPosition: Int? {
        if case .position(let position) = kind { return position }
        return nil
    }
}
