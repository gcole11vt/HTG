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

        if let existingProfile = profiles.first {
            return existingProfile
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
        try modelContext.save()
    }
}
