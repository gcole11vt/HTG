import Testing
@testable import HTG

@Suite("DistanceViewStyle Tests")
struct DistanceViewStyleTests {

    @Test("Default view style is Text")
    func defaultStyleIsText() {
        #expect(DistanceViewStyle.defaultStyle == .text)
    }

    @Test("Cases are ordered Ladder then Text with display titles")
    func casesAndTitles() {
        #expect(DistanceViewStyle.allCases == [.ladder, .text])
        #expect(DistanceViewStyle.ladder.title == "Ladder")
        #expect(DistanceViewStyle.text.title == "Text")
    }

    @Test("Raw values are stable persisted identifiers")
    func rawValuesAreStable() {
        #expect(DistanceViewStyle.ladder.rawValue == "ladder")
        #expect(DistanceViewStyle.text.rawValue == "text")
    }

    @Test("Unknown stored value resolves to the default")
    func unknownValueResolvesToDefault() {
        #expect(DistanceViewStyle.resolved(from: "grid") == .text)
        #expect(DistanceViewStyle.resolved(from: "ladder") == .ladder)
    }
}
