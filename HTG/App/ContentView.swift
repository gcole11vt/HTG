import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var launchViewModel: AppLaunchViewModel?

    var body: some View {
        ZStack {
            // Main app content (TabView)
            if launchViewModel?.hasOpenedJournal == true {
                mainTabView
                    .transition(.opacity)
            }

            // Opening animation overlay
            if let viewModel = launchViewModel, !viewModel.hasOpenedJournal {
                JournalOpeningAnimationView(ownerName: viewModel.ownerName) {
                    withAnimation(.easeOut(duration: JournalTheme.contentFadeDuration)) {
                        viewModel.completeOpening()
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: launchViewModel?.hasOpenedJournal)
        .task {
            if launchViewModel == nil {
                launchViewModel = AppLaunchViewModel(modelContext: modelContext)
            }
            await launchViewModel?.loadProfile()
        }
    }

    private var mainTabView: some View {
        TabView {
            GolfModeView()
                .tabItem {
                    Label("Golf", systemImage: "flag.fill")
                }

            RangeModeView()
                .tabItem {
                    Label("Range", systemImage: "target")
                }

            ClubListView()
                .tabItem {
                    Label("Clubs", systemImage: "bag.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Club.self, ShotType.self, RangeSession.self, Shot.self, UserProfile.self], inMemory: true)
}
