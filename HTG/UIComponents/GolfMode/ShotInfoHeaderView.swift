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
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(GTCColor.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .overlay(
                            Capsule()
                                .stroke(GTCColor.primary, lineWidth: 1)
                        )
                } else {
                    Text(" ")
                        .font(.system(size: 11, weight: .medium))
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
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(GTCColor.primary)

                Text("\(carryDistance) yd")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundStyle(GTCColor.text)
            }

            Text(shotTypeName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(GTCColor.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(GTCColor.secondary.opacity(0.08))
                )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(GTCColor.secondary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(GTCColor.primary, lineWidth: 1.5)
                )
        )
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
