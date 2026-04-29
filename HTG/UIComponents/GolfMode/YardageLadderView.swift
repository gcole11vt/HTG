import SwiftUI

struct YardageLadderView: View {
    let targetYardage: Int
    let minYardage: Int
    let maxYardage: Int
    let groupedEntries: [GroupedLadderEntry]
    var onSelectEntry: ((LadderEntry) -> Void)?
    private let columnSpacing: CGFloat = 8
    private let estimatedThreeDigitWidth: CGFloat = 22
    private let estimatedColumnPadding: CGFloat = 14
    private let barAreaHeight: CGFloat = 66

    var body: some View {
        ScrollViewReader { scrollProxy in
            GeometryReader { geometry in
                let columns = ladderColumns
                let labelAreaHeight = labelAreaHeight()
                let columnsPerScreen = maxColumns(for: geometry.size.width)
                let baseColumnWidth = max(
                    estimatedThreeDigitWidth + estimatedColumnPadding,
                    (geometry.size.width - columnSpacing * CGFloat(max(columnsPerScreen - 1, 0))) / CGFloat(columnsPerScreen)
                )
                let targetColumnID = centeredTargetColumnID(from: columns)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: columnSpacing) {
                        ForEach(columns) { column in
                            VStack(spacing: 4) {
                                Button {
                                    onSelectEntry?(column.entry)
                                } label: {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(barColor(for: column.entry))
                                        .frame(width: barWidth(for: column.entry), height: barHeight(for: column.carryDistance))
                                        .frame(maxHeight: .infinity, alignment: .bottom)
                                        .frame(height: barAreaHeight, alignment: .bottom)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .overlay(alignment: .center) {
                                    if column.id == targetColumnID {
                                        Path { path in
                                            let centerX = barWidth(for: column.entry) / 2
                                            path.move(to: CGPoint(x: centerX, y: 0))
                                            path.addLine(to: CGPoint(x: centerX, y: barAreaHeight - 2))
                                        }
                                        .stroke(
                                            GTCColor.accent,
                                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                                        )
                                    }
                                }

                                comboRow(for: column.entry, carryDistance: column.carryDistance)
                                    .frame(height: labelAreaHeight, alignment: .top)
                            }
                            .frame(width: baseColumnWidth, alignment: .bottom)
                            .id(column.id)
                        }
                    }
                }
                .onAppear {
                    centerLadder(on: targetColumnID, with: scrollProxy)
                }
                .onChange(of: targetYardage) { _, _ in
                    let updatedTargetID = centeredTargetColumnID(from: ladderColumns)
                    centerLadder(on: updatedTargetID, with: scrollProxy)
                }
                .onChange(of: columns.map(\.id)) { _, _ in
                    let updatedTargetID = centeredTargetColumnID(from: ladderColumns)
                    centerLadder(on: updatedTargetID, with: scrollProxy)
                }
            }
            .frame(height: barAreaHeight + labelAreaHeight() + 12)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(GTCColor.surface)
        )
    }

    private var ladderColumns: [LadderColumn] {
        let sortedGroups = groupedEntries.sorted { $0.carryDistance < $1.carryDistance }
        var occurrence: [String: Int] = [:]
        var columns: [LadderColumn] = []

        for group in sortedGroups {
            let orderedEntries = group.entries.sorted {
                if $0.clubNickname == $1.clubNickname {
                    return $0.shotTypeName < $1.shotTypeName
                }
                return $0.clubNickname < $1.clubNickname
            }
            for entry in orderedEntries {
                let baseKey = "\(group.carryDistance)|\(entry.clubName)|\(entry.shotTypeName)"
                let index = occurrence[baseKey, default: 0]
                occurrence[baseKey] = index + 1
                let stableID = "\(baseKey)|\(index)"
                columns.append(
                    LadderColumn(
                        id: stableID,
                        carryDistance: group.carryDistance,
                        entry: entry
                    )
                )
            }
        }
        return columns
    }

    private func barWidth(for entry: LadderEntry) -> CGFloat {
        entry.carryDistance == targetYardage ? 10 : 8
    }

    private func barHeight(for carryDistance: Int) -> CGFloat {
        let range = max(maxYardage - minYardage, 1)
        let clamped = min(max(carryDistance, minYardage), maxYardage)
        let normalized = CGFloat(clamped - minYardage) / CGFloat(range)
        return max(18, 20 + normalized * 38)
    }

    private func barColor(for entry: LadderEntry) -> Color {
        if entry.isSelected {
            return GTCColor.primary
        }
        return GTCColor.secondary.opacity(0.35)
    }

    private func maxColumns(for width: CGFloat) -> Int {
        let minColumnWidth = estimatedThreeDigitWidth + estimatedColumnPadding
        let raw = (width + columnSpacing) / (minColumnWidth + columnSpacing)
        return max(1, Int(raw.rounded(.down)))
    }

    private func labelAreaHeight() -> CGFloat {
        let comboLineHeight: CGFloat = 14
        let row3Height: CGFloat = 12
        return comboLineHeight + row3Height + 8
    }

    @ViewBuilder
    private func comboRow(for entry: LadderEntry, carryDistance: Int) -> some View {
        VStack(spacing: 2) {
            Button {
                onSelectEntry?(entry)
            } label: {
                Text("\(entry.clubNickname) \(entry.shotTypeName)")
                    .font(.system(size: 9, weight: entry.isSelected ? .semibold : .regular))
                    .foregroundStyle(entry.isSelected ? GTCColor.primary : GTCColor.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                onSelectEntry?(entry)
            } label: {
                Text("\(carryDistance)")
                    .font(.system(size: 9, weight: carryDistance == targetYardage ? .semibold : .regular))
                    .foregroundStyle(carryDistance == targetYardage ? GTCColor.primary : GTCColor.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.plain)
        }
    }

    private func centeredTargetColumnID(from columns: [LadderColumn]) -> String? {
        guard !columns.isEmpty else { return nil }

        let exact = columns.enumerated().filter { $0.element.carryDistance == targetYardage }
        if !exact.isEmpty {
            let middleIndex = exact.count / 2
            return exact[middleIndex].element.id
        }

        return columns.min(by: {
            abs($0.carryDistance - targetYardage) < abs($1.carryDistance - targetYardage)
        })?.id
    }

    private func centerLadder(on targetID: String?, with proxy: ScrollViewProxy) {
        guard let targetID else { return }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(targetID, anchor: .center)
            }
        }
    }

    private struct LadderColumn: Identifiable {
        let id: String
        let carryDistance: Int
        let entry: LadderEntry
    }
}

#Preview {
    let entries = [
        GroupedLadderEntry(
            carryDistance: 150,
            entries: [
                LadderEntry(clubName: "7 Iron", clubNickname: "7I", shotTypeName: "Full", carryDistance: 150, yardagePosition: 0.5, isSelected: true, isSameClubAsSelected: true, isPrimaryShotType: true),
                LadderEntry(clubName: "3 Wood", clubNickname: "3W", shotTypeName: "1/2", carryDistance: 150, yardagePosition: 0.5, isSelected: false, isSameClubAsSelected: false, isPrimaryShotType: false)
            ]
        ),
        GroupedLadderEntry(
            carryDistance: 145,
            entries: [
                LadderEntry(clubName: "8 Iron", clubNickname: "8I", shotTypeName: "Full", carryDistance: 145, yardagePosition: 0.4, isSelected: false, isSameClubAsSelected: false, isPrimaryShotType: true)
            ]
        ),
        GroupedLadderEntry(
            carryDistance: 160,
            entries: [
                LadderEntry(clubName: "6 Iron", clubNickname: "6I", shotTypeName: "Hard", carryDistance: 160, yardagePosition: 0.6, isSelected: false, isSameClubAsSelected: false, isPrimaryShotType: false)
            ]
        )
    ]

    return YardageLadderView(
        targetYardage: 150,
        minYardage: 127,
        maxYardage: 172,
        groupedEntries: entries
    ) { entry in
        print("Selected: \(entry.clubName) \(entry.shotTypeName)")
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
