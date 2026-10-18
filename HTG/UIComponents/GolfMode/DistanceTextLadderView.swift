import SwiftUI

/// Vertical scrolling text ladder. Unit-agnostic: golf uses yards, putting will use feet.
struct DistanceTextLadderView: View {
    let ladder: DistanceTextLadder
    let unit: DistanceUnit
    var recenterGeneration: Int = 0
    var onSelectRow: ((DistanceTextLadderRow) -> Void)?

    @State private var hasCenteredOnce = false

    private struct ScrollKey: Hashable {
        let anchorRowID: String?
        let recenterGeneration: Int
    }

    private var scrollKey: ScrollKey {
        ScrollKey(anchorRowID: ladder.anchorRowID, recenterGeneration: recenterGeneration)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                if ladder.rows.isEmpty { emptyState } else { rowStack }
            }
            .scrollIndicators(.visible)
            .task(id: scrollKey) { await recenter(proxy) }
        }
        .background(
            RoundedRectangle(cornerRadius: JournalTheme.cardCornerRadius)
                .fill(GTCColor.background)
                .overlay(
                    RoundedRectangle(cornerRadius: JournalTheme.cardCornerRadius)
                        .stroke(GTCColor.border, lineWidth: 1)
                )
        )
    }

    private var rowStack: some View {
        VStack(spacing: 2) {
            ForEach(Array(ladder.rows.enumerated()), id: \.element.id) { index, row in
                if ladder.targetMarkerInsertionIndex == index { targetMarker }
                DistanceTextLadderRowView(row: row, unit: unit) { onSelectRow?(row) }
                    .id(row.id)
            }
            if ladder.targetMarkerInsertionIndex == ladder.rows.count { targetMarker }
        }
        .padding(8)
    }

    private var targetMarker: some View {
        DistanceTextLadderTargetMarkerView(distance: ladder.targetDistance, unit: unit)
            .padding(.vertical, 4)
    }

    private var emptyState: some View {
        Text("No distances yet")
            .font(JournalTheme.handwritten(size: 14))
            .foregroundStyle(GTCColor.secondary)
            .frame(maxWidth: .infinity)
            .padding(20)
    }

    private func recenter(_ proxy: ScrollViewProxy) async {
        guard let anchorID = ladder.anchorRowID else { return }
        await Task.yield()
        if hasCenteredOnce {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(anchorID, anchor: .center)
            }
        } else {
            proxy.scrollTo(anchorID, anchor: .center)
            hasCenteredOnce = true
        }
    }
}

#Preview("Feet") {
    DistanceTextLadderView(
        ladder: DistanceTextLadderService.ladder(
            items: [3, 6, 10, 15].map {
                DistanceTextLadderItem(id: "\($0)", distance: $0, primaryLabel: "Position \($0)", secondaryLabel: "")
            },
            targetDistance: 8,
            selectedItemID: "10"
        ),
        unit: .feet
    )
    .frame(height: 300)
    .padding()
}
