import Foundation
import SwiftData

@MainActor
@Observable
final class AppLaunchViewModel {
    private let profileService: ProfileDataService

    var hasOpenedJournal: Bool = false
    var ownerName: String = "Golfer"
    var isLoading: Bool = true

    init(modelContext: ModelContext) {
        self.profileService = ProfileDataService(modelContext: modelContext)
    }

    func loadProfile() async {
        isLoading = true
        do {
            let profile = try await profileService.getOrCreateProfile()
            ownerName = profile.name.isEmpty ? "Golfer" : profile.name
        } catch {
            ownerName = "Golfer"
        }
        isLoading = false
    }

    func completeOpening() {
        hasOpenedJournal = true
    }
}
