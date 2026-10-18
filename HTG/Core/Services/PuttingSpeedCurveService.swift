import Foundation

/// Pure putting speed-curve math: averaging, smoothing, stroke suggestion and display helpers.
enum PuttingSpeedCurveService {
    static let snapLowerFraction = 0.25
    static let snapUpperFraction = 0.75

    // MARK: Points and smoothing

    static func averageFeet(_ putts: [Double]) -> Double? {
        guard !putts.isEmpty else { return nil }
        return putts.reduce(0, +) / Double(putts.count)
    }

    static func points(from puttsByPosition: [Int: [Double]]) -> [PuttingCalibrationPoint] {
        puttsByPosition.keys.sorted().compactMap { position in
            let putts = puttsByPosition[position] ?? []
            guard let average = averageFeet(putts) else { return nil }
            return PuttingCalibrationPoint(position: position, averageFeet: average, puttCount: putts.count)
        }
    }

    /// Positions whose average is no farther than the previous position's.
    static func nonMonotonicPositions(in points: [PuttingCalibrationPoint]) -> [Int] {
        zip(points, points.dropFirst()).filter { $1.averageFeet <= $0.averageFeet }.map { $1.position }
    }

    /// Weighted pool-adjacent-violators so averages never decrease.
    static func smoothedCurve(_ points: [PuttingCalibrationPoint]) -> [PuttingCalibrationPoint] {
        var blocks: [SmoothingBlock] = []
        for point in points {
            blocks.append(SmoothingBlock(points: [point]))
            while blocks.count > 1, blocks[blocks.count - 2].mean > blocks[blocks.count - 1].mean {
                let last = blocks.removeLast()
                blocks[blocks.count - 1].points += last.points
            }
        }
        return blocks.flatMap { block in
            block.points.map {
                PuttingCalibrationPoint(position: $0.position, averageFeet: block.mean, puttCount: $0.puttCount)
            }
        }
    }

    private struct SmoothingBlock {
        var points: [PuttingCalibrationPoint]

        var mean: Double {
            let weight = points.reduce(0) { $0 + $1.puttCount }
            let total = points.reduce(0.0) { $0 + $1.averageFeet * Double($1.puttCount) }
            return total / Double(weight)
        }
    }

    // MARK: Suggestion

    static func suggestion(forTargetFeet target: Double, curve: [PuttingCalibrationPoint]) -> PuttStrokeSuggestion? {
        guard let first = curve.first, let last = curve.last else { return nil }
        let origin = PuttingCalibrationPoint(position: 0, averageFeet: 0, puttCount: 0)
        let path = [origin] + curve
        let kind: PuttStrokeSuggestion.Kind
        if target <= last.averageFeet, let upperIndex = path.indices.dropFirst().first(where: { path[$0].averageFeet >= target }) {
            let lower = path[upperIndex - 1]
            let upper = path[upperIndex]
            let fraction = (target - lower.averageFeet) / (upper.averageFeet - lower.averageFeet)
            kind = snappedKind(fraction: fraction, lower: lower, upper: upper, shortest: first.position)
        } else {
            let fraction = (target - last.averageFeet) / lastPositiveSegmentWidth(in: path)
            kind = fraction < snapLowerFraction ? .position(last.position) : .longerThanCalibrated(longest: last.position)
        }
        return PuttStrokeSuggestion(kind: kind, targetFeet: target)
    }

    private static func snappedKind(
        fraction: Double,
        lower: PuttingCalibrationPoint,
        upper: PuttingCalibrationPoint,
        shortest: Int
    ) -> PuttStrokeSuggestion.Kind {
        if fraction >= snapUpperFraction { return .position(upper.position) }
        if fraction < snapLowerFraction || lower.position == 0 {
            return lower.position == 0 ? .shorterThanCalibrated(shortest: shortest) : .position(lower.position)
        }
        return .between(lower: lower.position, upper: upper.position)
    }

    /// Always exists: the origin segment has positive width because every putt is at least 1 ft.
    private static func lastPositiveSegmentWidth(in path: [PuttingCalibrationPoint]) -> Double {
        for index in stride(from: path.count - 1, to: 0, by: -1) {
            let width = path[index].averageFeet - path[index - 1].averageFeet
            if width > 0 { return width }
        }
        return 1
    }

    // MARK: Display

    static func title(for suggestion: PuttStrokeSuggestion) -> String {
        switch suggestion.kind {
        case .position(let position): "Position \(position)"
        case .between(let lower, _): "Position \(lower)½"
        case .shorterThanCalibrated(let shortest): "Shorter than \(shortest)"
        case .longerThanCalibrated(let longest): "Longer than \(longest)"
        }
    }

    static func detail(for suggestion: PuttStrokeSuggestion, curve: [PuttingCalibrationPoint]) -> String {
        func feet(_ position: Int) -> String {
            formatFeet(curve.first { $0.position == position }?.averageFeet ?? 0)
        }
        switch suggestion.kind {
        case .position(let position): return "Rolls about \(feet(position))"
        case .between(let lower, let upper): return "Between \(lower) (\(feet(lower))) and \(upper) (\(feet(upper)))"
        case .shorterThanCalibrated(let shortest): return "Your shortest stroke rolls \(feet(shortest))"
        case .longerThanCalibrated(let longest): return "Your longest stroke rolls \(feet(longest))"
        }
    }

    /// At most one decimal, trailing ".0" dropped.
    static func formatFeet(_ feet: Double) -> String {
        let rounded = (feet * 10).rounded() / 10
        if rounded == rounded.rounded() { return "\(Int(rounded)) ft" }
        return String(format: "%.1f ft", rounded)
    }

    // MARK: Ladder adapters

    static func itemID(position: Int) -> String { "position-\(position)" }

    static func textLadderItems(from curve: [PuttingCalibrationPoint]) -> [DistanceTextLadderItem] {
        curve.map {
            DistanceTextLadderItem(
                id: itemID(position: $0.position),
                distance: Int($0.averageFeet.rounded()),
                primaryLabel: "Position \($0.position)",
                secondaryLabel: ""
            )
        }
    }

    static func groupedLadderEntries(
        from curve: [PuttingCalibrationPoint],
        highlightedPosition: Int?
    ) -> [GroupedLadderEntry] {
        let entries = curve.map { point in
            LadderEntry(
                clubName: "Position \(point.position)",
                clubNickname: "P\(point.position)",
                shotTypeName: "",
                carryDistance: Int(point.averageFeet.rounded()),
                yardagePosition: 0,
                isSelected: point.position == highlightedPosition,
                isSameClubAsSelected: false,
                isPrimaryShotType: true
            )
        }
        return Dictionary(grouping: entries, by: \.carryDistance)
            .map { GroupedLadderEntry(id: UUID(), carryDistance: $0.key, entries: $0.value) }
            .sorted { $0.carryDistance < $1.carryDistance }
    }

    // MARK: Calibration age

    static func calibrationAgeDescription(_ date: Date, now: Date, calendar: Calendar = .current) -> String {
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)
        ).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = calendar.locale ?? .current
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }
}
