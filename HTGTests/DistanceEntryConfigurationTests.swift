import Testing
@testable import HTG

@Suite("DistanceEntryConfiguration Tests")
struct DistanceEntryConfigurationTests {
    @Test("Golf yards uses the yardage range")
    func golfYardsConfiguration() {
        let configuration = DistanceEntryConfiguration.golfYards
        #expect(configuration.validRange == YardageEntryValidationService.validRange)
        #expect(configuration.rangeHint == "50\u{2013}400 yards")
    }

    @Test("Putt feet is 1 to 99 feet")
    func puttFeetConfiguration() {
        let configuration = DistanceEntryConfiguration.puttFeet
        #expect(configuration.validRange == 1...99)
        #expect(configuration.rangeHint == "1\u{2013}99 feet")
    }
}
