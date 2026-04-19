import SwiftUI

/// GTC-aligned palette (see `gtc_colors.py`). Use these instead of system colors or ad-hoc RGB.
enum GTCColor {
    private static func srgb(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    // MARK: - Core palette

    static let primary = srgb(0x29443A)
    static let secondary = srgb(0x7E9286)
    static let background = srgb(0xF7F7F2)
    static let surface = srgb(0xFFFFFF)
    static let border = srgb(0xCDD4CE)
    static let accent = srgb(0x705C49)
    static let text = srgb(0x2C342F)
    static let warning = srgb(0x92400E)

    /// Swipe/archive affordance (not in `gtc_colors.py` until synced).
    static let swipe = srgb(0xC97B2F)

    // MARK: - Test mode (from `gtc_colors.py`)

    static let testMode = srgb(0x3B82F6)
    static let testModeBackground = srgb(0xEFF6FF)
    static let testModeBorder = srgb(0x93C5FD)
    static let testModeBadge = srgb(0xDBEAFE)

    // MARK: - Derived (ladder / routine; replaces scattered `.opacity` literals)

    static var ladderSelectionFill: Color { warning.opacity(0.1) }
    static var ladderSameClubMarker: Color { warning.opacity(0.5) }
    static var ladderDefaultMarker: Color { primary.opacity(0.6) }
    static var ladderDefaultText: Color { primary.opacity(0.8) }
    static var ladderSeparatorSlash: Color { primary.opacity(0.5) }
    static var ladderTickMinorFill: Color { primary.opacity(0.5) }

    static var routineSupportingText: Color { primary.opacity(0.7) }
    static var mantraSupportingText: Color { primary.opacity(0.8) }

    static var deltaPositiveBackground: Color { primary.opacity(0.2) }
    static var deltaNegativeBackground: Color { warning.opacity(0.2) }

    /// Subtle row highlight (replaces journal `paperDark`).
    static var rowHighlight: Color { border.opacity(0.35) }
}
