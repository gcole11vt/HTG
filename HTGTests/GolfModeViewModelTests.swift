import Testing
import SwiftData
@testable import HTG

@Suite("GolfModeViewModel Tests")
@MainActor
struct GolfModeViewModelTests {

    private func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([Club.self, ShotType.self, UserProfile.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func createClub(name: String, shotTypes: [(String, Int)], sortOrder: Int, in context: ModelContext) -> Club {
        let club = Club(name: name, sortOrder: sortOrder)
        for (index, (shotName, distance)) in shotTypes.enumerated() {
            let shotType = ShotType(name: shotName, carryDistance: distance, sortOrder: index, club: club)
            club.shotTypes.append(shotType)
        }
        context.insert(club)
        return club
    }

    // MARK: - Selection Tracking Tests

    @Test("Initially uses recommendation as displayed club shot")
    func initiallyUsesRecommendationAsDisplayed() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 150)], sortOrder: 0, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()

        #expect(viewModel.selectedClubShot == nil)
        #expect(viewModel.displayedClubShot?.clubName == "7 Iron")
        #expect(viewModel.displayedClubShot?.shotTypeName == "Full")
        #expect(viewModel.displayedClubShot?.carryDistance == 150)
    }

    @Test("Setting selected changes displayed club shot")
    func settingSelectedChangesDisplayed() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 150)], sortOrder: 0, in: container.mainContext)
        _ = createClub(name: "8 Iron", shotTypes: [("Full", 140)], sortOrder: 1, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()

        viewModel.selectClubShot(clubName: "8 Iron", shotTypeName: "Full", distance: 140)

        #expect(viewModel.selectedClubShot?.clubName == "8 Iron")
        #expect(viewModel.displayedClubShot?.clubName == "8 Iron")
        #expect(viewModel.displayedClubShot?.carryDistance == 140)
    }

    @Test("Show reset indicator false when selection matches recommendation")
    func showResetIndicatorFalseWhenMatchesRecommendation() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 150)], sortOrder: 0, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()

        // Select same as recommendation
        viewModel.selectClubShot(clubName: "7 Iron", shotTypeName: "Full", distance: 150)

        #expect(viewModel.showResetIndicator == false)
    }

    @Test("Show reset indicator true when selection differs from recommendation")
    func showResetIndicatorTrueWhenDiffers() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 150)], sortOrder: 0, in: container.mainContext)
        _ = createClub(name: "8 Iron", shotTypes: [("Full", 140)], sortOrder: 1, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()

        viewModel.selectClubShot(clubName: "8 Iron", shotTypeName: "Full", distance: 140)

        #expect(viewModel.showResetIndicator == true)
    }

    @Test("Reset to recommendation clears selection")
    func resetToRecommendationClearsSelection() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 150)], sortOrder: 0, in: container.mainContext)
        _ = createClub(name: "8 Iron", shotTypes: [("Full", 140)], sortOrder: 1, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()

        viewModel.selectClubShot(clubName: "8 Iron", shotTypeName: "Full", distance: 140)
        #expect(viewModel.selectedClubShot != nil)

        viewModel.resetToRecommendation()

        #expect(viewModel.selectedClubShot == nil)
        #expect(viewModel.displayedClubShot?.clubName == "7 Iron")
    }

    // MARK: - Ladder Calculation Tests

    @Test("Ladder range calculates correct min and max from percentage")
    func ladderRangeCalculatesCorrectMinMax() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 150)], sortOrder: 0, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(150)
        viewModel.yardageRangePercentage = 20

        // 150 +/- 20% = 120 to 180
        #expect(viewModel.ladderMinYardage == 120)
        #expect(viewModel.ladderMaxYardage == 180)
    }

    @Test("Ladder entries include clubs within range")
    func ladderEntriesIncludeClubsWithinRange() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 155)], sortOrder: 0, in: container.mainContext)
        _ = createClub(name: "8 Iron", shotTypes: [("Full", 145)], sortOrder: 1, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(150)
        viewModel.yardageRangePercentage = 15 // 127.5 to 172.5

        let entries = viewModel.ladderEntries
        let clubNames = entries.map { $0.clubName }

        #expect(clubNames.contains("7 Iron"))
        #expect(clubNames.contains("8 Iron"))
    }

    @Test("Ladder entries exclude clubs outside range")
    func ladderEntriesExcludeClubsOutsideRange() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "Driver", shotTypes: [("Full", 250)], sortOrder: 0, in: container.mainContext)
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 155)], sortOrder: 1, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(150)
        viewModel.yardageRangePercentage = 15 // 127.5 to 172.5

        let entries = viewModel.ladderEntries
        let clubNames = entries.map { $0.clubName }

        #expect(clubNames.contains("7 Iron"))
        #expect(!clubNames.contains("Driver"))
    }

    @Test("Ladder entry positions are normalized between 0 and 1")
    func ladderEntryPositionsNormalized() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "6 Iron", shotTypes: [("Full", 170)], sortOrder: 0, in: container.mainContext)
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 155)], sortOrder: 1, in: container.mainContext)
        _ = createClub(name: "8 Iron", shotTypes: [("Full", 140)], sortOrder: 2, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(155)
        viewModel.yardageRangePercentage = 15 // ~132 to ~178

        let entries = viewModel.ladderEntries

        for entry in entries {
            #expect(entry.yardagePosition >= 0.0)
            #expect(entry.yardagePosition <= 1.0)
        }

        // Entry at target should be at 0.5
        if let midEntry = entries.first(where: { $0.carryDistance == 155 }) {
            #expect(abs(midEntry.yardagePosition - 0.5) < 0.1)
        }
    }

    @Test("Selected club is marked in ladder entries")
    func selectedClubMarkedInLadderEntries() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 155)], sortOrder: 0, in: container.mainContext)
        _ = createClub(name: "8 Iron", shotTypes: [("Full", 145)], sortOrder: 1, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(150)

        viewModel.selectClubShot(clubName: "8 Iron", shotTypeName: "Full", distance: 145)

        let entries = viewModel.ladderEntries
        let selectedEntry = entries.first(where: { $0.clubName == "8 Iron" && $0.shotTypeName == "Full" })
        let nonSelectedEntry = entries.first(where: { $0.clubName == "7 Iron" })

        #expect(selectedEntry?.isSelected == true)
        #expect(nonSelectedEntry?.isSelected == false)
    }

    @Test("Same club different shots are marked correctly")
    func sameClubDifferentShotsMarkedCorrectly() async throws {
        let container = try makeTestContainer()
        _ = createClub(
            name: "7 Iron",
            shotTypes: [("Full", 155), ("3/4", 140)],
            sortOrder: 0,
            in: container.mainContext
        )

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(150)

        viewModel.selectClubShot(clubName: "7 Iron", shotTypeName: "Full", distance: 155)

        let entries = viewModel.ladderEntries
        let fullEntry = entries.first(where: { $0.clubName == "7 Iron" && $0.shotTypeName == "Full" })
        let threeQuarterEntry = entries.first(where: { $0.clubName == "7 Iron" && $0.shotTypeName == "3/4" })

        #expect(fullEntry?.isSelected == true)
        #expect(fullEntry?.isSameClubAsSelected == true)
        #expect(threeQuarterEntry?.isSelected == false)
        #expect(threeQuarterEntry?.isSameClubAsSelected == true)
    }

    // MARK: - Primary Shot Type Initial Filter Tests

    @Test("Initial filter is set from profile primaryShotType Full")
    func initialFilterFromProfileFull() async throws {
        let container = try makeTestContainer()
        _ = createClub(
            name: "7 Iron",
            shotTypes: [("Full", 150), ("3/4", 135)],
            sortOrder: 0,
            in: container.mainContext
        )

        // Default profile has primaryShotType = "Full"
        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()

        #expect(viewModel.selectedFilter == .full)
        // Recommendations should only contain Full shot types
        for rec in viewModel.recommendations {
            #expect(rec.shotTypeName == "Full")
        }
    }

    @Test("Initial filter is set from profile primaryShotType 3/4")
    func initialFilterFromProfileThreeQuarter() async throws {
        let container = try makeTestContainer()
        _ = createClub(
            name: "7 Iron",
            shotTypes: [("Full", 150), ("3/4", 135)],
            sortOrder: 0,
            in: container.mainContext
        )

        // Set profile primaryShotType to "3/4"
        let profileService = ProfileDataService(modelContext: container.mainContext)
        let profile = try await profileService.getOrCreateProfile()
        try await profileService.updateProfile(name: profile.name, handicap: profile.handicap, primaryShotType: "3/4")

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()

        #expect(viewModel.selectedFilter == .threeQuarter)
        for rec in viewModel.recommendations {
            #expect(rec.shotTypeName == "3/4")
        }
    }
}
