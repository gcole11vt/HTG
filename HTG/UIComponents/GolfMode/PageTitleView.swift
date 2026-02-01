import SwiftUI

struct PageTitleView: View {
    var body: some View {
        Text("Decide the Shot!")
            .font(JournalTheme.handwrittenBold(size: 22))
            .foregroundStyle(JournalTheme.inkBlue)
    }
}

#Preview {
    PageTitleView()
        .padding()
        .agedPaperBackground()
}
