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

                // Club name (abbreviated)
                Text(abbreviatedClubName)
                    .font(JournalTheme.handwritten(size: 12))
                    .foregroundStyle(textColor)

                if entry.isSelected {
                    Text(entry.shotTypeName)
                        .font(JournalTheme.handwritten(size: 10))
                        .foregroundStyle(JournalTheme.mutedGray)
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

    private var abbreviatedClubName: String {
        // Abbreviate common club names
        let name = entry.clubName
        if name.contains("Iron") {
            return name.replacingOccurrences(of: " Iron", with: "i")
        } else if name.contains("Wood") {
            return name.replacingOccurrences(of: " Wood", with: "W")
        } else if name == "Driver" {
            return "Dr"
        } else if name == "Putter" {
            return "Pt"
        }
        return name
    }
}

#Preview {
    VStack(spacing: 12) {
        LadderClubMarkerView(
            entry: LadderEntry(
                clubName: "7 Iron",
                shotTypeName: "Full",
                carryDistance: 155,
                yardagePosition: 0.6,
                isSelected: true,
                isSameClubAsSelected: true
            )
        )

        LadderClubMarkerView(
            entry: LadderEntry(
                clubName: "7 Iron",
                shotTypeName: "3/4",
                carryDistance: 140,
                yardagePosition: 0.4,
                isSelected: false,
                isSameClubAsSelected: true
            )
        )

        LadderClubMarkerView(
            entry: LadderEntry(
                clubName: "8 Iron",
                shotTypeName: "Full",
                carryDistance: 145,
                yardagePosition: 0.5,
                isSelected: false,
                isSameClubAsSelected: false
            )
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .agedPaperBackground()
}
