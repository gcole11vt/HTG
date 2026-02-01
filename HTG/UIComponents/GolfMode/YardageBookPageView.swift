import SwiftUI

struct YardageBookPageView: View {
    @Binding var targetYardage: Int
    let displayedClubShot: SelectedClubShot?
    let showResetIndicator: Bool
    let ladderMinYardage: Int
    let ladderMaxYardage: Int
    let ladderEntries: [LadderEntry]
    var onSelectEntry: ((LadderEntry) -> Void)?
    var onReset: (() -> Void)?

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left side - Yardage and Club Badge
                VStack(spacing: 16) {
                    Spacer()

                    YardageDisplayView(yardage: $targetYardage)

                    if let clubShot = displayedClubShot {
                        ClubShotBadgeView(
                            clubName: clubShot.clubName,
                            shotTypeName: clubShot.shotTypeName
                        )
                    }

                    if showResetIndicator {
                        ResetIndicatorView {
                            onReset?()
                        }
                        .transition(.opacity.combined(with: .scale))
                    }

                    Spacer()
                }
                .frame(width: geometry.size.width * 0.55)
                .animation(.easeInOut(duration: 0.3), value: showResetIndicator)

                // Right side - Yardage Ladder
                YardageLadderView(
                    targetYardage: targetYardage,
                    minYardage: ladderMinYardage,
                    maxYardage: ladderMaxYardage,
                    entries: ladderEntries,
                    onSelectEntry: onSelectEntry
                )
                .frame(width: geometry.size.width * 0.45)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .agedPaperBackground()
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var yardage = 150
        @State var showReset = true

        let entries = [
            LadderEntry(
                clubName: "6 Iron",
                shotTypeName: "Full",
                carryDistance: 165,
                yardagePosition: 0.7,
                isSelected: false,
                isSameClubAsSelected: false
            ),
            LadderEntry(
                clubName: "7 Iron",
                shotTypeName: "Full",
                carryDistance: 155,
                yardagePosition: 0.55,
                isSelected: true,
                isSameClubAsSelected: true
            ),
            LadderEntry(
                clubName: "8 Iron",
                shotTypeName: "Full",
                carryDistance: 145,
                yardagePosition: 0.4,
                isSelected: false,
                isSameClubAsSelected: false
            )
        ]

        var body: some View {
            YardageBookPageView(
                targetYardage: $yardage,
                displayedClubShot: SelectedClubShot(
                    clubName: "7 Iron",
                    shotTypeName: "Full",
                    carryDistance: 155
                ),
                showResetIndicator: showReset,
                ladderMinYardage: 127,
                ladderMaxYardage: 172,
                ladderEntries: entries
            ) { entry in
                print("Selected: \(entry.clubName)")
            } onReset: {
                showReset = false
            }
        }
    }
    return PreviewWrapper()
}
