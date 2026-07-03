import SwiftUI

struct MantraView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GTCSectionEyebrow("Mantra")

            Text("\"\(text)\"")
                .font(.system(size: 18, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(GTCColor.primary)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
        }
    }
}
