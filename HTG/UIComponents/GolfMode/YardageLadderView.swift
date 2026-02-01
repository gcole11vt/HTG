import SwiftUI

struct YardageLadderView: View {
    let targetYardage: Int
    let minYardage: Int
    let maxYardage: Int
    let groupedEntries: [GroupedLadderEntry]
    var onSelectEntry: ((LadderEntry) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                // Tick marks
                ForEach(tickMarks, id: \.yardage) { tick in
                    LadderTickMarkView(
                        yardage: tick.yardage,
                        isMajor: tick.isMajor
                    )
                    .position(
                        x: geometry.size.width - 25,
                        y: yPosition(for: tick.yardage, in: geometry.size.height)
                    )
                }

                // Green target bar — same width as a major (10yd) tick mark
                TargetYardageBarView()
                    .frame(width: 12)
                    .position(
                        x: geometry.size.width - 25,
                        y: yPosition(for: targetYardage, in: geometry.size.height)
                    )

                // Grouped club markers
                ForEach(groupedEntries) { group in
                    GroupedLadderClubMarkerView(group: group, onSelect: onSelectEntry)
                        .position(
                            x: geometry.size.width - 80,
                            y: yPosition(for: group.carryDistance, in: geometry.size.height)
                        )
                }
            }
        }
    }

    private var tickMarks: [TickMark] {
        var marks: [TickMark] = []
        let start = (minYardage / 5) * 5
        let end = ((maxYardage / 5) + 1) * 5

        for yardage in stride(from: end, through: start, by: -5) {
            if yardage >= minYardage && yardage <= maxYardage {
                marks.append(TickMark(
                    yardage: yardage,
                    isMajor: yardage % 10 == 0
                ))
            }
        }
        return marks
    }

    private func yPosition(for yardage: Int, in height: CGFloat) -> CGFloat {
        let range = maxYardage - minYardage
        guard range > 0 else { return height / 2 }

        let padding: CGFloat = 20
        let usableHeight = height - (padding * 2)

        let normalizedPosition = 1.0 - (Double(yardage - minYardage) / Double(range))
        return padding + CGFloat(normalizedPosition) * usableHeight
    }
}

private struct TickMark {
    let yardage: Int
    let isMajor: Bool
}

#Preview {
    let entries = [
        GroupedLadderEntry(
            carryDistance: 165,
            entries: [
                LadderEntry(clubName: "6 Iron", clubNickname: "6I", shotTypeName: "Full", carryDistance: 165, yardagePosition: 0.7, isSelected: false, isSameClubAsSelected: false, isPrimaryShotType: true)
            ]
        ),
        GroupedLadderEntry(
            carryDistance: 155,
            entries: [
                LadderEntry(clubName: "7 Iron", clubNickname: "7I", shotTypeName: "Full", carryDistance: 155, yardagePosition: 0.55, isSelected: true, isSameClubAsSelected: true, isPrimaryShotType: true)
            ]
        ),
        GroupedLadderEntry(
            carryDistance: 145,
            entries: [
                LadderEntry(clubName: "8 Iron", clubNickname: "8I", shotTypeName: "Full", carryDistance: 145, yardagePosition: 0.4, isSelected: false, isSameClubAsSelected: false, isPrimaryShotType: true)
            ]
        ),
        GroupedLadderEntry(
            carryDistance: 140,
            entries: [
                LadderEntry(clubName: "7 Iron", clubNickname: "7I", shotTypeName: "3/4", carryDistance: 140, yardagePosition: 0.35, isSelected: false, isSameClubAsSelected: true, isPrimaryShotType: false)
            ]
        )
    ]

    return YardageLadderView(
        targetYardage: 153,
        minYardage: 127,
        maxYardage: 172,
        groupedEntries: entries
    ) { entry in
        print("Selected: \(entry.clubName)")
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .agedPaperBackground()
}
