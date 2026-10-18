import SwiftUI
import SwiftData

private func makePersistentModelConfiguration(schema: Schema) -> ModelConfiguration {
    ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
}

private func defaultStorePaths() -> [String] {
    guard let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path else {
        return []
    }

    let storePath = "\(appSupportPath)/default.store"
    return [storePath, "\(storePath)-wal", "\(storePath)-shm"]
}

private func removePersistentStoreFiles() {
    defaultStorePaths().forEach { path in
        guard FileManager.default.fileExists(atPath: path) else {
            return
        }
        try? FileManager.default.removeItem(atPath: path)
    }
}

@main
struct HTGApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Club.self,
            ShotType.self,
            RangeSession.self,
            Shot.self,
            StoredShotType.self,
            UserProfile.self,
            AppSettings.self,
            PreShotRoutineItem.self,
            SwingThought.self,
            SyncTombstone.self,
            PuttingCalibration.self,
            PuttingCalibrationPutt.self
        ])

        let modelConfiguration = makePersistentModelConfiguration(schema: schema)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch let initialError {
            removePersistentStoreFiles()

            do {
                let retryConfiguration = makePersistentModelConfiguration(schema: schema)
                return try ModelContainer(for: schema, configurations: [retryConfiguration])
            } catch let retryError {
                fatalError("Could not create ModelContainer after recovery attempt. Initial error: \(initialError). Retry error: \(retryError)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
