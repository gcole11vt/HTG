import Foundation
import SwiftData

@MainActor
final class RangeDataService: Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createSession(clubName: String, shotTypeName: String) async throws -> RangeSession {
        let session = RangeSession(clubName: clubName, shotTypeName: shotTypeName)
        modelContext.insert(session)
        try modelContext.save()
        return session
    }

    func addShot(to session: RangeSession, distance: Int, isFromVoice: Bool) async throws {
        let shot = Shot(distance: distance, isFromVoice: isFromVoice, session: session)
        session.shots.append(shot)
        try modelContext.save()
    }

    func deleteShot(_ shot: Shot, from session: RangeSession) async throws {
        session.shots.removeAll { $0.id == shot.id }
        modelContext.delete(shot)
        try modelContext.save()
    }

    func deleteSession(_ session: RangeSession) async throws {
        modelContext.delete(session)
        try modelContext.save()
    }

    func fetchAllSessions() async throws -> [RangeSession] {
        let descriptor = FetchDescriptor<RangeSession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    func calculateStats(for session: RangeSession) -> RangeStats {
        let distances = session.shots.map { $0.distance }.sorted()

        guard !distances.isEmpty else {
            return RangeStats()
        }

        let count = distances.count
        let max = distances.last ?? 0
        let median = calculateMedian(distances)
        let percentile75 = calculatePercentile(distances, percentile: 0.75)

        return RangeStats(max: max, percentile75: percentile75, median: median, count: count)
    }

    func saveAsStoredShotType(session: RangeSession) async throws {
        let stats = calculateStats(for: session)

        let storedType = StoredShotType(
            clubName: session.clubName,
            shotTypeName: session.shotTypeName,
            distance: stats.median
        )

        modelContext.insert(storedType)
        try modelContext.save()
    }

    private func calculateMedian(_ sortedValues: [Int]) -> Int {
        guard !sortedValues.isEmpty else { return 0 }

        let count = sortedValues.count
        if count % 2 == 0 {
            // Even count: average of two middle values
            let mid1 = sortedValues[count / 2 - 1]
            let mid2 = sortedValues[count / 2]
            return (mid1 + mid2) / 2
        } else {
            // Odd count: middle value
            return sortedValues[count / 2]
        }
    }

    private func calculatePercentile(_ sortedValues: [Int], percentile: Double) -> Int {
        guard !sortedValues.isEmpty else { return 0 }

        let index = Int(Double(sortedValues.count - 1) * percentile)
        return sortedValues[index]
    }
}
