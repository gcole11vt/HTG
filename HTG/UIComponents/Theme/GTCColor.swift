import SwiftUI
import UIKit

/// GTC-aligned palette (see `gtc_colors.py`). Use these instead of system colors or ad-hoc RGB.
/// Each core color resolves dynamically to its light or dark value based on the active interface style.
enum GTCColor {
    private static func components(_ hex: UInt32) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        (
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255
        )
    }

    /// Builds a color that adapts to light/dark mode from two sRGB hex values.
    private static func srgb(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traitCollection in
            let hex = traitCollection.userInterfaceStyle == .dark ? dark : light
            let c = components(hex)
            return UIColor(red: c.red, green: c.green, blue: c.blue, alpha: 1)
        })
    }

    // MARK: - Core palette

    static let primary = srgb(light: 0x29443A, dark: 0xA7C8B7) // forest green / soft sage
    static let secondary = srgb(light: 0x7E9286, dark: 0x8FA99A) // muted sage
    static let background = srgb(light: 0xF7F7F2, dark: 0x101713) // off-white / very dark forest
    static let surface = srgb(light: 0xFFFFFF, dark: 0x17211C) // pure white / raised dark green
    static let border = srgb(light: 0xCDD4CE, dark: 0x314239) // light grey-green / green-grey divider
    static let accent = srgb(light: 0x705C49, dark: 0xC4A484) // warm brown / warm tan
    static let text = srgb(light: 0x2C342F, dark: 0xE8EFEA) // near-black green / near-white green tint
    static let warning = srgb(light: 0x92400E, dark: 0xF59E0B) // amber-brown / amber

    /// Swipe/archive affordance (not in `gtc_colors.py` until synced).
    static let swipe = srgb(light: 0xC97B2F, dark: 0xD98C3A) // warm orange (archive / swipe tint)

    // MARK: - Test mode (from `gtc_colors.py`)

    static let testMode = srgb(light: 0x3B82F6, dark: 0x60A5FA) // bright blue
    static let testModeBackground = srgb(light: 0xEFF6FF, dark: 0x10243F) // very light / deep blue
    static let testModeBorder = srgb(light: 0x93C5FD, dark: 0x2563EB) // light / vivid blue
    static let testModeBadge = srgb(light: 0xDBEAFE, dark: 0x1E3A5F) // pale / dark blue

    // MARK: - Derived (ladder / routine; replaces scattered `.opacity` literals)

    static var ladderSelectionFill: Color { warning.opacity(0.1) }
    static var ladderSameClubMarker: Color { warning.opacity(0.5) }
    static var ladderDefaultMarker: Color { primary.opacity(0.6) }
    static var ladderDefaultText: Color { primary.opacity(0.8) }
    static var ladderSeparatorSlash: Color { primary.opacity(0.5) }
    static var ladderTickMinorFill: Color { primary.opacity(0.5) }
    /// Unselected ladder bar — dark enough to read on the page background.
    static var ladderBarDefault: Color { secondary.opacity(0.55) }

    static var routineSupportingText: Color { primary.opacity(0.7) }
    static var mantraSupportingText: Color { primary.opacity(0.8) }

    static var deltaPositiveBackground: Color { primary.opacity(0.2) }
    static var deltaNegativeBackground: Color { warning.opacity(0.2) }
    static var deltaPositiveText: Color { primary }
    static var deltaNegativeText: Color { warning }
    static var accentCardFill: Color { secondary.opacity(0.08) }
    static var mutedChipFill: Color { secondary.opacity(0.08) }
    static var listeningMicFill: Color { warning.opacity(0.12) }

    /// Subtle row highlight (replaces journal `paperDark`).
    static var rowHighlight: Color { border.opacity(0.35) }
}
