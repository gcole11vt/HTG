import Testing
@testable import HTG

@Suite("NicknameGenerator Tests")
struct NicknameGeneratorTests {

    // MARK: - Number-first names

    @Test("7 Iron generates 7I")
    func sevenIron() {
        #expect(NicknameGenerator.generate(from: "7 Iron") == "7I")
    }

    @Test("3 Wood generates 3W")
    func threeWood() {
        #expect(NicknameGenerator.generate(from: "3 Wood") == "3W")
    }

    @Test("4 Hybrid generates 4H")
    func fourHybrid() {
        #expect(NicknameGenerator.generate(from: "4 Hybrid") == "4H")
    }

    @Test("5 Iron generates 5I")
    func fiveIron() {
        #expect(NicknameGenerator.generate(from: "5 Iron") == "5I")
    }

    // MARK: - Space-based names

    @Test("Pitching Wedge generates PW")
    func pitchingWedge() {
        #expect(NicknameGenerator.generate(from: "Pitching Wedge") == "PW")
    }

    @Test("Sand Wedge generates SW")
    func sandWedge() {
        #expect(NicknameGenerator.generate(from: "Sand Wedge") == "SW")
    }

    @Test("Lob Wedge generates LW")
    func lobWedge() {
        #expect(NicknameGenerator.generate(from: "Lob Wedge") == "LW")
    }

    @Test("Gap Wedge generates GW")
    func gapWedge() {
        #expect(NicknameGenerator.generate(from: "Gap Wedge") == "GW")
    }

    // MARK: - Fallback (no space, non-digit start)

    @Test("Driver generates Dr")
    func driver() {
        #expect(NicknameGenerator.generate(from: "Driver") == "Dr")
    }

    // MARK: - Edge cases

    @Test("Single character input returns that character")
    func singleCharacter() {
        #expect(NicknameGenerator.generate(from: "D") == "D")
    }

    @Test("Empty string returns empty string")
    func emptyString() {
        #expect(NicknameGenerator.generate(from: "") == "")
    }
}
