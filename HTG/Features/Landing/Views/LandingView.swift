import SwiftUI

/// Launch screen styled as the closed leather cover of a golf yardage book.
/// Purely decorative — no view model, no persistence.
struct LandingView: View {
    var body: some View {
        YardageBookCoverView()
            .ignoresSafeArea()
    }
}

/// Fixed design width the cover artwork was authored against (points).
/// All child layers derive their sizing from `scale = renderedWidth / referenceWidth`.
enum CoverMetrics {
    static let referenceWidth: CGFloat = 620
}

private struct YardageBookCoverView: View {
    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / CoverMetrics.referenceWidth

            ZStack(alignment: .topLeading) {
                CoverBackgroundView(scale: scale)
                CoverBoundSpineView(scale: scale)
                CoverEmbossedBorderView(scale: scale)
                CoverEyebrowLabelView(scale: scale)
                CoverGoldWordmarkView(scale: scale)
            }
        }
    }
}

private struct CoverBackgroundView: View {
    let scale: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0x33503F), location: 0),
                    .init(color: Color(hex: 0x29443A), location: 0.4),
                    .init(color: Color(hex: 0x1F3128), location: 1)
                ],
                startPoint: UnitPoint(x: 0.3, y: 0),
                endPoint: UnitPoint(x: 0.7, y: 1)
            )

            cornerVignette(center: UnitPoint(x: 0.15, y: 0.10))
            cornerVignette(center: UnitPoint(x: 0.92, y: 0.06))
            cornerVignette(center: UnitPoint(x: 0.08, y: 0.94))
            cornerVignette(center: UnitPoint(x: 0.95, y: 0.96))
        }
    }

    private func cornerVignette(center: UnitPoint) -> some View {
        RadialGradient(
            colors: [.black.opacity(0.38), .clear],
            center: center,
            startRadius: 0,
            endRadius: 160 * scale
        )
    }
}

private struct CoverBoundSpineView: View {
    let scale: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [.black.opacity(0.5), .black.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 34 * scale)

            Spacer(minLength: 0)
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.black.opacity(0.35))
                .frame(width: 2 * scale)
                .offset(x: 8 * scale)
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1 * scale)
                .offset(x: 20 * scale)
        }
    }
}

private struct CoverEmbossedBorderView: View {
    let scale: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .strokeBorder(Color(hex: 0xF7F7F2).opacity(0.16), lineWidth: 1)
            .padding(.leading, 46 * scale)
            .padding([.top, .trailing, .bottom], 22 * scale)
    }
}

private struct CoverEyebrowLabelView: View {
    let scale: CGFloat

    var body: some View {
        Text("Course Yardage Book")
            .font(.system(size: 12 * scale, design: .serif))
            .tracking(4 * scale)
            .textCase(.uppercase)
            .foregroundStyle(Color(hex: 0xF7F7F2).opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.leading, 46 * scale)
            .padding(.trailing, 22 * scale)
            .offset(y: 120 * scale)
    }
}

private struct CoverGoldWordmarkView: View {
    let scale: CGFloat

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ShimmeringGoldText(text: "HTG", fontSize: 60 * scale)
            }
        }
        .padding(.trailing, 44 * scale)
        .padding(.bottom, 50 * scale)
    }
}

/// Serif wordmark with a slow gold "shine" sweep, matching the animated
/// `background-position` shimmer from the original web mockup.
private struct ShimmeringGoldText: View {
    let text: String
    let fontSize: CGFloat

    @State private var isShining = false

    private let goldStops: [Color] = [
        Color(hex: 0x7A5F38),
        Color(hex: 0xE2C07F),
        Color(hex: 0x7A5F38),
        Color(hex: 0xC7A05E),
        Color(hex: 0x7A5F38)
    ]

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .semibold, design: .serif))
            .tracking(fontSize * 0.05)
            .foregroundStyle(
                LinearGradient(
                    colors: goldStops,
                    startPoint: isShining ? UnitPoint(x: 1, y: 0) : UnitPoint(x: -1, y: 0),
                    endPoint: isShining ? UnitPoint(x: 2, y: 0) : UnitPoint(x: 0, y: 0)
                )
            )
            .shadow(color: .black.opacity(0.3), radius: 0, x: 0, y: 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    isShining = true
                }
            }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

#Preview {
    LandingView()
}
