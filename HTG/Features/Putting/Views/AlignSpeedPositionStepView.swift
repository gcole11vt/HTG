import SwiftUI

/// Records one or more rolled putt distances (feet) for the current backswing position.
struct AlignSpeedPositionStepView: View {
    @Bindable var manager: AlignSpeedManager
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: JournalTheme.sectionSpacing) {
            heading
            entryRow
            puttChips
            summary
            Spacer()
        }
        .padding(.horizontal, JournalTheme.screenHorizontalPadding)
        .task(id: manager.step) {
            await Task.yield()
            isFieldFocused = true
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Position \(manager.currentPosition ?? 1)")
                .font(JournalTheme.sheetTitleFont)
                .foregroundStyle(GTCColor.primary)
            Text("Make this backswing and roll a putt. Enter how far it rolled. Add more putts to average them.")
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(GTCColor.secondary)
        }
    }

    private var entryRow: some View {
        HStack {
            TextField("0", text: entryBinding)
                .font(JournalTheme.handwritten(size: 20))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .frame(width: JournalTheme.compactNumericInputWidth)
                .focused($isFieldFocused)
                .accessibilityIdentifier("alignSpeedPuttField")
            Text("ft")
                .font(JournalTheme.handwritten(size: 16))
                .foregroundStyle(GTCColor.secondary)
            Button("Add") { addTapped() }
                .gtcProminentActionButtonStyle()
                .disabled(!manager.canAddPutt)
                .accessibilityIdentifier("alignSpeedAddButton")
        }
    }

    private var entryBinding: Binding<String> {
        Binding(
            get: { manager.puttEntryText },
            set: { manager.puttEntryText = YardageEntryValidationService(validRange: PuttingCalibrationRules.puttFeetRange).sanitizedEntryText($0) }
        )
    }

    private func addTapped() {
        manager.addPutt()
        isFieldFocused = true
    }

    private var puttChips: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(Array(manager.currentPutts.enumerated()), id: \.offset) { index, feet in
                Button { manager.removePutt(at: index) } label: {
                    GTCMetaChip("\(PuttingSpeedCurveService.formatFeet(feet)) \u{00D7}")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(PuttingSpeedCurveService.formatFeet(feet)) putt")
            }
        }
    }

    @ViewBuilder
    private var summary: some View {
        if let average = manager.currentAverage {
            let count = manager.currentPutts.count
            Text("Average \(PuttingSpeedCurveService.formatFeet(average)) \u{00B7} \(count) \(count == 1 ? "putt" : "putts")")
                .font(JournalTheme.handwrittenBold(size: 16))
                .foregroundStyle(GTCColor.primary)
        }
        if let warning = manager.currentWarning {
            Text(warning)
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(GTCColor.warning)
        }
    }
}
