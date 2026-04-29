import SwiftUI

struct YardageDisplayView: View {
    @Binding var yardage: Int
    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isTextFieldFocused: Bool
    private let minYardage = 50
    private let maxYardage = 400

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Button {
                    editText = ""
                    isEditing = true
                } label: {
                    Text("\(yardage)")
                        .font(JournalTheme.yardageFont)
                        .foregroundStyle(GTCColor.primary)
                        .contentTransition(.numericText())
                }
                .buttonStyle(.plain)

                Text("yards")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(GTCColor.secondary)

                Spacer(minLength: 8)

                HStack(spacing: 6) {
                    yardageStepButton(symbol: "minus") {
                        yardage = max(minYardage, yardage - 1)
                    }
                    yardageStepButton(symbol: "plus") {
                        yardage = min(maxYardage, yardage + 1)
                    }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            yardageEditSheet
        }
    }

    private var yardageEditSheet: some View {
        VStack(spacing: 16) {
            Spacer()

            HStack(spacing: 12) {
                Spacer()

                TextField("", text: $editText)
                    .font(JournalTheme.yardageFont)
                    .foregroundStyle(GTCColor.primary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isTextFieldFocused)
                    .frame(width: 160)

                Spacer()
            }

            Button {
                if let newYardage = Int(editText), newYardage > 0 {
                    yardage = min(max(newYardage, minYardage), maxYardage)
                }
                isEditing = false
            } label: {
                Text("Go")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(GTCColor.warning)
            .padding(.horizontal, 40)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isTextFieldFocused = false
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func yardageStepButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(GTCColor.primary)
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
