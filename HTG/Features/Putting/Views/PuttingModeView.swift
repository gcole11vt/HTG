import SwiftUI
import SwiftData

/// Putting tab root. Loads only while the Putting tab is selected.
struct PuttingModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @State private var viewModel: PuttingModeViewModel?

    var body: some View {
        content
            .task(id: navigationCoordinator.selectedTab) {
                if viewModel == nil {
                    viewModel = PuttingModeViewModel(modelContext: modelContext)
                }
                guard navigationCoordinator.selectedTab == .putting else { return }
                await viewModel?.load()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let viewModel, viewModel.hasLoaded {
            if viewModel.hasCalibration {
                puttingPage(viewModel: viewModel)
            } else {
                PuttingNoCalibrationView()
            }
        } else {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func puttingPage(viewModel: PuttingModeViewModel) -> some View {
        PuttingPageView(
            targetFeet: Binding(get: { viewModel.targetFeet }, set: { viewModel.setTargetFeet($0) }),
            viewStyle: viewModel.viewStyle,
            suggestionTitle: viewModel.suggestionTitle,
            suggestionDetail: viewModel.suggestionDetail,
            statusText: viewModel.calibrationStatusText,
            isStatusStale: viewModel.isCalibrationStale,
            textLadder: viewModel.textLadder,
            groupedLadderEntries: viewModel.groupedLadderEntries,
            ladderMaxFeet: viewModel.ladderMaxFeet,
            recenterGeneration: viewModel.recenterGeneration
        )
    }
}

#Preview {
    PuttingModeView()
        .environment(NavigationCoordinator())
        .modelContainer(
            for: [UserProfile.self, PuttingCalibration.self, PuttingCalibrationPutt.self],
            inMemory: true
        )
}
