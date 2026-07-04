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
    // nonisolated(unsafe): the engine and request are touched from a background task during
    // startup and from the audio tap thread; AVAudioEngine serializes its own internal state.
    nonisolated(unsafe) private let audioEngine = AVAudioEngine()
    nonisolated(unsafe) private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isStartingEngine = false
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
    private let synthesizerCompletionDelegate = SpeechSynthesizerCompletionDelegate()
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

    // Nonisolated so permission requests run off the main thread: TCC calls can block,
    // and a slow/wedged one must not freeze the UI.
    nonisolated func requestAuthorization() async -> Bool {
        guard await requestSpeechAuthorization() else { return false }
        return await requestRecordPermission()
    }

    private nonisolated func requestSpeechAuthorization() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        default:
            return false
        }
    }

    private nonisolated func requestRecordPermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return true
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }

    func startListening() async throws {
        guard !isListening, !isStartingEngine else { return }
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }

        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // On-device recognition has no 1-minute task limit and works without connectivity.
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        // Session activation and engine startup are blocking calls into the media daemons
        // and must stay off the main thread — a stalled daemon would freeze the whole UI.
        isStartingEngine = true
        defer { isStartingEngine = false }
        do {
            try await Task.detached { [self] in
                try startAudioEngineBlockingWork()
            }.value
        } catch {
            recognitionRequest = nil
            throw error
        }

        isListening = true
        recognitionTaskStartedAt = Date()

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
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

    private nonisolated func startAudioEngineBlockingWork() throws {
        let audioSession = AVAudioSession.sharedInstance()
        // .measurement mode strips signal processing and makes TTS output very quiet, and
        // playAndRecord ignores Bluetooth devices unless explicitly allowed — both matter here.
        try audioSession.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP]
        )
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Without record permission the input node reports a 0 Hz / 0-channel format,
        // and installTap raises an uncatchable ObjC exception. Bail out instead.
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            throw SpeechRecognitionError.audioSessionFailed
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
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
        // Delegate is set lazily because init() is nonisolated.
        if synthesizer.delegate !== synthesizerCompletionDelegate {
            synthesizer.delegate = synthesizerCompletionDelegate
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        // speak() only queues the utterance; isSpeaking stays false until playback actually
        // starts, so polling it here returns immediately and the engine restart cuts the
        // utterance off. Wait for the didFinish delegate callback instead.
        synthesizer.speak(utterance)
        await synthesizerCompletionDelegate.waitUntilDone()
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

/// Bridges AVSpeechSynthesizer's delegate callbacks to async/await so callers can
/// await the end of an utterance. A timeout backstop resumes the waiter even if the
/// synthesizer never delivers a callback, so the listening loop can't stall.
@MainActor
private final class SpeechSynthesizerCompletionDelegate: NSObject, AVSpeechSynthesizerDelegate {
    private var continuation: CheckedContinuation<Void, Never>?

    nonisolated override init() {
        super.init()
    }

    func waitUntilDone(timeout: Duration = .seconds(10)) async {
        let timeoutTask = Task { @MainActor in
            try? await Task.sleep(for: timeout)
            finish()
        }
        await withCheckedContinuation { continuation = $0 }
        timeoutTask.cancel()
    }

    private func finish() {
        continuation?.resume()
        continuation = nil
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.finish() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.finish() }
    }
}

enum SpeechRecognitionError: Error {
    case recognizerUnavailable
    case requestCreationFailed
    case audioSessionFailed
}
