import Testing
@testable import HTG

@MainActor
private final class FakeYardageVoiceListener: YardageVoiceListening {
    var authorized = true
    var startError: Error?
    var holdStart = false
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private var transcriptHandler: (@MainActor (String) -> Void)?
    private var startContinuation: CheckedContinuation<Void, Never>?

    func requestAuthorization() async -> Bool { authorized }

    func startListening(onTranscript: @escaping @MainActor (String) -> Void) async throws {
        startCount += 1
        transcriptHandler = onTranscript
        if holdStart { await withCheckedContinuation { startContinuation = $0 } }
        if let startError { throw startError }
    }

    func stopListening() { stopCount += 1 }
    func releaseStart() { startContinuation?.resume(); startContinuation = nil }
    func say(_ text: String) { transcriptHandler?(text) }
}

@MainActor
@Suite("YardageVoiceEntryViewModel Tests")
struct YardageVoiceEntryViewModelTests {
    private final class Heard { var values: [Int] = [] }

    private func makeSUT(_ listener: FakeYardageVoiceListener, heard: Heard) -> YardageVoiceEntryViewModel {
        YardageVoiceEntryViewModel(
            listener: listener,
            commitDelay: .milliseconds(5),
            listeningTimeout: .milliseconds(200)
        ) { heard.values.append($0) }
    }

    private func settle() async { try? await Task.sleep(for: .milliseconds(60)) }

    @Test("Tap starts listening")
    func tapStarts() async {
        let listener = FakeYardageVoiceListener()
        let sut = makeSUT(listener, heard: Heard())
        await sut.toggleListening()
        #expect(sut.state == .listening)
        #expect(listener.startCount == 1)
    }

    @Test("Valid spoken yardage is delivered and listening stops")
    func validYardage() async {
        let listener = FakeYardageVoiceListener()
        let heard = Heard()
        let sut = makeSUT(listener, heard: heard)
        await sut.toggleListening()
        listener.say("one fifty")
        await settle()
        #expect(heard.values == [150])
        #expect(sut.state == .idle)
        #expect(listener.stopCount == 1)
    }

    @Test("Later partial result replaces an earlier one before commit")
    func partialsDebounced() async {
        let listener = FakeYardageVoiceListener()
        let heard = Heard()
        let sut = makeSUT(listener, heard: heard)
        await sut.toggleListening()
        listener.say("one fifty")
        listener.say("one fifty five")
        await settle()
        #expect(heard.values == [155])
    }

    @Test("Out-of-range speech is not delivered")
    func outOfRange() async {
        let listener = FakeYardageVoiceListener()
        let heard = Heard()
        let sut = makeSUT(listener, heard: heard)
        await sut.toggleListening()
        listener.say("20 yards")
        await settle()
        #expect(heard.values.isEmpty)
        #expect(sut.state == .listening)
    }

    @Test("Tapping while listening stops")
    func tapStops() async {
        let listener = FakeYardageVoiceListener()
        let sut = makeSUT(listener, heard: Heard())
        await sut.toggleListening()
        await sut.toggleListening()
        #expect(sut.state == .idle)
        #expect(listener.stopCount == 1)
    }

    @Test("Denied permission reports status and does not start")
    func denied() async {
        let listener = FakeYardageVoiceListener()
        listener.authorized = false
        let sut = makeSUT(listener, heard: Heard())
        await sut.toggleListening()
        #expect(sut.state == .idle)
        #expect(listener.startCount == 0)
        #expect(sut.statusText != nil)
    }

    @Test("Start failure returns to idle with status")
    func startFailure() async {
        let listener = FakeYardageVoiceListener()
        listener.startError = SpeechRecognitionError.recognizerUnavailable
        let sut = makeSUT(listener, heard: Heard())
        await sut.toggleListening()
        #expect(sut.state == .idle)
        #expect(sut.statusText != nil)
    }

    @Test("Second tap during start does not start twice and cancels")
    func cancelDuringStart() async {
        let listener = FakeYardageVoiceListener()
        listener.holdStart = true
        let sut = makeSUT(listener, heard: Heard())
        let first = Task { await sut.toggleListening() }
        while listener.startCount == 0 { await Task.yield() }
        await sut.toggleListening()
        listener.releaseStart()
        await first.value
        #expect(listener.startCount == 1)
        #expect(sut.state == .idle)
        #expect(listener.stopCount >= 1)
    }

    @Test("cancel() during start ends idle")
    func externalCancelDuringStart() async {
        let listener = FakeYardageVoiceListener()
        listener.holdStart = true
        let sut = makeSUT(listener, heard: Heard())
        let first = Task { await sut.toggleListening() }
        while listener.startCount == 0 { await Task.yield() }
        sut.cancel()
        listener.releaseStart()
        await first.value
        #expect(sut.state == .idle)
    }

    @Test("Silence times out to idle")
    func timeout() async {
        let listener = FakeYardageVoiceListener()
        let sut = makeSUT(listener, heard: Heard())
        await sut.toggleListening()
        try? await Task.sleep(for: .milliseconds(350))
        #expect(sut.state == .idle)
        #expect(listener.stopCount == 1)
    }
}
