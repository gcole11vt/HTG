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
    var showPreShotRoutine: Bool = false
    var routineItems: [PreShotRoutineItem] = []
    var showMantra: Bool = false
    var mantraText: String = ""
    var matchingSwingThoughts: [SwingThought] = []
    var onSelectEntry: ((LadderEntry) -> Void)?
    var onSelectClubShot: ((SelectedClubShot) -> Void)?
    var onReset: (() -> Void)?

    @State private var showingClubSelector = false

    var body: some View {
        ZStack {
            GTCColor.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    PageTitleView()
                        .padding(.top, 8)

                    YardageDisplayView(yardage: $targetYardage)

                    if let clubShot = displayedClubShot {
                        ShotInfoHeaderView(
                            carryDistance: clubShot.carryDistance,
                            clubName: clubShot.clubName,
                            shotTypeName: clubShot.shotTypeName,
                            isRecommendationActive: !showResetIndicator,
                            onReset: onReset
                        )
                        .onTapGesture {
                            showingClubSelector = true
                        }
                    }

                    YardageLadderView(
                        targetYardage: targetYardage,
                        minYardage: ladderMinYardage,
                        maxYardage: ladderMaxYardage,
                        groupedEntries: groupedLadderEntries,
                        onSelectEntry: onSelectEntry
                    )

                    if showMantra {
                        MantraView(text: mantraText)
                    }

                    if showPreShotRoutine || !matchingSwingThoughts.isEmpty {
                        HStack(alignment: .top, spacing: 12) {
                            if showPreShotRoutine {
                                PreShotRoutineView(items: routineItems)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            if !matchingSwingThoughts.isEmpty {
                                SwingThoughtsView(thoughts: matchingSwingThoughts)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .animation(.easeInOut(duration: 0.2), value: showResetIndicator)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
