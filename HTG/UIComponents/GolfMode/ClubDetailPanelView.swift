import SwiftUI

struct ClubDetailPanelView: View {
    let clubs: [Club]
    let targetYardage: Int
    let currentSelection: SelectedClubShot?
    @Binding var selectedClubName: String
    @Binding var pendingSelection: SelectedClubShot?

    private var selectedClub: Club? {
        clubs.first { $0.name == selectedClubName }
    }

    private var visibleShotTypes: [ShotType] {
        guard let club = selectedClub else { return [] }
        return club.shotTypes
            .filter { !$0.isArchived }
            .sorted { $0.carryDistance > $1.carryDistance }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            clubPicker
            shotTypeList
        }
    }

    private var clubPicker: some View {
        Picker("Club", selection: $selectedClubName) {
            ForEach(clubs.filter { !$0.isArchived }.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.name) { club in
                Text(club.name).tag(club.name)
            }
        }
        .pickerStyle(.menu)
        .font(JournalTheme.handwrittenBold(size: 16))
        .tint(JournalTheme.inkBlue)
    }

    private var shotTypeList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(visibleShotTypes, id: \.id) { shotType in
                    let isCurrent = currentSelection?.clubName == selectedClubName
                        && currentSelection?.shotTypeName == shotType.name
                    let isPending = pendingSelection?.clubName == selectedClubName
                        && pendingSelection?.shotTypeName == shotType.name

                    ClubShotRowView(
                        clubNickname: selectedClub?.nickname ?? "",
                        shotTypeName: shotType.name,
                        carryDistance: shotType.carryDistance,
                        targetYardage: targetYardage,
                        isHighlighted: isPending,
                        isBordered: isCurrent
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        pendingSelection = SelectedClubShot(
                            clubName: selectedClubName,
                            shotTypeName: shotType.name,
                            carryDistance: shotType.carryDistance
                        )
                    }
                }
            }
        }
    }
}
