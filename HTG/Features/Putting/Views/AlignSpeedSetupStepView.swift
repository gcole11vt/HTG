import SwiftUI

struct AlignSpeedSetupStepView: View {
    let manager: AlignSpeedManager

    var body: some View {
        VStack(alignment: .leading, spacing: JournalTheme.sectionSpacing) {
            Text("Pick a flat, straight putt on the practice green. Position 1 is your shortest backswing; each number after it is a little longer.")
                .font(JournalTheme.handwritten(size: 16))
                .foregroundStyle(GTCColor.secondary)
            Stepper(
                "Positions: \(manager.positionCount)",
                value: Binding(get: { manager.positionCount }, set: { manager.setPositionCount($0) }),
                in: PuttingCalibrationRules.positionCountRange
            )
            .font(JournalTheme.handwrittenBold(size: 18))
            .foregroundStyle(GTCColor.primary)
            .gtcNeutralCard(fill: GTCColor.surface)
            Spacer()
        }
        .padding(.horizontal, JournalTheme.screenHorizontalPadding)
    }
}
