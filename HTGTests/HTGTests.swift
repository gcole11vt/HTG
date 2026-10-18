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

    // MARK: - Save Session Validation

    private func makeClubWithShotType(
        container: ModelContainer,
        carryDistance: Int = 140
    ) -> (club: Club, shotType: ShotType) {
        let club = Club(name: "7 Iron", sortOrder: 0)
        let shotType = ShotType(name: "Full", carryDistance: carryDistance, sortOrder: 0, club: club)
        club.shotTypes.append(shotType)
        container.mainContext.insert(club)
        return (club, shotType)
    }

    private func makeActiveManager(
        container: ModelContainer,
        isCustom: Bool = false,
        shotTypeName: String = "Full"
    ) async -> (manager: RangeManager, club: Club, shotType: ShotType) {
        let manager = makeRangeManager(container: container)
        let (club, shotType) = makeClubWithShotType(container: container)
        await manager.startSession(club: club, shotType: shotType, shotTypeName: shotTypeName, isCustom: isCustom)
        return (manager, club, shotType)
    }

    @Test("attemptSaveSession with empty entry returns false and sets validation message")
    func attemptSaveSessionWithEmptyEntryFails() async throws {
        let container = try makeTestContainer()
        let (manager, _, shotType) = await makeActiveManager(container: container)

        manager.updateSaveCarryDistanceText("")
        let saved = await manager.attemptSaveSession()

        #expect(!saved)
        #expect(manager.saveValidationMessage == RangeManager.missingCarryDistanceMessage)
        #expect(manager.currentSession != nil)
        #expect(shotType.carryDistance == 140)
    }

    @Test("attemptSaveSession rejects whitespace, zero, negative and non-numeric entries")
    func attemptSaveSessionRejectsInvalidEntries() async throws {
        let container = try makeTestContainer()
        let (manager, _, shotType) = await makeActiveManager(container: container)

        for input in ["  ", "0", "-5", "abc"] {
            manager.updateSaveCarryDistanceText(input)
            let saved = await manager.attemptSaveSession()

            #expect(!saved)
            #expect(manager.saveValidationMessage == RangeManager.missingCarryDistanceMessage)
            #expect(manager.currentSession != nil)
            #expect(shotType.carryDistance == 140)
        }
    }

    @Test("attemptSaveSession with valid entry saves and clears state")
    func attemptSaveSessionWithValidEntrySaves() async throws {
        let container = try makeTestContainer()
        let (manager, _, shotType) = await makeActiveManager(container: container)
        for distance in [150, 160, 170] {
            await manager.addShot(distance: distance)
        }

        manager.prepareSaveSheet()
        #expect(manager.saveCarryDistanceText == "160")

        let saved = await manager.attemptSaveSession()

        #expect(saved)
        #expect(shotType.carryDistance == 160)
        #expect(manager.currentSession == nil)
        #expect(manager.saveValidationMessage == nil)
    }

    @Test("attemptSaveSession with custom shot type adds a new shot type")
    func attemptSaveSessionWithCustomShotTypeAddsShotType() async throws {
        let container = try makeTestContainer()
        let (manager, club, _) = await makeActiveManager(
            container: container,
            isCustom: true,
            shotTypeName: "Punch"
        )

        manager.updateSaveCarryDistanceText("120")
        let saved = await manager.attemptSaveSession()

        #expect(saved)
        #expect(club.shotTypes.contains { $0.name == "Punch" && $0.carryDistance == 120 })
        #expect(manager.currentSession == nil)
    }

    @Test("prepareSaveSheet pre-fills median and clears a previous error")
    func prepareSaveSheetPrefillsMedianAndClearsError() async throws {
        let container = try makeTestContainer()
        let (manager, _, _) = await makeActiveManager(container: container)
        await manager.addShot(distance: 150)
        manager.updateSaveCarryDistanceText("")
        _ = await manager.attemptSaveSession()
        #expect(manager.saveValidationMessage != nil)

        manager.prepareSaveSheet()

        #expect(manager.saveCarryDistanceText == "\(manager.currentStats.median)")
        #expect(manager.saveValidationMessage == nil)
    }

    @Test("updateSaveCarryDistanceText clears validation message")
    func updateSaveCarryDistanceTextClearsValidationMessage() async throws {
        let container = try makeTestContainer()
        let (manager, _, _) = await makeActiveManager(container: container)
        manager.updateSaveCarryDistanceText("")
        _ = await manager.attemptSaveSession()
        #expect(manager.saveValidationMessage != nil)

        manager.updateSaveCarryDistanceText("155")

        #expect(manager.saveCarryDistanceText == "155")
        #expect(manager.saveValidationMessage == nil)
    }

    @Test("attemptSaveSession with no active session returns false")
    func attemptSaveSessionWithoutSessionFails() async throws {
        let container = try makeTestContainer()
        let manager = makeRangeManager(container: container)

        manager.updateSaveCarryDistanceText("150")
        let saved = await manager.attemptSaveSession()

        #expect(!saved)
        #expect(manager.errorMessage == "No club associated with session")
    }
}
