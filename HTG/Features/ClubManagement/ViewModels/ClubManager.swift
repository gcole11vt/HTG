import Foundation
import SwiftData

@MainActor
@Observable
final class ClubManager {
    private let service: ClubDataService

    var clubs: [Club] = []
    var archivedClubs: [Club] = []
    var isLoading: Bool = false
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.service = ClubDataService(modelContext: modelContext)
    }

    func loadClubs() async {
        isLoading = true
        errorMessage = nil
        do {
            clubs = try await service.fetchAllClubs()
            archivedClubs = try await service.fetchArchivedClubs()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadDefaultClubsIfNeeded() async {
        do {
            try await service.loadDefaultClubs()
            try await service.backfillNicknames()
            try await service.purgeExpiredShotTypes()
            await loadClubs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addClub(name: String, defaultDistance: Int, nickname: String? = nil) async {
        do {
            _ = try await service.addClub(name: name, defaultDistance: defaultDistance, nickname: nickname)
            await loadClubs()
        } catch ClubDataServiceError.maximumClubsReached {
            errorMessage = "Maximum of 13 clubs reached"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteClub(_ club: Club) async {
        do {
            try await service.deleteClub(club)
            await loadClubs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateClub(_ club: Club, name: String, nickname: String? = nil) async {
        do {
            try await service.updateClub(club, name: name, nickname: nickname)
            await loadClubs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reorderClubs(_ clubs: [Club]) async {
        do {
            try await service.reorderClubs(clubs)
            await loadClubs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archiveClub(_ club: Club) async {
        do {
            try await service.archiveClub(club)
            await loadClubs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restoreClub(_ club: Club) async {
        do {
            try await service.restoreClub(club)
            await loadClubs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addShotType(to club: Club, name: String, distance: Int) async {
        do {
            try await service.addShotType(to: club, name: name, distance: distance)
            await loadClubs()
        } catch ClubDataServiceError.maximumShotTypesReached {
            errorMessage = "Maximum of 5 shot types per club reached"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateShotType(_ shotType: ShotType, name: String, distance: Int) async {
        do {
            try await service.updateShotType(shotType, name: name, distance: distance)
            await loadClubs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archiveShotType(_ shotType: ShotType, from club: Club) async {
        do {
            try await service.archiveShotType(shotType, from: club)
            await loadClubs()
        } catch ClubDataServiceError.minimumShotTypesRequired {
            errorMessage = "Each club must have at least one shot type"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restoreShotType(_ shotType: ShotType) async {
        do {
            try await service.restoreShotType(shotType)
            await loadClubs()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
