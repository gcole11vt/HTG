import SwiftUI

struct PreShotRoutineView: View {
    let items: [PreShotRoutineItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pre-Shot Routine")
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(JournalTheme.mutedGray)

            let sorted = items.sorted { $0.sortOrder < $1.sortOrder }
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, item in
                Text("\(index + 1). \(item.text)")
                    .font(JournalTheme.handwritten(size: 16))
                    .foregroundStyle(JournalTheme.inkBlue.opacity(0.7))
            }
        }
    }
}
