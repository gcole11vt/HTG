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
    @FocusState private var isDistanceFieldFocused: Bool
    @FocusState private var isSaveFieldFocused: Bool
    private let sectionHeaderFont = Font.system(size: 11, weight: .medium)
    private let statsColumnRatio: CGFloat = 0.33

    var body: some View {
        NavigationStack {
            ZStack {
                GTCColor.background.ignoresSafeArea()

                if let session = rangeManager?.currentSession {
                    activeScreenContent(session: session)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            rangeSessionTitle
                                .padding(.top, 8)
                            startSessionView
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
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
        VStack(alignment: .leading, spacing: 14) {
            if let clubs = clubManager?.clubs, !clubs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    sectionEyebrow("Club")
                    Picker("Select Club", selection: $selectedClub) {
                        Text("Select Club").tag(nil as Club?)
                        ForEach(clubs) { club in
                            Text(club.name).tag(club as Club?)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(GTCColor.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(GTCColor.secondary.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(GTCColor.primary, lineWidth: 1.5)
                        )
                )

                if let club = selectedClub {
                    let activeShotTypes = club.shotTypes.filter { !$0.isArchived }

                    VStack(alignment: .leading, spacing: 8) {
                        sectionEyebrow("Shot Type")
                        Picker("Select Shot Type", selection: $shotTypeSelection) {
                            Text("Select Shot Type").tag(ShotTypeSelection.none)
                            ForEach(activeShotTypes) { shotType in
                                Text(shotType.name).tag(ShotTypeSelection.existing(shotType))
                            }
                            Text("Other").tag(ShotTypeSelection.other)
                        }
                        .pickerStyle(.menu)
                        .tint(GTCColor.primary)
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
                                .font(JournalTheme.handwritten(size: 16))
                                .foregroundStyle(GTCColor.text)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(GTCColor.secondary.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(GTCColor.primary, lineWidth: 1.5)
                            )
                    )

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
                    .tint(GTCColor.primary)
                    .disabled(startSessionDisabled(club: club))
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(GTCColor.border)
                    Text("No Clubs")
                        .font(JournalTheme.handwrittenBold(size: 24))
                        .foregroundStyle(GTCColor.primary)
                    Text("Add clubs to start tracking shots")
                        .font(JournalTheme.handwritten(size: 16))
                        .foregroundStyle(GTCColor.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
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

    private func activeScreenContent(session: RangeSession) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            rangeSessionTitle
                .padding(.top, 8)
            activeSessionView(session: session)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private var rangeSessionTitle: some View {
        Text("Range Session")
            .font(.system(size: 26, weight: .semibold, design: .serif))
            .foregroundStyle(GTCColor.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func activeSessionView(session: RangeSession) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sessionHeader(session: session)
            shotEntrySection
            sessionActionButtons
            twoColumnSection(session: session)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isDistanceFieldFocused = false
        }
        .onDisappear {
            stopSpeechIfNeeded()
        }
        .sheet(isPresented: $showingSaveSheet) {
            saveSessionSheet
        }
        .alert("Discard this session?", isPresented: $showingEndConfirmation) {
            Button("Discard", role: .destructive) {
                stopSpeechIfNeeded()
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
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func sessionHeader(session: RangeSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionEyebrow("Current Session")

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(session.clubName)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(GTCColor.primary)

                Text(session.shotTypeName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(GTCColor.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(GTCColor.secondary.opacity(0.08))
                    )
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(GTCColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(GTCColor.primary, lineWidth: 1.5)
                )
        )
    }

    private var shotEntrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionEyebrow("Shot Entry")
            HStack(spacing: 10) {
                TextField("Distance", text: $distanceText)
                    .font(JournalTheme.handwrittenBold(size: 20))
                    .foregroundStyle(GTCColor.primary)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 110)
                    .focused($isDistanceFieldFocused)

                Button("Add Shot") {
                    addShot()
                }
                .buttonStyle(.borderedProminent)
                .tint(GTCColor.primary)
                .disabled(distanceText.isEmpty)

                micToggleButton
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
                saveDistanceText = rangeManager?.defaultSaveCarryDistanceText() ?? ""
                showingSaveSheet = true
            } label: {
                Text("Save Session")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(GTCColor.primary)
            .disabled((rangeManager?.currentStats.count ?? 0) == 0)
        }
    }

    private func twoColumnSection(session: RangeSession) -> some View {
        GeometryReader { geometry in
            let availableWidth = max(geometry.size.width - 12, 0)
            let statsWidth = availableWidth * statsColumnRatio

            HStack(alignment: .top, spacing: 12) {
                previousShotsList(session: session)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Divider()
                    .overlay(GTCColor.border)
                    .frame(maxHeight: .infinity)

                statsColumn
                    .frame(width: statsWidth)
                    .frame(maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func previousShotsList(session: RangeSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            let sortedShots = session.shots.sorted(by: { $0.date > $1.date })
            HStack {
                sectionEyebrow("Previous Shots")
                Spacer()
                if sortedShots.count > 8 {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(GTCColor.secondary)
                        .accessibilityLabel("More shots below")
                }
            }

            if sortedShots.isEmpty {
                Text("No shots yet")
                    .font(JournalTheme.handwritten(size: 14))
                    .foregroundStyle(GTCColor.secondary)
                    .padding(.vertical, 8)
            } else {
                List {
                    ForEach(sortedShots) { shot in
                        HStack {
                            Text("\(shot.distance) yds")
                                .font(JournalTheme.handwritten(size: 15))
                                .foregroundStyle(GTCColor.text)

                            if shot.isFromVoice {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(GTCColor.secondary)
                            }

                            Spacer()

                            Button {
                                Task { await rangeManager?.deleteShot(shot) }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundStyle(GTCColor.warning)
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowBackground(GTCColor.surface)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let shot = sortedShots[index]
                            Task { await rangeManager?.deleteShot(shot) }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(GTCColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(GTCColor.border, lineWidth: 1)
                )
        )
    }

    private var statsColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionEyebrow("Stats")

            if let current = rangeManager?.currentCarryDistance {
                statItem(label: "Current", value: current, color: GTCColor.primary)
            }

            statItem(label: "Count", value: rangeManager?.currentStats.count ?? 0)
            statItem(label: "Median", value: rangeManager?.currentStats.median ?? 0)
            statItem(label: "Max", value: rangeManager?.currentStats.max ?? 0)
            statItem(label: "75th", value: rangeManager?.currentStats.percentile75 ?? 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(GTCColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(GTCColor.border, lineWidth: 1)
                )
        )
    }

    private func statItem(label: String, value: Int, color: Color = GTCColor.text) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(GTCColor.secondary)
            Text("\(value)")
                .font(JournalTheme.handwrittenBold(size: 20))
                .foregroundStyle(color)
        }
    }

    // MARK: - Save Session Sheet

    private var saveSessionSheet: some View {
        VStack(spacing: 16) {
            Spacer()

            sectionEyebrow("Save Carry Distance")

            Text("Save Carry Distance")
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundStyle(GTCColor.primary)

            HStack(spacing: 12) {
                Spacer()

                TextField("", text: $saveDistanceText)
                    .font(JournalTheme.yardageFont)
                    .foregroundStyle(GTCColor.primary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isSaveFieldFocused)
                    .minimumScaleFactor(0.5)
                    .frame(width: 160)

                Spacer()
            }

            Button {
                if let distance = rangeManager?.parsedCarryDistance(from: saveDistanceText) {
                    stopSpeechIfNeeded()
                    Task {
                        await rangeManager?.saveSession(carryDistance: distance)
                        showingSaveSheet = false
                        selectedClub = nil
                        shotTypeSelection = .none
                        customShotTypeName = ""
                    }
                }
            } label: {
                Text("Save")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(GTCColor.warning)
            .disabled(!(rangeManager?.isValidCarryDistanceInput(saveDistanceText) ?? false))
            .padding(.horizontal, 40)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isSaveFieldFocused = false
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
        .onAppear {
            saveDistanceText = rangeManager?.defaultSaveCarryDistanceText() ?? ""
            isSaveFieldFocused = true
        }
    }

    private var micToggleButton: some View {
        Button {
            toggleSpeechMode()
        } label: {
            Image(systemName: speechService.isListening ? "mic.fill" : "mic")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(speechService.isListening ? GTCColor.warning : GTCColor.primary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(speechService.isListening ? GTCColor.warning.opacity(0.12) : GTCColor.surface)
                        .overlay(
                            Circle()
                                .stroke(
                                    speechService.isListening ? GTCColor.warning : GTCColor.border,
                                    lineWidth: 1
                                )
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(speechService.isListening ? "Stop voice input" : "Start voice input")
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

    @ViewBuilder
    private func sectionEyebrow(_ text: String) -> some View {
        Text(text)
            .font(sectionHeaderFont)
            .foregroundStyle(GTCColor.secondary)
            .textCase(.uppercase)
    }

    private func stopSpeechIfNeeded() {
        guard speechService.isListening else { return }
        speechService.continuousMode = false
        speechService.stopListening()
    }

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
