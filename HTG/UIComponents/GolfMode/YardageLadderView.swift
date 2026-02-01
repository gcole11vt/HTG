import SwiftUI

struct YardageLadderView: View {
    let targetYardage: Int
    let minYardage: Int
    let maxYardage: Int
    let entries: [LadderEntry]
    var onSelectEntry: ((LadderEntry) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                // Tick marks (absolutely positioned using same Y-mapping as club markers)
                ForEach(tickMarks, id: \.yardage) { tick in
                    LadderTickMarkView(
                        yardage: tick.yardage,
                        isTarget: tick.isTarget,
                        isMajor: tick.isMajor
                    )
                    .position(
                        x: geometry.size.width - 25,
                        y: yPosition(for: tick.yardage, in: geometry.size.height)
                    )
                }

                // Club markers
                ForEach(entries) { entry in
                    LadderClubMarkerView(entry: entry, onSelect: onSelectEntry)
                        .position(
                            x: geometry.size.width - 80,
                            y: yPosition(for: entry.carryDistance, in: geometry.size.height)
                        )
                }
            }
        }
    }

    private var tickMarks: [TickMark] {
        var marks: [TickMark] = []
        // Generate tick marks every 5 yards
        let start = (minYardage / 5) * 5
        let end = ((maxYardage / 5) + 1) * 5

        for yardage in stride(from: end, through: start, by: -5) {
            if yardage >= minYardage && yardage <= maxYardage {
                marks.append(TickMark(
                    yardage: yardage,
                    isTarget: yardage == targetYardage,
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

        // Invert because higher yardage should be at top
        let normalizedPosition = 1.0 - (Double(yardage - minYardage) / Double(range))
        return padding + CGFloat(normalizedPosition) * usableHeight
    }
}

private struct TickMark {
    let yardage: Int
    let isTarget: Bool
    let isMajor: Bool
}

#Preview {
    let entries = [
        LadderEntry(
            clubName: "6 Iron",
            shotTypeName: "Full",
            carryDistance: 165,
            yardagePosition: 0.7,
            isSelected: false,
            isSameClubAsSelected: false
        ),
        LadderEntry(
            clubName: "7 Iron",
            shotTypeName: "Full",
            carryDistance: 155,
            yardagePosition: 0.55,
            isSelected: true,
            isSameClubAsSelected: true
        ),
        LadderEntry(
            clubName: "7 Iron",
            shotTypeName: "3/4",
            carryDistance: 140,
            yardagePosition: 0.35,
            isSelected: false,
            isSameClubAsSelected: true
        ),
        LadderEntry(
            clubName: "8 Iron",
            shotTypeName: "Full",
            carryDistance: 145,
            yardagePosition: 0.4,
            isSelected: false,
            isSameClubAsSelected: false
        )
    ]

    return YardageLadderView(
        targetYardage: 150,
        minYardage: 127,
        maxYardage: 172,
        entries: entries
    ) { entry in
        print("Selected: \(entry.clubName)")
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .agedPaperBackground()
}
