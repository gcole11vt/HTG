import Foundation
import SwiftData

@MainActor
@Observable
final class ProfileManager {
    private let service: ProfileDataService
    private let clubService: ClubDataService

    var profile: UserProfile?
    var shotTypeNames: [String] = []
    var isLoading: Bool = false
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.service = ProfileDataService(modelContext: modelContext)
        self.clubService = ClubDataService(modelContext: modelContext)
    }

    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            profile = try await service.getOrCreateProfile()
            shotTypeNames = try await clubService.fetchAllUniqueShotTypeNames()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateProfile(name: String, handicap: Int, primaryShotType: String? = nil) async {
        do {
            try await service.updateProfile(name: name, handicap: handicap, primaryShotType: primaryShotType)
            await loadProfile()
        } catch ProfileDataServiceError.invalidHandicap {
            errorMessage = "Handicap must be between 0 and 54"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
