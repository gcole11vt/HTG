import SwiftUI
import SwiftData

struct RangeModeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var rangeManager: RangeManager?
    @State private var clubManager: ClubManager?
    @State private var selectedClub: Club?
    @State private var selectedShotType: ShotType?
    @State private var distanceText: String = ""
    @State private var showingClubPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let session = rangeManager?.currentSession {
                    activeSessionView(session: session)
                } else {
                    startSessionView
                }
            }
            .navigationTitle("Range Mode")
            .task {
                if rangeManager == nil {
                    rangeManager = RangeManager(modelContext: modelContext)
                }
                if clubManager == nil {
                    clubManager = ClubManager(modelContext: modelContext)
                    await clubManager?.loadClubs()
                }
            }
        }
    }

    private var startSessionView: some View {
        VStack(spacing: 20) {
            Text("Start a Range Session")
                .font(.title2)
                .fontWeight(.semibold)

            if let clubs = clubManager?.clubs, !clubs.isEmpty {
                Picker("Select Club", selection: $selectedClub) {
                    Text("Select Club").tag(nil as Club?)
                    ForEach(clubs) { club in
                        Text(club.name).tag(club as Club?)
                    }
                }
                .pickerStyle(.menu)

                if let club = selectedClub {
                    Picker("Select Shot Type", selection: $selectedShotType) {
                        Text("Select Shot Type").tag(nil as ShotType?)
                        ForEach(club.shotTypes) { shotType in
                            Text(shotType.name).tag(shotType as ShotType?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Button("Start Session") {
                    Task {
                        guard let club = selectedClub,
                              let shotType = selectedShotType else { return }
                        await rangeManager?.startSession(
                            clubName: club.name,
                            shotTypeName: shotType.name
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedClub == nil || selectedShotType == nil)
            } else {
                ContentUnavailableView(
                    "No Clubs",
                    systemImage: "bag.fill",
                    description: Text("Add clubs to start tracking shots")
                )
            }
        }
        .padding()
    }

    private func activeSessionView(session: RangeSession) -> some View {
        VStack(spacing: 20) {
            sessionHeader(session: session)
            statsDisplay
            shotEntrySection
            shotsList(session: session)
            endSessionButton
        }
        .padding()
    }

    private func sessionHeader(session: RangeSession) -> some View {
        VStack {
            Text(session.clubName)
                .font(.title2)
                .fontWeight(.bold)
            Text(session.shotTypeName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var statsDisplay: some View {
        HStack(spacing: 30) {
            StatBox(label: "Max", value: rangeManager?.currentStats.max ?? 0)
            StatBox(label: "75th", value: rangeManager?.currentStats.percentile75 ?? 0)
            StatBox(label: "Median", value: rangeManager?.currentStats.median ?? 0)
            StatBox(label: "Count", value: rangeManager?.currentStats.count ?? 0)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var shotEntrySection: some View {
        HStack {
            TextField("Distance", text: $distanceText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)

            Button("Add Shot") {
                addShot()
            }
            .buttonStyle(.borderedProminent)
            .disabled(distanceText.isEmpty)
        }
    }

    private func shotsList(session: RangeSession) -> some View {
        List {
            ForEach(session.shots.sorted(by: { $0.date > $1.date })) { shot in
                HStack {
                    Text("\(shot.distance) yards")
                    Spacer()
                    if shot.isFromVoice {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { indexSet in
                deleteShots(at: indexSet, from: session)
            }
        }
        .frame(maxHeight: 200)
    }

    private var endSessionButton: some View {
        Button("End Session") {
            Task {
                await rangeManager?.endSession()
                selectedClub = nil
                selectedShotType = nil
            }
        }
        .buttonStyle(.bordered)
    }

    private func addShot() {
        guard let distance = Int(distanceText) else { return }
        Task {
            await rangeManager?.addShot(distance: distance)
            distanceText = ""
        }
    }

    private func deleteShots(at offsets: IndexSet, from session: RangeSession) {
        let sortedShots = session.shots.sorted(by: { $0.date > $1.date })
        for index in offsets {
            let shot = sortedShots[index]
            Task {
                await rangeManager?.deleteShot(shot)
            }
        }
    }
}

struct StatBox: View {
    let label: String
    let value: Int

    var body: some View {
        VStack {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    RangeModeView()
        .modelContainer(for: [Club.self, ShotType.self, RangeSession.self, Shot.self], inMemory: true)
}
