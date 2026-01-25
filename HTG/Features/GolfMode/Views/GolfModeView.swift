import SwiftUI
import SwiftData

struct GolfModeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: GolfModeViewModel?
    @State private var yardageText: String = "150"

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                yardageInputSection
                filterSection
                recommendationsList
            }
            .navigationTitle("Golf Mode")
            .task {
                if viewModel == nil {
                    viewModel = GolfModeViewModel(modelContext: modelContext)
                }
                await viewModel?.loadClubs()
            }
        }
    }

    private var yardageInputSection: some View {
        VStack(spacing: 8) {
            Text("Target Yardage")
                .font(.headline)

            HStack {
                TextField("Yards", text: $yardageText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .multilineTextAlignment(.center)

                Text("yards")
                    .foregroundStyle(.secondary)
            }
            .onChange(of: yardageText) { _, newValue in
                if let yardage = Int(newValue) {
                    viewModel?.setTargetYardage(yardage)
                }
            }
        }
        .padding()
    }

    private var filterSection: some View {
        Picker("Shot Type", selection: Binding(
            get: { viewModel?.selectedFilter ?? .all },
            set: { viewModel?.setFilter($0) }
        )) {
            ForEach(ShotTypeFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var recommendationsList: some View {
        List {
            if let recommendations = viewModel?.recommendations, !recommendations.isEmpty {
                ForEach(recommendations) { rec in
                    RecommendationRowView(recommendation: rec)
                }
            } else {
                ContentUnavailableView(
                    "No Recommendations",
                    systemImage: "questionmark.circle",
                    description: Text("Add clubs to see shot recommendations")
                )
            }
        }
    }
}

struct RecommendationRowView: View {
    let recommendation: ShotRecommendation

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(recommendation.clubName)
                    .font(.headline)
                Text(recommendation.shotTypeName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(recommendation.carryDistance) yds")
                    .font(.headline)
                Text(differenceText)
                    .font(.caption)
                    .foregroundStyle(differenceColor)
            }
        }
        .padding(.vertical, 4)
    }

    private var differenceText: String {
        if recommendation.distanceDifference == 0 {
            return "Exact"
        } else {
            return "\(recommendation.distanceDifference > 0 ? "+" : "")\(recommendation.distanceDifference)"
        }
    }

    private var differenceColor: Color {
        switch recommendation.distanceDifference {
        case 0...5: return .green
        case 6...10: return .yellow
        default: return .orange
        }
    }
}

#Preview {
    GolfModeView()
        .modelContainer(for: [Club.self, ShotType.self], inMemory: true)
}
