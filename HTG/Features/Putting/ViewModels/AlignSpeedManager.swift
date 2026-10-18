import Foundation
import SwiftData

/// Drives the Align Speed wizard. Putts live in memory until the final save, so cancelling saves nothing.
@MainActor
@Observable
final class AlignSpeedManager {
    enum Step: Equatable {
        case setup
        case position(Int)
        case review
    }

    private let calibrationService: PuttingCalibrationDataService
    private let entryValidator = YardageEntryValidationService(validRange: PuttingCalibrationRules.puttFeetRange)

    private(set) var step: Step = .setup
    private(set) var positionCount: Int
    private(set) var puttsByPosition: [Int: [Double]] = [:]
    private(set) var isSaving = false
    private(set) var didSave = false
    var errorMessage: String?
    var puttEntryText: String = ""

    init(modelContext: ModelContext, initialPositionCount: Int) {
        calibrationService = PuttingCalibrationDataService(modelContext: modelContext)
        positionCount = Self.clamped(initialPositionCount)
    }

    private static func clamped(_ count: Int) -> Int {
        let range = PuttingCalibrationRules.positionCountRange
        return min(max(count, range.lowerBound), range.upperBound)
    }

    // MARK: Setup

    /// Setup step only. Clamps to the allowed range and drops putts for positions that no longer exist.
    func setPositionCount(_ count: Int) {
        guard step == .setup else { return }
        positionCount = Self.clamped(count)
        puttsByPosition = puttsByPosition.filter { $0.key <= positionCount }
    }

    // MARK: Current position

    var currentPosition: Int? {
        if case .position(let position) = step { return position }
        return nil
    }

    var currentPutts: [Double] {
        currentPosition.flatMap { puttsByPosition[$0] } ?? []
    }

    var currentAverage: Double? {
        PuttingSpeedCurveService.averageFeet(currentPutts)
    }

    var sanitizedEntryText: String {
        entryValidator.sanitizedEntryText(puttEntryText)
    }

    var canAddPutt: Bool {
        currentPosition != nil && entryValidator.validatedYardage(from: puttEntryText) != nil
    }

    @discardableResult
    func addPutt() -> Bool {
        guard let position = currentPosition,
              let feet = entryValidator.validatedYardage(from: puttEntryText) else { return false }
        puttsByPosition[position, default: []].append(Double(feet))
        puttEntryText = ""
        return true
    }

    func removePutt(at index: Int) {
        guard let position = currentPosition,
              var putts = puttsByPosition[position],
              putts.indices.contains(index) else { return }
        putts.remove(at: index)
        puttsByPosition[position] = putts.isEmpty ? nil : putts
    }

    /// Set when this position's average is no longer than the previous position's.
    var currentWarning: String? {
        guard let position = currentPosition, position > 1,
              let average = currentAverage,
              let previous = PuttingSpeedCurveService.averageFeet(puttsByPosition[position - 1] ?? []),
              average <= previous else { return nil }
        let previousText = PuttingSpeedCurveService.formatFeet(previous)
        return "Shorter than position \(position - 1) (\(previousText)). Roll it again, or keep it."
    }

    // MARK: Navigation

    var canGoBack: Bool { step != .setup && !isSaving }

    var canAdvance: Bool {
        switch step {
        case .setup: true
        case .position: !currentPutts.isEmpty
        case .review: !isSaving
        }
    }

    func goBack() {
        guard canGoBack else { return }
        puttEntryText = ""
        switch step {
        case .setup: break
        case .position(let position): step = position > 1 ? .position(position - 1) : .setup
        case .review: step = .position(positionCount)
        }
    }

    func advance() async {
        guard canAdvance else { return }
        puttEntryText = ""
        switch step {
        case .setup: step = .position(1)
        case .position(let position): step = position < positionCount ? .position(position + 1) : .review
        case .review: await save()
        }
    }

    // MARK: Review and save

    var reviewPoints: [PuttingCalibrationPoint] {
        PuttingSpeedCurveService.points(from: puttsByPosition)
    }

    var reviewWarnings: [Int] {
        PuttingSpeedCurveService.nonMonotonicPositions(in: reviewPoints)
    }

    var hasUnsavedPutts: Bool {
        !didSave && puttsByPosition.values.contains { !$0.isEmpty }
    }

    func cancel() {
        puttsByPosition = [:]
        puttEntryText = ""
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await calibrationService.saveCalibration(
                positionCount: positionCount, puttsByPosition: puttsByPosition
            )
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
