import SwiftUI

struct ClubShotBadgeView: View {
    let clubName: String
    let shotTypeName: String
    var showCircle: Bool = true
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(spacing: 4) {
                Text(clubName)
                    .font(JournalTheme.clubNameFont)
                    .foregroundStyle(JournalTheme.inkBlue)

                Text(shotTypeName)
                    .font(JournalTheme.shotTypeFont)
                    .foregroundStyle(JournalTheme.mutedGray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                if showCircle {
                    RedMarkerCircle(size: 100, animated: true)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

#Preview {
    VStack(spacing: 40) {
        ClubShotBadgeView(clubName: "7 Iron", shotTypeName: "Full")

        ClubShotBadgeView(clubName: "8 Iron", shotTypeName: "3/4", showCircle: false)

        ClubShotBadgeView(clubName: "PW", shotTypeName: "Full") {
            print("Tapped")
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .agedPaperBackground()
}
