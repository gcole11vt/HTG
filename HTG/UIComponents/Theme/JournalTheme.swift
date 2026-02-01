import SwiftUI

enum JournalTheme {
    // MARK: - Colors

    static let leatherBrown = Color(red: 0.36, green: 0.25, blue: 0.22)
    static let leatherDark = Color(red: 0.26, green: 0.18, blue: 0.15)
    static let agedPaper = Color(red: 0.95, green: 0.92, blue: 0.87)
    static let paperDark = Color(red: 0.88, green: 0.85, blue: 0.80)
    static let paperFiber = Color(red: 0.90, green: 0.87, blue: 0.82)
    static let inkBlue = Color(red: 0.17, green: 0.24, blue: 0.31)
    static let redMarker = Color(red: 0.75, green: 0.22, blue: 0.17)
    static let mutedGray = Color(red: 0.58, green: 0.65, blue: 0.65)
    static let goldEmboss = Color(red: 0.83, green: 0.68, blue: 0.38)

    // MARK: - Fonts (Chalkboard SE - System Font)

    static func handwritten(size: CGFloat) -> Font {
        Font.custom("ChalkboardSE-Regular", size: size)
    }

    static func handwrittenBold(size: CGFloat) -> Font {
        Font.custom("ChalkboardSE-Bold", size: size)
    }

    static func blockFont(size: CGFloat) -> Font {
        Font.system(size: size, weight: .black, design: .serif)
    }

    // MARK: - Common Text Styles

    static var titleFont: Font {
        blockFont(size: 28)
    }

    static var yardageFont: Font {
        handwrittenBold(size: 72)
    }

    static var clubNameFont: Font {
        handwrittenBold(size: 24)
    }

    static var shotTypeFont: Font {
        handwritten(size: 18)
    }

    static var ladderFont: Font {
        handwritten(size: 14)
    }

    // MARK: - Animation Durations

    static let coverDisplayDuration: Double = 0.5
    static let pageTurnDuration: Double = 1.0
    static let contentFadeDuration: Double = 0.3
}
