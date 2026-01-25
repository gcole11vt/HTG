import Foundation
import SwiftData

enum ClubDataServiceError: Error, Equatable {
    case maximumClubsReached
    case maximumShotTypesReached
    case minimumShotTypesRequired
    case clubNotFound
}

@MainActor
final class ClubDataService: Sendable {
    private let modelContext: ModelContext

    static let maximumClubs = 13
    static let maximumShotTypesPerClub = 5
    static let minimumShotTypesPerClub = 1

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllClubs() async throws -> [Club] {
        let descriptor = FetchDescriptor<Club>(sortBy: [SortDescriptor(\.sortOrder)])
        return try modelContext.fetch(descriptor)
    }

    func addClub(name: String, defaultDistance: Int) async throws -> Club {
        let existingClubs = try await fetchAllClubs()

        guard existingClubs.count < Self.maximumClubs else {
            throw ClubDataServiceError.maximumClubsReached
        }

        let club = Club(name: name, sortOrder: existingClubs.count)
        let fullShotType = ShotType(name: "Full", carryDistance: defaultDistance, sortOrder: 0, club: club)
        club.shotTypes = [fullShotType]

        modelContext.insert(club)
        try modelContext.save()

        return club
    }

    func deleteClub(_ club: Club) async throws {
        modelContext.delete(club)
        try modelContext.save()
    }

    func updateClub(_ club: Club, name: String) async throws {
        club.name = name
        try modelContext.save()
    }

    func reorderClubs(_ clubs: [Club]) async throws {
        for (index, club) in clubs.enumerated() {
            club.sortOrder = index
        }
        try modelContext.save()
    }

    func addShotType(to club: Club, name: String, distance: Int) async throws {
        guard club.shotTypes.count < Self.maximumShotTypesPerClub else {
            throw ClubDataServiceError.maximumShotTypesReached
        }

        let shotType = ShotType(
            name: name,
            carryDistance: distance,
            sortOrder: club.shotTypes.count,
            club: club
        )
        club.shotTypes.append(shotType)
        try modelContext.save()
    }

    func deleteShotType(_ shotType: ShotType, from club: Club) async throws {
        guard club.shotTypes.count > Self.minimumShotTypesPerClub else {
            throw ClubDataServiceError.minimumShotTypesRequired
        }

        club.shotTypes.removeAll { $0.id == shotType.id }
        modelContext.delete(shotType)
        try modelContext.save()
    }

    func loadDefaultClubs() async throws {
        let existingClubs = try await fetchAllClubs()
        guard existingClubs.isEmpty else { return }

        let defaultClubs: [(String, Int)] = [
            ("Driver", 250),
            ("3 Wood", 230),
            ("5 Wood", 215),
            ("4 Hybrid", 200),
            ("5 Iron", 185),
            ("6 Iron", 175),
            ("7 Iron", 165),
            ("8 Iron", 155),
            ("9 Iron", 145),
            ("Pitching Wedge", 135),
            ("Gap Wedge", 120),
            ("Sand Wedge", 100),
            ("Lob Wedge", 80)
        ]

        for (index, (name, distance)) in defaultClubs.enumerated() {
            let club = Club(name: name, sortOrder: index)
            let fullShotType = ShotType(name: "Full", carryDistance: distance, sortOrder: 0, club: club)
            club.shotTypes = [fullShotType]
            modelContext.insert(club)
        }

        try modelContext.save()
    }
}
