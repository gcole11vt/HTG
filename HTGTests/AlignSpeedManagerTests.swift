import Testing
import SwiftData
import Foundation
@testable import HTG

@Suite("AlignSpeedManager Tests")
@MainActor
struct AlignSpeedManagerTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([PuttingCalibration.self, PuttingCalibrationPutt.self, PuttingPositionName.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeManager(count: Int = 5) throws -> (AlignSpeedManager, ModelContainer) {
        let container = try makeContainer()
        return (AlignSpeedManager(modelContext: container.mainContext, initialPositionCount: count), container)
    }

    private func roll(_ manager: AlignSpeedManager, _ feet: String) {
        manager.puttEntryText = feet
        manager.addPutt()
    }

    @Test("Starts at setup and clamps the position count")
    func startsAtSetupWithInitialPositionCount() throws {
        let (six, _) = try makeManager(count: 6)
        #expect(six.step == .setup)
        #expect(six.positionCount == 6)
        #expect(try makeManager(count: 0).0.positionCount == 3)
        #expect(try makeManager(count: 12).0.positionCount == 8)
    }

    @Test("setPositionCount clamps to 3...8")
    func positionCountBounds() throws {
        let (manager, _) = try makeManager()
        manager.setPositionCount(2)
        #expect(manager.positionCount == 3)
        manager.setPositionCount(9)
        #expect(manager.positionCount == 8)
        manager.setPositionCount(7)
        #expect(manager.positionCount == 7)
    }

    @Test("Begin moves to position one")
    func beginMovesToPositionOne() async throws {
        let (manager, _) = try makeManager()
        #expect(!manager.canGoBack)
        await manager.advance()
        #expect(manager.step == .position(1))
        #expect(manager.currentPosition == 1)
        #expect(manager.canGoBack)
    }

    @Test("addPutt records a valid entry and clears the field")
    func addPuttRecordsValidEntry() async throws {
        let (manager, _) = try makeManager()
        await manager.advance()
        manager.puttEntryText = "9"
        #expect(manager.canAddPutt)
        #expect(manager.addPutt())
        #expect(manager.currentPutts == [9])
        #expect(manager.puttEntryText.isEmpty)
    }

    @Test("addPutt rejects invalid entries")
    func addPuttRejectsInvalidEntry() async throws {
        let (manager, _) = try makeManager()
        await manager.advance()
        for text in ["", "0", "100"] {
            manager.puttEntryText = text
            #expect(!manager.canAddPutt)
            #expect(!manager.addPutt())
        }
        #expect(manager.currentPutts.isEmpty)
    }

    @Test("Average updates as putts are added and removed")
    func averageUpdatesAsPuttsAreAdded() async throws {
        let (manager, _) = try makeManager()
        await manager.advance()
        #expect(manager.currentAverage == nil)
        roll(manager, "8")
        roll(manager, "10")
        #expect(manager.currentAverage == 9)
        manager.removePutt(at: 0)
        #expect(manager.currentPutts == [10])
        manager.removePutt(at: 5)
        #expect(manager.currentPutts == [10])
    }

    @Test("Cannot advance a position without a putt")
    func cannotAdvanceWithoutAPutt() async throws {
        let (manager, _) = try makeManager()
        await manager.advance()
        #expect(!manager.canAdvance)
        await manager.advance()
        #expect(manager.step == .position(1))
    }

    @Test("Walks every position then review")
    func walksAllPositionsThenReview() async throws {
        let (manager, _) = try makeManager(count: 3)
        await manager.advance()
        roll(manager, "5")
        await manager.advance()
        #expect(manager.step == .position(2))
        roll(manager, "9")
        await manager.advance()
        #expect(manager.step == .position(3))
        roll(manager, "14")
        await manager.advance()
        #expect(manager.step == .review)
        #expect(!manager.didSave)
    }

    @Test("Going back preserves putts")
    func goingBackPreservesPutts() async throws {
        let (manager, _) = try makeManager(count: 3)
        await manager.advance()
        roll(manager, "5")
        await manager.advance()
        manager.goBack()
        #expect(manager.step == .position(1))
        #expect(manager.currentPutts == [5])
        manager.goBack()
        #expect(manager.step == .setup)
        #expect(!manager.canGoBack)
    }

    @Test("Warns when a position rolls shorter than the previous one")
    func warnsWhenPositionRollsShorterThanPrevious() async throws {
        let (manager, _) = try makeManager()
        await manager.advance()
        roll(manager, "10")
        #expect(manager.currentWarning == nil)
        await manager.advance()
        roll(manager, "8")
        #expect(manager.currentWarning == "Shorter than position 1 (10 ft). Roll it again, or keep it.")
        manager.removePutt(at: 0)
        roll(manager, "12")
        #expect(manager.currentWarning == nil)
    }

    @Test("Reducing the position count drops extra putts")
    func reducingPositionCountDropsExtraPutts() async throws {
        let (manager, _) = try makeManager(count: 5)
        await manager.advance()
        roll(manager, "4")
        await manager.advance()
        roll(manager, "8")
        await manager.advance()
        roll(manager, "12")
        manager.goBack()
        manager.goBack()
        manager.goBack()
        #expect(manager.puttsByPosition[3] == [12])
        manager.setPositionCount(3)
        #expect(Set(manager.puttsByPosition.keys) == [1, 2, 3])
        manager.setPositionCount(4)
        manager.setPositionCount(3)
        #expect(manager.puttsByPosition[3] == [12])
        manager.setPositionCount(2)
        #expect(manager.positionCount == 3)
    }

    @Test("Review lists averages and flags short rolls")
    func reviewListsAveragesAndWarnings() async throws {
        let (manager, _) = try makeManager(count: 3)
        for feet in ["10", "12", "11"] {
            await manager.advance()
            roll(manager, feet)
        }
        await manager.advance()
        #expect(manager.step == .review)
        #expect(manager.reviewPoints.map(\.averageFeet) == [10, 12, 11])
        #expect(manager.reviewWarnings == [3])
    }

    @Test("Saving from review activates the calibration")
    func saveFromReviewPersists() async throws {
        let (manager, container) = try makeManager(count: 3)
        for feet in ["4", "9", "15"] {
            await manager.advance()
            roll(manager, feet)
        }
        await manager.advance()
        await manager.advance()
        #expect(manager.didSave)
        #expect(!manager.hasUnsavedPutts)
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        let snapshot = try await service.latestSnapshot()
        #expect(snapshot?.positionCount == 3)
        #expect(snapshot?.puttsByPosition == [1: [4], 2: [9], 3: [15]])
    }

    @Test("hasUnsavedPutts tracks the draft")
    func hasUnsavedPuttsTracksDraft() async throws {
        let (manager, _) = try makeManager()
        #expect(!manager.hasUnsavedPutts)
        await manager.advance()
        roll(manager, "6")
        #expect(manager.hasUnsavedPutts)
    }

    @Test("Cancelling without saving persists nothing")
    func cancelDiscards() async throws {
        let (manager, container) = try makeManager(count: 3)
        await manager.advance()
        roll(manager, "6")
        manager.cancel()
        #expect(manager.puttsByPosition.isEmpty)
        #expect(!manager.hasUnsavedPutts)
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        #expect(try await service.latestSnapshot() == nil)
    }

    // MARK: Position names

    @Test("Current position name is the default, nil outside a position step")
    func currentPositionNameDefault() async throws {
        let (manager, _) = try makeManager()
        #expect(manager.currentPositionName == nil)
        await manager.advance()
        #expect(manager.currentPositionName == "Position 1")
    }

    @Test("loadPositionNames picks up persisted names")
    func loadPositionNamesPicksUpPersisted() async throws {
        let (manager, container) = try makeManager(count: 3)
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        try await service.renamePosition(2, to: "Knee")
        await manager.loadPositionNames()

        #expect(manager.name(for: 2) == "Knee")
        #expect(manager.name(for: 1) == "Position 1")
    }

    @Test("renameCurrentPosition persists immediately, even after cancel")
    func renameCurrentPositionPersists() async throws {
        let (manager, container) = try makeManager(count: 3)
        await manager.advance()
        await manager.renameCurrentPosition("Knee")
        #expect(manager.currentPositionName == "Knee")

        manager.cancel()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        #expect(try await service.positionNames().name(for: 1) == "Knee")
    }

    @Test("renameCurrentPosition is a no-op outside a position step")
    func renameCurrentPositionNoOpOutsidePosition() async throws {
        let (manager, container) = try makeManager(count: 3)
        await manager.renameCurrentPosition("Nope")
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        #expect(try await service.positionNames().custom.isEmpty)
    }
}
