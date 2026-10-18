import SwiftUI

/// Empty state shown until the user has aligned their putting speed.
struct PuttingNoCalibrationView: View {
    /// nil while the Align Speed wizard is not available; the button is then disabled.
    var onAlignSpeed: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "circle.circle")
                .font(.system(size: 48))
                .foregroundStyle(GTCColor.border)

            Text("Align your speed")
                .font(JournalTheme.handwrittenBold(size: 24))
                .foregroundStyle(GTCColor.primary)

            Text("Roll a few putts at each backswing length so HTG can suggest a stroke for any distance.")
                .font(JournalTheme.handwritten(size: 16))
                .foregroundStyle(GTCColor.secondary)
                .multilineTextAlignment(.center)

            alignSpeedButton
        }
        .padding(.horizontal, JournalTheme.screenHorizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var alignSpeedButton: some View {
        Button("Align Speed") { onAlignSpeed?() }
            .gtcProminentActionButtonStyle()
            .disabled(onAlignSpeed == nil)
    }
}

#Preview {
    PuttingNoCalibrationView()
}
