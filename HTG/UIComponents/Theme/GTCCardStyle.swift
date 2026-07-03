import SwiftUI

/// Shared visual shells derived from Golf Mode, the canonical style reference
/// (`docs/wireframes/GolfModeWireFrame.md`). All feature pages consume these
/// instead of composing card/eyebrow/chip styling inline.

/// Uppercased section header shown above every content block.
struct GTCSectionEyebrow: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(JournalTheme.sectionEyebrowFont)
            .foregroundStyle(GTCColor.secondary)
            .textCase(.uppercase)
    }
}

/// Small metadata chip (shot type, tags) per the Golf recommendation card.
struct GTCMetaChip: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(JournalTheme.chipLabelFont)
            .foregroundStyle(GTCColor.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(GTCColor.mutedChipFill)
            )
    }
}

extension View {
    /// Base card shell: tokenized padding, corner radius, fill, and stroke.
    func gtcCard(fill: Color, stroke: Color, lineWidth: CGFloat) -> some View {
        padding(.horizontal, JournalTheme.cardHorizontalPadding)
            .padding(.vertical, JournalTheme.cardVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: JournalTheme.cardCornerRadius)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: JournalTheme.cardCornerRadius)
                            .stroke(stroke, lineWidth: lineWidth)
                    )
            )
    }

    /// Neutral content card: hairline border.
    func gtcNeutralCard(fill: Color = GTCColor.surface) -> some View {
        gtcCard(fill: fill, stroke: GTCColor.border, lineWidth: 1)
    }

    /// Emphasized card: primary stroke.
    func gtcAccentCard(fill: Color = GTCColor.surface, lineWidth: CGFloat = 1.5) -> some View {
        gtcCard(fill: fill, stroke: GTCColor.primary, lineWidth: lineWidth)
    }

    /// Tinted emphasized card for form/picker sections.
    func gtcTintedAccentCard() -> some View {
        gtcCard(fill: GTCColor.accentCardFill, stroke: GTCColor.primary, lineWidth: 1.5)
    }

    /// Primary action button treatment shared across features.
    func gtcProminentActionButtonStyle() -> some View {
        buttonStyle(.borderedProminent)
            .tint(GTCColor.primary)
    }
}
