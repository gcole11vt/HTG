import SwiftUI

struct YardageDisplayView: View {
    @Binding var yardage: Int
    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        Button {
            editText = ""
            isEditing = true
        } label: {
            Text("\(yardage)")
                .font(JournalTheme.yardageFont)
                .foregroundStyle(JournalTheme.inkBlue)
                .contentTransition(.numericText())
        }
        .buttonStyle(.plain)
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
                    .foregroundStyle(JournalTheme.inkBlue)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isTextFieldFocused)
                    .frame(width: 160)

                Image(systemName: "mic.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(JournalTheme.mutedGray)

                Spacer()
            }

            Spacer()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Go") {
                    if let newYardage = Int(editText), newYardage > 0 {
                        yardage = newYardage
                    }
                    isEditing = false
                }
                .foregroundStyle(JournalTheme.redMarker)
                .fontWeight(.semibold)
            }
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
        .onAppear {
            isTextFieldFocused = true
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
