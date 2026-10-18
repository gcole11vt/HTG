import SwiftUI

/// One tappable row of the text ladder: distance, primary label, optional secondary label.
struct DistanceTextLadderRowView: View {
    let row: DistanceTextLadderRow
    let unit: DistanceUnit
    var onSelect: (() -> Void)?

    var body: some View {
        Button { onSelect?() } label: {
            HStack(spacing: 8) {
                distanceText
                Text(row.item.primaryLabel)
                    .font(.system(size: 15))
                    .foregroundStyle(GTCColor.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                secondaryText
                Spacer(minLength: 0)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(selectionBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(row.isSelected ? .isSelected : [])
    }

    private var distanceText: some View {
        Text("\(row.item.distance)")
            .font(.system(size: 15, weight: row.isClosestToTarget ? .bold : .semibold))
            .monospacedDigit()
            .foregroundStyle(row.isClosestToTarget ? GTCColor.primary : GTCColor.text)
            .frame(width: 36, alignment: .trailing)
    }

    @ViewBuilder
    private var secondaryText: some View {
        if !row.item.secondaryLabel.isEmpty {
            Text(row.item.secondaryLabel)
                .font(.system(size: 13))
                .foregroundStyle(GTCColor.secondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var selectionBackground: some View {
        if row.isSelected {
            RoundedRectangle(cornerRadius: 8)
                .fill(GTCColor.accentCardFill)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(GTCColor.primary, lineWidth: 1))
        }
    }

    private var accessibilityText: String {
        let spokenUnit = unit == .yards ? "yards" : "feet"
        let secondary = row.item.secondaryLabel.isEmpty ? "" : " \(row.item.secondaryLabel)"
        return "\(row.item.distance) \(spokenUnit), \(row.item.primaryLabel)\(secondary)"
    }
}

/// Dashed line showing where the target falls between two rows.
struct DistanceTextLadderTargetMarkerView: View {
    let distance: Int
    let unit: DistanceUnit

    var body: some View {
        HStack(spacing: 6) {
            dashedLine
            Text(unit.formatted(distance))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GTCColor.accent)
            dashedLine
        }
        .padding(.horizontal, 8)
        .accessibilityLabel("Target \(unit.formatted(distance))")
    }

    private var dashedLine: some View {
        Line()
            .stroke(GTCColor.accent, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            .frame(height: 1.5)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }
}

#Preview {
    VStack {
        DistanceTextLadderRowView(
            row: DistanceTextLadderRow(
                item: DistanceTextLadderItem(id: "a", distance: 150, primaryLabel: "7 Iron", secondaryLabel: "Full"),
                isClosestToTarget: true, isSelected: true),
            unit: .yards
        )
        DistanceTextLadderTargetMarkerView(distance: 152, unit: .yards)
    }
    .padding()
}
