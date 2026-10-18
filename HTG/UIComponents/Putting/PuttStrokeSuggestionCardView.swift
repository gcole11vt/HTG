import SwiftUI

/// Suggested backswing position for the current putt distance.
struct PuttStrokeSuggestionCardView: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(JournalTheme.clubNameFont)
                .foregroundStyle(GTCColor.primary)
            Text(detail)
                .font(JournalTheme.shotTypeFont)
                .foregroundStyle(GTCColor.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtcTintedAccentCard()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PuttStrokeSuggestionCardView(title: "Position 2½", detail: "Between 2 (8 ft) and 3 (14 ft)")
        .padding()
}
