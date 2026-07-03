import SwiftUI
import SwiftData

struct ClubListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var clubManager: ClubManager?
    @State private var profileManager: ProfileManager?
    @State private var showingAddClub = false
    @State private var showingYardageSheet = false
    @State private var refreshID = UUID()
    @State private var expandedClubIDs: Set<UUID> = []
    @State private var detailClub: Club?

    private var primaryShotType: String {
        profileManager?.profile?.primaryShotType ?? "Full"
    }

    private var sortedClubs: [Club] {
        guard let clubs = clubManager?.clubs else { return [] }
        let shotType = primaryShotType
        return clubs.sorted { lhs, rhs in
            ClubDistanceResolver.resolveDisplayDistance(for: lhs, primaryShotType: shotType) >
            ClubDistanceResolver.resolveDisplayDistance(for: rhs, primaryShotType: shotType)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ClubActiveClubsListSectionView(
                    clubs: sortedClubs,
                    primaryShotType: primaryShotType,
                    isLoading: clubManager?.isLoading == true,
                    expandedClubIDs: expandedClubIDs,
                    onToggleExpansion: { club in
                        withAnimation(.snappy) {
                            if expandedClubIDs.contains(club.id) {
                                expandedClubIDs.remove(club.id)
                            } else {
                                expandedClubIDs.insert(club.id)
                            }
                        }
                    },
                    onShowDetail: { club in
                        detailClub = club
                    },
                    onArchiveClub: { club in
                        Task { await clubManager?.archiveClub(club) }
                    }
                )

                ClubArchivedClubsSectionView(
                    clubs: clubManager?.archivedClubs ?? [],
                    primaryShotType: primaryShotType,
                    onRestoreClub: { club in
                        Task { await clubManager?.restoreClub(club) }
                    }
                )
            }
            .id(refreshID)
            .listStyle(.plain)
            .listRowSpacing(-20)
            .scrollContentBackground(.hidden)
            .background(GTCColor.background)
            .navigationTitle("My Clubs")
            .navigationDestination(item: $detailClub) { club in
                ClubDetailView(club: club, clubManager: clubManager, primaryShotType: primaryShotType)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingYardageSheet = true
                    } label: {
                        Image(systemName: "printer")
                    }
                    .accessibilityLabel("Print yardages")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddClub = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddClub) {
                AddClubSheet(clubManager: clubManager)
            }
            .sheet(isPresented: $showingYardageSheet) {
                YardageSheetView(clubs: clubManager?.clubs ?? [], primaryShotType: primaryShotType)
            }
            .task {
                if clubManager == nil {
                    clubManager = ClubManager(modelContext: modelContext)
                    await clubManager?.loadDefaultClubsIfNeeded()
                }
                if profileManager == nil {
                    profileManager = ProfileManager(modelContext: modelContext)
                    await profileManager?.loadProfile()
                }
            }
            .onAppear {
                refreshID = UUID()
                Task {
                    await clubManager?.loadClubs()
                    await profileManager?.loadProfile()
                }
            }
            .alert("Error", isPresented: .init(
                get: { clubManager?.errorMessage != nil },
                set: { if !$0 { clubManager?.errorMessage = nil } }
            )) {
                Button("OK") { clubManager?.errorMessage = nil }
            } message: {
                Text(clubManager?.errorMessage ?? "")
            }
        }
    }
}

struct ClubRowView: View {
    let club: Club
    let primaryShotType: String

    var body: some View {
        HStack {
            Text(club.name)
                .font(JournalTheme.handwrittenBold(size: 20))
                .foregroundStyle(GTCColor.primary)
            Spacer()
            Text("\(ClubDistanceResolver.resolveDisplayDistance(for: club, primaryShotType: primaryShotType)) yds")
                .font(JournalTheme.handwritten(size: 15))
                .foregroundStyle(GTCColor.secondary)
        }
    }
}

struct ClubActiveClubsListSectionView: View {
    let clubs: [Club]
    let primaryShotType: String
    let isLoading: Bool
    let expandedClubIDs: Set<UUID>
    let onToggleExpansion: (Club) -> Void
    let onShowDetail: (Club) -> Void
    let onArchiveClub: (Club) -> Void

    var body: some View {
        Section {
            if !clubs.isEmpty {
                ForEach(clubs) { club in
                    ExpandableClubRowView(
                        club: club,
                        primaryShotType: primaryShotType,
                        isExpanded: expandedClubIDs.contains(club.id),
                        onShowDetail: { onShowDetail(club) }
                    )
                    .clubCardRowStyle()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onToggleExpansion(club)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            onArchiveClub(club)
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(GTCColor.swipe)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            } else if isLoading {
                ProgressView("Loading clubs...")
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(GTCColor.border)
                    Text("No Clubs")
                        .font(JournalTheme.handwrittenBold(size: 24))
                        .foregroundStyle(GTCColor.primary)
                    Text("Add clubs to get started")
                        .font(JournalTheme.handwritten(size: 16))
                        .foregroundStyle(GTCColor.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        } header: {
            GTCSectionEyebrow("Clubs")
        }
    }
}

struct ExpandableClubRowView: View {
    let club: Club
    let primaryShotType: String
    let isExpanded: Bool
    let onShowDetail: () -> Void

    private var activeShotTypes: [ShotType] {
        club.shotTypes.filter { !$0.isArchived }.sorted { $0.carryDistance > $1.carryDistance }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow

            if isExpanded {
                expandedShotTypes
            }
        }
    }

    private var headerRow: some View {
        HStack {
            Text(club.name)
                .font(JournalTheme.handwrittenBold(size: 20))
                .foregroundStyle(GTCColor.primary)
            Spacer()
            Text("\(ClubDistanceResolver.resolveDisplayDistance(for: club, primaryShotType: primaryShotType)) yds")
                .font(JournalTheme.handwritten(size: 15))
                .foregroundStyle(GTCColor.secondary)
            Button {
                onShowDetail()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(GTCColor.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(club.name) details")
        }
    }

    private var expandedShotTypes: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .overlay(GTCColor.border)
                .padding(.vertical, 6)

            if activeShotTypes.isEmpty {
                Text("No shot types")
                    .font(JournalTheme.handwritten(size: 14))
                    .foregroundStyle(GTCColor.secondary)
            } else {
                ForEach(activeShotTypes) { shotType in
                    HStack {
                        Text(shotType.name)
                            .font(JournalTheme.handwritten(size: 15))
                            .fontWeight(shotType.name == primaryShotType ? .bold : .regular)
                            .foregroundStyle(GTCColor.text)
                        Spacer()
                        Text("\(shotType.carryDistance) yds")
                            .font(JournalTheme.handwritten(size: 15))
                            .foregroundStyle(GTCColor.secondary)
                    }
                }
            }
        }
        .padding(.leading, 4)
    }
}

struct ClubArchivedClubsSectionView: View {
    let clubs: [Club]
    let primaryShotType: String
    let onRestoreClub: (Club) -> Void

    var body: some View {
        if !clubs.isEmpty {
            Section {
                ForEach(clubs) { club in
                    ClubRowView(club: club, primaryShotType: primaryShotType)
                        .clubNeutralCardRowStyle()
                        .swipeActions(edge: .trailing) {
                            Button {
                                onRestoreClub(club)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(GTCColor.primary)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            } header: {
                GTCSectionEyebrow("Archived")
            }
        }
    }
}

struct ClubDetailView: View {
    let club: Club
    let clubManager: ClubManager?
    let primaryShotType: String
    @State private var showingAddShotType = false
    @State private var editedName: String = ""
    @State private var editedNickname: String = ""
    @State private var isEditingName = false
    @State private var isEditingNickname = false
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @Environment(\.modelContext) private var modelContext
    @State private var clubProfileManager: ProfileManager?
    @State private var clubSwingThoughts: [SwingThought] = []
    @State private var newClubSwingThoughtText: String = ""

    private var sortedShotTypes: [ShotType] {
        club.shotTypes.filter { !$0.isArchived }.sorted { $0.carryDistance > $1.carryDistance }
    }

    private var archivedShotTypes: [ShotType] {
        club.shotTypes.filter { $0.isArchived }.sorted { $0.carryDistance > $1.carryDistance }
    }

    private var primaryShotTypeDistance: Int? {
        club.shotTypes.first(where: { $0.name == primaryShotType })?.carryDistance
    }

    var body: some View {
        List {
            ClubIdentitySectionView(
                club: club,
                isEditingName: $isEditingName,
                editedName: $editedName,
                isEditingNickname: $isEditingNickname,
                editedNickname: $editedNickname,
                onSaveClubName: { updatedName in
                    Task {
                        await clubManager?.updateClub(club, name: updatedName)
                        isEditingName = false
                    }
                },
                onSaveNickname: { updatedNickname in
                    Task {
                        await clubManager?.updateClub(club, name: club.name, nickname: updatedNickname)
                        isEditingNickname = false
                    }
                }
            )

            ClubShotTypesSectionView(
                club: club,
                sortedShotTypes: sortedShotTypes,
                primaryShotType: primaryShotType,
                primaryShotTypeDistance: primaryShotTypeDistance,
                onOpenRangeForShotType: { shotType in
                    navigationCoordinator.navigateToRange(
                        clubName: club.name,
                        shotTypeName: shotType.name,
                        autoStart: true
                    )
                },
                onArchiveShotType: { shotType in
                    Task {
                        await clubManager?.archiveShotType(shotType, from: club)
                    }
                },
                onShowAddShotType: {
                    showingAddShotType = true
                },
                clubManager: clubManager
            )

            ClubArchivedShotTypesSectionView(
                archivedShotTypes: archivedShotTypes,
                onRestoreShotType: { shotType in
                    Task { await clubManager?.restoreShotType(shotType) }
                }
            )

            ClubSwingThoughtsSectionView(
                clubSwingThoughts: clubSwingThoughts,
                newThoughtText: $newClubSwingThoughtText,
                onDeleteThoughts: { thoughtsToDelete in
                    for thought in thoughtsToDelete {
                        await clubProfileManager?.deleteSwingThought(thought)
                    }
                    await loadClubSwingThoughts()
                },
                onAddThought: { text in
                    await clubProfileManager?.addSwingThought(
                        text: text,
                        tagType: "club",
                        tagValue: club.name
                    )
                    newClubSwingThoughtText = ""
                    await loadClubSwingThoughts()
                }
            )
        }
        .listStyle(.plain)
        .listRowSpacing(-20)
        .scrollContentBackground(.hidden)
        .background(GTCColor.background)
        .task {
            if clubProfileManager == nil {
                clubProfileManager = ProfileManager(modelContext: modelContext)
                await clubProfileManager?.loadProfile()
            }
            await loadClubSwingThoughts()
        }
        .navigationTitle(club.name)
        .sheet(isPresented: $showingAddShotType) {
            AddShotTypeSheet(club: club, clubManager: clubManager)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Range") {
                    navigationCoordinator.navigateToRange(clubName: club.name)
                }
            }
        }
    }

    private func loadClubSwingThoughts() async {
        guard let profile = clubProfileManager?.profile else { return }
        clubSwingThoughts = profile.swingThoughts.filter { $0.tagType == "club" && $0.tagValue == club.name }
    }
}

struct ShotTypeRowView: View {
    let shotType: ShotType
    let isPrimary: Bool
    let primaryDistance: Int?
    let clubManager: ClubManager?
    let club: Club
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var editedDistance: String = ""

    private var delta: Int? {
        guard !isPrimary, let primaryDistance else { return nil }
        let diff = shotType.carryDistance - primaryDistance
        return diff != 0 ? diff : nil
    }

    private var deltaBackgroundColor: Color {
        guard let delta else { return .clear }
        return delta > 0 ? GTCColor.deltaPositiveBackground : GTCColor.deltaNegativeBackground
    }

    private var deltaForegroundColor: Color {
        guard let delta else { return .clear }
        return delta > 0 ? GTCColor.deltaPositiveText : GTCColor.deltaNegativeText
    }

    var body: some View {
        if isEditing {
            editingContent
        } else {
            displayContent
        }
    }

    private var displayContent: some View {
        HStack {
            Text(shotType.name)
                .font(JournalTheme.listRowSecondaryFont)
                .fontWeight(isPrimary ? .bold : .regular)
            if let delta {
                Text(delta > 0 ? "+\(delta)" : "\(delta)")
                    .font(JournalTheme.inlineBadgeFont)
                    .padding(.horizontal, JournalTheme.inlineBadgeHorizontalPadding)
                    .padding(.vertical, JournalTheme.inlineBadgeVerticalPadding)
                    .background(deltaBackgroundColor)
                    .foregroundStyle(deltaForegroundColor)
                    .clipShape(Capsule())
            }
            Spacer()
            Text("\(shotType.carryDistance) yds")
                .font(JournalTheme.listRowSecondaryFont)
                .foregroundStyle(GTCColor.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editedName = shotType.name
            editedDistance = "\(shotType.carryDistance)"
            isEditing = true
        }
    }

    private var editingContent: some View {
        HStack {
            TextField("Name", text: $editedName)
                .textFieldStyle(.roundedBorder)
            TextField("Distance", text: $editedDistance)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .frame(width: JournalTheme.compactNumericInputWidth)
            Button("Save") {
                guard let distance = Int(editedDistance) else { return }
                Task {
                    await clubManager?.updateShotType(shotType, name: editedName, distance: distance)
                    isEditing = false
                }
            }
            .gtcProminentActionButtonStyle()
        }
    }
}

struct ClubIdentitySectionView: View {
    let club: Club
    @Binding var isEditingName: Bool
    @Binding var editedName: String
    @Binding var isEditingNickname: Bool
    @Binding var editedNickname: String
    let onSaveClubName: (String) -> Void
    let onSaveNickname: (String) -> Void

    var body: some View {
        Section {
            if isEditingName {
                HStack {
                    TextField("Name", text: $editedName)
                        .font(JournalTheme.handwritten(size: 16))
                        .foregroundStyle(GTCColor.text)
                    Button("Save") {
                        onSaveClubName(editedName)
                    }
                    .gtcProminentActionButtonStyle()
                }
                .clubAccentCardRowStyle()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                HStack {
                    Text(club.name)
                        .font(JournalTheme.handwrittenBold(size: 20))
                        .foregroundStyle(GTCColor.primary)
                    Spacer()
                    Button("Edit") {
                        editedName = club.name
                        isEditingName = true
                    }
                }
                .clubAccentCardRowStyle()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if isEditingNickname {
                HStack {
                    TextField("Nickname", text: $editedNickname)
                        .font(JournalTheme.handwritten(size: 16))
                        .foregroundStyle(GTCColor.text)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: editedNickname) { _, newValue in
                            let filtered = String(newValue.filter { $0.isLetter || $0.isNumber }.prefix(2))
                            if filtered != newValue {
                                editedNickname = filtered
                            }
                        }
                    Button("Save") {
                        onSaveNickname(editedNickname)
                    }
                    .gtcProminentActionButtonStyle()
                }
                .clubAccentCardRowStyle()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                HStack {
                    Text(club.nickname)
                        .font(JournalTheme.handwritten(size: 16))
                        .foregroundStyle(GTCColor.primary)
                    Text("Nickname")
                        .font(JournalTheme.inlineHelperLabelFont)
                        .foregroundStyle(GTCColor.border)
                        .italic()
                        .frame(maxWidth: .infinity)
                    Button("Edit") {
                        editedNickname = club.nickname
                        isEditingNickname = true
                    }
                }
                .clubAccentCardRowStyle()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        } header: {
            GTCSectionEyebrow("Club")
        }
    }
}

struct ClubShotTypesSectionView: View {
    let club: Club
    let sortedShotTypes: [ShotType]
    let primaryShotType: String
    let primaryShotTypeDistance: Int?
    let onOpenRangeForShotType: (ShotType) -> Void
    let onArchiveShotType: (ShotType) -> Void
    let onShowAddShotType: () -> Void
    let clubManager: ClubManager?

    var body: some View {
        Section {
            ForEach(sortedShotTypes) { shotType in
                ShotTypeRowView(
                    shotType: shotType,
                    isPrimary: shotType.name == primaryShotType,
                    primaryDistance: primaryShotTypeDistance,
                    clubManager: clubManager,
                    club: club
                )
                .clubNeutralCardRowStyle()
                .swipeActions(edge: .leading) {
                    Button("Range") {
                        onOpenRangeForShotType(shotType)
                    }
                    .tint(GTCColor.primary)
                }
                .swipeActions(edge: .trailing) {
                    Button("Archive", role: .destructive) {
                        onArchiveShotType(shotType)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if sortedShotTypes.count < 5 {
                Button {
                    onShowAddShotType()
                } label: {
                    Text("Add Shot Type")
                }
                .gtcProminentActionButtonStyle()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        } header: {
            GTCSectionEyebrow("Shot Type")
        }
    }
}

struct ClubArchivedShotTypesSectionView: View {
    let archivedShotTypes: [ShotType]
    let onRestoreShotType: (ShotType) -> Void

    var body: some View {
        if !archivedShotTypes.isEmpty {
            Section {
                ForEach(archivedShotTypes) { shotType in
                    HStack {
                        Text(shotType.name)
                        Spacer()
                        Text("\(shotType.carryDistance) yds")
                            .font(JournalTheme.listRowSecondaryFont)
                            .foregroundStyle(GTCColor.secondary)
                    }
                    .foregroundStyle(GTCColor.secondary)
                    .clubNeutralCardRowStyle()
                    .swipeActions(edge: .trailing) {
                        Button {
                            onRestoreShotType(shotType)
                        } label: {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                        }
                        .tint(GTCColor.primary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            } header: {
                GTCSectionEyebrow("Archived")
            }
        }
    }
}

struct ClubSwingThoughtsSectionView: View {
    let clubSwingThoughts: [SwingThought]
    @Binding var newThoughtText: String
    let onDeleteThoughts: ([SwingThought]) async -> Void
    let onAddThought: (String) async -> Void

    var body: some View {
        Section {
            if clubSwingThoughts.isEmpty {
                Text("No swing thoughts for this club")
                    .font(JournalTheme.handwritten(size: 14))
                    .foregroundStyle(GTCColor.secondary)
                    .clubNeutralCardRowStyle()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(clubSwingThoughts) { thought in
                    Text(thought.text)
                        .font(JournalTheme.handwritten(size: 15))
                        .foregroundStyle(GTCColor.text)
                        .clubNeutralCardRowStyle()
                }
                .onDelete { indexSet in
                    let thoughtsToDelete = indexSet.map { clubSwingThoughts[$0] }
                    Task {
                        await onDeleteThoughts(thoughtsToDelete)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            HStack {
                TextField("New swing thought", text: $newThoughtText)
                    .font(JournalTheme.handwritten(size: 16))
                    .foregroundStyle(GTCColor.text)
                Button("Add") {
                    let trimmedText = newThoughtText.trimmingCharacters(in: .whitespaces)
                    guard !trimmedText.isEmpty else { return }
                    Task {
                        await onAddThought(trimmedText)
                    }
                }
                .gtcProminentActionButtonStyle()
                .disabled(newThoughtText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .clubAccentCardRowStyle()
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } header: {
            GTCSectionEyebrow("Swing Thoughts")
        }
    }
}

struct AddClubSheet: View {
    let clubManager: ClubManager?
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var nickname: String = ""
    @State private var distanceText: String = "150"

    var body: some View {
        NavigationStack {
            ZStack {
                GTCColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: JournalTheme.sectionSpacing) {
                        Text("Add Club")
                            .font(JournalTheme.sheetTitleFont)
                            .foregroundStyle(GTCColor.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: JournalTheme.subsectionSpacing) {
                            GTCSectionEyebrow("Club")
                            TextField("Club Name", text: $name)
                                .font(JournalTheme.handwritten(size: 16))
                                .foregroundStyle(GTCColor.text)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: name) { _, newValue in
                                    nickname = NicknameGenerator.generate(from: newValue)
                                }
                        }
                        .clubAccentCardSectionStyle()

                        VStack(alignment: .leading, spacing: JournalTheme.subsectionSpacing) {
                            GTCSectionEyebrow("Nickname")
                            TextField("Nickname (1-2 chars)", text: $nickname)
                                .font(JournalTheme.handwritten(size: 16))
                                .foregroundStyle(GTCColor.text)
                                .textInputAutocapitalization(.characters)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: nickname) { _, newValue in
                                    let filtered = String(newValue.filter { $0.isLetter || $0.isNumber }.prefix(2))
                                    if filtered != newValue {
                                        nickname = filtered
                                    }
                                }
                        }
                        .clubAccentCardSectionStyle()

                        VStack(alignment: .leading, spacing: JournalTheme.subsectionSpacing) {
                            GTCSectionEyebrow("Default Distance")
                            TextField("Default Distance (yards)", text: $distanceText)
                                .font(JournalTheme.handwrittenBold(size: 20))
                                .foregroundStyle(GTCColor.primary)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                        .clubAccentCardSectionStyle()
                    }
                    .padding(.horizontal, JournalTheme.screenHorizontalPadding)
                    .padding(.vertical, JournalTheme.screenHorizontalPadding)
                }
            }
            .navigationTitle("Add Club")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let distance = Int(distanceText) else { return }
                        Task {
                            await clubManager?.addClub(name: name, defaultDistance: distance, nickname: nickname.isEmpty ? nil : nickname)
                            dismiss()
                        }
                    }
                    .gtcProminentActionButtonStyle()
                    .disabled(name.isEmpty || distanceText.isEmpty)
                }
            }
        }
    }
}

struct AddShotTypeSheet: View {
    let club: Club
    let clubManager: ClubManager?
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var distanceText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                GTCColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: JournalTheme.sectionSpacing) {
                        Text("Add Shot Type")
                            .font(JournalTheme.sheetTitleFont)
                            .foregroundStyle(GTCColor.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: JournalTheme.subsectionSpacing) {
                            GTCSectionEyebrow("Shot Type")
                            TextField("Shot Type Name", text: $name)
                                .font(JournalTheme.handwritten(size: 16))
                                .foregroundStyle(GTCColor.text)
                                
                        }
                        .clubAccentCardSectionStyle()

                        VStack(alignment: .leading, spacing: JournalTheme.subsectionSpacing) {
                            GTCSectionEyebrow("Carry Distance")
                            TextField("Carry Distance (yards)", text: $distanceText)
                                .font(JournalTheme.handwrittenBold(size: 16))
                                .foregroundStyle(GTCColor.text)
                                
                                .keyboardType(.numberPad)
                            
                        }
                        .clubAccentCardSectionStyle()
                    }
                    .padding(.horizontal, JournalTheme.screenHorizontalPadding)
                    .padding(.vertical, JournalTheme.screenHorizontalPadding)
                }
            }
            .navigationTitle("Add Shot Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let distance = Int(distanceText) else { return }
                        Task {
                            await clubManager?.addShotType(to: club, name: name, distance: distance)
                            dismiss()
                        }
                    }
                    .gtcProminentActionButtonStyle()
                    .disabled(name.isEmpty || distanceText.isEmpty)
                }
            }
        }
    }
}

private extension View {
    func clubCardRowStyle() -> some View {
        gtcAccentCard(fill: GTCColor.background, lineWidth: 1)
    }

    func clubNeutralCardRowStyle() -> some View {
        gtcNeutralCard(fill: GTCColor.background)
    }

    func clubAccentCardRowStyle() -> some View {
        gtcAccentCard(fill: GTCColor.background)
    }

    func clubAccentCardSectionStyle() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .gtcTintedAccentCard()
    }
}

/*#Preview {
    ClubListView()
        .environment(NavigationCoordinator())
        .modelContainer(for: [Club.self, ShotType.self], inMemory: true)
}*/

#Preview("Club Identity - Fast") {
    struct PreviewHost: View {
        @State private var isEditingName = false
        @State private var editedName = "7 Iron"
        @State private var isEditingNickname = false
        @State private var editedNickname = "7I"
        let club = Club(name: "7 Iron", nickname: "7I", sortOrder: 1)
        var body: some View {
            List {
                ClubIdentitySectionView(
                    club: club,
                    isEditingName: $isEditingName,
                    editedName: $editedName,
                    isEditingNickname: $isEditingNickname,
                    editedNickname: $editedNickname,
                    onSaveClubName: { _ in },
                    onSaveNickname: { _ in }
                )
            }
            .listStyle(.plain)
            .background(GTCColor.background)
        }
    }
    return PreviewHost()
}

#Preview("Club List - Seeded Base 3") {
    ClubListView()
        .environment(NavigationCoordinator())
        .modelContainer(ClubListPreviewData.container)
}

private enum ClubListPreviewData {
    @MainActor
    static let container: ModelContainer = {
        let schema = Schema([
            Club.self,
            ShotType.self,
            UserProfile.self,
            PreShotRoutineItem.self,
            SwingThought.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        // Keep this deterministic so Preview doesn't change on every refresh.
        let base: [(name: String, full: Int, sortOrder: Int)] = [
            ("Driver", 250, 0),
            ("7 Iron", 165, 1),
            ("Pitching Wedge", 135, 2)
        ]

        for entry in base {
            let club = Club(
                name: entry.name,
                nickname: NicknameGenerator.generate(from: entry.name),
                sortOrder: entry.sortOrder
            )

            let full = ShotType(name: "Full", carryDistance: entry.full, sortOrder: 0, club: club)
            let threeQuarter = ShotType(name: "3/4", carryDistance: Int(Double(entry.full) * 0.93), sortOrder: 1, club: club)
            let hard = ShotType(name: "Hard", carryDistance: Int(Double(entry.full) * 1.06), sortOrder: 2, club: club)
            let half = ShotType(name: "1/2", carryDistance: Int(Double(entry.full) * 0.65), sortOrder: 3, club: club)

            club.shotTypes = [full, threeQuarter, hard, half]
            context.insert(club)
        }

        // Gives primary shot type context used by ClubListView sorting/display.
        let profile = UserProfile(name: "Preview", handicap: 12, primaryShotType: "Full")
        context.insert(profile)

        try? context.save()
        return container
    }()
}
