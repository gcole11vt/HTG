import Foundation
import SwiftData

@MainActor
@Observable
final class ProfileManager {
    private let service: ProfileDataService
    private let clubService: ClubDataService
    private let swingThoughtService: SwingThoughtDataService

    var profile: UserProfile?
    var shotTypeNames: [String] = []
    var clubNames: [String] = []
    var isLoading: Bool = false
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.service = ProfileDataService(modelContext: modelContext)
        self.clubService = ClubDataService(modelContext: modelContext)
        self.swingThoughtService = SwingThoughtDataService(modelContext: modelContext)
    }

    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            profile = try await service.getOrCreateProfile()
            if let profile {
                await swingThoughtService.seedDefaultsIfNeeded(for: profile)
            }
            shotTypeNames = try await clubService.fetchAllUniqueShotTypeNames()
            clubNames = try await clubService.fetchAllClubs().map(\.name)
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

    // MARK: - Golf Mode View Style

    var golfModeViewStyle: DistanceViewStyle {
        profile?.golfModeViewStyle ?? .defaultStyle
    }

    func setGolfModeViewStyle(_ style: DistanceViewStyle) async {
        do {
            try await service.updateGolfModeViewStyle(style)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Pre-Shot Routine

    func addRoutineItem(text: String) async {
        guard let profile else { return }
        do {
            try await swingThoughtService.addRoutineItem(to: profile, text: text)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteRoutineItem(_ item: PreShotRoutineItem) async {
        do {
            try await swingThoughtService.deleteRoutineItem(item)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reorderRoutineItems(_ items: [PreShotRoutineItem]) async {
        do {
            try await swingThoughtService.reorderRoutineItems(items)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateRoutineItemText(_ item: PreShotRoutineItem, text: String) async {
        do {
            try await swingThoughtService.updateRoutineItemText(item, text: text)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Mantra

    func updateMantra(_ text: String) async {
        guard let profile else { return }
        do {
            try await swingThoughtService.updateMantra(for: profile, text: text)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setShowPreShotRoutine(_ visible: Bool) async {
        guard let profile else { return }
        do {
            try await swingThoughtService.setShowPreShotRoutine(for: profile, visible: visible)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setShowMantra(_ visible: Bool) async {
        guard let profile else { return }
        do {
            try await swingThoughtService.setShowMantra(for: profile, visible: visible)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setShowSwingThoughts(_ visible: Bool) async {
        guard let profile else { return }
        do {
            try await swingThoughtService.setShowSwingThoughts(for: profile, visible: visible)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Swing Thoughts

    func addSwingThought(text: String, tagType: String, tagValue: String) async {
        guard let profile else { return }
        do {
            try await swingThoughtService.addSwingThought(to: profile, text: text, tagType: tagType, tagValue: tagValue)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteSwingThought(_ thought: SwingThought) async {
        do {
            try await swingThoughtService.deleteSwingThought(thought)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
