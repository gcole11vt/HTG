import Testing
import SwiftData
@testable import HTG

@MainActor
@Suite("YardageSheetBuilder Tests")
struct YardageSheetBuilderTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Club.self, ShotType.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeClub(
        in container: ModelContainer,
        name: String,
        isArchived: Bool = false,
        shotTypes: [(name: String, distance: Int, isArchived: Bool)]
    ) -> Club {
        let club = Club(name: name, sortOrder: 0, isArchived: isArchived)
        container.mainContext.insert(club)
        for (index, definition) in shotTypes.enumerated() {
            let shotType = ShotType(name: definition.name, carryDistance: definition.distance, sortOrder: index, club: club)
            shotType.isArchived = definition.isArchived
            container.mainContext.insert(shotType)
        }
        return club
    }

    // MARK: - By-club grouping

    @Test("Club groups exclude archived clubs")
    func clubGroupsExcludeArchivedClubs() throws {
        let container = try makeContainer()
        let driver = makeClub(in: container, name: "Driver", shotTypes: [("Tee", 280, false)])
        _ = makeClub(in: container, name: "Old 3 Wood", isArchived: true, shotTypes: [("Full", 240, false)])

        let groups = YardageSheetBuilder.clubGroups(from: [driver] + [], primaryShotType: "Full")
        let allGroups = YardageSheetBuilder.clubGroups(
            from: try container.mainContext.fetch(FetchDescriptor<Club>()),
            primaryShotType: "Full"
        )

        #expect(groups.map(\.clubName) == ["Driver"])
        #expect(allGroups.map(\.clubName) == ["Driver"])
    }

    @Test("Club groups exclude archived and zero-distance shot types")
    func clubGroupsExcludeArchivedAndZeroShotTypes() throws {
        let container = try makeContainer()
        let club = makeClub(in: container, name: "7 Iron", shotTypes: [
            ("Full", 165, false),
            ("Punch", 0, false),
            ("Old Full", 160, true)
        ])

        let groups = YardageSheetBuilder.clubGroups(from: [club], primaryShotType: "Full")

        #expect(groups.count == 1)
        #expect(groups[0].entries.map(\.shotTypeName) == ["Full"])
    }

    @Test("Club groups are ordered by display distance descending")
    func clubGroupsOrderedByDisplayDistanceDescending() throws {
        let container = try makeContainer()
        let sevenIron = makeClub(in: container, name: "7 Iron", shotTypes: [("Full", 165, false)])
        let driver = makeClub(in: container, name: "Driver", shotTypes: [("Full", 280, false)])
        let wedge = makeClub(in: container, name: "Pitching Wedge", shotTypes: [("Full", 135, false)])

        let groups = YardageSheetBuilder.clubGroups(from: [sevenIron, driver, wedge], primaryShotType: "Full")

        #expect(groups.map(\.clubName) == ["Driver", "7 Iron", "Pitching Wedge"])
    }

    @Test("Entries within a club group are sorted by distance descending")
    func clubGroupEntriesSortedByDistanceDescending() throws {
        let container = try makeContainer()
        let driver = makeClub(in: container, name: "Driver", shotTypes: [
            ("Low Tee", 265, false),
            ("Hard", 290, false),
            ("Tee", 280, false)
        ])

        let groups = YardageSheetBuilder.clubGroups(from: [driver], primaryShotType: "Tee")

        #expect(groups[0].entries.map(\.carryDistance) == [290, 280, 265])
    }

    @Test("Clubs with no printable shot types are omitted")
    func clubsWithNoPrintableShotTypesOmitted() throws {
        let container = try makeContainer()
        let emptyClub = makeClub(in: container, name: "New Club", shotTypes: [("Full", 0, false)])
        let driver = makeClub(in: container, name: "Driver", shotTypes: [("Tee", 280, false)])

        let groups = YardageSheetBuilder.clubGroups(from: [emptyClub, driver], primaryShotType: "Full")

        #expect(groups.map(\.clubName) == ["Driver"])
    }

    // MARK: - By-yardage flattening

    @Test("Entries by yardage are flattened and sorted descending across clubs")
    func entriesByYardageSortedDescending() throws {
        let container = try makeContainer()
        let driver = makeClub(in: container, name: "Driver", shotTypes: [("Tee", 280, false), ("Low Tee", 265, false)])
        let sevenIron = makeClub(in: container, name: "7 Iron", shotTypes: [("Full", 165, false), ("Hard", 172, false)])

        let entries = YardageSheetBuilder.entriesByYardage(from: [sevenIron, driver])

        #expect(entries.map(\.carryDistance) == [280, 265, 172, 165])
        #expect(entries[0].clubName == "Driver")
    }

    @Test("Entries by yardage exclude archived clubs and shot types")
    func entriesByYardageExcludeArchived() throws {
        let container = try makeContainer()
        let driver = makeClub(in: container, name: "Driver", shotTypes: [("Tee", 280, false), ("Old", 270, true)])
        let archived = makeClub(in: container, name: "Old Wood", isArchived: true, shotTypes: [("Full", 240, false)])

        let entries = YardageSheetBuilder.entriesByYardage(from: [driver, archived])

        #expect(entries.map(\.carryDistance) == [280])
    }

    // MARK: - Print column splitting

    @Test("Group column split balances line counts and keeps order")
    func splitGroupsBalancesLineCounts() throws {
        let container = try makeContainer()
        let clubs = ["A", "B", "C", "D"].map { name in
            makeClub(in: container, name: name, shotTypes: [
                ("One", 100, false), ("Two", 90, false), ("Three", 80, false)
            ])
        }

        let groups = YardageSheetBuilder.clubGroups(from: clubs, primaryShotType: "One")
        let columns = YardageSheetBuilder.splitGroupsIntoColumns(groups, columnCount: 2)

        #expect(columns.count == 2)
        #expect(columns[0].map(\.clubName) == ["A", "B"])
        #expect(columns[1].map(\.clubName) == ["C", "D"])
    }

    @Test("Group column split moves overflow to later columns without reordering")
    func splitGroupsKeepsOrderOnUnevenSizes() throws {
        let container = try makeContainer()
        let big = makeClub(in: container, name: "Big", shotTypes: (1...5).map { ("Type \($0)", 100 + $0, false) })
        let smalls = ["S1", "S2", "S3"].map { name in
            makeClub(in: container, name: name, shotTypes: [("Full", 90, false)])
        }

        let groups = YardageSheetBuilder.clubGroups(from: [big] + smalls, primaryShotType: "Type 1")
        let columns = YardageSheetBuilder.splitGroupsIntoColumns(groups, columnCount: 2)

        #expect(columns[0].map(\.clubName) == ["Big"])
        #expect(columns[1].map(\.clubName) == ["S1", "S2", "S3"])
    }

    @Test("Entry column split chunks sequentially")
    func splitEntriesChunksSequentially() throws {
        let container = try makeContainer()
        let driver = makeClub(in: container, name: "Driver", shotTypes: (1...5).map { ("Type \($0)", 200 + $0, false) })

        let entries = YardageSheetBuilder.entriesByYardage(from: [driver])
        let columns = YardageSheetBuilder.splitEntriesIntoColumns(entries, columnCount: 2)

        #expect(columns.count == 2)
        #expect(columns[0].count == 3)
        #expect(columns[1].count == 2)
        #expect(columns[0][0].carryDistance == 205)
        #expect(columns[1][1].carryDistance == 201)
    }
}
