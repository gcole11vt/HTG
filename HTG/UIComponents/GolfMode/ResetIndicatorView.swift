import SwiftUI

struct ResetIndicatorView: View {
    var onReset: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            onReset()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .medium))

                Text("reset")
                    .font(JournalTheme.handwritten(size: 14))
            }
            .foregroundStyle(JournalTheme.mutedGray)
            .opacity(isPressed ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ClubShotBadgeView(clubName: "8 Iron", shotTypeName: "Full")

        ResetIndicatorView {
            print("Reset tapped")
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .agedPaperBackground()
}
