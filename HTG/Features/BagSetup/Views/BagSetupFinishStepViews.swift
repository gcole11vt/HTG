import SwiftUI

struct BagSetupEstimatingStepView: View {
    let manager: BagSetupManager

    var body: some View {
        VStack(alignment: .leading, spacing: JournalTheme.sectionSpacing) {
            header
            yardageList
        }
        .padding(.horizontal, JournalTheme.screenHorizontalPadding)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Estimating other yardages")
                .font(JournalTheme.sheetTitleFont)
                .foregroundStyle(GTCColor.primary)
            Text("Estimated clubs are marked — tap the arrow to save your bag.")
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(GTCColor.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var yardageList: some View {
        ScrollView {
            VStack(spacing: JournalTheme.subsectionSpacing) {
                ForEach(manager.resolvedYardages) { resolved in
                    resolvedRow(resolved)
                }
            }
            .padding(.bottom, JournalTheme.sectionSpacing)
        }
    }

    private func resolvedRow(_ resolved: BagSetupManager.ResolvedYardage) -> some View {
        HStack(spacing: 8) {
            Text(resolved.name)
                .font(JournalTheme.handwritten(size: 16))
                .foregroundStyle(GTCColor.text)

            if resolved.isEstimated {
                GTCMetaChip("Estimated")
            }

            Spacer()

            Text("\(resolved.yardage) yds")
                .font(JournalTheme.handwrittenBold(size: 16))
                .foregroundStyle(GTCColor.primary)
        }
        .gtcNeutralCard(fill: GTCColor.surface)
    }
}

struct BagSetupCompleteStepView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: JournalTheme.sectionSpacing) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(GTCColor.primary)

            Text("Your bag is ready!")
                .font(JournalTheme.sheetTitleFont)
                .foregroundStyle(GTCColor.primary)

            Text("Head to the Range to Dial In Your Yardages")
                .font(JournalTheme.handwritten(size: 18))
                .foregroundStyle(GTCColor.text)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Done") { onDone() }
                .gtcProminentActionButtonStyle()
                .padding(.bottom, JournalTheme.sectionSpacing)
        }
        .padding(.horizontal, JournalTheme.screenHorizontalPadding)
    }
}
