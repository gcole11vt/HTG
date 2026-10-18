import Testing
import SwiftData
@testable import HTG

@Suite("GolfModeViewModel Tests")
@MainActor
struct GolfModeViewModelTests {

    private func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([Club.self, ShotType.self, UserProfile.self, AppSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func createClub(name: String, nickname: String? = nil, shotTypes: [(String, Int)], sortOrder: Int, in context: ModelContext) -> Club {
        let resolvedNickname = nickname ?? NicknameGenerator.generate(from: name)
        let club = Club(name: name, nickname: resolvedNickname, sortOrder: sortOrder)
        for (index, (shotName, distance)) in shotTypes.enumerated() {
            let shotType = ShotType(name: shotName, carryDistance: distance, sortOrder: index, club: club)
            club.shotTypes.append(shotType)
        }
        context.insert(club)
        return club
    }

    @Test("View style reflects the profile's Golf Mode setting")
    func viewStyleReflectsProfileSetting() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 150)], sortOrder: 0, in: container.mainContext)
        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        #expect(viewModel.viewStyle == .text)

        try await ProfileDataService(modelContext: container.mainContext).updateGolfModeViewStyle(.ladder)
        await viewModel.refresh()

        #expect(viewModel.viewStyle == .ladder)
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

        viewModel.setTargetYardage(155)
        #expect(viewModel.selectedClubShot == nil)
        #expect(viewModel.showResetIndicator == false)
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
        viewModel.setTargetYardage(-20)
        #expect(viewModel.targetYardage == 50)
        viewModel.setTargetYardage(999)
        #expect(viewModel.targetYardage == 400)
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

    // MARK: - Nickname and Primary Shot Type in Ladder Tests

    @Test("Ladder entries contain correct clubNickname values")
    func ladderEntriesContainCorrectNicknames() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", nickname: "7I", shotTypes: [("Full", 155)], sortOrder: 0, in: container.mainContext)
        _ = createClub(name: "Pitching Wedge", nickname: "PW", shotTypes: [("Full", 135)], sortOrder: 1, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(145)
        viewModel.yardageRangePercentage = 20

        let entries = viewModel.ladderEntries
        let ironEntry = entries.first(where: { $0.clubName == "7 Iron" })
        let wedgeEntry = entries.first(where: { $0.clubName == "Pitching Wedge" })

        #expect(ironEntry?.clubNickname == "7I")
        #expect(wedgeEntry?.clubNickname == "PW")
    }

    // MARK: - Grouped Ladder Entry Tests

    @Test("Two entries at same distance produce one grouped entry")
    func twoEntriesSameDistanceProduceOneGroup() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", nickname: "7I", shotTypes: [("Full", 150)], sortOrder: 0, in: container.mainContext)
        _ = createClub(name: "Pitching Wedge", nickname: "PW", shotTypes: [("Full", 150)], sortOrder: 1, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(150)
        viewModel.yardageRangePercentage = 15

        let grouped = viewModel.groupedLadderEntries
        let at150 = grouped.filter { $0.carryDistance == 150 }

        #expect(at150.count == 1)
        #expect(at150.first?.entries.count == 2)
    }

    @Test("Primary entry sorts first in grouped entry")
    func primaryEntrySortsFirstInGroup() async throws {
        let container = try makeTestContainer()
        // PW non-primary and 7I primary at same distance
        _ = createClub(name: "Pitching Wedge", nickname: "PW", shotTypes: [("3/4", 150)], sortOrder: 1, in: container.mainContext)
        _ = createClub(name: "7 Iron", nickname: "7I", shotTypes: [("Full", 150)], sortOrder: 0, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(150)
        viewModel.yardageRangePercentage = 15

        let grouped = viewModel.groupedLadderEntries
        let at150 = grouped.first { $0.carryDistance == 150 }

        #expect(at150?.entries.first?.isPrimaryShotType == true)
        #expect(at150?.entries.first?.clubNickname == "7I")
    }

    @Test("displayLabel for group of 2 shows nicknames joined by slash")
    func displayLabelForGroupOfTwo() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", nickname: "7I", shotTypes: [("Full", 150)], sortOrder: 0, in: container.mainContext)
        _ = createClub(name: "Pitching Wedge", nickname: "PW", shotTypes: [("Full", 150)], sortOrder: 1, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(150)
        viewModel.yardageRangePercentage = 15

        let grouped = viewModel.groupedLadderEntries
        let at150 = grouped.first { $0.carryDistance == 150 }

        // Primary sorts first, so "7I / PW"
        #expect(at150?.displayLabel == "7I / PW")
    }

    @Test("displayLabel for single primary shows nickname only")
    func displayLabelForSinglePrimary() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", nickname: "7I", shotTypes: [("Full", 155)], sortOrder: 0, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(155)
        viewModel.yardageRangePercentage = 15

        let grouped = viewModel.groupedLadderEntries
        let at155 = grouped.first { $0.carryDistance == 155 }

        #expect(at155?.displayLabel == "7I")
    }

    @Test("displayLabel for single non-primary shows nickname and shot type")
    func displayLabelForSingleNonPrimary() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", nickname: "7I", shotTypes: [("3/4", 140)], sortOrder: 0, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(140)
        viewModel.yardageRangePercentage = 15

        let grouped = viewModel.groupedLadderEntries
        let at140 = grouped.first { $0.carryDistance == 140 }

        #expect(at140?.displayLabel == "7I 3/4")
    }

    @Test("isPrimaryShotType is correctly set on ladder entries")
    func isPrimaryShotTypeCorrectlySet() async throws {
        let container = try makeTestContainer()
        _ = createClub(
            name: "7 Iron",
            nickname: "7I",
            shotTypes: [("Full", 155), ("3/4", 140)],
            sortOrder: 0,
            in: container.mainContext
        )

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(150)
        viewModel.yardageRangePercentage = 15

        let entries = viewModel.ladderEntries
        let fullEntry = entries.first(where: { $0.shotTypeName == "Full" })
        let threeQuarterEntry = entries.first(where: { $0.shotTypeName == "3/4" })

        #expect(fullEntry?.isPrimaryShotType == true)
        #expect(threeQuarterEntry?.isPrimaryShotType == false)
    }

    @Test("Refresh reloads clubs added after the initial load and clears manual selection")
    func refreshReloadsClubsAndClearsSelection() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 150)], sortOrder: 0, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.selectClubShot(clubName: "7 Iron", shotTypeName: "Full", distance: 150)

        _ = createClub(name: "8 Iron", shotTypes: [("Full", 140)], sortOrder: 1, in: container.mainContext)
        try container.mainContext.save()

        await viewModel.refresh()

        #expect(viewModel.clubs.count == 2)
        #expect(viewModel.selectedClubShot == nil)
    }

    @Test("Refresh picks up the yardage range percentage from app settings")
    func refreshPicksUpYardageRangeFromSettings() async throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 150)], sortOrder: 0, in: container.mainContext)

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(100)

        // Default settings: 100 +/- 15% = 85 to 115
        #expect(viewModel.ladderMinYardage == 85)
        #expect(viewModel.ladderMaxYardage == 115)

        let settingsService = AppSettingsService(modelContext: container.mainContext)
        try await settingsService.updateYardageRangePercentage(25)

        await viewModel.refresh()

        // 100 +/- 25% = 75 to 125
        #expect(viewModel.ladderMinYardage == 75)
        #expect(viewModel.ladderMaxYardage == 125)
    }

    @Test("Refresh drops archived shot types from the ladder")
    func refreshDropsArchivedShotTypesFromLadder() async throws {
        let container = try makeTestContainer()
        let club = createClub(
            name: "7 Iron",
            shotTypes: [("Full", 150), ("3/4", 148)],
            sortOrder: 0,
            in: container.mainContext
        )

        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        viewModel.setTargetYardage(150)
        #expect(viewModel.ladderEntries.count == 2)

        club.shotTypes.first { $0.name == "3/4" }?.isArchived = true
        try container.mainContext.save()

        await viewModel.refresh()

        let entries = viewModel.ladderEntries
        #expect(entries.count == 1)
        #expect(entries.first?.shotTypeName == "Full")
    }

    // MARK: - Text Ladder Tests

    private func makeLoadedViewModel(in container: ModelContainer) async -> GolfModeViewModel {
        _ = createClub(name: "Driver", shotTypes: [("Tee", 250)], sortOrder: 0, in: container.mainContext)
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 150)], sortOrder: 1, in: container.mainContext)
        _ = createClub(name: "8 Iron", shotTypes: [("Full", 140)], sortOrder: 2, in: container.mainContext)
        _ = createClub(name: "Pitching Wedge", shotTypes: [("Full", 120)], sortOrder: 3, in: container.mainContext)
        let viewModel = GolfModeViewModel(modelContext: container.mainContext)
        await viewModel.loadClubs()
        return viewModel
    }

    @Test("Text ladder lists the whole bag, not only the ladder range")
    func textLadderListsWholeBag() async throws {
        let container = try makeTestContainer()
        let viewModel = await makeLoadedViewModel(in: container)
        #expect(viewModel.textLadder.rows.count == 4)
        #expect(viewModel.ladderEntries.count == 2)
    }

    @Test("Text ladder anchors on the target yardage")
    func textLadderAnchorsOnTarget() async throws {
        let container = try makeTestContainer()
        let viewModel = await makeLoadedViewModel(in: container)
        viewModel.setTargetYardage(122)
        #expect(viewModel.textLadder.anchorRowID == "Pitching Wedge-Full")
        #expect(viewModel.textLadder.targetDistance == 122)
    }

    @Test("Text ladder flags the displayed club shot")
    func textLadderFlagsDisplayed() async throws {
        let container = try makeTestContainer()
        let viewModel = await makeLoadedViewModel(in: container)
        #expect(viewModel.textLadder.rows.filter(\.isSelected).map(\.id) == ["7 Iron-Full"])
        viewModel.selectClubShot(clubName: "8 Iron", shotTypeName: "Full", distance: 140)
        #expect(viewModel.textLadder.rows.filter(\.isSelected).map(\.id) == ["8 Iron-Full"])
    }

    @Test("Selecting a text ladder row selects that club shot")
    func selectingTextLadderRow() async throws {
        let container = try makeTestContainer()
        let viewModel = await makeLoadedViewModel(in: container)
        let row = try #require(viewModel.textLadder.rows.first { $0.id == "8 Iron-Full" })
        viewModel.selectTextLadderRow(row)
        #expect(viewModel.displayedClubShot?.clubName == "8 Iron")
        #expect(viewModel.displayedClubShot?.shotTypeName == "Full")
        #expect(viewModel.displayedClubShot?.carryDistance == 140)
        #expect(viewModel.showResetIndicator)
    }

    @Test("Recenter generation bumps on target change and refresh only")
    func recenterGenerationBumps() async throws {
        let container = try makeTestContainer()
        let viewModel = await makeLoadedViewModel(in: container)
        let start = viewModel.ladderRecenterGeneration
        viewModel.setTargetYardage(151)
        #expect(viewModel.ladderRecenterGeneration == start + 1)
        viewModel.selectClubShot(clubName: "8 Iron", shotTypeName: "Full", distance: 140)
        #expect(viewModel.ladderRecenterGeneration == start + 1)
        viewModel.resetToRecommendation()
        #expect(viewModel.ladderRecenterGeneration == start + 1)
        await viewModel.refresh()
        #expect(viewModel.ladderRecenterGeneration == start + 2)
    }

    @Test("Tab-entry load bumps the recenter generation")
    func tabEntryBumpsGeneration() async throws {
        let container = try makeTestContainer()
        let viewModel = await makeLoadedViewModel(in: container)
        let start = viewModel.ladderRecenterGeneration
        await viewModel.ensureDefaultsThenLoadClubs()
        #expect(viewModel.ladderRecenterGeneration == start + 1)
    }

    @Test("Text ladder reflects bag changes after refresh")
    func textLadderReflectsBagChanges() async throws {
        let container = try makeTestContainer()
        let viewModel = await makeLoadedViewModel(in: container)
        _ = createClub(name: "9 Iron", shotTypes: [("Full", 130)], sortOrder: 4, in: container.mainContext)
        try container.mainContext.save()
        await viewModel.refresh()
        #expect(viewModel.textLadder.rows.contains { $0.id == "9 Iron-Full" })
    }
}
