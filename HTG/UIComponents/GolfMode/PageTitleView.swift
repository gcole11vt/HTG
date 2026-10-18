import SwiftUI

struct PageTitleView: View {
    var title: String = "Decide the Shot!"

    var body: some View {
        Text(title)
            .font(JournalTheme.pageTitleFont)
            .foregroundStyle(GTCColor.primary)
    }
}

#Preview {
    PageTitleView()
        .padding()
}
