import Foundation

/// Fills in unknown full-swing carry yardages for a bag ordered longest club first.
enum BagYardageEstimator {
    static let fallbackGapYards = 10
    static let minimumYardage = 5

    /// Estimates the `nil` entries of `orderedYardages` (index 0 = longest-hitting club).
    /// Unknowns between two known clubs are linearly interpolated; unknowns beyond the
    /// known range step by `fallbackGapYards` per club. Returns nil when nothing is known.
    static func estimate(orderedYardages: [Int?]) -> [Int]? {
        var yardages = orderedYardages
        let knownIndices = yardages.indices.filter { yardages[$0] != nil }
        guard let firstKnown = knownIndices.first, let lastKnown = knownIndices.last else {
            return nil
        }

        interpolateBetweenKnowns(&yardages, knownIndices: knownIndices)

        for index in stride(from: firstKnown - 1, through: 0, by: -1) {
            yardages[index] = yardages[index + 1]! + fallbackGapYards
        }
        for index in yardages.indices.dropFirst(lastKnown + 1) {
            yardages[index] = max(yardages[index - 1]! - fallbackGapYards, minimumYardage)
        }

        return yardages.compactMap(\.self)
    }

    private static func interpolateBetweenKnowns(_ yardages: inout [Int?], knownIndices: [Int]) {
        for (lower, upper) in zip(knownIndices, knownIndices.dropFirst()) {
            let startValue = Double(yardages[lower]!)
            let endValue = Double(yardages[upper]!)
            let stepCount = Double(upper - lower)

            for index in (lower + 1)..<upper {
                let progress = Double(index - lower) / stepCount
                let interpolated = (startValue + (endValue - startValue) * progress).rounded()
                yardages[index] = max(Int(interpolated), minimumYardage)
            }
        }
    }
}
