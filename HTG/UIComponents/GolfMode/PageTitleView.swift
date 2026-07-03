import SwiftUI

struct PageTitleView: View {
    var body: some View {
        Text("Decide the Shot!")
            .font(JournalTheme.pageTitleFont)
            .foregroundStyle(GTCColor.primary)
    }
}

#Preview {
    PageTitleView()
        .padding()
}
