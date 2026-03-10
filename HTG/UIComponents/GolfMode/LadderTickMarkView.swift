import SwiftUI

struct LadderTickMarkView: View {
    let yardage: Int
    let isMajor: Bool
    var isTarget: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            if isMajor {
                Text("\(yardage)")
                    .font(JournalTheme.ladderFont)
                    .foregroundStyle(isTarget ? JournalTheme.targetGreen : JournalTheme.inkBlue)
                    .frame(width: 30, alignment: .trailing)
            } else {
                Spacer()
                    .frame(width: 30)
            }

            Rectangle()
                .fill(isTarget ? JournalTheme.targetGreen : JournalTheme.inkBlue.opacity(0.5))
                .frame(width: isTarget || isMajor ? 12 : 6, height: isTarget ? 3 : 1)
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        LadderTickMarkView(yardage: 160, isMajor: true)
        LadderTickMarkView(yardage: 155, isMajor: false)
        LadderTickMarkView(yardage: 150, isMajor: true, isTarget: true)
        LadderTickMarkView(yardage: 145, isMajor: false)
        LadderTickMarkView(yardage: 140, isMajor: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
