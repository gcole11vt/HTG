import Foundation
import SwiftData

enum PuttingCalibrationDataServiceError: Error, Equatable {
    case invalidPositionCount
    case missingPutts(position: Int)
    case unexpectedPosition(Int)
    case puttOutOfRange
    case invalidPosition
}

@MainActor
final class PuttingCalibrationDataService: Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Validates everything before inserting, then saves parent and children in one `save()`.
    func saveCalibration(
        positionCount: Int,
        puttsByPosition: [Int: [Double]],
        now: Date = Date()
    ) async throws -> PuttingCalibrationSnapshot {
        try validate(positionCount: positionCount, puttsByPosition: puttsByPosition)
        let calibration = PuttingCalibration(createdAt: now, positionCount: positionCount)
        calibration.updatedAt = now
        modelContext.insert(calibration)
        for position in 1...positionCount {
            for (sequence, feet) in (puttsByPosition[position] ?? []).enumerated() {
                let putt = PuttingCalibrationPutt(
                    position: position, sequence: sequence, distanceFeet: feet, calibration: calibration
                )
                putt.updatedAt = now
                modelContext.insert(putt)
            }
        }
        try modelContext.save()
        return snapshot(from: calibration)
    }

    func latestSnapshot() async throws -> PuttingCalibrationSnapshot? {
        try latestCalibration().map(snapshot(from:))
    }

    func latestPositionCount() async throws -> Int? {
        try latestCalibration()?.positionCount
    }

    // MARK: Position names

    static let maxNameLength = 20

    /// Trimmed and capped; nil when blank.
    static func normalizedName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxNameLength))
    }

    /// Live typing cap; does not trim so spaces can be typed mid-name.
    static func clampedEntryText(_ raw: String) -> String {
        String(raw.prefix(maxNameLength))
    }

    func positionNames() async throws -> PuttingPositionNames {
        let rows = try modelContext.fetch(FetchDescriptor<PuttingPositionName>())
        return PuttingPositionNames(custom: Dictionary(rows.map { ($0.position, $0.name) }) { _, latest in latest })
    }

    /// Blank or default-equal names delete the row. Returns the resolved display name.
    @discardableResult
    func renamePosition(_ position: Int, to rawName: String, now: Date = Date()) async throws -> String {
        guard (1...PuttingCalibrationRules.positionCountRange.upperBound).contains(position) else {
            throw PuttingCalibrationDataServiceError.invalidPosition
        }
        let defaultName = PuttingPositionNames.defaultName(for: position)
        let existing = try modelContext.fetch(
            FetchDescriptor<PuttingPositionName>(predicate: #Predicate { $0.position == position })
        )
        guard let name = Self.normalizedName(rawName), name != defaultName else {
            existing.forEach(modelContext.delete)
            try modelContext.save()
            return defaultName
        }
        if let row = existing.first {
            row.name = name
            row.updatedAt = now
        } else {
            let row = PuttingPositionName(position: position, name: name)
            row.updatedAt = now
            modelContext.insert(row)
        }
        try modelContext.save()
        return name
    }

    private func latestCalibration() throws -> PuttingCalibration? {
        var descriptor = FetchDescriptor<PuttingCalibration>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func validate(positionCount: Int, puttsByPosition: [Int: [Double]]) throws {
        guard PuttingCalibrationRules.positionCountRange.contains(positionCount) else {
            throw PuttingCalibrationDataServiceError.invalidPositionCount
        }
        if let extra = puttsByPosition.keys.sorted().first(where: { !(1...positionCount).contains($0) }) {
            throw PuttingCalibrationDataServiceError.unexpectedPosition(extra)
        }
        let allowed = Double(PuttingCalibrationRules.puttFeetRange.lowerBound)...Double(PuttingCalibrationRules.puttFeetRange.upperBound)
        for position in 1...positionCount {
            guard let putts = puttsByPosition[position], !putts.isEmpty else {
                throw PuttingCalibrationDataServiceError.missingPutts(position: position)
            }
            guard putts.allSatisfy({ allowed.contains($0) }) else {
                throw PuttingCalibrationDataServiceError.puttOutOfRange
            }
        }
    }

    private func snapshot(from calibration: PuttingCalibration) -> PuttingCalibrationSnapshot {
        let grouped = Dictionary(grouping: calibration.putts, by: \.position)
        return PuttingCalibrationSnapshot(
            id: calibration.id,
            createdAt: calibration.createdAt,
            positionCount: calibration.positionCount,
            puttsByPosition: grouped.mapValues { $0.sorted { $0.sequence < $1.sequence }.map(\.distanceFeet) }
        )
    }
}
