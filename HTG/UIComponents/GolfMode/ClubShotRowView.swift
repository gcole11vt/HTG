import SwiftUI

struct ClubShotRowView: View {
    let clubNickname: String
    let shotTypeName: String
    let carryDistance: Int
    let targetYardage: Int
    var isHighlighted: Bool = false
    var isBordered: Bool = false

    private var differential: Int {
        carryDistance - targetYardage
    }

    private var differentialText: String {
        if differential >= 0 {
            return "+\(differential)"
        } else {
            return "\(differential)"
        }
    }

    private var differentialColor: Color {
        differential >= 0 ? JournalTheme.targetGreen : JournalTheme.redMarker
    }

    var body: some View {
        HStack {
            Text(clubNickname)
                .font(JournalTheme.handwrittenBold(size: 16))
                .foregroundStyle(JournalTheme.inkBlue)

            Text(shotTypeName)
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(JournalTheme.mutedGray)

            Spacer()

            Text(differentialText)
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(differentialColor)

            Text("\(carryDistance)")
                .font(JournalTheme.handwrittenBold(size: 16))
                .foregroundStyle(JournalTheme.inkBlue)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isHighlighted ? JournalTheme.paperDark : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isBordered ? JournalTheme.inkBlue : Color.clear, lineWidth: 1.5)
        )
    }
}

#Preview {
    VStack(spacing: 8) {
        ClubShotRowView(
            clubNickname: "7I",
            shotTypeName: "Full",
            carryDistance: 155,
            targetYardage: 150,
            isHighlighted: false,
            isBordered: true
        )
        ClubShotRowView(
            clubNickname: "8I",
            shotTypeName: "Full",
            carryDistance: 145,
            targetYardage: 150,
            isHighlighted: true,
            isBordered: false
        )
        ClubShotRowView(
            clubNickname: "PW",
            shotTypeName: "3/4",
            carryDistance: 120,
            targetYardage: 150
        )
    }
    .padding()
    .agedPaperBackground()
}
