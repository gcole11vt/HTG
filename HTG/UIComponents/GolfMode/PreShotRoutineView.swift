import SwiftUI

struct PreShotRoutineView: View {
    let items: [PreShotRoutineItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GTCSectionEyebrow("Pre-Shot Routine")

            let sorted = items.sorted { $0.sortOrder < $1.sortOrder }
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 8) {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(GTCColor.secondary)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                                .foregroundStyle(GTCColor.border)
                        )
                    Text(item.text)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(GTCColor.text)
                }
            }
        }
    }
}
