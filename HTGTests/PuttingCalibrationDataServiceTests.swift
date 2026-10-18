import Testing
import SwiftData
import Foundation
@testable import HTG

@Suite("PuttingCalibrationDataService Tests")
@MainActor
struct PuttingCalibrationDataServiceTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([PuttingCalibration.self, PuttingCalibrationPutt.self, PuttingPositionName.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func counts(_ container: ModelContainer) throws -> (Int, Int) {
        let context = container.mainContext
        return (
            try context.fetchCount(FetchDescriptor<PuttingCalibration>()),
            try context.fetchCount(FetchDescriptor<PuttingCalibrationPutt>())
        )
    }

    @Test("Save persists putts in entry order")
    func saveCalibrationPersistsPuttsInEntryOrder() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)

        _ = try await service.saveCalibration(positionCount: 3, puttsByPosition: [1: [5, 4], 2: [9], 3: [14]])

        #expect(try counts(container).1 == 4)
        #expect(try await service.latestSnapshot()?.puttsByPosition[1] == [5, 4])
    }

    @Test("Save rejects a missing position")
    func saveRejectsMissingPosition() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)

        await #expect(throws: PuttingCalibrationDataServiceError.missingPutts(position: 3)) {
            _ = try await service.saveCalibration(positionCount: 3, puttsByPosition: [1: [5], 2: [9]])
        }
        let stored = try counts(container)
        #expect(stored.0 == 0 && stored.1 == 0)
    }

    @Test("Save rejects a position count outside range")
    func saveRejectsPositionCountOutsideRange() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)

        for count in [2, 9] {
            await #expect(throws: PuttingCalibrationDataServiceError.invalidPositionCount) {
                _ = try await service.saveCalibration(positionCount: count, puttsByPosition: [:])
            }
        }
    }

    @Test("Save rejects a putt outside the feet range")
    func saveRejectsPuttOutsideFeetRange() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)

        for bad in [0.0, 100] {
            await #expect(throws: PuttingCalibrationDataServiceError.puttOutOfRange) {
                _ = try await service.saveCalibration(positionCount: 3, puttsByPosition: [1: [bad], 2: [9], 3: [14]])
            }
        }
        #expect(try counts(container).0 == 0)
    }

    @Test("Save rejects positions outside the count")
    func saveRejectsExtraPositions() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)

        await #expect(throws: PuttingCalibrationDataServiceError.self) {
            _ = try await service.saveCalibration(positionCount: 3, puttsByPosition: [1: [5], 2: [9], 3: [14], 4: [20]])
        }
    }

    @Test("Latest snapshot is the newest calibration")
    func latestSnapshotIsNewestCalibration() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        #expect(try await service.latestSnapshot() == nil)

        let t0 = Date(timeIntervalSince1970: 1_000_000)
        _ = try await service.saveCalibration(positionCount: 3, puttsByPosition: [1: [4], 2: [8], 3: [14]], now: t0)
        let second = try await service.saveCalibration(
            positionCount: 3, puttsByPosition: [1: [5], 2: [9], 3: [15]], now: t0.addingTimeInterval(60)
        )

        let latest = try await service.latestSnapshot()
        #expect(latest?.id == second.id)
        #expect(latest?.puttsByPosition[1] == [5])
    }

    @Test("Latest position count comes from the newest calibration")
    func latestPositionCountComesFromNewestCalibration() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        #expect(try await service.latestPositionCount() == nil)

        _ = try await service.saveCalibration(
            positionCount: 6, puttsByPosition: [1: [3], 2: [5], 3: [8], 4: [12], 5: [17], 6: [23]]
        )
        #expect(try await service.latestPositionCount() == 6)
    }

    // MARK: Position names

    private func nameCount(_ container: ModelContainer) throws -> Int {
        try container.mainContext.fetchCount(FetchDescriptor<PuttingPositionName>())
    }

    @Test("Position names default when nothing is stored")
    func positionNamesDefaultWhenEmpty() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        let names = try await service.positionNames()
        #expect(names.name(for: 3) == "Position 3")
        #expect(!names.isCustom(3))
    }

    @Test("Rename persists across services")
    func renamePersists() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        let resolved = try await service.renamePosition(2, to: "Knee")
        #expect(resolved == "Knee")

        let other = PuttingCalibrationDataService(modelContext: container.mainContext)
        let names = try await other.positionNames()
        #expect(names.name(for: 2) == "Knee")
        #expect(names.isCustom(2))
    }

    @Test("Rename trims whitespace")
    func renameTrimsWhitespace() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        #expect(try await service.renamePosition(2, to: "  Knee  ") == "Knee")
    }

    @Test("Blank rename reverts to the default and deletes the row")
    func blankRenameReverts() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        try await service.renamePosition(2, to: "Knee")
        let resolved = try await service.renamePosition(2, to: "   ")
        #expect(resolved == "Position 2")
        #expect(try nameCount(container) == 0)
        #expect(try await service.positionNames().name(for: 2) == "Position 2")
    }

    @Test("Renaming to the default text stores no row")
    func renameToDefaultStoresNothing() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        #expect(try await service.renamePosition(2, to: "Position 2") == "Position 2")
        #expect(try nameCount(container) == 0)
    }

    @Test("Renaming twice updates the same row")
    func renameTwiceUpdatesSameRow() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        try await service.renamePosition(2, to: "Knee")
        try await service.renamePosition(2, to: "Hip")
        #expect(try nameCount(container) == 1)
        #expect(try await service.positionNames().name(for: 2) == "Hip")
    }

    @Test("Rename rejects positions outside range")
    func renameRejectsInvalidPosition() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        await #expect(throws: PuttingCalibrationDataServiceError.invalidPosition) {
            try await service.renamePosition(0, to: "Zero")
        }
        await #expect(throws: PuttingCalibrationDataServiceError.invalidPosition) {
            try await service.renamePosition(9, to: "Nine")
        }
        #expect(try nameCount(container) == 0)
    }

    @Test("Names are capped at 20 characters")
    func namesAreCapped() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        let long = String(repeating: "a", count: 30)
        #expect(try await service.renamePosition(1, to: long).count == 20)
        #expect(PuttingCalibrationDataService.clampedEntryText(long).count == 20)
        #expect(PuttingCalibrationDataService.maxNameLength == 20)
    }

    @Test("Names survive a new calibration")
    func namesSurviveNewCalibration() async throws {
        let container = try makeContainer()
        let service = PuttingCalibrationDataService(modelContext: container.mainContext)
        try await service.renamePosition(2, to: "Knee")
        _ = try await service.saveCalibration(positionCount: 3, puttsByPosition: [1: [4], 2: [8], 3: [14]])
        _ = try await service.saveCalibration(positionCount: 3, puttsByPosition: [1: [5], 2: [9], 3: [15]])
        #expect(try await service.positionNames().name(for: 2) == "Knee")
    }
}
