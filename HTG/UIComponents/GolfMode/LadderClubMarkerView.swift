import SwiftUI

struct LadderClubMarkerView: View {
    let entry: LadderEntry
    var onSelect: ((LadderEntry) -> Void)?

    var body: some View {
        Button {
            onSelect?(entry)
        } label: {
            HStack(spacing: 6) {
                // Club dot
                Circle()
                    .fill(markerColor)
                    .frame(width: 8, height: 8)

                // Club nickname + optional shot type
                if entry.isPrimaryShotType {
                    Text(entry.clubNickname)
                        .font(JournalTheme.handwritten(size: 13))
                        .foregroundStyle(textColor)
                } else {
                    Text("\(entry.clubNickname) \(entry.shotTypeName)")
                        .font(JournalTheme.handwritten(size: 12))
                        .foregroundStyle(textColor)
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background {
                if entry.isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(JournalTheme.redMarker.opacity(0.1))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(onSelect == nil)
    }

    private var markerColor: Color {
        if entry.isSelected {
            return JournalTheme.redMarker
        } else if entry.isSameClubAsSelected {
            return JournalTheme.redMarker.opacity(0.5)
        } else {
            return JournalTheme.inkBlue.opacity(0.6)
        }
    }

    private var textColor: Color {
        if entry.isSelected {
            return JournalTheme.redMarker
        } else {
            return JournalTheme.inkBlue.opacity(0.8)
        }
    }

}

#Preview {
    VStack(spacing: 12) {
        LadderClubMarkerView(
            entry: LadderEntry(
                clubName: "7 Iron",
                clubNickname: "7I",
                shotTypeName: "Full",
                carryDistance: 155,
                yardagePosition: 0.6,
                isSelected: true,
                isSameClubAsSelected: true,
                isPrimaryShotType: true
            )
        )

        LadderClubMarkerView(
            entry: LadderEntry(
                clubName: "7 Iron",
                clubNickname: "7I",
                shotTypeName: "3/4",
                carryDistance: 140,
                yardagePosition: 0.4,
                isSelected: false,
                isSameClubAsSelected: true,
                isPrimaryShotType: false
            )
        )

        LadderClubMarkerView(
            entry: LadderEntry(
                clubName: "8 Iron",
                clubNickname: "8I",
                shotTypeName: "Full",
                carryDistance: 145,
                yardagePosition: 0.5,
                isSelected: false,
                isSameClubAsSelected: false,
                isPrimaryShotType: true
            )
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .agedPaperBackground()
}
