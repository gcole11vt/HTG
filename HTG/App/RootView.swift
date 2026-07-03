import SwiftUI

/// Shows the `LandingView` cover screen briefly on launch, then fades into
/// the main `ContentView` tab experience.
struct RootView: View {
    @State private var isShowingLanding = true

    var body: some View {
        Group {
            if isShowingLanding {
                LandingView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeInOut(duration: 0.6)) {
                isShowingLanding = false
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Club.self, ShotType.self, RangeSession.self, Shot.self, UserProfile.self], inMemory: true)
}
