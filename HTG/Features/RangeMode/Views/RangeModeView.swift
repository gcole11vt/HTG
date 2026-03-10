import SwiftUI
import SwiftData

struct RangeModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @State private var rangeManager: RangeManager?
    @State private var clubManager: ClubManager?
    @State private var selectedClub: Club?
    @State private var shotTypeSelection: ShotTypeSelection = .none
    @State private var customShotTypeName: String = ""
    @State private var showMaxShotTypesAlert: Bool = false
    @State private var distanceText: String = ""
    @State private var showingSaveSheet: Bool = false
    @State private var saveDistanceText: String = ""
    @State private var showingEndConfirmation: Bool = false
    @State private var speechService = SpeechRecognitionService()
    @State private var showPermissionDeniedAlert = false
    @FocusState private var isSaveFieldFocused: Bool

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
                applyPreselectionIfNeeded()
            }
            .onAppear {
                applyPreselectionIfNeeded()
            }
            .alert("Maximum Shot Types", isPresented: $showMaxShotTypesAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This club already has the maximum number of shot types. You can still use an existing shot type name.")
            }
            .alert("Microphone Access Required", isPresented: $showPermissionDeniedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("HTG needs microphone and speech recognition access to use voice input. Enable these in Settings.")
            }
        }
    }

    // MARK: - Start Session

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
                    let activeShotTypes = club.shotTypes.filter { !$0.isArchived }

                    Picker("Select Shot Type", selection: $shotTypeSelection) {
                        Text("Select Shot Type").tag(ShotTypeSelection.none)
                        ForEach(activeShotTypes) { shotType in
                            Text(shotType.name).tag(ShotTypeSelection.existing(shotType))
                        }
                        Text("Other").tag(ShotTypeSelection.other)
                    }
                    .pickerStyle(.menu)
                    .onChange(of: shotTypeSelection) { _, newValue in
                        if case .other = newValue {
                            let activeCount = activeShotTypes.count
                            if activeCount >= ClubDataService.maximumShotTypesPerClub {
                                showMaxShotTypesAlert = true
                            }
                        } else {
                            customShotTypeName = ""
                        }
                    }

                    if case .other = shotTypeSelection {
                        TextField("Custom shot type name", text: $customShotTypeName)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button("Start Session") {
                        Task {
                            let club = club
                            switch shotTypeSelection {
                            case .other:
                                let existingMatch = club.shotTypes.first(where: {
                                    $0.name.lowercased() == customShotTypeName.lowercased() && !$0.isArchived
                                })
                                await rangeManager?.startSession(
                                    club: club,
                                    shotType: existingMatch,
                                    shotTypeName: customShotTypeName,
                                    isCustom: existingMatch == nil
                                )
                            case .existing(let shotType):
                                await rangeManager?.startSession(
                                    club: club,
                                    shotType: shotType,
                                    shotTypeName: shotType.name,
                                    isCustom: false
                                )
                            case .none:
                                break
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(startSessionDisabled(club: club))
                }
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

    private func startSessionDisabled(club: Club) -> Bool {
        switch shotTypeSelection {
        case .none:
            return true
        case .existing:
            return false
        case .other:
            let activeCount = club.shotTypes.filter { !$0.isArchived }.count
            let nameMatchesExisting = club.shotTypes.contains(where: {
                $0.name.lowercased() == customShotTypeName.lowercased() && !$0.isArchived
            })
            if customShotTypeName.trimmingCharacters(in: .whitespaces).isEmpty { return true }
            if activeCount >= ClubDataService.maximumShotTypesPerClub && !nameMatchesExisting { return true }
            return false
        }
    }

    // MARK: - Active Session

    private func activeSessionView(session: RangeSession) -> some View {
        VStack(spacing: 16) {
            sessionHeader(session: session)
            shotEntrySection
            sessionActionButtons
            twoColumnSection(session: session)
        }
        .padding()
        .sheet(isPresented: $showingSaveSheet) {
            saveSessionSheet
        }
        .alert("Discard this session?", isPresented: $showingEndConfirmation) {
            Button("Discard", role: .destructive) {
                Task {
                    await rangeManager?.endSession()
                    selectedClub = nil
                    shotTypeSelection = .none
                    customShotTypeName = ""
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All shot data will be lost.")
        }
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

    private var shotEntrySection: some View {
        HStack(spacing: 12) {
            TextField("Distance", text: $distanceText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)

            Button("Add Shot") {
                addShot()
            }
            .buttonStyle(.borderedProminent)
            .disabled(distanceText.isEmpty)

            Button {
                toggleSpeechMode()
            } label: {
                Image(systemName: speechService.isListening ? "mic.fill" : "mic")
                    .font(.system(size: 22))
                    .foregroundStyle(speechService.isListening ? .red : .secondary)
            }
        }
    }

    private var sessionActionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showingEndConfirmation = true
            } label: {
                Text("End Session")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                saveDistanceText = "\(rangeManager?.currentStats.median ?? 0)"
                showingSaveSheet = true
            } label: {
                Text("Save Session")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled((rangeManager?.currentStats.count ?? 0) == 0)
        }
    }

    private func twoColumnSection(session: RangeSession) -> some View {
        HStack(alignment: .top, spacing: 12) {
            previousShotsList(session: session)
                .frame(maxWidth: .infinity)

            Divider()

            statsColumn
                .frame(width: 80)
        }
    }

    private func previousShotsList(session: RangeSession) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PREVIOUS SHOTS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            let sortedShots = session.shots.sorted(by: { $0.date > $1.date })
            List {
                ForEach(sortedShots) { shot in
                    HStack {
                        Text("\(shot.distance) yds")
                            .font(.body)

                        if shot.isFromVoice {
                            Image(systemName: "mic.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            Task { await rangeManager?.deleteShot(shot) }
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let shot = sortedShots[index]
                        Task { await rangeManager?.deleteShot(shot) }
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private var statsColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STATS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if let current = rangeManager?.currentCarryDistance {
                statItem(label: "Current", value: current, color: .green)
            }

            statItem(label: "Count", value: rangeManager?.currentStats.count ?? 0)
            statItem(label: "Median", value: rangeManager?.currentStats.median ?? 0)
            statItem(label: "Max", value: rangeManager?.currentStats.max ?? 0)
            statItem(label: "75th", value: rangeManager?.currentStats.percentile75 ?? 0)
        }
    }

    private func statItem(label: String, value: Int, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }

    // MARK: - Save Session Sheet

    private var saveSessionSheet: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("Save Carry Distance")
                .font(.headline)

            HStack(spacing: 12) {
                Spacer()

                TextField("", text: $saveDistanceText)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isSaveFieldFocused)
                    .frame(width: 160)

                Spacer()
            }

            Spacer()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Go") {
                    if let distance = Int(saveDistanceText), distance > 0 {
                        Task {
                            await rangeManager?.saveSession(carryDistance: distance)
                            showingSaveSheet = false
                            selectedClub = nil
                            shotTypeSelection = .none
                            customShotTypeName = ""
                        }
                    }
                }
                .foregroundStyle(.green)
                .fontWeight(.semibold)
            }
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
        .onAppear {
            isSaveFieldFocused = true
        }
    }

    // MARK: - Speech

    private func toggleSpeechMode() {
        if speechService.isListening {
            speechService.continuousMode = false
            speechService.stopListening()
            return
        }

        Task {
            let authorized = await speechService.requestAuthorization()
            guard authorized else {
                showPermissionDeniedAlert = true
                return
            }

            speechService.continuousMode = true
            speechService.onDistanceConfirmed = { @MainActor distance in
                Task {
                    await rangeManager?.addShot(distance: distance, isFromVoice: true)
                }
            }
            speechService.onDeleteRequested = { @MainActor in
                Task {
                    await rangeManager?.deleteLastShot()
                }
            }
            speechService.onStopRequested = { @MainActor in
                // Mic icon state updates automatically via speechService.isListening
            }

            try? await speechService.startListening()
        }
    }

    // MARK: - Helpers

    private func applyPreselectionIfNeeded() {
        guard let clubName = navigationCoordinator.rangePreselectedClubName,
              let club = clubManager?.clubs.first(where: { $0.name == clubName }) else { return }
        selectedClub = club
        if let shotTypeName = navigationCoordinator.rangePreselectedShotTypeName,
           let shotType = club.shotTypes.first(where: { $0.name == shotTypeName }) {
            shotTypeSelection = .existing(shotType)
            if navigationCoordinator.rangeAutoStartSession {
                Task {
                    await rangeManager?.startSession(
                        club: club,
                        shotType: shotType,
                        shotTypeName: shotType.name,
                        isCustom: false
                    )
                }
            }
        }
        navigationCoordinator.clearRangePreselection()
    }

    private func addShot() {
        guard let distance = Int(distanceText) else { return }
        Task {
            await rangeManager?.addShot(distance: distance)
            distanceText = ""
        }
    }
}

// MARK: - Shot Type Selection

enum ShotTypeSelection: Hashable {
    case none
    case existing(ShotType)
    case other

    var shotType: ShotType? {
        if case .existing(let st) = self { return st }
        return nil
    }

    static func == (lhs: ShotTypeSelection, rhs: ShotTypeSelection) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none), (.other, .other): return true
        case (.existing(let a), .existing(let b)): return a.id == b.id
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .none: hasher.combine(0)
        case .existing(let st): hasher.combine(1); hasher.combine(st.id)
        case .other: hasher.combine(2)
        }
    }
}

#Preview {
    RangeModeView()
        .environment(NavigationCoordinator())
        .modelContainer(for: [Club.self, ShotType.self, RangeSession.self, Shot.self], inMemory: true)
}
