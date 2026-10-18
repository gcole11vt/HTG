import Testing
import SwiftData
import Foundation
@testable import HTG

@Suite("PuttingModeViewModel Tests")
@MainActor
struct PuttingModeViewModelTests {
    private let standardPutts: [Int: [Double]] = [1: [4], 2: [8], 3: [14], 4: [21], 5: [30]]

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            UserProfile.self, PreShotRoutineItem.self, SwingThought.self,
            PuttingCalibration.self, PuttingCalibrationPutt.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func seed(_ container: ModelContainer, at date: Date = Date()) async throws {
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        _ = try await service.saveCalibration(positionCount: 5, puttsByPosition: standardPutts, now: date)
    }

    @Test("Loads without a calibration")
    func loadsWithoutCalibration() async throws {
        let container = try makeContainer()
        let viewModel = PuttingModeViewModel(modelContext: container.mainContext)
        await viewModel.load()

        #expect(!viewModel.hasCalibration)
        #expect(viewModel.suggestion == nil)
        #expect(viewModel.textLadder.rows.isEmpty)
        #expect(viewModel.targetFeet == 10)
        #expect(viewModel.hasLoaded)
    }

    @Test("Loads the latest calibration and suggests")
    func loadsLatestCalibrationAndSuggests() async throws {
        let container = try makeContainer()
        try await seed(container)
        let viewModel = PuttingModeViewModel(modelContext: container.mainContext)
        await viewModel.load()

        #expect(viewModel.suggestion?.kind == .between(lower: 2, upper: 3))
        #expect(viewModel.suggestionTitle == "Position 2½")
        #expect(viewModel.suggestionDetail == "Between 2 (8 ft) and 3 (14 ft)")
    }

    @Test("Setting target clamps and bumps recenter")
    func setTargetFeetClampsAndBumpsRecenter() async throws {
        let container = try makeContainer()
        let viewModel = PuttingModeViewModel(modelContext: container.mainContext)
        let before = viewModel.recenterGeneration

        viewModel.setTargetFeet(0)
        #expect(viewModel.targetFeet == 1)
        viewModel.setTargetFeet(150)
        #expect(viewModel.targetFeet == 99)
        #expect(viewModel.recenterGeneration == before + 2)
    }

    @Test("Load bumps recenter generation")
    func loadBumpsRecenterGeneration() async throws {
        let container = try makeContainer()
        let viewModel = PuttingModeViewModel(modelContext: container.mainContext)
        let before = viewModel.recenterGeneration
        await viewModel.load()
        #expect(viewModel.recenterGeneration == before + 1)
    }

    @Test("Exact target highlights the text ladder row")
    func exactTargetHighlightsTextLadderRow() async throws {
        let container = try makeContainer()
        try await seed(container)
        let viewModel = PuttingModeViewModel(modelContext: container.mainContext)
        await viewModel.load()
        viewModel.setTargetFeet(14)

        #expect(viewModel.textLadder.rows.first { $0.isSelected }?.id == "position-3")
    }

    @Test("View style follows the Golf Mode setting")
    func viewStyleFollowsGolfModeSetting() async throws {
        let container = try makeContainer()
        let viewModel = PuttingModeViewModel(modelContext: container.mainContext)
        await viewModel.load()
        #expect(viewModel.viewStyle == .text)

        try await ProfileDataService(modelContext: container.mainContext).updateGolfModeViewStyle(.ladder)
        await viewModel.load()
        #expect(viewModel.viewStyle == .ladder)
    }

    @Test("Calibration saved reloads the latest calibration")
    func calibrationSavedReloadsLatestCalibration() async throws {
        let container = try makeContainer()
        let viewModel = PuttingModeViewModel(modelContext: container.mainContext)
        await viewModel.load()
        #expect(!viewModel.hasCalibration)

        try await seed(container)
        await viewModel.calibrationSaved()
        #expect(viewModel.hasCalibration)
    }

    @Test("Status text describes calibration age")
    func statusTextDescribesCalibrationAge() async throws {
        let container = try makeContainer()
        try await seed(container)
        let viewModel = PuttingModeViewModel(modelContext: container.mainContext)
        await viewModel.load()
        #expect(viewModel.calibrationStatusText == "Aligned Today")
        #expect(!viewModel.isCalibrationStale)

        await viewModel.load(now: Date().addingTimeInterval(86_400))
        #expect(viewModel.calibrationStatusText == "Aligned Yesterday")
        #expect(viewModel.isCalibrationStale)
    }

    @Test("Initial wizard position count defaults then follows latest")
    func initialPositionCountForWizard() async throws {
        let container = try makeContainer()
        let viewModel = PuttingModeViewModel(modelContext: container.mainContext)
        #expect(await viewModel.initialPositionCountForWizard() == 5)
    }
}
