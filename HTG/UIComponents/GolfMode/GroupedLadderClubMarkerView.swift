import SwiftUI

struct GroupedLadderClubMarkerView: View {
    let group: GroupedLadderEntry
    var onSelect: ((LadderEntry) -> Void)?

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(markerColor)
                .frame(width: 8, height: 8)

            ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                if index > 0 {
                    Text("/")
                        .font(JournalTheme.handwritten(size: fontSize))
                        .foregroundStyle(GTCColor.ladderSeparatorSlash)
                }
                Button {
                    onSelect?(entry)
                } label: {
                    Text(entryLabel(for: entry))
                        .font(JournalTheme.handwritten(size: fontSize))
                        .foregroundStyle(entry.isSelected ? GTCColor.warning : textColor)
                }
                .buttonStyle(.plain)
                .disabled(onSelect == nil)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .background {
            if group.isAnySelected {
                RoundedRectangle(cornerRadius: 4)
                    .fill(GTCColor.ladderSelectionFill)
            }
        }
    }

    private func entryLabel(for entry: LadderEntry) -> String {
        if group.entries.count > 1 || entry.isPrimaryShotType {
            return entry.clubNickname
        }
        return "\(entry.clubNickname) \(entry.shotTypeName)"
    }

    private var fontSize: CGFloat {
        if group.isPrimaryFontSize {
            return 13
        }
        return 12
    }

    private var markerColor: Color {
        if group.isAnySelected {
            return GTCColor.warning
        } else if group.isAnySameClubAsSelected {
            return GTCColor.ladderSameClubMarker
        }
        return GTCColor.ladderDefaultMarker
    }

    private var textColor: Color {
        if group.isAnySelected {
            return GTCColor.warning
        }
        return GTCColor.ladderDefaultText
    }
}

#Preview {
    VStack(spacing: 12) {
        GroupedLadderClubMarkerView(
            group: GroupedLadderEntry(
                carryDistance: 150,
                entries: [
                    LadderEntry(clubName: "7 Iron", clubNickname: "7I", shotTypeName: "Full", carryDistance: 150, yardagePosition: 0.5, isSelected: true, isSameClubAsSelected: true, isPrimaryShotType: true),
                    LadderEntry(clubName: "Pitching Wedge", clubNickname: "PW", shotTypeName: "Full", carryDistance: 150, yardagePosition: 0.5, isSelected: false, isSameClubAsSelected: false, isPrimaryShotType: true)
                ]
            )
        )

        GroupedLadderClubMarkerView(
            group: GroupedLadderEntry(
                carryDistance: 155,
                entries: [
                    LadderEntry(clubName: "7 Iron", clubNickname: "7I", shotTypeName: "Full", carryDistance: 155, yardagePosition: 0.6, isSelected: false, isSameClubAsSelected: false, isPrimaryShotType: true)
                ]
            )
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
