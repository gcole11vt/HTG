import SwiftUI

struct BagSetupSelectionStepView: View {
    let manager: BagSetupManager

    var body: some View {
        VStack(alignment: .leading, spacing: JournalTheme.sectionSpacing) {
            if let category = manager.currentCategory {
                stepTitle(category.title)

                if manager.isBagFull {
                    bagFullHint
                }

                optionList(for: category)
            }
        }
        .padding(.horizontal, JournalTheme.screenHorizontalPadding)
    }

    private func stepTitle(_ title: String) -> some View {
        Text(title)
            .font(JournalTheme.sheetTitleFont)
            .foregroundStyle(GTCColor.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bagFullHint: some View {
        Text("Your bag is full — unselect a club to add a different one.")
            .font(JournalTheme.handwritten(size: 14))
            .foregroundStyle(GTCColor.warning)
    }

    private func optionList(for category: BagSetupClubCategory) -> some View {
        ScrollView {
            VStack(spacing: JournalTheme.subsectionSpacing) {
                ForEach(category.options) { option in
                    optionRow(option)
                }
            }
            .padding(.bottom, JournalTheme.sectionSpacing)
        }
    }

    private func optionRow(_ option: BagSetupClubOption) -> some View {
        let isSelected = manager.isSelected(option.name)
        let isBlocked = !isSelected && manager.isBagFull

        return Button {
            manager.toggle(option.name)
        } label: {
            HStack {
                Text(option.name)
                    .font(JournalTheme.handwritten(size: 16))
                    .foregroundStyle(GTCColor.text)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? GTCColor.primary : GTCColor.border)
            }
            .contentShape(Rectangle())
            .gtcNeutralCard(fill: isSelected ? GTCColor.primary.opacity(0.08) : GTCColor.surface)
        }
        .buttonStyle(.plain)
        .opacity(isBlocked ? 0.4 : 1)
        .disabled(isBlocked)
    }
}
