import SwiftUI
import SwiftData

struct GolfModeView: View {
    @Environment(\.modelContext) private var modelContext
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
        .task {
            if viewModel == nil {
                viewModel = GolfModeViewModel(modelContext: modelContext)
            }
            await viewModel?.loadClubs()
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
            groupedLadderEntries: viewModel.groupedLadderEntries
        ) { entry in
            viewModel.selectClubShot(
                clubName: entry.clubName,
                shotTypeName: entry.shotTypeName,
                distance: entry.carryDistance
            )
        } onReset: {
            viewModel.resetToRecommendation()
        }
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .agedPaperBackground()
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bag")
                .font(.system(size: 48))
                .foregroundStyle(JournalTheme.mutedGray)

            Text("No Clubs")
                .font(JournalTheme.handwrittenBold(size: 24))
                .foregroundStyle(JournalTheme.inkBlue)

            Text("Add clubs in the Clubs tab\nto see shot recommendations")
                .font(JournalTheme.handwritten(size: 16))
                .foregroundStyle(JournalTheme.mutedGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .agedPaperBackground()
    }
}

#Preview {
    GolfModeView()
        .modelContainer(for: [Club.self, ShotType.self], inMemory: true)
}
