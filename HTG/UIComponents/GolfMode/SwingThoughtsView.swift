import SwiftUI

struct SwingThoughtsView: View {
    let thoughts: [SwingThought]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GTCSectionEyebrow("Swing Thoughts")

            ForEach(thoughts) { thought in
                HStack(alignment: .top, spacing: 4) {
                    Text("\u{2022}")
                        .foregroundStyle(GTCColor.accent)
                    Text(thought.text)
                }
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(GTCColor.text)
            }
        }
    }
}
