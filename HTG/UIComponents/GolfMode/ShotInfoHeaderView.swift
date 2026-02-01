import SwiftUI

struct ShotInfoHeaderView: View {
    let carryDistance: Int
    let clubName: String
    let shotTypeName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(carryDistance)")
                .font(JournalTheme.handwrittenBold(size: 24))
                .foregroundStyle(JournalTheme.inkBlue)

            Text(clubName)
                .font(JournalTheme.handwrittenBold(size: 24))
                .foregroundStyle(JournalTheme.inkBlue)

            Text(shotTypeName)
                .font(JournalTheme.handwritten(size: 18))
                .foregroundStyle(JournalTheme.mutedGray)
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
    .agedPaperBackground()
}
