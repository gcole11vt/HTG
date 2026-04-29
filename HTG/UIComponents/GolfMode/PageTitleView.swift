import SwiftUI

struct PageTitleView: View {
    var body: some View {
        Text("Decide the Shot!")
            .font(.system(size: 26, weight: .semibold, design: .serif))
            .foregroundStyle(GTCColor.primary)
    }
}

#Preview {
    PageTitleView()
        .padding()
}
