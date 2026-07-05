import SwiftUI
import SwiftData

struct GolfModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @State private var viewModel: GolfModeViewModel?

    var body: some View {
        Group {
            if let viewModel = viewModel {
                if viewModel.clubs.isEmpty {
                    emptyStateView
                } else {
                    yardageBookContent(viewModel: viewModel)
                }
            } else {
                loadingView
            }
        }
        .task(id: navigationCoordinator.selectedTab) {
            if viewModel == nil {
                viewModel = GolfModeViewModel(modelContext: modelContext)
            }
            guard navigationCoordinator.selectedTab == .golf else { return }
            await viewModel?.ensureDefaultsThenLoadClubs()
        }
    }

    private func yardageBookContent(viewModel: GolfModeViewModel) -> some View {
        YardageBookPageView(
            targetYardage: Binding(
                get: { viewModel.targetYardage },
                set: { viewModel.setTargetYardage($0) }
            ),
            displayedClubShot: viewModel.displayedClubShot,
            showResetIndicator: viewModel.showResetIndicator,
            ladderMinYardage: viewModel.ladderMinYardage,
            ladderMaxYardage: viewModel.ladderMaxYardage,
            groupedLadderEntries: viewModel.groupedLadderEntries,
            clubs: viewModel.clubs,
            allShotTypeNames: viewModel.shotTypeNamesInBag,
            showPreShotRoutine: viewModel.showPreShotRoutine,
            routineItems: viewModel.sortedRoutineItems,
            showMantra: viewModel.showMantra,
            mantraText: viewModel.mantraText,
            matchingSwingThoughts: viewModel.matchingSwingThoughts,
            onSelectEntry: { entry in
                viewModel.selectClubShot(
                    clubName: entry.clubName,
                    shotTypeName: entry.shotTypeName,
                    distance: entry.carryDistance
                )
            },
            onSelectClubShot: { selection in
                viewModel.selectClubShot(
                    clubName: selection.clubName,
                    shotTypeName: selection.shotTypeName,
                    distance: selection.carryDistance
                )
            },
            onReset: {
                viewModel.resetToRecommendation()
            },
            onRefresh: {
                Task { await viewModel.refresh() }
            }
        )
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bag")
                .font(.system(size: 48))
                .foregroundStyle(GTCColor.border)

            Text("No Clubs")
                .font(JournalTheme.handwrittenBold(size: 24))
                .foregroundStyle(GTCColor.primary)

            Text("Add clubs in the Clubs tab\nto see shot recommendations")
                .font(JournalTheme.handwritten(size: 16))
                .foregroundStyle(GTCColor.border)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    GolfModeView()
        .environment(NavigationCoordinator())
        .modelContainer(for: [Club.self, ShotType.self], inMemory: true)
}
