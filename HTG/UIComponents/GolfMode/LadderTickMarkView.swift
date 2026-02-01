import SwiftUI

struct LadderTickMarkView: View {
    let yardage: Int
    let isMajor: Bool

    var body: some View {
        HStack(spacing: 4) {
            if isMajor {
                Text("\(yardage)")
                    .font(JournalTheme.ladderFont)
                    .foregroundStyle(JournalTheme.inkBlue)
                    .frame(width: 30, alignment: .trailing)
            } else {
                Spacer()
                    .frame(width: 30)
            }

            Rectangle()
                .fill(JournalTheme.inkBlue.opacity(0.5))
                .frame(width: isMajor ? 12 : 6, height: 1)
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        LadderTickMarkView(yardage: 160, isMajor: true)
        LadderTickMarkView(yardage: 155, isMajor: false)
        LadderTickMarkView(yardage: 150, isMajor: true)
        LadderTickMarkView(yardage: 145, isMajor: false)
        LadderTickMarkView(yardage: 140, isMajor: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .agedPaperBackground()
}
