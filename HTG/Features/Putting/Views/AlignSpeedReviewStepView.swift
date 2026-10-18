import SwiftUI

/// Final check before saving: per-position putt counts and averages, with short rolls flagged.
struct AlignSpeedReviewStepView: View {
    let manager: AlignSpeedManager

    var body: some View {
        VStack(alignment: .leading, spacing: JournalTheme.sectionSpacing) {
            Text("Review your positions")
                .font(JournalTheme.sheetTitleFont)
                .foregroundStyle(GTCColor.primary)
            ScrollView {
                VStack(spacing: JournalTheme.subsectionSpacing) {
                    ForEach(manager.reviewPoints, id: \.position) { point in
                        reviewRow(point)
                    }
                }
            }
            footnote
            saveButton
        }
        .padding(.horizontal, JournalTheme.screenHorizontalPadding)
        .padding(.bottom, 12)
    }

    private func reviewRow(_ point: PuttingCalibrationPoint) -> some View {
        let isFlagged = manager.reviewWarnings.contains(point.position)
        return HStack {
            if isFlagged { Image(systemName: "exclamationmark.triangle") }
            Text(manager.name(for: point.position))
            Spacer()
            Text("\(point.puttCount) \(point.puttCount == 1 ? "putt" : "putts")")
                .foregroundStyle(GTCColor.secondary)
            Text(PuttingSpeedCurveService.formatFeet(point.averageFeet))
                .frame(minWidth: 64, alignment: .trailing)
        }
        .font(JournalTheme.handwritten(size: 16))
        .foregroundStyle(isFlagged ? GTCColor.warning : GTCColor.text)
        .gtcNeutralCard(fill: GTCColor.surface)
    }

    @ViewBuilder
    private var footnote: some View {
        if !manager.reviewWarnings.isEmpty {
            Text("Flagged positions rolled no farther than the one before. Go back to re-roll, or save and HTG will smooth them.")
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(GTCColor.warning)
        }
    }

    private var saveButton: some View {
        Button {
            Task { await manager.advance() }
        } label: {
            if manager.isSaving {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                Text("Save Calibration").frame(maxWidth: .infinity)
            }
        }
        .gtcProminentActionButtonStyle()
        .disabled(!manager.canAdvance)
        .accessibilityIdentifier("alignSpeedSaveButton")
    }
}
