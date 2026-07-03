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

    // MARK: - Cross-feature list/detail tokens

    static var listRowPrimaryFont: Font {
        .system(size: 17, weight: .semibold)
    }

    static var listRowSecondaryFont: Font {
        .system(size: 17, weight: .regular)
    }

    static var inlineBadgeFont: Font {
        .system(size: 12, weight: .semibold)
    }

    static var inlineHelperLabelFont: Font {
        .system(size: 14, weight: .regular)
    }

    /// Canonical eyebrow style from Golf Mode (12 semibold, uppercased via `GTCSectionEyebrow`).
    static var sectionEyebrowFont: Font {
        .system(size: 12, weight: .semibold)
    }

    static var pageTitleFont: Font {
        .system(size: 26, weight: .semibold, design: .serif)
    }

    static var cardTitleFont: Font {
        .system(size: 28, weight: .semibold, design: .serif)
    }

    static var sheetTitleFont: Font {
        .system(size: 24, weight: .semibold, design: .serif)
    }

    /// Small metadata chips (shot type tags) per the Golf recommendation card.
    static var chipLabelFont: Font {
        .system(size: 11, weight: .medium)
    }

    /// Label above a metric value (stats tiles).
    static var metricLabelFont: Font {
        .system(size: 11, weight: .medium)
    }

    // MARK: - Cross-feature layout tokens

    static let compactNumericInputWidth: CGFloat = 80
    static let distanceInputWidth: CGFloat = 110
    static let sheetNumericInputWidth: CGFloat = 160
    static let sheetDetentHeight: CGFloat = 320
    static let statsColumnWidthRatio: CGFloat = 0.33
    static let inlineBadgeHorizontalPadding: CGFloat = 6
    static let inlineBadgeVerticalPadding: CGFloat = 2
    static let screenHorizontalPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 14
    static let subsectionSpacing: CGFloat = 8
    static let cardCornerRadius: CGFloat = 14
    static let cardHorizontalPadding: CGFloat = 12
    static let cardVerticalPadding: CGFloat = 10
}
