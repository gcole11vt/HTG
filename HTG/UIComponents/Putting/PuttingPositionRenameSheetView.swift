import SwiftUI

/// What the rename sheet needs to open for one position.
struct PuttingPositionRenameRequest: Identifiable, Equatable {
    let position: Int
    let currentName: String
    let defaultName: String

    var id: Int { position }
}

/// Short sheet for renaming a backswing position. Blank input reverts to the default name.
struct PuttingPositionRenameSheetView: View {
    let request: PuttingPositionRenameRequest
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @FocusState private var isFieldFocused: Bool

    init(request: PuttingPositionRenameRequest, onSave: @escaping (String) -> Void) {
        self.request = request
        self.onSave = onSave
        _text = State(initialValue: request.currentName)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: JournalTheme.subsectionSpacing) {
                Text(request.defaultName)
                    .font(JournalTheme.handwritten(size: 14))
                    .foregroundStyle(GTCColor.secondary)
                nameField
                Text("Leave blank to use \(request.defaultName).")
                    .font(JournalTheme.handwritten(size: 14))
                    .foregroundStyle(GTCColor.secondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, JournalTheme.screenHorizontalPadding)
            .padding(.top, 8)
            .background(GTCColor.background.ignoresSafeArea())
            .navigationTitle("Rename Position")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .presentationDetents([.height(260)])
        .task {
            await Task.yield()
            isFieldFocused = true
        }
    }

    private var nameField: some View {
        TextField(request.defaultName, text: $text)
            .font(JournalTheme.handwritten(size: 20))
            .onChange(of: text) { _, newValue in
                let clamped = PuttingCalibrationDataService.clampedEntryText(newValue)
                if clamped != newValue { text = clamped }
            }
            .textFieldStyle(.roundedBorder)
            .submitLabel(.done)
            .focused($isFieldFocused)
            .onSubmit(saveTapped)
            .accessibilityIdentifier("positionRenameField")
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
                .accessibilityIdentifier("positionRenameCancelButton")
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save", action: saveTapped)
                .accessibilityIdentifier("positionRenameSaveButton")
        }
    }

    private func saveTapped() {
        onSave(text)
        dismiss()
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        PuttingPositionRenameSheetView(
            request: PuttingPositionRenameRequest(position: 3, currentName: "Position 3", defaultName: "Position 3"),
            onSave: { _ in }
        )
    }
}
