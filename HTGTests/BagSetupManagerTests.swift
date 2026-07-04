import Testing
import Foundation
import SwiftData
@testable import HTG

@Suite("BagSetupManager Tests")
@MainActor
struct BagSetupManagerTests {

    private func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([Club.self, ShotType.self, SyncTombstone.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeManager(container: ModelContainer) -> BagSetupManager {
        BagSetupManager(modelContext: container.mainContext)
    }

    /// Advances from the woods step through wedges into the arrange step.
    private func advanceToArrange(_ manager: BagSetupManager) async {
        for _ in 0..<4 {
            await manager.advance()
        }
    }

    // MARK: - Selection

    @Test("Driver is auto-selected on the woods step")
    func driverAutoSelected() throws {
        let manager = makeManager(container: try makeTestContainer())

        #expect(manager.step == .woods)
        #expect(manager.isSelected("Driver"))
        #expect(manager.selectedCount == 1)
    }

    @Test("Toggling a club updates the live counter immediately")
    func toggleUpdatesCounter() throws {
        let manager = makeManager(container: try makeTestContainer())

        manager.toggle("3 Wood")
        #expect(manager.selectedCount == 2)

        manager.toggle("3 Wood")
        #expect(manager.selectedCount == 1)
    }

    @Test("Selection is capped at 13 clubs")
    func selectionCappedAtThirteen() throws {
        let manager = makeManager(container: try makeTestContainer())

        for number in 2...9 {
            manager.toggle("\(number) Wood")
        }
        for number in 1...4 {
            manager.toggle("\(number) Hybrid")
        }
        #expect(manager.selectedCount == 13)
        #expect(manager.isBagFull)

        manager.toggle("5 Hybrid")
        #expect(manager.selectedCount == 13)
        #expect(!manager.isSelected("5 Hybrid"))

        // Deselecting still works when the bag is full
        manager.toggle("3 Wood")
        #expect(manager.selectedCount == 12)
    }

    // MARK: - Step Navigation

    @Test("Steps advance woods → hybrids → irons → wedges → arrange → yardages")
    func stepsAdvanceInOrder() async throws {
        let manager = makeManager(container: try makeTestContainer())

        #expect(manager.step == .woods)
        await manager.advance()
        #expect(manager.step == .hybrids)
        await manager.advance()
        #expect(manager.step == .irons)
        await manager.advance()
        #expect(manager.step == .wedges)
        await manager.advance()
        #expect(manager.step == .arrange)
        await manager.advance()
        #expect(manager.step == .yardages)
    }

    @Test("Back returns to the previous step and is unavailable on the first step")
    func backNavigation() async throws {
        let manager = makeManager(container: try makeTestContainer())

        #expect(!manager.canGoBack)

        await manager.advance()
        #expect(manager.canGoBack)

        manager.goBack()
        #expect(manager.step == .woods)
    }

    @Test("Cannot advance past wedges with an empty bag")
    func cannotAdvanceWithEmptyBag() async throws {
        let manager = makeManager(container: try makeTestContainer())

        manager.toggle("Driver")
        for _ in 0..<3 {
            await manager.advance()
        }
        #expect(manager.step == .wedges)
        #expect(!manager.canAdvance)

        manager.toggle("Pitching Wedge")
        #expect(manager.canAdvance)
    }

    // MARK: - Arrangement

    @Test("Arrangement starts in canonical order: woods, hybrids, irons, wedges")
    func arrangementStartsCanonical() async throws {
        let manager = makeManager(container: try makeTestContainer())

        manager.toggle("7 Iron")
        manager.toggle("Pitching Wedge")
        manager.toggle("3 Wood")
        manager.toggle("4 Hybrid")
        await advanceToArrange(manager)

        #expect(manager.step == .arrange)
        #expect(manager.arrangedClubNames == ["Driver", "3 Wood", "4 Hybrid", "7 Iron", "Pitching Wedge"])
    }

    @Test("Clubs can be moved to a new position")
    func moveClubs() async throws {
        let manager = makeManager(container: try makeTestContainer())

        manager.toggle("3 Wood")
        manager.toggle("7 Iron")
        await advanceToArrange(manager)

        manager.moveClubs(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        #expect(manager.arrangedClubNames == ["7 Iron", "Driver", "3 Wood"])
    }

    // MARK: - Yardages & Completion

    @Test("Finishing with every yardage filled saves the bag without estimating")
    func finishWithAllYardagesFilled() async throws {
        let container = try makeTestContainer()
        let manager = makeManager(container: container)

        manager.toggle("7 Iron")
        await advanceToArrange(manager)
        await manager.advance()
        #expect(manager.step == .yardages)

        manager.yardageInputs["Driver"] = "250"
        manager.yardageInputs["7 Iron"] = "165"
        await manager.advance()

        #expect(manager.step == .complete)

        let service = ClubDataService(modelContext: container.mainContext)
        let clubs = try await service.fetchAllClubs()
        #expect(clubs.map(\.name) == ["Driver", "7 Iron"])
        #expect(clubs.compactMap { $0.shotTypes.first?.carryDistance } == [250, 165])
    }

    @Test("Finishing with missing yardages estimates them before saving")
    func finishWithMissingYardagesEstimates() async throws {
        let container = try makeTestContainer()
        let manager = makeManager(container: container)

        manager.toggle("Driver")
        manager.toggle("7 Iron")
        manager.toggle("8 Iron")
        manager.toggle("9 Iron")
        await advanceToArrange(manager)
        await manager.advance()

        manager.yardageInputs["7 Iron"] = "140"
        manager.yardageInputs["9 Iron"] = "120"
        await manager.advance()

        #expect(manager.step == .estimating)
        #expect(manager.resolvedYardages == [
            BagSetupManager.ResolvedYardage(name: "7 Iron", yardage: 140, isEstimated: false),
            BagSetupManager.ResolvedYardage(name: "8 Iron", yardage: 130, isEstimated: true),
            BagSetupManager.ResolvedYardage(name: "9 Iron", yardage: 120, isEstimated: false)
        ])

        await manager.advance()
        #expect(manager.step == .complete)

        let service = ClubDataService(modelContext: container.mainContext)
        let clubs = try await service.fetchAllClubs()
        #expect(clubs.compactMap { $0.shotTypes.first?.carryDistance } == [140, 130, 120])
    }

    @Test("Going back from estimating returns to yardage entry")
    func backFromEstimating() async throws {
        let manager = makeManager(container: try makeTestContainer())

        manager.toggle("7 Iron")
        await advanceToArrange(manager)
        await manager.advance()
        await manager.advance()
        #expect(manager.step == .estimating)

        manager.goBack()
        #expect(manager.step == .yardages)
    }

    @Test("Finishing with no yardages falls back to catalog defaults")
    func finishWithNoYardagesUsesCatalogDefaults() async throws {
        let container = try makeTestContainer()
        let manager = makeManager(container: container)

        manager.toggle("Lob Wedge")
        await advanceToArrange(manager)
        await manager.advance()
        await manager.advance()

        #expect(manager.step == .estimating)
        #expect(manager.resolvedYardages == [
            BagSetupManager.ResolvedYardage(name: "Driver", yardage: 250, isEstimated: true),
            BagSetupManager.ResolvedYardage(name: "Lob Wedge", yardage: 80, isEstimated: true)
        ])
    }

    @Test("Completing setup replaces an existing bag and records tombstones")
    func completingSetupReplacesExistingBag() async throws {
        let container = try makeTestContainer()
        let service = ClubDataService(modelContext: container.mainContext)
        try await service.loadDefaultClubs()

        let manager = makeManager(container: container)
        await advanceToArrange(manager)
        await manager.advance()
        manager.yardageInputs["Driver"] = "260"
        await manager.advance()

        #expect(manager.step == .complete)

        let clubs = try await service.fetchAllClubs()
        #expect(clubs.map(\.name) == ["Driver"])

        let tombstones = try container.mainContext.fetch(FetchDescriptor<SyncTombstone>())
        #expect(tombstones.count == 13)
    }
}
