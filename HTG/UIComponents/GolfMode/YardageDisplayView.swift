import SwiftUI

struct YardageDisplayView: View {
    @Binding var yardage: Int
    @State private var isEditing = false
    @State private var editText = ""

    var body: some View {
        Button {
            editText = "\(yardage)"
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
        NavigationStack {
            VStack(spacing: 24) {
                Text("Target Yardage")
                    .font(JournalTheme.handwrittenBold(size: 24))
                    .foregroundStyle(JournalTheme.inkBlue)

                TextField("", text: $editText)
                    .font(JournalTheme.yardageFont)
                    .foregroundStyle(JournalTheme.inkBlue)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(width: 200)

                Spacer()
            }
            .padding(.top, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .agedPaperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isEditing = false
                    }
                    .foregroundStyle(JournalTheme.inkBlue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if let newYardage = Int(editText), newYardage > 0 {
                            yardage = newYardage
                        }
                        isEditing = false
                    }
                    .foregroundStyle(JournalTheme.redMarker)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
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
            .agedPaperBackground()
        }
    }
    return PreviewWrapper()
}
