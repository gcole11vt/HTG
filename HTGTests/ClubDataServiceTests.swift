import Testing
import SwiftData
@testable import HTG

@Suite("ClubDataService Tests")
@MainActor
struct ClubDataServiceTests {

    private func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([Club.self, ShotType.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeService(container: ModelContainer) -> ClubDataService {
        ClubDataService(modelContext: container.mainContext)
    }

    @Test("Fetch all clubs returns empty array initially")
    func fetchAllClubsReturnsEmptyInitially() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let clubs = try await service.fetchAllClubs()

        #expect(clubs.isEmpty)
    }

    @Test("Add club creates club with default shot type")
    func addClubCreatesClubWithDefaultShotType() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)

        #expect(club.name == "7 Iron")
        #expect(club.shotTypes.count == 1)
        #expect(club.shotTypes.first?.name == "Full")
        #expect(club.shotTypes.first?.carryDistance == 165)
    }

    @Test("Add club enforces maximum of 13 clubs")
    func addClubEnforcesMaximum() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        // Add 13 clubs
        for i in 1...13 {
            _ = try await service.addClub(name: "Club \(i)", defaultDistance: 100 + i * 10)
        }

        // 14th club should throw
        await #expect(throws: ClubDataServiceError.maximumClubsReached) {
            _ = try await service.addClub(name: "Club 14", defaultDistance: 240)
        }
    }

    @Test("Delete club removes club from storage")
    func deleteClubRemovesFromStorage() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "Driver", defaultDistance: 250)
        try await service.deleteClub(club)

        let clubs = try await service.fetchAllClubs()
        #expect(clubs.isEmpty)
    }

    @Test("Update club changes club name")
    func updateClubChangesName() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        try await service.updateClub(club, name: "7 Iron (New)")

        #expect(club.name == "7 Iron (New)")
    }

    @Test("Reorder clubs updates sort order")
    func reorderClubsUpdatesSortOrder() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let driver = try await service.addClub(name: "Driver", defaultDistance: 250)
        let iron7 = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        let wedge = try await service.addClub(name: "Pitching Wedge", defaultDistance: 135)

        try await service.reorderClubs([wedge, driver, iron7])

        #expect(wedge.sortOrder == 0)
        #expect(driver.sortOrder == 1)
        #expect(iron7.sortOrder == 2)
    }

    @Test("Add shot type to club creates new shot type")
    func addShotTypeToClub() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        try await service.addShotType(to: club, name: "Three-Quarter", distance: 150)

        #expect(club.shotTypes.count == 2)
        let threeQuarter = club.shotTypes.first { $0.name == "Three-Quarter" }
        #expect(threeQuarter?.carryDistance == 150)
    }

    @Test("Add shot type enforces maximum of 5 per club")
    func addShotTypeEnforcesMaximum() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        // Club starts with 1 shot type, add 4 more
        try await service.addShotType(to: club, name: "Three-Quarter", distance: 150)
        try await service.addShotType(to: club, name: "Half", distance: 130)
        try await service.addShotType(to: club, name: "Punch", distance: 120)
        try await service.addShotType(to: club, name: "Flop", distance: 100)

        // 6th shot type should throw
        await #expect(throws: ClubDataServiceError.maximumShotTypesReached) {
            try await service.addShotType(to: club, name: "Extra", distance: 90)
        }
    }

    @Test("Delete shot type removes from club")
    func deleteShotTypeRemovesFromClub() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        try await service.addShotType(to: club, name: "Three-Quarter", distance: 150)

        let threeQuarter = club.shotTypes.first { $0.name == "Three-Quarter" }!
        try await service.deleteShotType(threeQuarter, from: club)

        #expect(club.shotTypes.count == 1)
        #expect(club.shotTypes.first?.name == "Full")
    }

    @Test("Delete shot type enforces minimum of 1 per club")
    func deleteShotTypeEnforcesMinimum() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        let fullShot = club.shotTypes.first!

        await #expect(throws: ClubDataServiceError.minimumShotTypesRequired) {
            try await service.deleteShotType(fullShot, from: club)
        }
    }

    @Test("Load default clubs creates 13 standard clubs")
    func loadDefaultClubsCreatesStandardSet() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        try await service.loadDefaultClubs()

        let clubs = try await service.fetchAllClubs()
        #expect(clubs.count == 13)

        // Verify driver exists with correct distance
        let driver = clubs.first { $0.name == "Driver" }
        #expect(driver != nil)
        #expect(driver?.shotTypes.first?.carryDistance == 250)

        // Verify lob wedge exists with correct distance
        let lobWedge = clubs.first { $0.name == "Lob Wedge" }
        #expect(lobWedge != nil)
        #expect(lobWedge?.shotTypes.first?.carryDistance == 80)
    }

    @Test("Load default clubs does nothing if clubs exist")
    func loadDefaultClubsSkipsIfClubsExist() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        _ = try await service.addClub(name: "Custom Club", defaultDistance: 200)
        try await service.loadDefaultClubs()

        let clubs = try await service.fetchAllClubs()
        #expect(clubs.count == 1)
        #expect(clubs.first?.name == "Custom Club")
    }

    @Test("Fetch all clubs returns sorted by sortOrder")
    func fetchAllClubsReturnsSorted() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        _ = try await service.addClub(name: "Wedge", defaultDistance: 100)
        _ = try await service.addClub(name: "Driver", defaultDistance: 250)
        _ = try await service.addClub(name: "Iron", defaultDistance: 165)

        let clubs = try await service.fetchAllClubs()

        #expect(clubs[0].name == "Wedge")
        #expect(clubs[1].name == "Driver")
        #expect(clubs[2].name == "Iron")
    }
}
