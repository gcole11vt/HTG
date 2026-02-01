import SwiftUI

struct JournalOpeningAnimationView: View {
    let ownerName: String
    var onComplete: () -> Void

    @State private var animationPhase: AnimationPhase = .showCover
    @State private var coverRotation: Double = 0

    private enum AnimationPhase {
        case showCover
        case turning
        case completed
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.opacity(0.9)
                    .ignoresSafeArea()

                // Journal cover with 3D rotation
                JournalCoverView(ownerName: ownerName)
                    .frame(width: min(geometry.size.width * 0.8, 350))
                    .rotation3DEffect(
                        .degrees(coverRotation),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .leading,
                        perspective: 0.5
                    )
                    .opacity(animationPhase == .completed ? 0 : 1)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Phase 1: Show cover
        DispatchQueue.main.asyncAfter(deadline: .now() + JournalTheme.coverDisplayDuration) {
            // Phase 2: Page turn animation
            animationPhase = .turning
            withAnimation(.easeInOut(duration: JournalTheme.pageTurnDuration)) {
                coverRotation = -180
            }

            // Phase 3: Complete
            DispatchQueue.main.asyncAfter(deadline: .now() + JournalTheme.pageTurnDuration) {
                animationPhase = .completed
                DispatchQueue.main.asyncAfter(deadline: .now() + JournalTheme.contentFadeDuration) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    JournalOpeningAnimationView(ownerName: "Gregory Cole") {
        print("Animation complete")
    }
}
