import Foundation
import SwiftData

@MainActor
@Observable
final class GolfModeViewModel {
    private let recommendationService: ShotRecommendationService
    private let clubService: ClubDataService
    private let profileService: ProfileDataService
    private let swingThoughtService: SwingThoughtDataService
    private let settingsService: AppSettingsService

    var profile: UserProfile?
    var targetYardage: Int = 150
    var selectedFilter: ShotTypeFilter = .all
    var recommendations: [ShotRecommendation] = []
    var clubs: [Club] = []
    var isLoading: Bool = false
    var errorMessage: String?
    private let minTargetYardage = YardageEntryValidationService.validRange.lowerBound
    private let maxTargetYardage = YardageEntryValidationService.validRange.upperBound

    // Selection tracking
    var selectedClubShot: SelectedClubShot?
    var yardageRangePercentage: Int = 15
    private var primaryShotTypeName: String = "Full"

    /// Bump = "scroll the text ladder back to the target".
    private(set) var ladderRecenterGeneration = 0

    // Computed properties for selection
    var recommendedClubShot: SelectedClubShot? {
        guard let rec = recommendations.first else { return nil }
        return SelectedClubShot(
            clubName: rec.clubName,
            shotTypeName: rec.shotTypeName,
            carryDistance: rec.carryDistance
        )
    }

    var displayedClubShot: SelectedClubShot? {
        selectedClubShot ?? recommendedClubShot
    }

    var showResetIndicator: Bool {
        guard let selected = selectedClubShot,
              let recommended = recommendedClubShot else { return false }
        return selected.clubName != recommended.clubName ||
               selected.shotTypeName != recommended.shotTypeName
    }

    // Ladder range calculations
    var ladderMinYardage: Int {
        Int((Double(targetYardage) * (1.0 - Double(yardageRangePercentage) / 100.0)).rounded())
    }

    var ladderMaxYardage: Int {
        Int((Double(targetYardage) * (1.0 + Double(yardageRangePercentage) / 100.0)).rounded())
    }

    var ladderEntries: [LadderEntry] {
        computeLadderEntries()
    }

    var groupedLadderEntries: [GroupedLadderEntry] {
        let entries = ladderEntries
        let grouped = Dictionary(grouping: entries) { $0.carryDistance }
        return grouped.map { distance, group in
            GroupedLadderEntry(carryDistance: distance, entries: group)
        }.sorted { $0.carryDistance > $1.carryDistance }
    }

    /// Whole-bag text ladder, matching the printed By Yardage card.
    var textLadder: DistanceTextLadder {
        DistanceTextLadderService.ladder(
            items: DistanceTextLadderService.golfItems(from: clubs),
            targetDistance: targetYardage,
            selectedItemID: displayedClubShot.map {
                DistanceTextLadderService.golfItemID(clubName: $0.clubName, shotTypeName: $0.shotTypeName)
            }
        )
    }

    init(modelContext: ModelContext) {
        self.recommendationService = ShotRecommendationService()
        self.clubService = ClubDataService(modelContext: modelContext)
        self.profileService = ProfileDataService(modelContext: modelContext)
        self.swingThoughtService = SwingThoughtDataService(modelContext: modelContext)
        self.settingsService = AppSettingsService(modelContext: modelContext)
    }

    // MARK: - Swing Thoughts & Routine

    var viewStyle: DistanceViewStyle {
        profile?.golfModeViewStyle ?? .defaultStyle
    }

    var sortedRoutineItems: [PreShotRoutineItem] {
        profile?.preShotRoutineItems.sorted { $0.sortOrder < $1.sortOrder } ?? []
    }

    var showPreShotRoutine: Bool {
        profile?.showPreShotRoutine == true && !sortedRoutineItems.isEmpty
    }

    var showMantra: Bool {
        profile?.showMantra == true && !(profile?.mantra.isEmpty ?? true)
    }

    var mantraText: String {
        profile?.mantra ?? ""
    }

    var matchingSwingThoughts: [SwingThought] {
        guard let profile, let clubShot = displayedClubShot else { return [] }
        return swingThoughtService.matchingSwingThoughts(
            from: profile,
            clubName: clubShot.clubName,
            shotTypeName: clubShot.shotTypeName
        )
    }

    /// Ensures default clubs exist when the store is empty, runs maintenance, then loads clubs and profile-driven UI state.
    func ensureDefaultsThenLoadClubs() async {
        do {
            try await clubService.loadDefaultClubs()
            try await clubService.backfillNicknames()
            try await clubService.purgeExpiredShotTypes()
        } catch {
            errorMessage = error.localizedDescription
        }
        await loadClubs()
        ladderRecenterGeneration += 1
    }

    /// Reloads the bag and app settings from the store on demand (after bag edits
    /// or a sync), dropping any manual selection so the recommendation and the
    /// yardage ladder match the new data.
    func refresh() async {
        resetToRecommendation()
        await loadClubs()
        ladderRecenterGeneration += 1
    }

    func loadClubs() async {
        isLoading = true
        do {
            clubs = try await clubService.fetchAllClubs()
            let settings = try await settingsService.getOrCreateSettings()
            yardageRangePercentage = settings.yardageRangePercentage
            let loadedProfile = try await profileService.getOrCreateProfile()
            profile = loadedProfile
            primaryShotTypeName = loadedProfile.primaryShotType
            await swingThoughtService.seedDefaultsIfNeeded(for: loadedProfile)
            if let filter = ShotTypeFilter(rawValue: loadedProfile.primaryShotType) {
                selectedFilter = filter
            }
            updateRecommendations()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setTargetYardage(_ yardage: Int) {
        targetYardage = min(max(yardage, minTargetYardage), maxTargetYardage)
        resetToRecommendation()
        updateRecommendations()
        ladderRecenterGeneration += 1
    }

    func setFilter(_ filter: ShotTypeFilter) {
        selectedFilter = filter
        updateRecommendations()
    }

    private func updateRecommendations() {
        recommendations = recommendationService.getRecommendations(
            targetYardage: targetYardage,
            clubs: clubs,
            filter: selectedFilter
        )
    }

    // MARK: - Bag Metadata

    var shotTypeNamesInBag: [String] {
        var names: Set<String> = []
        for club in clubs where !club.isArchived {
            for shotType in club.shotTypes where !shotType.isArchived {
                names.insert(shotType.name)
            }
        }
        return names.sorted()
    }

    // MARK: - Selection Methods

    func selectClubShot(clubName: String, shotTypeName: String, distance: Int) {
        selectedClubShot = SelectedClubShot(
            clubName: clubName,
            shotTypeName: shotTypeName,
            carryDistance: distance
        )
    }

    /// Golf-specific mapping: golf rows carry club name and shot type as their labels.
    /// Other modes (e.g. Putting) must supply their own selection mapping.
    func selectTextLadderRow(_ row: DistanceTextLadderRow) {
        selectClubShot(
            clubName: row.item.primaryLabel,
            shotTypeName: row.item.secondaryLabel,
            distance: row.item.distance
        )
    }

    func resetToRecommendation() {
        selectedClubShot = nil
    }

    // MARK: - Ladder Calculation

    private func computeLadderEntries() -> [LadderEntry] {
        var entries: [LadderEntry] = []
        let minYardage = ladderMinYardage
        let maxYardage = ladderMaxYardage
        let range = Double(maxYardage - minYardage)

        let selectedClubName = displayedClubShot?.clubName
        let selectedShotTypeName = displayedClubShot?.shotTypeName

        for club in clubs {
            for shotType in club.shotTypes where !shotType.isArchived {
                let distance = shotType.carryDistance

                // Only include shots within the ladder range
                guard distance >= minYardage && distance <= maxYardage else { continue }

                // Calculate normalized position (0 = min, 1 = max)
                let position: CGFloat = range > 0
                    ? CGFloat(distance - minYardage) / CGFloat(range)
                    : 0.5

                let isSelected = club.name == selectedClubName &&
                                 shotType.name == selectedShotTypeName
                let isSameClub = club.name == selectedClubName

                let entry = LadderEntry(
                    clubName: club.name,
                    clubNickname: club.nickname,
                    shotTypeName: shotType.name,
                    carryDistance: distance,
                    yardagePosition: position,
                    isSelected: isSelected,
                    isSameClubAsSelected: isSameClub,
                    isPrimaryShotType: shotType.name == primaryShotTypeName
                )
                entries.append(entry)
            }
        }

        return entries.sorted { $0.carryDistance > $1.carryDistance }
    }
}
