import SwiftUI
import SwiftData

/// Align Speed wizard: setup, one step per backswing position, then review and save.
struct AlignSpeedView: View {
    let initialPositionCount: Int
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var manager: AlignSpeedManager?
    @State private var isConfirmingCancel = false

    var body: some View {
        NavigationStack {
            ZStack {
                GTCColor.background.ignoresSafeArea()
                if let manager { wizardContent(manager: manager) }
            }
            .navigationTitle("Align Speed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancelTapped() }
                }
            }
            .task {
                createManagerIfNeeded()
                await manager?.loadPositionNames()
            }
            .onChange(of: manager?.didSave ?? false) { _, didSave in
                if didSave { onSaved(); dismiss() }
            }
            .alert("Error", isPresented: errorBinding) {
                Button("OK") { manager?.errorMessage = nil }
            } message: {
                Text(manager?.errorMessage ?? "")
            }
            .confirmationDialog("Discard this calibration?", isPresented: $isConfirmingCancel) {
                Button("Discard", role: .destructive) { discardAndDismiss() }
                Button("Keep Working", role: .cancel) {}
            }
        }
        .interactiveDismissDisabled(manager?.hasUnsavedPutts ?? false)
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { manager?.errorMessage != nil },
            set: { if !$0 { manager?.errorMessage = nil } }
        )
    }

    private func createManagerIfNeeded() {
        if manager == nil {
            manager = AlignSpeedManager(modelContext: modelContext, initialPositionCount: initialPositionCount)
        }
    }

    private func cancelTapped() {
        if manager?.hasUnsavedPutts == true {
            isConfirmingCancel = true
        } else {
            discardAndDismiss()
        }
    }

    private func discardAndDismiss() {
        manager?.cancel()
        dismiss()
    }

    private func wizardContent(manager: AlignSpeedManager) -> some View {
        VStack(spacing: JournalTheme.sectionSpacing) {
            AlignSpeedHeaderView(manager: manager)
                .padding(.horizontal, JournalTheme.screenHorizontalPadding)
                .padding(.top, 8)
            stepContent(manager: manager)
        }
    }

    @ViewBuilder
    private func stepContent(manager: AlignSpeedManager) -> some View {
        switch manager.step {
        case .setup: AlignSpeedSetupStepView(manager: manager)
        case .position: AlignSpeedPositionStepView(manager: manager)
        case .review: AlignSpeedReviewStepView(manager: manager)
        }
    }
}

struct AlignSpeedHeaderView: View {
    let manager: AlignSpeedManager

    var body: some View {
        HStack {
            arrowButton(systemName: "arrow.left", identifier: "alignSpeedBackButton", isEnabled: manager.canGoBack) {
                manager.goBack()
            }
            Spacer()
            Text(title)
                .font(JournalTheme.handwrittenBold(size: 18))
                .foregroundStyle(GTCColor.primary)
            Spacer()
            if manager.step == .review {
                Color.clear.frame(width: 44, height: 44)
            } else {
                arrowButton(systemName: "arrow.right", identifier: "alignSpeedNextButton", isEnabled: manager.canAdvance) {
                    Task { await manager.advance() }
                }
            }
        }
    }

    private var title: String {
        switch manager.step {
        case .setup: "Set Up"
        case .position(let position): "Position \(position) of \(manager.positionCount)"
        case .review: "Review"
        }
    }

    private func arrowButton(
        systemName: String, identifier: String, isEnabled: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.weight(.semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .tint(GTCColor.primary)
        .disabled(!isEnabled)
        .accessibilityIdentifier(identifier)
    }
}

#Preview {
    AlignSpeedView(initialPositionCount: 5, onSaved: {})
        .modelContainer(for: [PuttingCalibration.self, PuttingCalibrationPutt.self, PuttingPositionName.self], inMemory: true)
}
