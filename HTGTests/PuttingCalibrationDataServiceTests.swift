import Testing
import SwiftData
import Foundation
@testable import HTG

@Suite("PuttingCalibrationDataService Tests")
@MainActor
struct PuttingCalibrationDataServiceTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([PuttingCalibration.self, PuttingCalibrationPutt.self])
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
}
