import SwiftUI

/// Target yardage row. One tap on the number raises a blank number pad; Go submits, Cancel discards.
struct YardageDisplayView: View {
    @Binding var yardage: Int
    var onRefresh: (() -> Void)?
    @State private var entryText = ""
    @FocusState private var isEntryFocused: Bool
    @Environment(\.scenePhase) private var scenePhase
    private let validator = YardageEntryValidationService()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                yardageEntryField

                Text("yards")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(GTCColor.secondary)

                Spacer(minLength: 8)

                if isEntryFocused {
                    editingControls
                } else {
                    idleControls
                }
            }
            rangeHintCaption
                .opacity(isEntryFocused ? 1 : 0)
                .accessibilityHidden(!isEntryFocused)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { isEntryFocused = false }
        }
        .onDisappear { isEntryFocused = false }
    }

    private var yardageEntryField: some View {
        TextField(
            "",
            text: $entryText,
            prompt: Text("\(yardage)")
                .foregroundStyle(isEntryFocused ? GTCColor.border : GTCColor.primary)
        )
        .font(JournalTheme.yardageFont)
        .foregroundStyle(GTCColor.primary)
        .keyboardType(.numberPad)
        .focused($isEntryFocused)
        .fixedSize()
        .onChange(of: entryText) { _, newText in
            let sanitized = validator.sanitizedEntryText(newText)
            if sanitized != newText { entryText = sanitized }
        }
        .onChange(of: isEntryFocused) { _, focused in
            if !focused { entryText = "" }
        }
        .accessibilityLabel("Target yardage")
        .accessibilityHint("Double tap to type a new yardage")
    }

    private var idleControls: some View {
        HStack(spacing: 6) {
            if let onRefresh {
                yardageStepButton(symbol: "arrow.clockwise", action: onRefresh)
            }
            yardageStepButton(symbol: "minus") {
                yardage = max(YardageEntryValidationService.validRange.lowerBound, yardage - 1)
            }
            yardageStepButton(symbol: "plus") {
                yardage = min(YardageEntryValidationService.validRange.upperBound, yardage + 1)
            }
        }
    }

    private var editingControls: some View {
        let validYardage = validator.validatedYardage(from: entryText)
        return HStack(spacing: 6) {
            yardageStepButton(symbol: "xmark", label: "Cancel") {
                isEntryFocused = false
            }
            yardageStepButton(symbol: "checkmark", label: "Go", tint: GTCColor.warning) {
                guard let validYardage else { return }
                yardage = validYardage
                isEntryFocused = false
            }
            .disabled(validYardage == nil)
            .opacity(validYardage == nil ? 0.4 : 1)
        }
    }

    private var rangeHintCaption: some View {
        let range = YardageEntryValidationService.validRange
        return Text("\(range.lowerBound)\u{2013}\(range.upperBound) yards")
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(validator.isDefinitelyOutOfRange(entryText) ? GTCColor.warning : GTCColor.secondary)
    }

    private func yardageStepButton(
        symbol: String,
        label: String? = nil,
        tint: Color = GTCColor.primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(GTCColor.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GTCColor.border, lineWidth: 1)
                        )
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label ?? symbolAccessibilityLabel(symbol))
    }

    private func symbolAccessibilityLabel(_ symbol: String) -> String {
        switch symbol {
        case "minus": return "Decrease yardage"
        case "plus": return "Increase yardage"
        default: return "Refresh"
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var yardage = 150
        var body: some View {
            VStack {
                YardageDisplayView(yardage: $yardage)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    return PreviewWrapper()
}
