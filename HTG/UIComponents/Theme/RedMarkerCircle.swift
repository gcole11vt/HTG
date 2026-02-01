import SwiftUI

struct RedMarkerCircle: View {
    let size: CGFloat
    var animated: Bool = true

    @State private var drawProgress: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: drawProgress)
            .stroke(
                JournalTheme.redMarker,
                style: StrokeStyle(
                    lineWidth: 3,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                if animated {
                    animateDrawing()
                } else {
                    drawProgress = 1.0
                }
            }
    }

    private func animateDrawing() {
        // Slight rotation to give hand-drawn feel
        rotation = Double.random(in: -5...5)

        // Animate the circle drawing
        withAnimation(.easeOut(duration: 0.5)) {
            drawProgress = 1.0
        }
    }
}

struct RedMarkerCircleOverlay: ViewModifier {
    var animated: Bool = true
    var padding: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    let circleSize = max(geometry.size.width, geometry.size.height) + padding * 2
                    RedMarkerCircle(size: circleSize, animated: animated)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                }
            }
    }
}

extension View {
    func redMarkerCircle(animated: Bool = true, padding: CGFloat = 8) -> some View {
        modifier(RedMarkerCircleOverlay(animated: animated, padding: padding))
    }
}

#Preview {
    VStack(spacing: 40) {
        Text("7 Iron")
            .font(JournalTheme.clubNameFont)
            .foregroundStyle(JournalTheme.inkBlue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .redMarkerCircle()

        Text("Full")
            .font(JournalTheme.shotTypeFont)
            .foregroundStyle(JournalTheme.inkBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .redMarkerCircle(animated: false)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .agedPaperBackground()
}
