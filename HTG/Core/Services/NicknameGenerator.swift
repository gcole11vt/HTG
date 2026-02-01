import Foundation

enum NicknameGenerator {
    static func generate(from name: String) -> String {
        guard !name.isEmpty else { return "" }

        let firstChar = name.first!

        // Rule 1: If name starts with a digit
        if firstChar.isNumber {
            let rest = name.dropFirst()
            if let nextAlphanumeric = rest.first(where: { $0.isLetter || $0.isNumber }) {
                return "\(firstChar)\(nextAlphanumeric.uppercased())"
            }
            return String(firstChar)
        }

        // Rule 2: If name contains a space → first letter of first two words
        let words = name.split(separator: " ")
        if words.count >= 2 {
            let first = words[0].first!
            let second = words[1].first!
            return "\(first.uppercased())\(second.uppercased())"
        }

        // Rule 3: Fallback → first two alphanumeric characters
        let alphanumerics = name.filter { $0.isLetter || $0.isNumber }
        if alphanumerics.count >= 2 {
            let firstTwo = alphanumerics.prefix(2)
            return "\(firstTwo.first!.uppercased())\(firstTwo.dropFirst().first!.lowercased())"
        }

        return String(alphanumerics.prefix(1)).uppercased()
    }
}
