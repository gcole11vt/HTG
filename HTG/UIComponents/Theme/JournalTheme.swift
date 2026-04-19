import SwiftUI

enum JournalTheme {
    // MARK: - Fonts

    static func handwritten(size: CGFloat) -> Font {
        .system(size: size)
    }

    static func handwrittenBold(size: CGFloat) -> Font {
        .system(size: size, weight: .bold)
    }

    static func blockFont(size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .serif)
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
}
