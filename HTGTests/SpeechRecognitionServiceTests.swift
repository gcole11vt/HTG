import Testing
@testable import HTG

@Suite("SpeechRecognitionService Tests")
struct SpeechRecognitionServiceTests {

    @Test("Extract distance from yards format")
    func extractDistanceFromYardsFormat() {
        let service = SpeechRecognitionService()

        let result = service.extractDistance(from: "150 yards")

        #expect(result == 150)
    }

    @Test("Extract distance from yds format")
    func extractDistanceFromYdsFormat() {
        let service = SpeechRecognitionService()

        let result = service.extractDistance(from: "175 yds")

        #expect(result == 175)
    }

    @Test("Extract distance from number only")
    func extractDistanceFromNumberOnly() {
        let service = SpeechRecognitionService()

        let result = service.extractDistance(from: "200")

        #expect(result == 200)
    }

    @Test("Extract distance handles leading text")
    func extractDistanceHandlesLeadingText() {
        let service = SpeechRecognitionService()

        let result = service.extractDistance(from: "that was 165 yards")

        #expect(result == 165)
    }

    @Test("Extract distance handles trailing text")
    func extractDistanceHandlesTrailingText() {
        let service = SpeechRecognitionService()

        let result = service.extractDistance(from: "155 yards nice shot")

        #expect(result == 155)
    }

    @Test("Extract distance returns nil for non-numeric text")
    func extractDistanceReturnsNilForNonNumeric() {
        let service = SpeechRecognitionService()

        let result = service.extractDistance(from: "hello world")

        #expect(result == nil)
    }

    @Test("Extract distance validates minimum of 1 yard")
    func extractDistanceValidatesMinimum() {
        let service = SpeechRecognitionService()

        let result = service.extractDistance(from: "0 yards")

        #expect(result == nil)
    }

    @Test("Extract distance validates maximum of 1000 yards")
    func extractDistanceValidatesMaximum() {
        let service = SpeechRecognitionService()

        let result = service.extractDistance(from: "1001 yards")

        #expect(result == nil)
    }

    @Test("Extract distance accepts boundary value 1")
    func extractDistanceAcceptsMinBoundary() {
        let service = SpeechRecognitionService()

        let result = service.extractDistance(from: "1 yard")

        #expect(result == 1)
    }

    @Test("Extract distance accepts boundary value 1000")
    func extractDistanceAcceptsMaxBoundary() {
        let service = SpeechRecognitionService()

        let result = service.extractDistance(from: "1000 yards")

        #expect(result == 1000)
    }

    @Test("Extract distance handles case insensitivity")
    func extractDistanceHandlesCaseInsensitivity() {
        let service = SpeechRecognitionService()

        let result = service.extractDistance(from: "180 YARDS")

        #expect(result == 180)
    }

    @Test("Extract distance extracts first number in string")
    func extractDistanceExtractsFirstNumber() {
        let service = SpeechRecognitionService()

        let result = service.extractDistance(from: "shot 150 yards past the 100 marker")

        #expect(result == 150)
    }

    @Test("Extract distance handles word numbers")
    func extractDistanceHandlesWordOneHundred() {
        let service = SpeechRecognitionService()

        // Word numbers like "one fifty" are complex - service handles digits only
        let result = service.extractDistance(from: "one hundred fifty yards")

        #expect(result == nil) // Service focuses on digit parsing
    }

    @Test("Extract distance returns nil for empty string")
    func extractDistanceReturnsNilForEmpty() {
        let service = SpeechRecognitionService()

        let result = service.extractDistance(from: "")

        #expect(result == nil)
    }

    @Test("Extract distance handles whitespace")
    func extractDistanceHandlesWhitespace() {
        let service = SpeechRecognitionService()

        let result = service.extractDistance(from: "   160   yards   ")

        #expect(result == 160)
    }

    @Test("Extract distance ignores negative sign and extracts number")
    func extractDistanceHandlesNegative() {
        let service = SpeechRecognitionService()

        // Regex extracts "50" from "-50", which is valid
        let result = service.extractDistance(from: "-50 yards")

        #expect(result == 50)
    }
}
