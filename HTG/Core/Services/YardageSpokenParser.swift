import Foundation

/// Turns a speech transcript ("one fifty", "165 yards") into a valid yardage. Pure logic.
struct YardageSpokenParser: Sendable {
    private let validator: YardageEntryValidationService

    init(validator: YardageEntryValidationService = YardageEntryValidationService()) {
        self.validator = validator
    }

    /// The spoken yardage, or nil when none is found or it falls outside the valid range.
    func yardage(from transcript: String) -> Int? {
        let lowercased = transcript.lowercased()
        if let digits = firstDigitRun(in: lowercased) {
            return validator.validatedYardage(from: digits)
        }
        guard let value = valueFromNumberWords(in: lowercased) else { return nil }
        return validator.validatedYardage(from: String(value))
    }

    private func firstDigitRun(in text: String) -> String? {
        var run = ""
        for character in text {
            if character.isASCII && character.isNumber {
                run.append(character)
            } else if !run.isEmpty {
                break
            }
        }
        return run.isEmpty ? nil : run
    }

    private static let units: [String: Int] = [
        "zero": 0, "oh": 0, "o": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9
    ]
    private static let teens: [String: Int] = [
        "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
        "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19
    ]
    private static let tens: [String: Int] = [
        "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60,
        "seventy": 70, "eighty": 80, "ninety": 90
    ]

    private func valueFromNumberWords(in text: String) -> Int? {
        let words = text
            .split(whereSeparator: { !$0.isLetter })
            .map(String.init)
        // Keep the first contiguous run of number words ("and"/"a" may sit inside it).
        var run: [String] = []
        for word in words {
            if isNumberWord(word) {
                run.append(word)
            } else if (word == "and" || word == "a") && !run.isEmpty {
                continue
            } else if word == "a" {
                run.append("one")
            } else if !run.isEmpty {
                break
            }
        }
        return value(of: run)
    }

    private func isNumberWord(_ word: String) -> Bool {
        word == "hundred" || Self.units[word] != nil || Self.teens[word] != nil || Self.tens[word] != nil
    }

    private func value(of run: [String]) -> Int? {
        guard !run.isEmpty else { return nil }
        if let hundredIndex = run.firstIndex(of: "hundred") {
            let hundreds = hundredIndex == 0 ? 1 : value(of: Array(run[..<hundredIndex]))
            let remainder = hundredIndex + 1 < run.count ? value(of: Array(run[(hundredIndex + 1)...])) : 0
            guard let hundreds, let remainder, (1...9).contains(hundreds), remainder < 100 else { return nil }
            return hundreds * 100 + remainder
        }
        // "one fifty", "two twenty five", "one oh five": a leading digit followed by a 2-digit part.
        if run.count > 1, let lead = Self.units[run[0]], lead > 0,
           let rest = twoDigitValue(of: Array(run[1...])) {
            return lead * 100 + rest
        }
        if let value = twoDigitValue(of: run) { return value }
        // Digit-by-digit: "one five zero".
        let digits = run.compactMap { Self.units[$0] }
        guard digits.count == run.count else { return nil }
        return Int(digits.map(String.init).joined())
    }

    private func twoDigitValue(of run: [String]) -> Int? {
        switch run.count {
        case 1:
            return Self.teens[run[0]] ?? Self.tens[run[0]]
        case 2:
            if let tens = Self.tens[run[0]], let unit = Self.units[run[1]], unit > 0 { return tens + unit }
            if run[0] == "oh" || run[0] == "o" || run[0] == "zero",
               let unit = Self.units[run[1]], unit > 0 { return unit }
            return nil
        default:
            return nil
        }
    }
}
