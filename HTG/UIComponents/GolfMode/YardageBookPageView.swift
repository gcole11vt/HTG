import SwiftUI

struct YardageBookPageView: View {
    @Binding var targetYardage: Int
    let displayedClubShot: SelectedClubShot?
    let showResetIndicator: Bool
    let ladderMinYardage: Int
    let ladderMaxYardage: Int
    let groupedLadderEntries: [GroupedLadderEntry]
    var clubs: [Club] = []
    var allShotTypeNames: [String] = []
    var onSelectEntry: ((LadderEntry) -> Void)?
    var onSelectClubShot: ((SelectedClubShot) -> Void)?
    var onReset: (() -> Void)?

    @State private var showingClubSelector = false

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 8) {
                PageTitleView()
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                HStack(alignment: .top, spacing: 0) {
                    // Left column — top aligned
                    VStack(alignment: .leading, spacing: 12) {
                        YardageDisplayView(yardage: $targetYardage)

                        if let clubShot = displayedClubShot {
                            ShotInfoHeaderView(
                                carryDistance: clubShot.carryDistance,
                                clubName: clubShot.clubName,
                                shotTypeName: clubShot.shotTypeName
                            )
                            .onTapGesture {
                                showingClubSelector = true
                            }
                        }

                        if showResetIndicator {
                            ResetIndicatorView {
                                onReset?()
                            }
                            .transition(.opacity.combined(with: .scale))
                        }

                        Spacer()
                    }
                    .padding(.leading, 16)
                    .frame(width: geometry.size.width * 0.55)
                    .animation(.easeInOut(duration: 0.3), value: showResetIndicator)

                    // Right column — YardageLadder
                    YardageLadderView(
                        targetYardage: targetYardage,
                        minYardage: ladderMinYardage,
                        maxYardage: ladderMaxYardage,
                        groupedEntries: groupedLadderEntries,
                        onSelectEntry: onSelectEntry
                    )
                    .frame(width: geometry.size.width * 0.45)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .agedPaperBackground()
        .sheet(isPresented: $showingClubSelector) {
            if let clubShot = displayedClubShot {
                ClubSelectorSheetView(
                    targetYardage: targetYardage,
                    clubs: clubs,
                    currentSelection: clubShot,
                    allShotTypeNames: allShotTypeNames
                ) { selection in
                    onSelectClubShot?(selection)
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var yardage = 150
        @State var showReset = true

        let groupedEntries = [
            GroupedLadderEntry(
                carryDistance: 165,
                entries: [
                    LadderEntry(clubName: "6 Iron", clubNickname: "6I", shotTypeName: "Full", carryDistance: 165, yardagePosition: 0.7, isSelected: false, isSameClubAsSelected: false, isPrimaryShotType: true)
                ]
            ),
            GroupedLadderEntry(
                carryDistance: 155,
                entries: [
                    LadderEntry(clubName: "7 Iron", clubNickname: "7I", shotTypeName: "Full", carryDistance: 155, yardagePosition: 0.55, isSelected: true, isSameClubAsSelected: true, isPrimaryShotType: true)
                ]
            ),
            GroupedLadderEntry(
                carryDistance: 145,
                entries: [
                    LadderEntry(clubName: "8 Iron", clubNickname: "8I", shotTypeName: "Full", carryDistance: 145, yardagePosition: 0.4, isSelected: false, isSameClubAsSelected: false, isPrimaryShotType: true)
                ]
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
                groupedLadderEntries: groupedEntries
            ) { entry in
                print("Selected: \(entry.clubName)")
            } onReset: {
                showReset = false
            }
        }
    }
    return PreviewWrapper()
}
