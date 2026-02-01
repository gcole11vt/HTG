import Foundation
import SwiftData

@MainActor
final class AppSettingsService: Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getOrCreateSettings() async throws -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        let existingSettings = try modelContext.fetch(descriptor)

        if let settings = existingSettings.first {
            return settings
        }

        let newSettings = AppSettings()
        modelContext.insert(newSettings)
        try modelContext.save()
        return newSettings
    }

    func updateYardageRangePercentage(_ percentage: Int) async throws {
        let settings = try await getOrCreateSettings()
        settings.yardageRangePercentage = percentage
        try modelContext.save()
    }
}
