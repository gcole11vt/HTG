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
                        .foregroundStyle(textColor.opacity(0.5))
                }
                Button {
                    onSelect?(entry)
                } label: {
                    Text(entryLabel(for: entry))
                        .font(JournalTheme.handwritten(size: fontSize))
                        .foregroundStyle(entry.isSelected ? JournalTheme.redMarker : textColor)
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
                    .fill(JournalTheme.redMarker.opacity(0.1))
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
