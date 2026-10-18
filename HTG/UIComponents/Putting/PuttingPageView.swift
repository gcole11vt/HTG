import SwiftUI

/// Putting page: distance entry, stroke suggestion and the Ladder or Text view of the calibrated curve.
struct PuttingPageView: View {
    @Binding var targetFeet: Int
    let viewStyle: DistanceViewStyle
    let suggestionTitle: String
    let suggestionDetail: String
    let statusText: String
    let isStatusStale: Bool
    let textLadder: DistanceTextLadder
    let groupedLadderEntries: [GroupedLadderEntry]
    let ladderMaxFeet: Int
    var recenterGeneration: Int = 0
    /// nil while the Align Speed wizard is not available; the button is then disabled.
    var onAlignSpeed: (() -> Void)?
    /// Called when the user taps a position name in the text ladder.
    var onSelectRowLabel: ((DistanceTextLadderRow) -> Void)?

    var body: some View {
        ZStack {
            GTCColor.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: JournalTheme.sectionSpacing) {
                PageTitleView(title: "Read the Green")
                    .padding(.top, 8)
                statusRow
                YardageDisplayView(yardage: $targetFeet, onRefresh: nil, configuration: .puttFeet)
                PuttStrokeSuggestionCardView(title: suggestionTitle, detail: suggestionDetail)
                curveView
            }
            .padding(.horizontal, JournalTheme.screenHorizontalPadding)
            .padding(.bottom, 12)
        }
        .ignoresSafeArea(.keyboard)
    }

    private var statusRow: some View {
        HStack {
            Text(statusText)
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(isStatusStale ? GTCColor.warning : GTCColor.secondary)
            Spacer()
            Button { onAlignSpeed?() } label: {
                Label("Align Speed", systemImage: "arrow.triangle.2.circlepath")
                    .font(JournalTheme.handwritten(size: 14))
            }
            .tint(GTCColor.primary)
            .disabled(onAlignSpeed == nil)
        }
    }

    @ViewBuilder
    private var curveView: some View {
        switch viewStyle {
        case .ladder:
            YardageLadderView(
                targetYardage: targetFeet,
                minYardage: 0,
                maxYardage: ladderMaxFeet,
                groupedEntries: groupedLadderEntries,
                onSelectEntry: nil
            )
            Spacer(minLength: 0)
        case .text:
            DistanceTextLadderView(
                ladder: textLadder, unit: .feet, recenterGeneration: recenterGeneration,
                onSelectRowLabel: onSelectRowLabel
            )
                .frame(maxHeight: .infinity)
        }
    }
}

#Preview("Text") {
    previewPage(style: .text)
}

#Preview("Ladder") {
    previewPage(style: .ladder)
}

@MainActor
private func previewPage(style: DistanceViewStyle) -> some View {
    let curve = PuttingSpeedCurveService.points(from: [1: [4], 2: [8], 3: [14], 4: [21], 5: [30]])
    let suggestion = PuttingSpeedCurveService.suggestion(forTargetFeet: 10, curve: curve)
    return PuttingPageView(
        targetFeet: .constant(10),
        viewStyle: style,
        suggestionTitle: suggestion.map { PuttingSpeedCurveService.title(for: $0) } ?? "",
        suggestionDetail: suggestion.map { PuttingSpeedCurveService.detail(for: $0, curve: curve) } ?? "",
        statusText: "Aligned Today",
        isStatusStale: false,
        textLadder: DistanceTextLadderService.ladder(
            items: PuttingSpeedCurveService.textLadderItems(from: curve),
            targetDistance: 10,
            selectedItemID: nil
        ),
        groupedLadderEntries: PuttingSpeedCurveService.groupedLadderEntries(from: curve, highlightedPosition: nil),
        ladderMaxFeet: 30
    )
}
