import SwiftUI

struct MantraView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mantra")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GTCColor.secondary)
                .textCase(.uppercase)

            Text("\"\(text)\"")
                .font(.system(size: 18, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(GTCColor.primary)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
        }
    }
}
