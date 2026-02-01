import SwiftUI

struct GroupedLadderClubMarkerView: View {
    let group: GroupedLadderEntry
    var onSelect: ((LadderEntry) -> Void)?

    var body: some View {
        Button {
            if let entry = group.entries.first {
                onSelect?(entry)
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(markerColor)
                    .frame(width: 8, height: 8)

                Text(group.displayLabel)
                    .font(JournalTheme.handwritten(size: fontSize))
                    .foregroundStyle(textColor)
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background {
                if group.isAnySelected {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(JournalTheme.redMarker.opacity(0.1))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(onSelect == nil)
    }

    private var fontSize: CGFloat {
        if group.isPrimaryFontSize {
            return 13
        }
        return 12
    }

    private var markerColor: Color {
        if group.isAnySelected {
            return JournalTheme.redMarker
        } else if group.isAnySameClubAsSelected {
            return JournalTheme.redMarker.opacity(0.5)
        }
        return JournalTheme.inkBlue.opacity(0.6)
    }

    private var textColor: Color {
        if group.isAnySelected {
            return JournalTheme.redMarker
        }
        return JournalTheme.inkBlue.opacity(0.8)
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
    .agedPaperBackground()
}
