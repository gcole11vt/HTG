import Foundation
import SwiftData

enum ProfileDataServiceError: Error, Equatable {
    case invalidHandicap
}

@MainActor
final class ProfileDataService: Sendable {
    private let modelContext: ModelContext

    static let minimumHandicap = 0
    static let maximumHandicap = 54

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getOrCreateProfile() async throws -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try modelContext.fetch(descriptor)

        // Prefer a personalized profile, then the most recently updated, so
        // an empty auto-created duplicate never shadows the synced one.
        let best = profiles.sorted { lhs, rhs in
            let lhsPristine = lhs.name.trimmingCharacters(in: .whitespaces).isEmpty
            let rhsPristine = rhs.name.trimmingCharacters(in: .whitespaces).isEmpty
            if lhsPristine != rhsPristine { return !lhsPristine }
            return lhs.updatedAt > rhs.updatedAt
        }.first

        if let best {
            return best
        }

        let newProfile = UserProfile()
        modelContext.insert(newProfile)
        try modelContext.save()
        return newProfile
    }

    func updateProfile(name: String, handicap: Int, primaryShotType: String? = nil) async throws {
        guard handicap >= Self.minimumHandicap && handicap <= Self.maximumHandicap else {
            throw ProfileDataServiceError.invalidHandicap
        }

        let profile = try await getOrCreateProfile()
        profile.name = name
        profile.handicap = handicap
        if let primaryShotType {
            profile.primaryShotType = primaryShotType
        }
        profile.updatedAt = Date()
        try modelContext.save()
    }

    func updateGolfModeViewStyle(_ style: DistanceViewStyle) async throws {
        let profile = try await getOrCreateProfile()
        profile.golfModeViewStyle = style
        profile.updatedAt = Date()
        try modelContext.save()
    }
}
