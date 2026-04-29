import Testing
import SwiftData
@testable import HTG

@Suite("HTG Tests")
@MainActor
struct HTGTests {
    @Test("App launches successfully")
    func appLaunches() async throws {
        #expect(true)
    }

    private func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([RangeSession.self, Shot.self, StoredShotType.self, Club.self, ShotType.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeRangeManager(container: ModelContainer) -> RangeManager {
        RangeManager(modelContext: container.mainContext)
    }

    @Test("Positive integer carry input is valid")
    func positiveIntegerCarryInputIsValid() throws {
        let container = try makeTestContainer()
        let manager = makeRangeManager(container: container)

        #expect(manager.isValidCarryDistanceInput("162"))
        #expect(manager.parsedCarryDistance(from: "162") == 162)
    }

    @Test("Invalid carry inputs are rejected")
    func invalidCarryInputsAreRejected() throws {
        let container = try makeTestContainer()
        let manager = makeRangeManager(container: container)

        #expect(!manager.isValidCarryDistanceInput(""))
        #expect(!manager.isValidCarryDistanceInput("abc"))
        #expect(!manager.isValidCarryDistanceInput("0"))
        #expect(!manager.isValidCarryDistanceInput("-10"))
        #expect(manager.parsedCarryDistance(from: "abc") == nil)
    }

    @Test("Default save distance text uses positive median")
    func defaultSaveDistanceTextUsesPositiveMedian() throws {
        let container = try makeTestContainer()
        let manager = makeRangeManager(container: container)

        manager.currentStats = RangeStats(max: 170, percentile75: 168, median: 162, count: 4)
        #expect(manager.defaultSaveCarryDistanceText() == "162")
    }

    @Test("Default save distance text falls back to max when median is not positive")
    func defaultSaveDistanceTextFallsBackToMax() throws {
        let container = try makeTestContainer()
        let manager = makeRangeManager(container: container)

        manager.currentStats = RangeStats(max: 141, percentile75: 0, median: 0, count: 1)
        #expect(manager.defaultSaveCarryDistanceText() == "141")
    }

    @Test("Default save distance text falls back to current carry distance")
    func defaultSaveDistanceTextFallsBackToCurrentCarryDistance() throws {
        let container = try makeTestContainer()
        let manager = makeRangeManager(container: container)
        let shotType = ShotType(name: "Full", carryDistance: 155, sortOrder: 0)
        manager.sessionShotType = shotType
        manager.currentStats = RangeStats(max: 0, percentile75: 0, median: 0, count: 1)

        #expect(manager.defaultSaveCarryDistanceText() == "155")
    }

    @Test("Default save distance text is empty when no positive candidates exist")
    func defaultSaveDistanceTextIsEmptyWhenNoPositiveCandidatesExist() throws {
        let container = try makeTestContainer()
        let manager = makeRangeManager(container: container)
        manager.currentStats = RangeStats()

        #expect(manager.defaultSaveCarryDistanceText().isEmpty)
    }
}
