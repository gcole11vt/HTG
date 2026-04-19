import SwiftUI

struct ShotInfoHeaderView: View {
    let carryDistance: Int
    let clubName: String
    let shotTypeName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(carryDistance)")
                .font(JournalTheme.handwritten(size: 24))
                .foregroundStyle(GTCColor.primary)

            Text(clubName)
                .font(JournalTheme.handwritten(size: 24))
                .foregroundStyle(GTCColor.primary)

            Text(shotTypeName)
                .font(JournalTheme.handwritten(size: 18))
                .foregroundStyle(GTCColor.border)
        }
    }
}

#Preview {
    ShotInfoHeaderView(
        carryDistance: 150,
        clubName: "7 Iron",
        shotTypeName: "Full"
    )
    .padding()
}
