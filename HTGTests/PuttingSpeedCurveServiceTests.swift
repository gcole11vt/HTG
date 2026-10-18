import Testing
import Foundation
@testable import HTG

@Suite("PuttingSpeedCurveService Tests")
struct PuttingSpeedCurveServiceTests {
    private typealias Service = PuttingSpeedCurveService

    private func curve(_ feet: Double...) -> [PuttingCalibrationPoint] {
        feet.enumerated().map { PuttingCalibrationPoint(position: $0.offset + 1, averageFeet: $0.element, puttCount: 1) }
    }

    private var standard: [PuttingCalibrationPoint] { curve(4, 8, 14, 21, 30) }

    private func kind(_ target: Double, _ points: [PuttingCalibrationPoint]) -> PuttStrokeSuggestion.Kind? {
        Service.suggestion(forTargetFeet: target, curve: points)?.kind
    }

    // MARK: Averaging and points

    @Test("Average of putts is the mean")
    func averageOfPuttsIsTheMean() {
        #expect(Service.averageFeet([8, 10, 12]) == 10)
        #expect(Service.averageFeet([9]) == 9)
        #expect(Service.averageFeet([8, 9]) == 8.5)
        #expect(Service.averageFeet([]) == nil)
    }

    @Test("Points are sorted by position with counts")
    func pointsAreSortedByPositionWithCounts() {
        let points = Service.points(from: [3: [14, 15], 1: [4], 2: [8, 8, 9]])
        #expect(points.map(\.position) == [1, 2, 3])
        #expect(points.map(\.puttCount) == [1, 3, 2])
        #expect(abs(points[1].averageFeet - 8.3333) < 0.001)
        #expect(points[2].averageFeet == 14.5)
    }

    @Test("Points skip empty positions")
    func pointsSkipEmptyPositions() {
        let points = Service.points(from: [1: [4], 2: []])
        #expect(points.map(\.position) == [1])
    }

    // MARK: Monotonic checks and smoothing

    @Test("Monotonic points are reported clean")
    func monotonicPointsAreReportedClean() {
        #expect(Service.nonMonotonicPositions(in: standard).isEmpty)
    }

    @Test("Shorter or equal positions are flagged")
    func shorterOrEqualPositionsAreFlagged() {
        #expect(Service.nonMonotonicPositions(in: curve(4, 10, 9, 15, 15)) == [3, 5])
    }

    @Test("Smoothing leaves a monotonic curve unchanged")
    func smoothingLeavesMonotonicCurveUnchanged() {
        #expect(Service.smoothedCurve(standard) == standard)
    }

    @Test("Smoothing pools a violating pair")
    func smoothingPoolsAViolatingPair() {
        let smoothed = Service.smoothedCurve(curve(4, 10, 9, 15))
        #expect(smoothed.map(\.averageFeet) == [4, 9.5, 9.5, 15])
        #expect(smoothed.map(\.position) == [1, 2, 3, 4])
    }

    @Test("Smoothing is weighted by putt count")
    func smoothingIsWeightedByPuttCount() {
        let points = [
            PuttingCalibrationPoint(position: 1, averageFeet: 4, puttCount: 1),
            PuttingCalibrationPoint(position: 2, averageFeet: 10, puttCount: 3),
            PuttingCalibrationPoint(position: 3, averageFeet: 9, puttCount: 1)
        ]
        let smoothed = Service.smoothedCurve(points)
        #expect(smoothed[1].averageFeet == 9.75)
        #expect(smoothed[2].averageFeet == 9.75)
    }

    @Test("Smoothing handles cascading violations")
    func smoothingHandlesCascadingViolations() {
        #expect(Service.smoothedCurve(curve(10, 8, 6)).map(\.averageFeet) == [8, 8, 8])
    }

    // MARK: Suggestions

    @Test("Exact distance suggests that position")
    func exactDistanceSuggestsThatPosition() {
        #expect(kind(8, standard) == .position(2))
    }

    @Test("Near lower position snaps down")
    func nearLowerPositionSnapsDown() {
        #expect(kind(9, standard) == .position(2))
    }

    @Test("Mid segment suggests between")
    func midSegmentSuggestsBetween() {
        for target in [10.0, 11, 12] {
            #expect(kind(target, standard) == .between(lower: 2, upper: 3))
        }
    }

    @Test("Near upper position snaps up")
    func nearUpperPositionSnapsUp() {
        #expect(kind(13, standard) == .position(3))
    }

    @Test("Snap boundaries are exact")
    func snapBoundariesAreExact() {
        #expect(kind(9.5, standard) == .between(lower: 2, upper: 3))
        #expect(kind(12.5, standard) == .position(3))
    }

    @Test("Target at or just below shortest suggests position one")
    func targetAtOrJustBelowShortestSuggestsPositionOne() {
        #expect(kind(4, standard) == .position(1))
        #expect(kind(3, standard) == .position(1))
    }

    @Test("Target well below shortest is shorter than calibrated")
    func targetWellBelowShortestIsShorterThanCalibrated() {
        #expect(kind(2, standard) == .shorterThanCalibrated(shortest: 1))
        #expect(kind(0.5, standard) == .shorterThanCalibrated(shortest: 1))
    }

    @Test("Target at or just beyond longest suggests last position")
    func targetAtOrJustBeyondLongestSuggestsLastPosition() {
        #expect(kind(30, standard) == .position(5))
        #expect(kind(32, standard) == .position(5))
    }

    @Test("Target well beyond longest is longer than calibrated")
    func targetWellBeyondLongestIsLongerThanCalibrated() {
        #expect(kind(33, standard) == .longerThanCalibrated(longest: 5))
    }

    @Test("Plateau resolves to the first position reaching target")
    func plateauResolvesToTheFirstPositionReachingTarget() {
        let plateau = Service.smoothedCurve(curve(4, 10, 9, 15))
        #expect(kind(9.5, plateau) == .position(2))
        #expect(kind(9.6, plateau) == .position(3))
    }

    @Test("Empty curve has no suggestion")
    func emptyCurveHasNoSuggestion() {
        #expect(Service.suggestion(forTargetFeet: 10, curve: []) == nil)
    }

    @Test("Single point curve uses the origin segment")
    func singlePointCurveUsesOriginSegment() {
        let single = curve(10)
        #expect(kind(10, single) == .position(1))
        #expect(kind(12, single) == .position(1))
        #expect(kind(13, single) == .longerThanCalibrated(longest: 1))
        #expect(kind(5, single) == .shorterThanCalibrated(shortest: 1))
    }

    @Test("All-equal curve is well defined")
    func allEqualCurveIsWellDefined() {
        let flat = curve(10, 10, 10)
        #expect(kind(10, flat) == .position(1))
        #expect(kind(9, flat) == .position(1))
        #expect(kind(11, flat) == .position(3))
        #expect(kind(13, flat) == .longerThanCalibrated(longest: 3))
    }

    @Test("Trailing plateau extrapolates from last rising segment")
    func trailingPlateauExtrapolatesFromLastRisingSegment() {
        let trailing = curve(4, 8, 14, 14)
        #expect(kind(15, trailing) == .position(4))
        #expect(kind(16, trailing) == .longerThanCalibrated(longest: 4))
    }

    @Test("Highlighted position only for snapped suggestions")
    func highlightedPositionOnlyForSnappedSuggestions() {
        #expect(Service.suggestion(forTargetFeet: 14, curve: standard)?.highlightedPosition == 3)
        #expect(Service.suggestion(forTargetFeet: 11, curve: standard)?.highlightedPosition == nil)
        #expect(Service.suggestion(forTargetFeet: 40, curve: standard)?.highlightedPosition == nil)
    }

    // MARK: Display

    @Test("Titles describe the stroke")
    func titlesDescribeTheStroke() {
        #expect(Service.title(for: PuttStrokeSuggestion(kind: .position(2), targetFeet: 8)) == "Position 2")
        #expect(Service.title(for: PuttStrokeSuggestion(kind: .between(lower: 2, upper: 3), targetFeet: 11)) == "Position 2½")
        #expect(Service.title(for: PuttStrokeSuggestion(kind: .shorterThanCalibrated(shortest: 1), targetFeet: 2)) == "Shorter than 1")
        #expect(Service.title(for: PuttStrokeSuggestion(kind: .longerThanCalibrated(longest: 5), targetFeet: 40)) == "Longer than 5")
    }

    @Test("Details quote calibrated distances")
    func detailsQuoteCalibratedDistances() {
        func detail(_ kind: PuttStrokeSuggestion.Kind) -> String {
            Service.detail(for: PuttStrokeSuggestion(kind: kind, targetFeet: 11), curve: standard)
        }
        #expect(detail(.between(lower: 2, upper: 3)) == "Between 2 (8 ft) and 3 (14 ft)")
        #expect(detail(.position(3)) == "Rolls about 14 ft")
        #expect(detail(.shorterThanCalibrated(shortest: 1)) == "Your shortest stroke rolls 4 ft")
        #expect(detail(.longerThanCalibrated(longest: 5)) == "Your longest stroke rolls 30 ft")
    }

    @Test("Feet formatting drops trailing zero")
    func feetFormattingDropsTrailingZero() {
        #expect(Service.formatFeet(8) == "8 ft")
        #expect(Service.formatFeet(9.333) == "9.3 ft")
        #expect(Service.formatFeet(9.96) == "10 ft")
    }

    // MARK: Ladder adapters

    @Test("Text ladder items use rounded feet and position labels")
    func textLadderItemsUseRoundedFeetAndPositionLabels() {
        let items = Service.textLadderItems(from: curve(4, 8.4, 13.6))
        #expect(items.map(\.id) == ["position-1", "position-2", "position-3"])
        #expect(items.map(\.distance) == [4, 8, 14])
        #expect(items.map(\.primaryLabel) == ["Position 1", "Position 2", "Position 3"])
        #expect(items.allSatisfy { $0.secondaryLabel.isEmpty })
    }

    @Test("Text ladder anchors between positions")
    func textLadderAnchorsBetweenPositions() {
        let ladder = DistanceTextLadderService.ladder(
            items: Service.textLadderItems(from: standard),
            targetDistance: 11,
            selectedItemID: nil
        )
        #expect(ladder.targetMarkerInsertionIndex == 3)
        #expect(ladder.anchorRowID == "position-3")
    }

    @Test("Grouped ladder entries flag the highlighted position")
    func groupedLadderEntriesFlagHighlightedPosition() throws {
        let groups = Service.groupedLadderEntries(from: standard, highlightedPosition: 3)
        #expect(groups.count == 5)
        let entry = try #require(groups.flatMap(\.entries).first { $0.clubNickname == "P3" })
        #expect(entry.isSelected)
        #expect(entry.isPrimaryShotType)
        #expect(entry.shotTypeName.isEmpty)
        #expect(entry.carryDistance == 14)
    }

    // MARK: Calibration age

    @Test("Calibration age describes today, yesterday and date")
    func calibrationAgeDescribesTodayYesterdayAndDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        calendar.locale = Locale(identifier: "en_US_POSIX")
        func date(_ day: Int, _ hour: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
        }
        let now = date(17, 12)
        #expect(Service.calibrationAgeDescription(date(17, 8), now: now, calendar: calendar) == "Today")
        #expect(Service.calibrationAgeDescription(date(16, 20), now: now, calendar: calendar) == "Yesterday")
        #expect(Service.calibrationAgeDescription(date(12, 9), now: now, calendar: calendar) == "Oct 12")
    }

    // MARK: Position names

    private let kneeNames = PuttingPositionNames(custom: [2: "Knee"])

    @Test("Text ladder uses custom labels and keeps ids")
    func textLadderUsesCustomNames() {
        let items = Service.textLadderItems(from: standard, names: kneeNames)
        #expect(items.first { $0.id == "position-2" }?.primaryLabel == "Knee")
        #expect(items.first { $0.id == "position-3" }?.primaryLabel == "Position 3")
    }

    @Test("Grouped ladder entries use custom names and keep nicknames")
    func groupedEntriesUseCustomNames() throws {
        let groups = Service.groupedLadderEntries(from: standard, highlightedPosition: nil, names: kneeNames)
        let entry = try #require(groups.flatMap(\.entries).first { $0.clubNickname == "P2" })
        #expect(entry.clubName == "Knee")
    }

    @Test("Titles use custom names")
    func titlesUseCustomNames() {
        let exact = PuttStrokeSuggestion(kind: .position(2), targetFeet: 8)
        let between = PuttStrokeSuggestion(kind: .between(lower: 2, upper: 3), targetFeet: 11)
        #expect(Service.title(for: exact, names: kneeNames) == "Knee")
        #expect(Service.title(for: between, names: kneeNames) == "Knee½")
        #expect(Service.title(for: between) == "Position 2½")
    }

    @Test("Position parses from item id")
    func positionFromItemID() {
        #expect(Service.position(fromItemID: "position-3") == 3)
        #expect(Service.position(fromItemID: "foo") == nil)
        #expect(Service.position(fromItemID: "position-x") == nil)
    }
}
