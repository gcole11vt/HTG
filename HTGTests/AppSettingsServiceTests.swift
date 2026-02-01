import Testing
import SwiftData
@testable import HTG

@Suite("AppSettingsService Tests")
@MainActor
struct AppSettingsServiceTests {

    private func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([AppSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test("Creates default settings on first access")
    func createsDefaultSettingsOnFirstAccess() async throws {
        let container = try makeTestContainer()
        let service = AppSettingsService(modelContext: container.mainContext)

        let settings = try await service.getOrCreateSettings()

        #expect(settings.yardageRangePercentage == 15)
    }

    @Test("Returns existing settings on subsequent access")
    func returnsExistingSettings() async throws {
        let container = try makeTestContainer()
        let service = AppSettingsService(modelContext: container.mainContext)

        let settings1 = try await service.getOrCreateSettings()
        let settings2 = try await service.getOrCreateSettings()

        #expect(settings1.id == settings2.id)
    }

    @Test("Persists yardage range percentage")
    func persistsYardageRangePercentage() async throws {
        let container = try makeTestContainer()
        let service = AppSettingsService(modelContext: container.mainContext)

        try await service.updateYardageRangePercentage(20)

        let settings = try await service.getOrCreateSettings()
        #expect(settings.yardageRangePercentage == 20)
    }
}
