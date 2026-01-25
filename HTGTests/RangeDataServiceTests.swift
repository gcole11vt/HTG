import Testing
import SwiftData
@testable import HTG

@Suite("RangeDataService Tests")
@MainActor
struct RangeDataServiceTests {

    private func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([RangeSession.self, Shot.self, StoredShotType.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeService(container: ModelContainer) -> RangeDataService {
        RangeDataService(modelContext: container.mainContext)
    }

    @Test("Create session creates new range session")
    func createSessionCreatesNewSession() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let session = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")

        #expect(session.clubName == "7 Iron")
        #expect(session.shotTypeName == "Full")
        #expect(session.shots.isEmpty)
    }

    @Test("Add shot to session creates shot record")
    func addShotToSessionCreatesRecord() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let session = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")
        try await service.addShot(to: session, distance: 165, isFromVoice: false)

        #expect(session.shots.count == 1)
        #expect(session.shots.first?.distance == 165)
        #expect(session.shots.first?.isFromVoice == false)
    }

    @Test("Add voice shot marks as from voice")
    func addVoiceShotMarksAsFromVoice() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let session = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")
        try await service.addShot(to: session, distance: 165, isFromVoice: true)

        #expect(session.shots.first?.isFromVoice == true)
    }

    @Test("Delete shot removes from session")
    func deleteShotRemovesFromSession() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let session = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")
        try await service.addShot(to: session, distance: 165, isFromVoice: false)
        try await service.addShot(to: session, distance: 160, isFromVoice: false)

        let shotToDelete = session.shots.first!
        try await service.deleteShot(shotToDelete, from: session)

        #expect(session.shots.count == 1)
    }

    @Test("Calculate stats returns correct max")
    func calculateStatsReturnsMax() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let session = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")
        try await service.addShot(to: session, distance: 160, isFromVoice: false)
        try await service.addShot(to: session, distance: 165, isFromVoice: false)
        try await service.addShot(to: session, distance: 155, isFromVoice: false)

        let stats = service.calculateStats(for: session)

        #expect(stats.max == 165)
    }

    @Test("Calculate stats returns correct median for odd count")
    func calculateStatsReturnsMedianOdd() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let session = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")
        try await service.addShot(to: session, distance: 160, isFromVoice: false)
        try await service.addShot(to: session, distance: 165, isFromVoice: false)
        try await service.addShot(to: session, distance: 155, isFromVoice: false)

        let stats = service.calculateStats(for: session)

        #expect(stats.median == 160)
    }

    @Test("Calculate stats returns correct median for even count")
    func calculateStatsReturnsMedianEven() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let session = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")
        try await service.addShot(to: session, distance: 160, isFromVoice: false)
        try await service.addShot(to: session, distance: 165, isFromVoice: false)
        try await service.addShot(to: session, distance: 155, isFromVoice: false)
        try await service.addShot(to: session, distance: 170, isFromVoice: false)

        let stats = service.calculateStats(for: session)

        // Sorted: 155, 160, 165, 170 - median is average of middle two: (160+165)/2 = 162
        #expect(stats.median == 162)
    }

    @Test("Calculate stats returns correct 75th percentile")
    func calculateStatsReturns75thPercentile() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let session = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")
        // Add 8 shots for clear percentile calculation
        try await service.addShot(to: session, distance: 150, isFromVoice: false)
        try await service.addShot(to: session, distance: 155, isFromVoice: false)
        try await service.addShot(to: session, distance: 160, isFromVoice: false)
        try await service.addShot(to: session, distance: 162, isFromVoice: false)
        try await service.addShot(to: session, distance: 165, isFromVoice: false)
        try await service.addShot(to: session, distance: 168, isFromVoice: false)
        try await service.addShot(to: session, distance: 170, isFromVoice: false)
        try await service.addShot(to: session, distance: 175, isFromVoice: false)

        let stats = service.calculateStats(for: session)

        // 75th percentile at index 5 (0.75 * 7 = 5.25, truncated to 5): 168
        #expect(stats.percentile75 == 168)
    }

    @Test("Calculate stats returns correct count")
    func calculateStatsReturnsCount() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let session = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")
        try await service.addShot(to: session, distance: 160, isFromVoice: false)
        try await service.addShot(to: session, distance: 165, isFromVoice: false)
        try await service.addShot(to: session, distance: 155, isFromVoice: false)

        let stats = service.calculateStats(for: session)

        #expect(stats.count == 3)
    }

    @Test("Calculate stats returns zeros for empty session")
    func calculateStatsReturnsZerosForEmptySession() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let session = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")

        let stats = service.calculateStats(for: session)

        #expect(stats.max == 0)
        #expect(stats.median == 0)
        #expect(stats.percentile75 == 0)
        #expect(stats.count == 0)
    }

    @Test("Save as stored shot type persists data")
    func saveAsStoredShotTypePersistsData() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let session = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")
        try await service.addShot(to: session, distance: 160, isFromVoice: false)
        try await service.addShot(to: session, distance: 165, isFromVoice: false)
        try await service.addShot(to: session, distance: 170, isFromVoice: false)

        try await service.saveAsStoredShotType(session: session)

        let descriptor = FetchDescriptor<StoredShotType>()
        let storedTypes = try container.mainContext.fetch(descriptor)

        #expect(storedTypes.count == 1)
        #expect(storedTypes.first?.clubName == "7 Iron")
        #expect(storedTypes.first?.shotTypeName == "Full")
        // Uses median as the stored distance
        #expect(storedTypes.first?.distance == 165)
    }

    @Test("Fetch all sessions returns sessions")
    func fetchAllSessionsReturnsSessions() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        _ = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")
        _ = try await service.createSession(clubName: "8 Iron", shotTypeName: "Full")

        let sessions = try await service.fetchAllSessions()

        #expect(sessions.count == 2)
    }

    @Test("Delete session removes session")
    func deleteSessionRemovesSession() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let session = try await service.createSession(clubName: "7 Iron", shotTypeName: "Full")
        try await service.deleteSession(session)

        let sessions = try await service.fetchAllSessions()
        #expect(sessions.isEmpty)
    }
}
