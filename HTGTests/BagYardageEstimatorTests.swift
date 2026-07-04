import Testing
@testable import HTG

@Suite("BagYardageEstimator Tests")
struct BagYardageEstimatorTests {

    @Test("Known yardages pass through unchanged")
    func knownYardagesPassThrough() {
        let result = BagYardageEstimator.estimate(orderedYardages: [250, 230, 165])

        #expect(result == [250, 230, 165])
    }

    @Test("Single unknown between knowns is linearly interpolated")
    func singleGapInterpolation() {
        // 7 Iron 140, 8 Iron unknown, 9 Iron 120 -> 8 Iron 130
        let result = BagYardageEstimator.estimate(orderedYardages: [140, nil, 120])

        #expect(result == [140, 130, 120])
    }

    @Test("Multiple unknowns between knowns split the gap evenly")
    func multipleGapInterpolation() {
        // 6 Iron 135, 7 & 8 Iron unknown, 9 Iron 120 -> 7 Iron 130, 8 Iron 125
        let result = BagYardageEstimator.estimate(orderedYardages: [135, nil, nil, 120])

        #expect(result == [135, 130, 125, 120])
    }

    @Test("Unknown longer clubs extend upward by 10 yards per club")
    func upwardExtrapolation() {
        // Driver & 3 Wood unknown above 3 Iron 200 -> 3 Wood 210, Driver 220
        let result = BagYardageEstimator.estimate(orderedYardages: [nil, nil, 200])

        #expect(result == [220, 210, 200])
    }

    @Test("Unknown shorter clubs extend downward by 10 yards per club")
    func downwardExtrapolation() {
        // Sand Wedge 90, Lob Wedge unknown -> Lob Wedge 80
        let result = BagYardageEstimator.estimate(orderedYardages: [90, nil])

        #expect(result == [90, 80])
    }

    @Test("Interpolated values round to the nearest yard")
    func interpolationRounding() {
        // Midpoint of 140 and 125 is 132.5 -> rounds to 133
        let result = BagYardageEstimator.estimate(orderedYardages: [140, nil, 125])

        #expect(result == [140, 133, 125])
    }

    @Test("Estimates never drop below the minimum yardage")
    func minimumClamp() {
        let result = BagYardageEstimator.estimate(orderedYardages: [20, nil, nil])

        #expect(result == [20, 10, 5])
    }

    @Test("Returns nil when no yardages are known")
    func allUnknownReturnsNil() {
        let result = BagYardageEstimator.estimate(orderedYardages: [nil, nil, nil])

        #expect(result == nil)
    }

    @Test("Empty input returns nil")
    func emptyInputReturnsNil() {
        #expect(BagYardageEstimator.estimate(orderedYardages: []) == nil)
    }
}
