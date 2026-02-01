import SwiftUI

struct TargetYardageBarView: View {
    var body: some View {
        Rectangle()
            .fill(JournalTheme.targetGreen)
            .frame(height: 3)
    }
}

#Preview {
    TargetYardageBarView()
        .padding()
        .agedPaperBackground()
}
