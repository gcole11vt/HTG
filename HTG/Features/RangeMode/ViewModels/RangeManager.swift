import Foundation
import SwiftData

@MainActor
@Observable
final class RangeManager {
    private let service: RangeDataService

    var currentSession: RangeSession?
    var sessions: [RangeSession] = []
    var currentStats: RangeStats = RangeStats()
    var isLoading: Bool = false
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.service = RangeDataService(modelContext: modelContext)
    }

    func startSession(clubName: String, shotTypeName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            currentSession = try await service.createSession(clubName: clubName, shotTypeName: shotTypeName)
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

    func endSession() async {
        currentSession = nil
        currentStats = RangeStats()
    }

    func saveSessionAsStoredShotType() async {
        guard let session = currentSession else {
            errorMessage = "No active session"
            return
        }

        do {
            try await service.saveAsStoredShotType(session: session)
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
