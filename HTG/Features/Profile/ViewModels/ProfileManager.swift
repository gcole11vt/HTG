import Foundation
import SwiftData

@MainActor
@Observable
final class ProfileManager {
    private let service: ProfileDataService

    var profile: UserProfile?
    var isLoading: Bool = false
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.service = ProfileDataService(modelContext: modelContext)
    }

    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            profile = try await service.getOrCreateProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateProfile(name: String, handicap: Int) async {
        do {
            try await service.updateProfile(name: name, handicap: handicap)
            await loadProfile()
        } catch ProfileDataServiceError.invalidHandicap {
            errorMessage = "Handicap must be between 0 and 54"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
