import Foundation
import SwiftData

@MainActor
@Observable
final class RangeManager {
    private let service: RangeDataService
    private let clubDataService: ClubDataService

    var currentSession: RangeSession?
    var sessions: [RangeSession] = []
    var currentStats: RangeStats = RangeStats()
    var isLoading: Bool = false
    var errorMessage: String?

    var sessionClub: Club?
    var sessionShotType: ShotType?
    var isCustomShotType: Bool = false

    var currentCarryDistance: Int? {
        guard let shotType = sessionShotType, shotType.carryDistance > 0 else { return nil }
        return shotType.carryDistance
    }

    init(modelContext: ModelContext) {
        self.service = RangeDataService(modelContext: modelContext)
        self.clubDataService = ClubDataService(modelContext: modelContext)
    }

    func startSession(club: Club, shotType: ShotType?, shotTypeName: String, isCustom: Bool) async {
        isLoading = true
        errorMessage = nil
        sessionClub = club
        sessionShotType = shotType
        isCustomShotType = isCustom
        do {
            currentSession = try await service.createSession(clubName: club.name, shotTypeName: shotTypeName)
            updateStats()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addShot(distance: Int, isFromVoice: Bool = false) async {
        guard let session = currentSession else {
            errorMessage = "No active session"
            return
        }

        do {
            try await service.addShot(to: session, distance: distance, isFromVoice: isFromVoice)
            updateStats()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteShot(_ shot: Shot) async {
        guard let session = currentSession else {
            errorMessage = "No active session"
            return
        }

        do {
            try await service.deleteShot(shot, from: session)
            updateStats()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteLastShot() async {
        guard let session = currentSession,
              let lastShot = session.shots.sorted(by: { $0.date > $1.date }).first else { return }
        await deleteShot(lastShot)
    }

    func endSession() async {
        if let session = currentSession {
            do {
                try await service.deleteSession(session)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        currentSession = nil
        currentStats = RangeStats()
        sessionClub = nil
        sessionShotType = nil
        isCustomShotType = false
    }

    func saveSession(carryDistance: Int) async {
        guard let club = sessionClub else {
            errorMessage = "No club associated with session"
            return
        }
        guard let session = currentSession else {
            errorMessage = "No active session"
            return
        }

        do {
            if isCustomShotType {
                let existingMatch = club.shotTypes.first(where: {
                    $0.name.lowercased() == session.shotTypeName.lowercased() && !$0.isArchived
                })
                if let existing = existingMatch {
                    try await service.updateShotTypeCarryDistance(existing, distance: carryDistance)
                } else {
                    try await clubDataService.addShotType(to: club, name: session.shotTypeName, distance: carryDistance)
                }
            } else if let shotType = sessionShotType {
                try await service.updateShotTypeCarryDistance(shotType, distance: carryDistance)
            }

            try await service.deleteSession(session)

            currentSession = nil
            currentStats = RangeStats()
            sessionClub = nil
            sessionShotType = nil
            isCustomShotType = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadSessions() async {
        isLoading = true
        do {
            sessions = try await service.fetchAllSessions()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteSession(_ session: RangeSession) async {
        do {
            try await service.deleteSession(session)
            await loadSessions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateStats() {
        guard let session = currentSession else {
            currentStats = RangeStats()
            return
        }
        currentStats = service.calculateStats(for: session)
    }
}
