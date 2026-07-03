import AVFoundation
import Foundation
import Speech

enum VoiceCommand: Equatable {
    case delete
    case stop
}

@MainActor
@Observable
final class SpeechRecognitionService {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    var isListening: Bool = false
    var lastRecognizedText: String = ""
    var lastExtractedDistance: Int?

    nonisolated(unsafe) static let minimumDistance = 1
    nonisolated(unsafe) static let maximumDistance = 1000
    nonisolated(unsafe) static var deleteCommands: Set<String> = ["delete", "error"]
    nonisolated(unsafe) static var stopCommands: Set<String> = ["stop", "done"]

    var continuousMode: Bool = false
    var onDistanceConfirmed: (@MainActor (Int) -> Void)?
    var onDeleteRequested: (@MainActor () -> Void)?
    var onStopRequested: (@MainActor () -> Void)?

    private var silenceTimerTask: Task<Void, Never>?
    private let synthesizer = AVSpeechSynthesizer()
    private var recognitionTaskStartedAt: Date?
    private var rapidTaskFailureCount = 0

    nonisolated init() {}

    nonisolated func extractDistance(from text: String) -> Int? {
        let lowercased = text.lowercased().trimmingCharacters(in: .whitespaces)

        // Use regex to find the first number in the string
        let pattern = #"\b(\d+)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(lowercased.startIndex..., in: lowercased)
        guard let match = regex.firstMatch(in: lowercased, options: [], range: range) else {
            return nil
        }

        guard let numberRange = Range(match.range(at: 1), in: lowercased) else {
            return nil
        }

        let numberString = String(lowercased[numberRange])
        guard let distance = Int(numberString) else {
            return nil
        }

        // Validate range
        guard distance >= Self.minimumDistance && distance <= Self.maximumDistance else {
            return nil
        }

        return distance
    }

    nonisolated func extractCommand(from text: String) -> VoiceCommand? {
        let trimmed = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if Self.deleteCommands.contains(trimmed) {
            return .delete
        }
        if Self.stopCommands.contains(trimmed) {
            return .stop
        }
        return nil
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func startListening() async throws {
        guard !isListening else { return }
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }

        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.requestCreationFailed
        }

        recognitionRequest.shouldReportPartialResults = true
        // On-device recognition has no 1-minute task limit and works without connectivity.
        if speechRecognizer.supportsOnDeviceRecognition {
            recognitionRequest.requiresOnDeviceRecognition = true
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isListening = true
        recognitionTaskStartedAt = Date()

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }

                if let result = result {
                    self.lastRecognizedText = result.bestTranscription.formattedString
                    self.lastExtractedDistance = self.extractDistance(from: self.lastRecognizedText)
                    self.rapidTaskFailureCount = 0

                    if self.continuousMode {
                        self.resetSilenceTimer()
                    }
                }

                if error != nil || result?.isFinal == true {
                    await self.handleRecognitionTaskEnded()
                }
            }
        }
    }

    func stopListening() {
        silenceTimerTask?.cancel()
        silenceTimerTask = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }

    func speakBack(_ text: String) async {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        synthesizer.speak(utterance)

        // Wait for speech to finish
        while synthesizer.isSpeaking {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    /// Recognition tasks die on their own (server-based recognition is capped at ~1 minute,
    /// and transient errors kill the task). In continuous mode the session must survive that:
    /// process any pending input, then start a fresh task.
    private func handleRecognitionTaskEnded() async {
        guard continuousMode else {
            stopListening()
            return
        }
        // isListening is false only when stopListening() already ran (deliberate stop or a
        // restart in flight) — the cancel-triggered callback must not restart again.
        guard isListening else { return }

        silenceTimerTask?.cancel()

        // A task that dies almost immediately after starting means recognition itself is
        // failing (no connectivity and no on-device model). Give up instead of spinning.
        if let startedAt = recognitionTaskStartedAt, Date().timeIntervalSince(startedAt) < 2 {
            rapidTaskFailureCount += 1
        } else {
            rapidTaskFailureCount = 0
        }
        guard rapidTaskFailureCount < 3 else {
            rapidTaskFailureCount = 0
            continuousMode = false
            stopListening()
            onStopRequested?()
            return
        }

        await handleSilenceTimeout()
    }

    private func resetSilenceTimer() {
        silenceTimerTask?.cancel()
        guard continuousMode else { return }

        silenceTimerTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await handleSilenceTimeout()
        }
    }

    private func handleSilenceTimeout() async {
        guard continuousMode, isListening else { return }

        // Check for command first
        if let command = extractCommand(from: lastRecognizedText) {
            switch command {
            case .delete:
                onDeleteRequested?()
                stopListening()
                await speakBack("Deleted")
                do {
                    try await startListening()
                } catch {
                    continuousMode = false
                    onStopRequested?()
                }
            case .stop:
                continuousMode = false
                stopListening()
                onStopRequested?()
            }
            lastRecognizedText = ""
            lastExtractedDistance = nil
            return
        }

        // Check for distance
        if let distance = lastExtractedDistance {
            onDistanceConfirmed?(distance)
            stopListening()
            await speakBack("\(distance). Next shot.")
            lastRecognizedText = ""
            lastExtractedDistance = nil
            do {
                try await startListening()
            } catch {
                continuousMode = false
                onStopRequested?()
            }
        } else {
            // No valid input detected, restart listening
            lastRecognizedText = ""
            stopListening()
            do {
                try await startListening()
            } catch {
                continuousMode = false
                onStopRequested?()
            }
        }
    }
}

enum SpeechRecognitionError: Error {
    case recognizerUnavailable
    case requestCreationFailed
    case audioSessionFailed
}
