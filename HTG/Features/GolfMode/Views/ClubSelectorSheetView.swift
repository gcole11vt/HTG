import SwiftUI

struct ClubSelectorSheetView: View {
    let targetYardage: Int
    let clubs: [Club]
    let currentSelection: SelectedClubShot?
    let allShotTypeNames: [String]
    let onConfirm: (SelectedClubShot) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedClubName: String
    @State private var pendingSelection: SelectedClubShot?
    @State private var activeShotTypeFilters: Set<String>

    init(
        targetYardage: Int,
        clubs: [Club],
        currentSelection: SelectedClubShot?,
        allShotTypeNames: [String],
        onConfirm: @escaping (SelectedClubShot) -> Void
    ) {
        self.targetYardage = targetYardage
        self.clubs = clubs
        self.currentSelection = currentSelection
        self.allShotTypeNames = allShotTypeNames
        self.onConfirm = onConfirm
        self._selectedClubName = State(initialValue: currentSelection?.clubName ?? "")
        self._activeShotTypeFilters = State(initialValue: Set(allShotTypeNames))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                targetHeader
                panelContent
                selectButton
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(JournalTheme.handwritten(size: 16))
                    .foregroundStyle(JournalTheme.mutedGray)
                }
            }
            .agedPaperBackground()
            .presentationDetents([.large])
        }
    }

    private var targetHeader: some View {
        VStack(spacing: 2) {
            Text("Target")
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(JournalTheme.mutedGray)
            Text("\(targetYardage)")
                .font(JournalTheme.handwrittenBold(size: 36))
                .foregroundStyle(JournalTheme.inkBlue)
        }
    }

    private var panelContent: some View {
        HStack(alignment: .top, spacing: 12) {
            ClubDetailPanelView(
                clubs: clubs,
                targetYardage: targetYardage,
                currentSelection: currentSelection,
                selectedClubName: $selectedClubName,
                pendingSelection: $pendingSelection
            )
            .frame(maxWidth: .infinity)

            Divider()

            AllShotsOverviewPanelView(
                clubs: clubs,
                targetYardage: targetYardage,
                currentSelection: currentSelection,
                allShotTypeNames: allShotTypeNames,
                activeShotTypeFilters: $activeShotTypeFilters,
                pendingSelection: $pendingSelection
            )
            .frame(maxWidth: .infinity)
        }
    }

    private var selectButton: some View {
        Button {
            if let selection = pendingSelection {
                onConfirm(selection)
                dismiss()
            }
        } label: {
            Text("Select")
                .font(JournalTheme.handwrittenBold(size: 18))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(pendingSelection != nil ? JournalTheme.inkBlue : JournalTheme.mutedGray)
                )
        }
        .disabled(pendingSelection == nil)
    }
}
