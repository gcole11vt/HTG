import Testing
@testable import HTG

@Suite("YardageSpokenParser Tests")
struct YardageSpokenParserTests {
    private let parser = YardageSpokenParser()

    @Test("Parses digit transcripts", arguments: [
        ("150", 150), ("150 yards", 150), ("it's 165 yards out", 165), ("Yardage 95", 95)
    ])
    func digits(text: String, expected: Int) {
        #expect(parser.yardage(from: text) == expected)
    }

    @Test("Parses spoken words", arguments: [
        ("one fifty", 150), ("one hundred fifty", 150), ("a hundred and fifty yards", 150),
        ("two twenty five", 225), ("one eighty-five", 185), ("two hundred", 200),
        ("ninety five", 95), ("seventy", 70), ("one oh five", 105),
        ("one five zero", 150), ("one sixty", 160), ("three hundred twelve", 312)
    ])
    func words(text: String, expected: Int) {
        #expect(parser.yardage(from: text) == expected)
    }

    @Test("Rejects out-of-range or non-numeric", arguments: [
        "", "hello there", "ten", "forty", "five hundred", "1000", "20 yards", "one"
    ])
    func rejects(text: String) {
        #expect(parser.yardage(from: text) == nil)
    }
}
