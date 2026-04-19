import SwiftUI

struct MantraView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(JournalTheme.handwritten(size: 18))
            .italic()
            .foregroundStyle(GTCColor.mantraSupportingText)
    }
}
