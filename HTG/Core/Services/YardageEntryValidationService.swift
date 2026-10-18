import Foundation

/// Validates the digits typed into the Golf Mode yardage field. Pure logic.
struct YardageEntryValidationService: Sendable {
    static let validRange: ClosedRange<Int> = 50...400
    let validRange: ClosedRange<Int>

    /// Digits in the range's upper bound (3 for yards, 2 for putt feet).
    var maximumDigitCount: Int { String(validRange.upperBound).count }

    init(validRange: ClosedRange<Int> = YardageEntryValidationService.validRange) {
        self.validRange = validRange
    }

    /// Strips non-digits and truncates to `maximumDigitCount`.
    func sanitizedEntryText(_ rawText: String) -> String {
        String(rawText.filter { $0.isASCII && $0.isNumber }.prefix(maximumDigitCount))
    }

    /// The submitted yardage, or nil when empty, non-numeric, or out of range.
    func validatedYardage(from entryText: String) -> Int? {
        guard let value = Int(entryText), validRange.contains(value) else { return nil }
        return value
    }

    /// True once a full-length entry is still invalid, which drives the warning caption.
    func isDefinitelyOutOfRange(_ entryText: String) -> Bool {
        entryText.count == maximumDigitCount && validatedYardage(from: entryText) == nil
    }
}
