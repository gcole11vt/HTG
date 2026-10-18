import Foundation
import SwiftData

enum PuttingCalibrationDataServiceError: Error, Equatable {
    case invalidPositionCount
    case missingPutts(position: Int)
    case unexpectedPosition(Int)
    case puttOutOfRange
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
