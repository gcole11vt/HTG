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
        var descriptor = FetchDescriptor<Club>(
            predicate: #Predicate { $0.isArchived == false },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor)
    }

    func fetchArchivedClubs() async throws -> [Club] {
        var descriptor = FetchDescriptor<Club>(
            predicate: #Predicate { $0.isArchived == true },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor)
    }

    func archiveClub(_ club: Club) async throws {
        club.isArchived = true
        try modelContext.save()
    }

    func restoreClub(_ club: Club) async throws {
        club.isArchived = false
        try modelContext.save()
    }

    func addClub(name: String, defaultDistance: Int, nickname: String? = nil) async throws -> Club {
        let existingClubs = try await fetchAllClubs()

        guard existingClubs.count < Self.maximumClubs else {
            throw ClubDataServiceError.maximumClubsReached
        }

        let resolvedNickname = nickname ?? NicknameGenerator.generate(from: name)
        let club = Club(name: name, nickname: resolvedNickname, sortOrder: existingClubs.count)
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

    func updateClub(_ club: Club, name: String, nickname: String? = nil) async throws {
        club.name = name
        if let nickname {
            club.nickname = nickname
        }
        try modelContext.save()
    }

    func reorderClubs(_ clubs: [Club]) async throws {
        for (index, club) in clubs.enumerated() {
            club.sortOrder = index
        }
        try modelContext.save()
    }

    func addShotType(to club: Club, name: String, distance: Int) async throws {
        let activeShotTypes = club.shotTypes.filter { !$0.isArchived }
        guard activeShotTypes.count < Self.maximumShotTypesPerClub else {
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

    func updateShotType(_ shotType: ShotType, name: String, distance: Int) async throws {
        shotType.name = name
        shotType.carryDistance = distance
        try modelContext.save()
    }

    func archiveShotType(_ shotType: ShotType, from club: Club) async throws {
        let activeShotTypes = club.shotTypes.filter { !$0.isArchived }
        guard activeShotTypes.count > Self.minimumShotTypesPerClub else {
            throw ClubDataServiceError.minimumShotTypesRequired
        }

        shotType.isArchived = true
        shotType.archivedDate = Date()
        try modelContext.save()
    }

    func restoreShotType(_ shotType: ShotType) async throws {
        shotType.isArchived = false
        shotType.archivedDate = nil
        try modelContext.save()
    }

    func purgeExpiredShotTypes() async throws {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        var descriptor = FetchDescriptor<ShotType>(
            predicate: #Predicate<ShotType> { shotType in
                shotType.isArchived == true
            }
        )
        descriptor.includePendingChanges = true
        let archivedShotTypes = try modelContext.fetch(descriptor)
        let expired = archivedShotTypes.filter { shotType in
            guard let archivedDate = shotType.archivedDate else { return false }
            return archivedDate < sevenDaysAgo
        }
        guard !expired.isEmpty else { return }
        for shotType in expired {
            shotType.club?.shotTypes.removeAll { $0.id == shotType.id }
            modelContext.delete(shotType)
        }
        try modelContext.save()
    }

    func backfillNicknames() async throws {
        var descriptor = FetchDescriptor<Club>(
            predicate: #Predicate { $0.nickname == "" }
        )
        descriptor.includePendingChanges = true
        let clubs = try modelContext.fetch(descriptor)
        guard !clubs.isEmpty else { return }
        for club in clubs {
            club.nickname = NicknameGenerator.generate(from: club.name)
        }
        try modelContext.save()
    }

    func fetchAllUniqueShotTypeNames() async throws -> [String] {
        let descriptor = FetchDescriptor<ShotType>()
        let shotTypes = try modelContext.fetch(descriptor)
        let uniqueNames = Set(shotTypes.map(\.name))
        return uniqueNames.sorted()
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
            let club = Club(name: name, nickname: NicknameGenerator.generate(from: name), sortOrder: index)
            let fullShot = ShotType(name: "Full", carryDistance: distance, sortOrder: 0, club: club)
            let threeQuarterDist = Int(Double(distance) * Double.random(in: 0.90...0.95))
            let threeQuarterShot = ShotType(name: "3/4", carryDistance: threeQuarterDist, sortOrder: 1, club: club)
            let hardDist = Int(Double(distance) * Double.random(in: 1.02...1.08))
            let hardShot = ShotType(name: "Hard", carryDistance: hardDist, sortOrder: 2, club: club)
            let halfDist = Int(Double(distance) * Double.random(in: 0.55...0.75))
            let halfShot = ShotType(name: "1/2", carryDistance: halfDist, sortOrder: 3, club: club)
            club.shotTypes = [fullShot, threeQuarterShot, hardShot, halfShot]
            modelContext.insert(club)
        }

        try modelContext.save()
    }
}
