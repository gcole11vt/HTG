import Foundation
import SwiftData

@MainActor
@Observable
final class GolfModeViewModel {
    private let recommendationService: ShotRecommendationService
    private let clubService: ClubDataService

    var targetYardage: Int = 150
    var selectedFilter: ShotTypeFilter = .all
    var recommendations: [ShotRecommendation] = []
    var clubs: [Club] = []
    var isLoading: Bool = false
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.recommendationService = ShotRecommendationService()
        self.clubService = ClubDataService(modelContext: modelContext)
    }

    func loadClubs() async {
        isLoading = true
        do {
            clubs = try await clubService.fetchAllClubs()
            updateRecommendations()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setTargetYardage(_ yardage: Int) {
        targetYardage = yardage
        updateRecommendations()
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
}
