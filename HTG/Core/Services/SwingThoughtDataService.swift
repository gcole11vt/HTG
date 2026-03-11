import Foundation
import SwiftData

@MainActor
final class SwingThoughtDataService: Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Default Seeding

    func seedDefaultsIfNeeded(for profile: UserProfile) async {
        guard profile.preShotRoutineItems.isEmpty else { return }

        let defaults = ["Pick target", "Visualize shot", "One practice swing", "Commit"]
        for (index, text) in defaults.enumerated() {
            let item = PreShotRoutineItem(text: text, sortOrder: index, profile: profile)
            modelContext.insert(item)
        }
        try? modelContext.save()
    }

    // MARK: - Pre-Shot Routine

    func addRoutineItem(to profile: UserProfile, text: String) async throws {
        let nextOrder = profile.preShotRoutineItems.count
        let item = PreShotRoutineItem(text: text, sortOrder: nextOrder, profile: profile)
        modelContext.insert(item)
        try modelContext.save()
    }

    func deleteRoutineItem(_ item: PreShotRoutineItem) async throws {
        modelContext.delete(item)
        try modelContext.save()
    }

    func reorderRoutineItems(_ items: [PreShotRoutineItem]) async throws {
        for (index, item) in items.enumerated() {
            item.sortOrder = index
        }
        try modelContext.save()
    }

    func updateRoutineItemText(_ item: PreShotRoutineItem, text: String) async throws {
        item.text = text
        try modelContext.save()
    }

    // MARK: - Swing Thoughts

    func addSwingThought(to profile: UserProfile, text: String, tagType: String, tagValue: String) async throws {
        let thought = SwingThought(text: text, tagType: tagType, tagValue: tagValue, profile: profile)
        modelContext.insert(thought)
        try modelContext.save()
    }

    func deleteSwingThought(_ thought: SwingThought) async throws {
        modelContext.delete(thought)
        try modelContext.save()
    }

    func matchingSwingThoughts(from profile: UserProfile, clubName: String, shotTypeName: String) -> [SwingThought] {
        profile.swingThoughts.filter { thought in
            switch thought.tagType {
            case "all":
                return true
            case "club":
                return thought.tagValue == clubName
            case "shotType":
                return thought.tagValue == shotTypeName
            default:
                return false
            }
        }
    }

    // MARK: - Mantra & Toggles

    func updateMantra(for profile: UserProfile, text: String) async throws {
        profile.mantra = text
        try modelContext.save()
    }

    func setShowPreShotRoutine(for profile: UserProfile, visible: Bool) async throws {
        profile.showPreShotRoutine = visible
        try modelContext.save()
    }

    func setShowMantra(for profile: UserProfile, visible: Bool) async throws {
        profile.showMantra = visible
        try modelContext.save()
    }
}
