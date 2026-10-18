import Foundation

/// UI state for the yardage microphone button: listen, parse, deliver one valid yardage.
@MainActor
@Observable
final class YardageVoiceEntryViewModel {
    enum State: Equatable {
        case idle
        case starting
        case listening
    }

    private(set) var state: State = .idle
    private(set) var statusText: String?

    private let listener: YardageVoiceListening
    private let parser: YardageSpokenParser
    private let commitDelay: Duration
    private let listeningTimeout: Duration
    private let onYardageHeard: (Int) -> Void
    private var cancelRequested = false
    private var commitTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?

    init(
        listener: YardageVoiceListening,
        parser: YardageSpokenParser = YardageSpokenParser(),
        commitDelay: Duration = .milliseconds(900),
        listeningTimeout: Duration = .seconds(8),
        onYardageHeard: @escaping (Int) -> Void
    ) {
        self.listener = listener
        self.parser = parser
        self.commitDelay = commitDelay
        self.listeningTimeout = listeningTimeout
        self.onYardageHeard = onYardageHeard
    }

    var isActive: Bool { state != .idle }

    func toggleListening() async {
        switch state {
        case .starting:
            cancelRequested = true
        case .listening:
            finish(status: nil)
        case .idle:
            await begin()
        }
    }

    /// Stops any capture or in-flight start (tab change, backgrounding).
    func cancel() {
        switch state {
        case .starting: cancelRequested = true
        case .listening: finish(status: nil)
        case .idle: break
        }
    }

    private func begin() async {
        cancelRequested = false
        statusText = nil
        state = .starting
        guard await listener.requestAuthorization() else {
            finish(status: "Allow microphone and speech access in Settings")
            return
        }
        guard !cancelRequested else { finish(status: nil); return }
        do {
            try await listener.startListening { [weak self] transcript in
                self?.received(transcript)
            }
        } catch {
            finish(status: "Couldn't start listening")
            return
        }
        guard !cancelRequested else { finish(status: nil); return }
        state = .listening
        statusText = "Listening\u{2026}"
        startTimeout()
    }

    private func received(_ transcript: String) {
        guard state == .listening else { return }
        commitTask?.cancel()
        guard let yardage = parser.yardage(from: transcript) else { return }
        commitTask = Task { [weak self, commitDelay] in
            try? await Task.sleep(for: commitDelay)
            guard !Task.isCancelled, let self, self.state == .listening else { return }
            self.onYardageHeard(yardage)
            self.finish(status: nil)
        }
    }

    private func startTimeout() {
        timeoutTask = Task { [weak self, listeningTimeout] in
            try? await Task.sleep(for: listeningTimeout)
            guard !Task.isCancelled, let self, self.state == .listening else { return }
            self.finish(status: "Didn't catch a yardage")
        }
    }

    private func finish(status: String?) {
        commitTask?.cancel()
        timeoutTask?.cancel()
        commitTask = nil
        timeoutTask = nil
        listener.stopListening()
        cancelRequested = false
        state = .idle
        statusText = status
    }
}
