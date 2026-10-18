import Testing
import SwiftData
@testable import HTG

@MainActor
@Suite("DistanceTextLadderService Tests")
struct DistanceTextLadderServiceTests {

    private func item(_ id: String, _ distance: Int, _ primary: String? = nil, _ secondary: String = "") -> DistanceTextLadderItem {
        DistanceTextLadderItem(id: id, distance: distance, primaryLabel: primary ?? id, secondaryLabel: secondary)
    }

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

    @Test("Distance units format yards and feet")
    func unitsFormat() {
        #expect(DistanceUnit.yards.abbreviation == "yd")
        #expect(DistanceUnit.feet.abbreviation == "ft")
        #expect(DistanceUnit.yards.formatted(152) == "152 yd")
        #expect(DistanceUnit.feet.formatted(8) == "8 ft")
    }

    @Test("Golf item ID matches the printed yardage entry ID")
    func golfItemIDMatchesPrintEntry() {
        let id = DistanceTextLadderService.golfItemID(clubName: "7 Iron", shotTypeName: "Full")
        #expect(id == "7 Iron-Full")
        #expect(id == YardageSheetEntry(clubName: "7 Iron", shotTypeName: "Full", carryDistance: 150).id)
    }

    @Test("Golf items mirror the By Yardage print entries")
    func golfItemsMirrorPrintEntries() throws {
        let container = try makeContainer()
        let clubs = [
            makeClub(in: container, name: "Driver", shotTypes: [("Tee", 250, false)]),
            makeClub(in: container, name: "7 Iron", shotTypes: [("Full", 150, false), ("3/4", 140, false), ("Punch", 0, false), ("Old", 145, true)]),
            makeClub(in: container, name: "Pitching Wedge", shotTypes: [("Full", 120, false)]),
            makeClub(in: container, name: "Old 3W", isArchived: true, shotTypes: [("Full", 230, false)])
        ]
        let items = DistanceTextLadderService.golfItems(from: clubs)
        #expect(items.map(\.distance) == [250, 150, 140, 120])
        #expect(items.map(\.primaryLabel) == ["Driver", "7 Iron", "7 Iron", "Pitching Wedge"])
        #expect(items[2].secondaryLabel == "3/4")
        #expect(items.map(\.id) == YardageSheetBuilder.entriesByYardage(from: clubs).map(\.id))
    }

    @Test("Rows are sorted by distance descending with deterministic ties")
    func sortAndTies() {
        let ladder = DistanceTextLadderService.ladder(
            items: [item("b", 140), item("c", 150), item("a", 150)],
            targetDistance: 150, selectedItemID: nil
        )
        #expect(ladder.rows.map(\.id) == ["a", "c", "b"])
    }

    @Test("Exact match anchors that row with no target marker")
    func exactMatch() {
        let ladder = DistanceTextLadderService.ladder(
            items: [item("155", 155), item("150", 150), item("145", 145)],
            targetDistance: 150, selectedItemID: nil
        )
        #expect(ladder.anchorRowID == "150")
        #expect(Set(ladder.rows.filter(\.isClosestToTarget).map(\.id)) == ["150"])
        #expect(ladder.targetMarkerInsertionIndex == nil)
    }

    @Test("No exact match anchors the nearest row and places the marker between neighbours")
    func nearestWithMarker() {
        let ladder = DistanceTextLadderService.ladder(
            items: [item("155", 155), item("150", 150), item("145", 145)],
            targetDistance: 152, selectedItemID: nil
        )
        #expect(ladder.anchorRowID == "150")
        #expect(ladder.targetMarkerInsertionIndex == 1)
    }

    @Test("Equidistant tie prefers the longer distance")
    func equidistantTie() {
        let ladder = DistanceTextLadderService.ladder(
            items: [item("155", 155), item("145", 145)],
            targetDistance: 150, selectedItemID: nil
        )
        #expect(ladder.anchorRowID == "155")
        #expect(ladder.rows.filter(\.isClosestToTarget).map(\.id) == ["155"])
        #expect(ladder.targetMarkerInsertionIndex == 1)
    }

    @Test("All rows at the closest distance are highlighted and the middle one anchors")
    func closestGroup() {
        let ladder = DistanceTextLadderService.ladder(
            items: [item("a", 150), item("b", 150), item("c", 150), item("140", 140)],
            targetDistance: 150, selectedItemID: nil
        )
        #expect(Set(ladder.rows.filter(\.isClosestToTarget).map(\.id)) == ["a", "b", "c"])
        #expect(ladder.rows.first { $0.id == "140" }?.isClosestToTarget == false)
        #expect(ladder.anchorRowID == "b")
    }

    @Test("Target beyond the longest row anchors the top with the marker first")
    func targetAboveAll() {
        let ladder = DistanceTextLadderService.ladder(
            items: [item("250", 250), item("150", 150)], targetDistance: 300, selectedItemID: nil
        )
        #expect(ladder.anchorRowID == "250")
        #expect(ladder.targetMarkerInsertionIndex == 0)
    }

    @Test("Target below the shortest row anchors the bottom with the marker last")
    func targetBelowAll() {
        let ladder = DistanceTextLadderService.ladder(
            items: [item("150", 150), item("120", 120)], targetDistance: 60, selectedItemID: nil
        )
        #expect(ladder.anchorRowID == "120")
        #expect(ladder.targetMarkerInsertionIndex == 2)
    }

    @Test("Only the selected item is flagged")
    func selection() {
        let items = [item("a", 150), item("b", 140)]
        let selected = DistanceTextLadderService.ladder(items: items, targetDistance: 150, selectedItemID: "b")
        #expect(selected.rows.filter(\.isSelected).map(\.id) == ["b"])
        let none = DistanceTextLadderService.ladder(items: items, targetDistance: 150, selectedItemID: nil)
        #expect(none.rows.filter(\.isSelected).isEmpty)
        let unknown = DistanceTextLadderService.ladder(items: items, targetDistance: 150, selectedItemID: "zzz")
        #expect(unknown.rows.filter(\.isSelected).isEmpty)
    }

    @Test("Empty items produce an empty ladder")
    func emptyItems() {
        let ladder = DistanceTextLadderService.ladder(items: [], targetDistance: 150, selectedItemID: nil)
        #expect(ladder.rows.isEmpty)
        #expect(ladder.anchorRowID == nil)
        #expect(ladder.targetMarkerInsertionIndex == nil)
        #expect(ladder.targetDistance == 150)
    }

    @Test("Ladder is unit-agnostic for putting distances")
    func puttingFeet() {
        let ladder = DistanceTextLadderService.ladder(
            items: [item("3", 3), item("6", 6), item("10", 10), item("15", 15)],
            targetDistance: 8, selectedItemID: nil
        )
        #expect(ladder.anchorRowID == "10")
        #expect(ladder.targetMarkerInsertionIndex == 2)
    }
}
