import Testing
import Foundation
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
        try await service.addShotType(to: club, name: "3/4", distance: 150)

        #expect(club.shotTypes.count == 2)
        let threeQuarter = club.shotTypes.first { $0.name == "3/4" }
        #expect(threeQuarter?.carryDistance == 150)
    }

    @Test("Add shot type enforces maximum of 5 per club")
    func addShotTypeEnforcesMaximum() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        // Club starts with 1 shot type, add 4 more
        try await service.addShotType(to: club, name: "3/4", distance: 150)
        try await service.addShotType(to: club, name: "1/2", distance: 130)
        try await service.addShotType(to: club, name: "Punch", distance: 120)
        try await service.addShotType(to: club, name: "Flop", distance: 100)

        // 6th shot type should throw
        await #expect(throws: ClubDataServiceError.maximumShotTypesReached) {
            try await service.addShotType(to: club, name: "Extra", distance: 90)
        }
    }

    @Test("Archive shot type marks it as archived")
    func archiveShotTypeMarksAsArchived() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        try await service.addShotType(to: club, name: "3/4", distance: 150)

        let threeQuarter = club.shotTypes.first { $0.name == "3/4" }!
        try await service.archiveShotType(threeQuarter, from: club)

        #expect(threeQuarter.isArchived == true)
        #expect(threeQuarter.archivedDate != nil)
        #expect(club.shotTypes.count == 2)
        #expect(club.shotTypes.filter { !$0.isArchived }.count == 1)
    }

    @Test("Archive shot type enforces minimum of 1 active per club")
    func archiveShotTypeEnforcesMinimum() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        let fullShot = club.shotTypes.first!

        await #expect(throws: ClubDataServiceError.minimumShotTypesRequired) {
            try await service.archiveShotType(fullShot, from: club)
        }
    }

    @Test("Restore shot type clears archived state")
    func restoreShotTypeClearsArchivedState() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        try await service.addShotType(to: club, name: "3/4", distance: 150)

        let threeQuarter = club.shotTypes.first { $0.name == "3/4" }!
        try await service.archiveShotType(threeQuarter, from: club)
        try await service.restoreShotType(threeQuarter)

        #expect(threeQuarter.isArchived == false)
        #expect(threeQuarter.archivedDate == nil)
    }

    @Test("Purge expired shot types deletes archived older than 7 days")
    func purgeExpiredShotTypesDeletesOld() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        try await service.addShotType(to: club, name: "3/4", distance: 150)

        let threeQuarter = club.shotTypes.first { $0.name == "3/4" }!
        try await service.archiveShotType(threeQuarter, from: club)

        // Manually set archivedDate to 8 days ago
        threeQuarter.archivedDate = Calendar.current.date(byAdding: .day, value: -8, to: Date())
        try container.mainContext.save()

        try await service.purgeExpiredShotTypes()

        #expect(club.shotTypes.count == 1)
        #expect(club.shotTypes.first?.name == "Full")
    }

    @Test("Purge does not delete recently archived shot types")
    func purgeKeepsRecentlyArchived() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        try await service.addShotType(to: club, name: "3/4", distance: 150)

        let threeQuarter = club.shotTypes.first { $0.name == "3/4" }!
        try await service.archiveShotType(threeQuarter, from: club)

        try await service.purgeExpiredShotTypes()

        #expect(club.shotTypes.count == 2)
        #expect(threeQuarter.isArchived == true)
    }

    @Test("Archived shot types do not count toward maximum of 5")
    func archivedShotTypesDontCountTowardMax() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        try await service.addShotType(to: club, name: "3/4", distance: 150)
        try await service.addShotType(to: club, name: "1/2", distance: 130)
        try await service.addShotType(to: club, name: "Punch", distance: 120)
        try await service.addShotType(to: club, name: "Flop", distance: 100)

        // Archive one to free a slot
        let flop = club.shotTypes.first { $0.name == "Flop" }!
        try await service.archiveShotType(flop, from: club)

        // Should be able to add another since archived doesn't count
        try await service.addShotType(to: club, name: "Stinger", distance: 110)
        let activeCount = club.shotTypes.filter { !$0.isArchived }.count
        #expect(activeCount == 5)
    }

    @Test("Load default clubs creates 13 standard clubs")
    func loadDefaultClubsCreatesStandardSet() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        try await service.loadDefaultClubs()

        let clubs = try await service.fetchAllClubs()
        #expect(clubs.count == 13)

        // Verify driver exists with correct distance and 4 shot types
        let driver = clubs.first { $0.name == "Driver" }
        #expect(driver != nil)
        #expect(driver?.shotTypes.count == 4)
        let driverFull = driver?.shotTypes.first { $0.name == "Full" }
        #expect(driverFull?.carryDistance == 250)

        // Verify lob wedge exists with correct distance and 4 shot types
        let lobWedge = clubs.first { $0.name == "Lob Wedge" }
        #expect(lobWedge != nil)
        #expect(lobWedge?.shotTypes.count == 4)
        let lobWedgeFull = lobWedge?.shotTypes.first { $0.name == "Full" }
        #expect(lobWedgeFull?.carryDistance == 80)
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

    // MARK: - Archive Tests

    @Test("New club defaults isArchived to false")
    func newClubDefaultsIsArchivedFalse() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "Driver", defaultDistance: 250)

        #expect(club.isArchived == false)
    }

    @Test("Archive club sets isArchived to true")
    func archiveClubSetsFlag() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "Driver", defaultDistance: 250)
        try await service.archiveClub(club)

        #expect(club.isArchived == true)
    }

    @Test("Restore club sets isArchived to false")
    func restoreClubSetsFlag() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "Driver", defaultDistance: 250)
        try await service.archiveClub(club)
        try await service.restoreClub(club)

        #expect(club.isArchived == false)
    }

    @Test("Fetch all clubs excludes archived clubs")
    func fetchAllClubsExcludesArchived() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club1 = try await service.addClub(name: "Driver", defaultDistance: 250)
        _ = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        try await service.archiveClub(club1)

        let clubs = try await service.fetchAllClubs()

        #expect(clubs.count == 1)
        #expect(clubs.first?.name == "7 Iron")
    }

    @Test("Fetch archived clubs returns only archived")
    func fetchArchivedClubsReturnsOnlyArchived() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club1 = try await service.addClub(name: "Driver", defaultDistance: 250)
        _ = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        try await service.archiveClub(club1)

        let archived = try await service.fetchArchivedClubs()

        #expect(archived.count == 1)
        #expect(archived.first?.name == "Driver")
    }

    @Test("Archived clubs do not count toward 13 club maximum")
    func archivedClubsDontCountTowardMax() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        // Add 13 clubs
        var clubs: [Club] = []
        for i in 1...13 {
            let club = try await service.addClub(name: "Club \(i)", defaultDistance: 100 + i * 10)
            clubs.append(club)
        }

        // Archive one club
        try await service.archiveClub(clubs[0])

        // Should now be able to add a 14th club (since one is archived)
        let newClub = try await service.addClub(name: "Club 14", defaultDistance: 240)
        #expect(newClub.name == "Club 14")
    }

    // MARK: - Shot Type Names

    @Test("Fetch all unique shot type names returns deduplicated sorted names")
    func fetchAllUniqueShotTypeNamesReturnsSorted() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club1 = try await service.addClub(name: "Driver", defaultDistance: 250)
        let club2 = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        try await service.addShotType(to: club1, name: "3/4", distance: 230)
        try await service.addShotType(to: club2, name: "1/2", distance: 130)
        try await service.addShotType(to: club2, name: "3/4", distance: 150)

        let names = try await service.fetchAllUniqueShotTypeNames()

        #expect(names == ["1/2", "3/4", "Full"])
    }

    // MARK: - Update Shot Type

    // MARK: - Nickname Tests

    @Test("Add club generates a nickname automatically")
    func addClubGeneratesNickname() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)

        #expect(club.nickname == "7I")
    }

    @Test("Load default clubs generates nicknames for all 13 clubs")
    func loadDefaultClubsGeneratesNicknames() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        try await service.loadDefaultClubs()
        let clubs = try await service.fetchAllClubs()

        for club in clubs {
            #expect(!club.nickname.isEmpty, "Club '\(club.name)' should have a nickname")
        }

        let driver = clubs.first { $0.name == "Driver" }
        #expect(driver?.nickname == "Dr")

        let pitchingWedge = clubs.first { $0.name == "Pitching Wedge" }
        #expect(pitchingWedge?.nickname == "PW")
    }

    @Test("Backfill nicknames fills empty nicknames")
    func backfillNicknamesFillsEmpty() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        // Create a club with an empty nickname manually
        let club = Club(name: "Sand Wedge", nickname: "", sortOrder: 0)
        let shotType = ShotType(name: "Full", carryDistance: 100, sortOrder: 0, club: club)
        club.shotTypes = [shotType]
        container.mainContext.insert(club)
        try container.mainContext.save()

        #expect(club.nickname == "")

        try await service.backfillNicknames()

        #expect(club.nickname == "SW")
    }

    @Test("Update club changes nickname when provided")
    func updateClubChangesNickname() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        try await service.updateClub(club, name: "7 Iron", nickname: "7i")

        #expect(club.nickname == "7i")
    }

    @Test("Update shot type changes name and distance")
    func updateShotTypeChangesNameAndDistance() async throws {
        let container = try makeTestContainer()
        let service = makeService(container: container)

        let club = try await service.addClub(name: "7 Iron", defaultDistance: 165)
        let shotType = club.shotTypes.first!

        try await service.updateShotType(shotType, name: "Punch", distance: 140)

        #expect(shotType.name == "Punch")
        #expect(shotType.carryDistance == 140)
    }
}
