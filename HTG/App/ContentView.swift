import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
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
