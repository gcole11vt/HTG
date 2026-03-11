import SwiftUI

struct SwingThoughtsView: View {
    let thoughts: [SwingThought]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Swing Thoughts")
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(JournalTheme.mutedGray)

            ForEach(thoughts) { thought in
                HStack(alignment: .top, spacing: 4) {
                    Text("\u{2022}")
                    Text(thought.text)
                }
                .font(JournalTheme.handwritten(size: 16))
                .foregroundStyle(JournalTheme.inkBlue.opacity(0.7))
            }
        }
    }
}
