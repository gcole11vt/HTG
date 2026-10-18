import Testing
@testable import HTG

@Suite("YardageEntryValidationService Tests")
struct YardageEntryValidationServiceTests {
    private let service = YardageEntryValidationService()

    @Test func validRangeIsFiftyToFourHundred() {
        #expect(YardageEntryValidationService.validRange == 50...400)
    }

    @Test func sanitizedEntryKeepsDigits() {
        #expect(service.sanitizedEntryText("152") == "152")
    }

    @Test func sanitizedEntryStripsNonDigits() {
        #expect(service.sanitizedEntryText("1a5") == "15")
        #expect(service.sanitizedEntryText(" 15 ") == "15")
        #expect(service.sanitizedEntryText("-150") == "150")
        #expect(service.sanitizedEntryText("1,5") == "15")
    }

    @Test func sanitizedEntryTruncatesToThreeDigits() {
        #expect(service.sanitizedEntryText("1520") == "152")
    }

    @Test func sanitizedEntryOfEmptyIsEmpty() {
        #expect(service.sanitizedEntryText("") == "")
    }

    @Test func validatedYardageAcceptsInRangeValue() {
        #expect(service.validatedYardage(from: "152") == 152)
    }

    @Test func validatedYardageAcceptsBoundaries() {
        #expect(service.validatedYardage(from: "50") == 50)
        #expect(service.validatedYardage(from: "400") == 400)
    }

    @Test func validatedYardageRejectsBelowMinimum() {
        #expect(service.validatedYardage(from: "49") == nil)
        #expect(service.validatedYardage(from: "0") == nil)
        #expect(service.validatedYardage(from: "5") == nil)
    }

    @Test func validatedYardageRejectsAboveMaximum() {
        #expect(service.validatedYardage(from: "401") == nil)
        #expect(service.validatedYardage(from: "999") == nil)
    }

    @Test func validatedYardageRejectsEmptyAndNonNumeric() {
        #expect(service.validatedYardage(from: "") == nil)
        #expect(service.validatedYardage(from: "abc") == nil)
    }

    @Test func validatedYardageAcceptsLeadingZero() {
        #expect(service.validatedYardage(from: "075") == 75)
    }

    @Test func isDefinitelyOutOfRangeFlagsThreeDigitOverflow() {
        #expect(service.isDefinitelyOutOfRange("401"))
        #expect(!service.isDefinitelyOutOfRange("152"))
    }

    @Test func isDefinitelyOutOfRangeAllowsPartialEntry() {
        #expect(!service.isDefinitelyOutOfRange("1"))
        #expect(!service.isDefinitelyOutOfRange("15"))
        #expect(!service.isDefinitelyOutOfRange(""))
    }

    @Test func customRangeIsRespected() {
        let putting = YardageEntryValidationService(validRange: 1...99)
        #expect(putting.validatedYardage(from: "12") == 12)
        #expect(putting.validatedYardage(from: "100") == nil)
    }
}
