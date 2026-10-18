import Foundation

/// Abstraction over live speech recognition so the yardage mic logic is testable.
@MainActor
protocol YardageVoiceListening: AnyObject {
    func requestAuthorization() async -> Bool
    /// Begins capture; `onTranscript` receives each (partial or final) transcript.
    func startListening(onTranscript: @escaping @MainActor (String) -> Void) async throws
    func stopListening()
}

/// Adapter reusing Range Mode's `SpeechRecognitionService` for Golf Mode yardage entry.
@MainActor
final class SpeechRecognitionYardageListener: YardageVoiceListening {
    private let service = SpeechRecognitionService()

    func requestAuthorization() async -> Bool {
        await service.requestAuthorization()
    }

    func startListening(onTranscript: @escaping @MainActor (String) -> Void) async throws {
        service.onTranscriptUpdate = onTranscript
        do {
            try await service.startListening()
        } catch {
            service.onTranscriptUpdate = nil
            throw error
        }
    }

    func stopListening() {
        service.onTranscriptUpdate = nil
        service.stopListening()
    }
}
