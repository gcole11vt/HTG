import SwiftUI

struct LeatherBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base leather color
                    JournalTheme.leatherBrown

                    // Subtle gradient for depth
                    LinearGradient(
                        colors: [
                            JournalTheme.leatherDark.opacity(0.3),
                            Color.clear,
                            JournalTheme.leatherDark.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Texture overlay (placeholder - can be replaced with actual texture image)
                    // Image("leather-texture")
                    //     .resizable()
                    //     .opacity(0.15)
                }
            )
    }
}

extension View {
    func leatherBackground() -> some View {
        modifier(LeatherBackground())
    }
}

#Preview {
    Text("Leather Background")
        .foregroundStyle(.white)
        .font(JournalTheme.titleFont)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .leatherBackground()
}
