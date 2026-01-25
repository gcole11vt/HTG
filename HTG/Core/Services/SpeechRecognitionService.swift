import Foundation
import Speech

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
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.requestCreationFailed
        }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        isListening = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }

                if let result = result {
                    self.lastRecognizedText = result.bestTranscription.formattedString
                    self.lastExtractedDistance = self.extractDistance(from: self.lastRecognizedText)
                }

                if error != nil || result?.isFinal == true {
                    self.stopListening()
                }
            }
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }
}

enum SpeechRecognitionError: Error {
    case recognizerUnavailable
    case requestCreationFailed
    case audioSessionFailed
}
