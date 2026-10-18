import SwiftUI

/// Mantra, pre-shot routine and swing thoughts stacked vertically for the narrow Text page column.
struct GolfModeFocusColumnView: View {
    let showMantra: Bool
    let mantraText: String
    let showPreShotRoutine: Bool
    let routineItems: [PreShotRoutineItem]
    let matchingSwingThoughts: [SwingThought]

    var hasContent: Bool {
        showMantra || showPreShotRoutine || !matchingSwingThoughts.isEmpty
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: JournalTheme.sectionSpacing) {
                if showMantra {
                    MantraView(text: mantraText)
                }
                if showPreShotRoutine {
                    PreShotRoutineView(items: routineItems)
                }
                if !matchingSwingThoughts.isEmpty {
                    SwingThoughtsView(thoughts: matchingSwingThoughts)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

#Preview {
    GolfModeFocusColumnView(
        showMantra: true,
        mantraText: "Smooth tempo",
        showPreShotRoutine: false,
        routineItems: [],
        matchingSwingThoughts: []
    )
    .padding()
}
