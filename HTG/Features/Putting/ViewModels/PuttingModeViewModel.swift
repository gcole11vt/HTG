import Foundation
import SwiftData

@MainActor
@Observable
final class PuttingModeViewModel {
    private let calibrationService: PuttingCalibrationDataService
    private let profileService: ProfileDataService

    private(set) var targetFeet = PuttingCalibrationRules.defaultTargetFeet
    private(set) var calibration: PuttingCalibrationSnapshot?
    private(set) var viewStyle: DistanceViewStyle = .defaultStyle
    /// Bump = "scroll the text ladder back to the target".
    private(set) var recenterGeneration = 0
    private(set) var hasLoaded = false
    private var loadedAt = Date()
    var errorMessage: String?

    init(modelContext: ModelContext) {
        calibrationService = PuttingCalibrationDataService(modelContext: modelContext)
        profileService = ProfileDataService(modelContext: modelContext)
    }

    // MARK: Derived state

    var hasCalibration: Bool { calibration != nil }

    /// Smoothed so what the ladder shows matches what is suggested.
    var curve: [PuttingCalibrationPoint] {
        guard let calibration else { return [] }
        return PuttingSpeedCurveService.smoothedCurve(PuttingSpeedCurveService.points(from: calibration.puttsByPosition))
    }

    var suggestion: PuttStrokeSuggestion? {
        PuttingSpeedCurveService.suggestion(forTargetFeet: Double(targetFeet), curve: curve)
    }

    var suggestionTitle: String {
        suggestion.map(PuttingSpeedCurveService.title(for:)) ?? ""
    }

    var suggestionDetail: String {
        suggestion.map { PuttingSpeedCurveService.detail(for: $0, curve: curve) } ?? ""
    }

    var calibrationStatusText: String {
        guard let calibration else { return "" }
        return "Aligned " + PuttingSpeedCurveService.calibrationAgeDescription(calibration.createdAt, now: loadedAt)
    }

    var isCalibrationStale: Bool {
        guard let calibration else { return false }
        return PuttingSpeedCurveService.calibrationAgeDescription(calibration.createdAt, now: loadedAt) != "Today"
    }

    var textLadder: DistanceTextLadder {
        DistanceTextLadderService.ladder(
            items: PuttingSpeedCurveService.textLadderItems(from: curve),
            targetDistance: targetFeet,
            selectedItemID: suggestion?.highlightedPosition.map(PuttingSpeedCurveService.itemID(position:))
        )
    }

    var groupedLadderEntries: [GroupedLadderEntry] {
        PuttingSpeedCurveService.groupedLadderEntries(from: curve, highlightedPosition: suggestion?.highlightedPosition)
    }

    var ladderMaxFeet: Int {
        let longest = curve.last.map { Int($0.averageFeet.rounded()) } ?? 0
        return max(longest, targetFeet)
    }

    // MARK: Actions

    func load(now: Date = Date()) async {
        do {
            viewStyle = try await profileService.getOrCreateProfile().golfModeViewStyle
            calibration = try await calibrationService.latestSnapshot()
        } catch {
            errorMessage = error.localizedDescription
        }
        loadedAt = now
        hasLoaded = true
        recenterGeneration += 1
    }

    func setTargetFeet(_ feet: Int) {
        let range = PuttingCalibrationRules.puttFeetRange
        targetFeet = min(max(feet, range.lowerBound), range.upperBound)
        recenterGeneration += 1
    }

    func calibrationSaved() async {
        await load()
    }

    func initialPositionCountForWizard() async -> Int {
        (try? await calibrationService.latestPositionCount()) ?? PuttingCalibrationRules.defaultPositionCount
    }
}
