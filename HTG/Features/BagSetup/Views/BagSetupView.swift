import SwiftUI
import SwiftData

struct BagSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var manager: BagSetupManager?

    var body: some View {
        NavigationStack {
            ZStack {
                GTCColor.background.ignoresSafeArea()

                if let manager {
                    wizardContent(manager: manager)
                }
            }
            .navigationTitle("Initial Bag Set Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                if manager == nil {
                    manager = BagSetupManager(modelContext: modelContext)
                }
            }
            .alert("Error", isPresented: errorBinding) {
                Button("OK") { manager?.errorMessage = nil }
            } message: {
                Text(manager?.errorMessage ?? "")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { manager?.errorMessage != nil },
            set: { if !$0 { manager?.errorMessage = nil } }
        )
    }

    private func wizardContent(manager: BagSetupManager) -> some View {
        VStack(spacing: JournalTheme.sectionSpacing) {
            if manager.step != .complete {
                BagSetupHeaderView(manager: manager)
                    .padding(.horizontal, JournalTheme.screenHorizontalPadding)
                    .padding(.top, 8)
            }

            stepContent(manager: manager)
        }
    }

    @ViewBuilder
    private func stepContent(manager: BagSetupManager) -> some View {
        switch manager.step {
        case .woods, .hybrids, .irons, .wedges:
            BagSetupSelectionStepView(manager: manager)
        case .arrange:
            BagSetupArrangeStepView(manager: manager)
        case .yardages:
            BagSetupYardageStepView(manager: manager)
        case .estimating:
            BagSetupEstimatingStepView(manager: manager)
        case .complete:
            BagSetupCompleteStepView { dismiss() }
        }
    }
}

struct BagSetupHeaderView: View {
    let manager: BagSetupManager

    var body: some View {
        HStack {
            Button {
                manager.goBack()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .tint(GTCColor.primary)
            .disabled(!manager.canGoBack)
            .accessibilityIdentifier("bagSetupBackButton")

            Spacer()

            Text("\(manager.selectedCount)/\(ClubDataService.maximumClubs)")
                .font(JournalTheme.handwrittenBold(size: 18))
                .foregroundStyle(GTCColor.primary)

            Spacer()

            Button {
                Task { await manager.advance() }
            } label: {
                Group {
                    if manager.isSaving {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.title3.weight(.semibold))
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .tint(GTCColor.primary)
            .disabled(!manager.canAdvance)
            .accessibilityIdentifier("bagSetupNextButton")
        }
    }
}

#Preview {
    BagSetupView()
        .modelContainer(for: [Club.self, ShotType.self, SyncTombstone.self], inMemory: true)
}
