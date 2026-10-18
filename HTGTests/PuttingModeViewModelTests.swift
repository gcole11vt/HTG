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
            PuttingCalibration.self, PuttingCalibrationPutt.self, PuttingPositionName.self
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

    @Test("Custom names show in the ladder and suggestion title")
    func customNamesShowInLadderAndTitle() async throws {
        let container = try makeContainer()
        try await seed(container)
        try await PuttingCalibrationDataService(modelContext: container.mainContext).renamePosition(3, to: "Knee")
        let viewModel = PuttingModeViewModel(modelContext: container.mainContext)
        await viewModel.load()
        viewModel.setTargetFeet(14)

        #expect(viewModel.suggestionTitle == "Knee")
        #expect(viewModel.textLadder.rows.contains { $0.item.primaryLabel == "Knee" })
    }

    @Test("beginRename sets a request for the row position")
    func beginRenameSetsRequest() async throws {
        let container = try makeContainer()
        try await seed(container)
        let viewModel = PuttingModeViewModel(modelContext: container.mainContext)
        await viewModel.load()

        viewModel.beginRename(itemID: "position-3")
        #expect(viewModel.renameRequest?.position == 3)
        #expect(viewModel.renameRequest?.currentName == "Position 3")
        #expect(viewModel.renameRequest?.defaultName == "Position 3")

        viewModel.beginRename(itemID: "bogus")
        #expect(viewModel.renameRequest?.position == 3)
    }

    @Test("renamePosition updates, persists and clears the request")
    func renamePositionPersists() async throws {
        let container = try makeContainer()
        try await seed(container)
        let viewModel = PuttingModeViewModel(modelContext: container.mainContext)
        await viewModel.load()
        viewModel.beginRename(itemID: "position-3")

        await viewModel.renamePosition(3, to: "Hip")
        #expect(viewModel.renameRequest == nil)
        #expect(viewModel.textLadder.rows.contains { $0.item.primaryLabel == "Hip" })

        let fresh = PuttingModeViewModel(modelContext: container.mainContext)
        await fresh.load()
        #expect(fresh.textLadder.rows.contains { $0.item.primaryLabel == "Hip" })
    }

    @Test("Blank rename reverts to the default label")
    func blankRenameReverts() async throws {
        let container = try makeContainer()
        try await seed(container)
        let viewModel = PuttingModeViewModel(modelContext: container.mainContext)
        await viewModel.load()
        await viewModel.renamePosition(3, to: "Hip")
        await viewModel.renamePosition(3, to: "   ")
        #expect(viewModel.textLadder.rows.contains { $0.item.primaryLabel == "Position 3" })
    }
}
