import SwiftUI

/// Fixed top block shared by the Ladder and Text pages: title, target yardage and the shot card.
struct GolfModeShotHeaderView: View {
    @Binding var targetYardage: Int
    let displayedClubShot: SelectedClubShot?
    let showResetIndicator: Bool
    var clubs: [Club] = []
    var allShotTypeNames: [String] = []
    var onSelectClubShot: ((SelectedClubShot) -> Void)?
    var onReset: (() -> Void)?
    var onRefresh: (() -> Void)?

    @State private var showingClubSelector = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PageTitleView()
                .padding(.top, 8)

            YardageDisplayView(yardage: $targetYardage, onRefresh: onRefresh)

            shotCard
        }
        .sheet(isPresented: $showingClubSelector) { clubSelectorSheet }
    }

    @ViewBuilder
    private var shotCard: some View {
        if let clubShot = displayedClubShot {
            ShotInfoHeaderView(
                carryDistance: clubShot.carryDistance,
                clubName: clubShot.clubName,
                shotTypeName: clubShot.shotTypeName,
                isRecommendationActive: !showResetIndicator,
                onReset: onReset
            )
            .onTapGesture { showingClubSelector = true }
        }
    }

    @ViewBuilder
    private var clubSelectorSheet: some View {
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

#Preview {
    @Previewable @State var yardage = 150
    GolfModeShotHeaderView(
        targetYardage: $yardage,
        displayedClubShot: SelectedClubShot(clubName: "7 Iron", shotTypeName: "Full", carryDistance: 155),
        showResetIndicator: false
    )
    .padding(.horizontal, 20)
}
