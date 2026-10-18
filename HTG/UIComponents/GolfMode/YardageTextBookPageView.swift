import SwiftUI

/// Golf Mode page for the Text view: fixed header, scrolling text ladder, fixed focus column.
struct YardageTextBookPageView: View {
    @Binding var targetYardage: Int
    let displayedClubShot: SelectedClubShot?
    let showResetIndicator: Bool
    let ladder: DistanceTextLadder
    var recenterGeneration: Int = 0
    var clubs: [Club] = []
    var allShotTypeNames: [String] = []
    var showPreShotRoutine: Bool = false
    var routineItems: [PreShotRoutineItem] = []
    var showMantra: Bool = false
    var mantraText: String = ""
    var matchingSwingThoughts: [SwingThought] = []
    var onSelectRow: ((DistanceTextLadderRow) -> Void)?
    var onSelectClubShot: ((SelectedClubShot) -> Void)?
    var onReset: (() -> Void)?
    var onRefresh: (() -> Void)?

    private var focusColumn: GolfModeFocusColumnView {
        GolfModeFocusColumnView(
            showMantra: showMantra,
            mantraText: mantraText,
            showPreShotRoutine: showPreShotRoutine,
            routineItems: routineItems,
            matchingSwingThoughts: matchingSwingThoughts
        )
    }

    var body: some View {
        ZStack {
            GTCColor.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                GolfModeShotHeaderView(
                    targetYardage: $targetYardage,
                    displayedClubShot: displayedClubShot,
                    showResetIndicator: showResetIndicator,
                    clubs: clubs,
                    allShotTypeNames: allShotTypeNames,
                    onSelectClubShot: onSelectClubShot,
                    onReset: onReset,
                    onRefresh: onRefresh
                )
                twoColumnArea
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .animation(.easeInOut(duration: 0.2), value: showResetIndicator)
        }
    }

    private var twoColumnArea: some View {
        GeometryReader { proxy in
            let hasFocus = focusColumn.hasContent
            let spacing: CGFloat = 12
            let ladderWidth = hasFocus ? (proxy.size.width - spacing) * 0.6 : proxy.size.width
            HStack(alignment: .top, spacing: spacing) {
                DistanceTextLadderView(
                    ladder: ladder,
                    unit: .yards,
                    recenterGeneration: recenterGeneration,
                    onSelectRow: onSelectRow
                )
                .frame(width: ladderWidth, height: proxy.size.height)

                if hasFocus {
                    focusColumn
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var yardage = 152
    YardageTextBookPageView(
        targetYardage: $yardage,
        displayedClubShot: SelectedClubShot(clubName: "7 Iron", shotTypeName: "Full", carryDistance: 150),
        showResetIndicator: false,
        ladder: DistanceTextLadderService.ladder(
            items: [
                DistanceTextLadderItem(id: "d", distance: 250, primaryLabel: "Driver", secondaryLabel: "Tee"),
                DistanceTextLadderItem(id: "7", distance: 150, primaryLabel: "7 Iron", secondaryLabel: "Full"),
                DistanceTextLadderItem(id: "p", distance: 120, primaryLabel: "Pitching Wedge", secondaryLabel: "Full")
            ],
            targetDistance: 152,
            selectedItemID: "7"
        ),
        showMantra: true,
        mantraText: "Smooth tempo"
    )
}
