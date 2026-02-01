import SwiftUI

struct LadderTickMarkView: View {
    let yardage: Int
    let isTarget: Bool
    let isMajor: Bool // Every 10 yards

    var body: some View {
        HStack(spacing: 4) {
            if isMajor {
                Text("\(yardage)")
                    .font(JournalTheme.ladderFont)
                    .foregroundStyle(isTarget ? JournalTheme.redMarker : JournalTheme.inkBlue)
                    .frame(width: 30, alignment: .trailing)
            } else {
                Spacer()
                    .frame(width: 30)
            }

            // Tick mark
            Rectangle()
                .fill(isTarget ? JournalTheme.redMarker : JournalTheme.inkBlue.opacity(0.5))
                .frame(width: isMajor ? 12 : 6, height: isTarget ? 2 : 1)

            if isTarget {
                Image(systemName: "arrowtriangle.left.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(JournalTheme.redMarker)
            }
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        LadderTickMarkView(yardage: 160, isTarget: false, isMajor: true)
        LadderTickMarkView(yardage: 155, isTarget: false, isMajor: false)
        LadderTickMarkView(yardage: 150, isTarget: true, isMajor: true)
        LadderTickMarkView(yardage: 145, isTarget: false, isMajor: false)
        LadderTickMarkView(yardage: 140, isTarget: false, isMajor: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .agedPaperBackground()
}
