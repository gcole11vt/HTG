import SwiftUI

struct AllShotsOverviewPanelView: View {
    let clubs: [Club]
    let targetYardage: Int
    let currentSelection: SelectedClubShot?
    let allShotTypeNames: [String]
    @Binding var activeShotTypeFilters: Set<String>
    @Binding var pendingSelection: SelectedClubShot?

    private struct ComboEntry: Identifiable {
        let id = UUID()
        let clubName: String
        let clubNickname: String
        let shotTypeName: String
        let carryDistance: Int
    }

    private var allCombos: [ComboEntry] {
        var entries: [ComboEntry] = []
        for club in clubs where !club.isArchived {
            for shotType in club.shotTypes where !shotType.isArchived {
                guard activeShotTypeFilters.contains(shotType.name) else { continue }
                entries.append(ComboEntry(
                    clubName: club.name,
                    clubNickname: club.nickname,
                    shotTypeName: shotType.name,
                    carryDistance: shotType.carryDistance
                ))
            }
        }
        return entries.sorted { $0.carryDistance > $1.carryDistance }
    }

    private var centeredWindow: [ComboEntry] {
        let combos = allCombos
        guard !combos.isEmpty else { return [] }

        // Find anchor: last item where carryDistance >= targetYardage
        let anchorIndex: Int
        if let lastIndex = combos.lastIndex(where: { $0.carryDistance >= targetYardage }) {
            anchorIndex = lastIndex
        } else {
            anchorIndex = 0
        }

        // Place anchor at index 3 (middle of 7)
        let windowSize = 7
        let idealStart = anchorIndex - 3
        let clampedStart = max(0, min(idealStart, combos.count - windowSize))
        let start = max(0, clampedStart)
        let end = min(combos.count, start + windowSize)

        return Array(combos[start..<end])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            filterMenu
            shotList
        }
    }

    private var filterMenu: some View {
        Menu {
            ForEach(allShotTypeNames, id: \.self) { name in
                Button {
                    if activeShotTypeFilters.contains(name) {
                        activeShotTypeFilters.remove(name)
                    } else {
                        activeShotTypeFilters.insert(name)
                    }
                } label: {
                    Label(name, systemImage: activeShotTypeFilters.contains(name) ? "checkmark.circle.fill" : "circle")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("Filter")
                    .font(JournalTheme.handwritten(size: 14))
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 14))
            }
            .foregroundStyle(JournalTheme.mutedGray)
        }
    }

    private var shotList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(centeredWindow) { combo in
                    let isCurrent = currentSelection?.clubName == combo.clubName
                        && currentSelection?.shotTypeName == combo.shotTypeName
                    let isPending = pendingSelection?.clubName == combo.clubName
                        && pendingSelection?.shotTypeName == combo.shotTypeName

                    ClubShotRowView(
                        clubNickname: combo.clubNickname,
                        shotTypeName: combo.shotTypeName,
                        carryDistance: combo.carryDistance,
                        targetYardage: targetYardage,
                        isHighlighted: isPending,
                        isBordered: isCurrent
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        pendingSelection = SelectedClubShot(
                            clubName: combo.clubName,
                            shotTypeName: combo.shotTypeName,
                            carryDistance: combo.carryDistance
                        )
                    }
                }
            }
        }
    }
}
