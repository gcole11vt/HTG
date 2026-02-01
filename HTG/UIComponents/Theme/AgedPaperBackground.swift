import SwiftUI

// MARK: - Deterministic Seeded RNG

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - Paper Grain Canvas

private struct PaperGrainView: View {
    var body: some View {
        Canvas { context, size in
            var rng = SeededGenerator(seed: 42)
            let dotCount = 2000
            for _ in 0..<dotCount {
                let x = CGFloat.random(in: 0..<size.width, using: &rng)
                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                let radius = CGFloat.random(in: 0.5...1.5, using: &rng)
                let path = Path(ellipseIn: CGRect(
                    x: x - radius,
                    y: y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.fill(path, with: .color(JournalTheme.paperDark))
            }
        }
        .opacity(0.07)
    }
}

// MARK: - Paper Fiber Canvas

private struct PaperFiberView: View {
    var body: some View {
        Canvas { context, size in
            var rng = SeededGenerator(seed: 137)
            let lineCount = 150
            for _ in 0..<lineCount {
                let x = CGFloat.random(in: 0..<size.width, using: &rng)
                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                let length = CGFloat.random(in: 8...25, using: &rng)
                let angle = CGFloat.random(in: 0..<(.pi), using: &rng)
                let dx = cos(angle) * length
                let dy = sin(angle) * length
                var path = Path()
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + dx, y: y + dy))
                context.stroke(
                    path,
                    with: .color(JournalTheme.paperFiber),
                    lineWidth: 0.5
                )
            }
        }
        .opacity(0.04)
    }
}

// MARK: - Background Modifier

struct AgedPaperBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Layer 1: Base fill
                    JournalTheme.agedPaper

                    // Layer 2: Paper grain (random dots)
                    PaperGrainView()

                    // Layer 3: Fiber lines
                    PaperFiberView()

                    // Layer 4: Soft vignette
                    GeometryReader { geo in
                        RadialGradient(
                            colors: [
                                Color.clear,
                                JournalTheme.paperDark.opacity(0.25)
                            ],
                            center: .center,
                            startRadius: min(geo.size.width, geo.size.height) * 0.3,
                            endRadius: max(geo.size.width, geo.size.height) * 0.7
                        )
                    }

                    // Layer 5: Spine shadow (left edge)
                    LinearGradient(
                        stops: [
                            .init(color: JournalTheme.leatherDark.opacity(0.08), location: 0),
                            .init(color: Color.clear, location: 0.15)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )

                    // Layer 6: Edge warmth (top/bottom darkening)
                    LinearGradient(
                        stops: [
                            .init(color: JournalTheme.paperDark.opacity(0.06), location: 0),
                            .init(color: Color.clear, location: 0.12),
                            .init(color: Color.clear, location: 0.88),
                            .init(color: JournalTheme.paperDark.opacity(0.06), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
    }
}

extension View {
    func agedPaperBackground() -> some View {
        modifier(AgedPaperBackground())
    }
}

#Preview {
    VStack {
        Text("150")
            .font(JournalTheme.yardageFont)
            .foregroundStyle(JournalTheme.inkBlue)

        Text("7 Iron - Full")
            .font(JournalTheme.clubNameFont)
            .foregroundStyle(JournalTheme.inkBlue)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .agedPaperBackground()
}
