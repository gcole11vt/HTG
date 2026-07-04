import SwiftUI

struct BagSetupYardageStepView: View {
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
            Text("Pre-fill any full yardages you know")
                .font(JournalTheme.sheetTitleFont)
                .foregroundStyle(GTCColor.primary)
            Text("Leave a club blank and we'll estimate it for you.")
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(GTCColor.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var yardageList: some View {
        ScrollView {
            VStack(spacing: JournalTheme.subsectionSpacing) {
                ForEach(manager.arrangedClubNames, id: \.self) { name in
                    yardageRow(for: name)
                }
            }
            .padding(.bottom, JournalTheme.sectionSpacing)
        }
    }

    private func yardageRow(for name: String) -> some View {
        HStack {
            Text(name)
                .font(JournalTheme.handwritten(size: 16))
                .foregroundStyle(GTCColor.text)
            Spacer()
            TextField("yds", text: yardageBinding(for: name))
                .font(JournalTheme.handwritten(size: 16))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .frame(width: JournalTheme.compactNumericInputWidth)
                .accessibilityIdentifier("yardageInput-\(name)")
        }
        .gtcNeutralCard(fill: GTCColor.surface)
    }

    private func yardageBinding(for name: String) -> Binding<String> {
        Binding(
            get: { manager.yardageInputs[name] ?? "" },
            set: { manager.yardageInputs[name] = $0 }
        )
    }
}
