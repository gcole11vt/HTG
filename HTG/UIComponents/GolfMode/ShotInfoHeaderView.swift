import SwiftUI

struct ShotInfoHeaderView: View {
    let carryDistance: Int
    let clubName: String
    let shotTypeName: String
    let isRecommendationActive: Bool
    var onReset: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if isRecommendationActive {
                    Text("Recommended")
                        .font(JournalTheme.chipLabelFont)
                        .foregroundStyle(GTCColor.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .overlay(
                            Capsule()
                                .stroke(GTCColor.primary, lineWidth: 1)
                        )
                } else {
                    Text(" ")
                        .font(JournalTheme.chipLabelFont)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .hidden()
                }

                Spacer()

                if !isRecommendationActive, let onReset {
                    Button(action: onReset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(GTCColor.primary)
                            .frame(width: 26, height: 26)
                            .background(
                                Circle()
                                    .fill(GTCColor.surface)
                                    .overlay(
                                        Circle()
                                            .stroke(GTCColor.primary, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(clubName)
                    .font(JournalTheme.cardTitleFont)
                    .foregroundStyle(GTCColor.primary)

                Text("\(carryDistance) yd")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundStyle(GTCColor.text)
            }

            GTCMetaChip(shotTypeName)
        }
        .gtcTintedAccentCard()
    }
}

#Preview {
    ShotInfoHeaderView(
        carryDistance: 150,
        clubName: "7 Iron",
        shotTypeName: "Full",
        isRecommendationActive: true
    )
    .padding()
}
