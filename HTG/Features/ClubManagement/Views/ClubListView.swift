import SwiftUI
import SwiftData

struct ClubListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var clubManager: ClubManager?
    @State private var profileManager: ProfileManager?
    @State private var showingAddClub = false

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
                if !sortedClubs.isEmpty {
                    ForEach(sortedClubs) { club in
                        NavigationLink(value: club) {
                            ClubRowView(club: club, primaryShotType: primaryShotType)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                Task { await clubManager?.archiveClub(club) }
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                            .tint(.orange)
                        }
                    }
                } else if clubManager?.isLoading == true {
                    ProgressView("Loading clubs...")
                } else {
                    ContentUnavailableView(
                        "No Clubs",
                        systemImage: "bag.fill",
                        description: Text("Add clubs to get started")
                    )
                }

                if let archivedClubs = clubManager?.archivedClubs, !archivedClubs.isEmpty {
                    Section("Archived") {
                        ForEach(archivedClubs) { club in
                            ClubRowView(club: club, primaryShotType: primaryShotType)
                                .foregroundStyle(.secondary)
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        Task { await clubManager?.restoreClub(club) }
                                    } label: {
                                        Label("Restore", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                }
            }
            .navigationTitle("My Clubs")
            .navigationDestination(for: Club.self) { club in
                ClubDetailView(club: club, clubManager: clubManager, primaryShotType: primaryShotType)
            }
            .toolbar {
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
                .font(.headline)
            Spacer()
            Text("\(ClubDistanceResolver.resolveDisplayDistance(for: club, primaryShotType: primaryShotType)) yds")
                .foregroundStyle(.secondary)
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
            Section("Club Name") {
                if isEditingName {
                    HStack {
                        TextField("Name", text: $editedName)
                        Button("Save") {
                            Task {
                                await clubManager?.updateClub(club, name: editedName)
                                isEditingName = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    HStack {
                        Text(club.name)
                        Spacer()
                        Button("Edit") {
                            editedName = club.name
                            isEditingName = true
                        }
                    }
                }

                if isEditingNickname {
                    HStack {
                        TextField("Nickname", text: $editedNickname)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: editedNickname) { _, newValue in
                                let filtered = String(newValue.filter { $0.isLetter || $0.isNumber }.prefix(2))
                                if filtered != newValue {
                                    editedNickname = filtered
                                }
                            }
                        Button("Save") {
                            Task {
                                await clubManager?.updateClub(club, name: club.name, nickname: editedNickname)
                                isEditingNickname = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    HStack {
                        Text(club.nickname)
                        Text("Nickname")
                            .foregroundStyle(.gray)
                            .italic()
                            .frame(maxWidth: .infinity)
                        Button("Edit") {
                            editedNickname = club.nickname
                            isEditingNickname = true
                        }
                    }
                }
            }

            Section("Shot Types") {
                ForEach(sortedShotTypes) { shotType in
                    ShotTypeRowView(
                        shotType: shotType,
                        isPrimary: shotType.name == primaryShotType,
                        primaryDistance: primaryShotTypeDistance,
                        clubManager: clubManager,
                        club: club
                    )
                    .swipeActions(edge: .leading) {
                        Button("Range") {
                            navigationCoordinator.navigateToRange(
                                clubName: club.name,
                                shotTypeName: shotType.name,
                                autoStart: true
                            )
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Archive", role: .destructive) {
                            Task {
                                await clubManager?.archiveShotType(shotType, from: club)
                            }
                        }
                    }
                }

                if sortedShotTypes.count < 5 {
                    Button {
                        showingAddShotType = true
                    } label: {
                        Label("Add Shot Type", systemImage: "plus")
                    }
                }
            }

            if !archivedShotTypes.isEmpty {
                Section("Archived") {
                    ForEach(archivedShotTypes) { shotType in
                        HStack {
                            Text(shotType.name)
                            Spacer()
                            Text("\(shotType.carryDistance) yds")
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.secondary)
                        .swipeActions(edge: .trailing) {
                            Button {
                                Task { await clubManager?.restoreShotType(shotType) }
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.green)
                        }
                    }
                }
            }
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
                .fontWeight(isPrimary ? .bold : .regular)
            if let delta {
                Text(delta > 0 ? "+\(delta)" : "\(delta)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(delta > 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundStyle(delta > 0 ? .green : .red)
                    .clipShape(Capsule())
            }
            Spacer()
            Text("\(shotType.carryDistance) yds")
                .foregroundStyle(.secondary)
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
                .frame(width: 80)
            Button("Save") {
                guard let distance = Int(editedDistance) else { return }
                Task {
                    await clubManager?.updateShotType(shotType, name: editedName, distance: distance)
                    isEditing = false
                }
            }
            .buttonStyle(.borderedProminent)
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
            Form {
                TextField("Club Name", text: $name)
                    .onChange(of: name) { _, newValue in
                        nickname = NicknameGenerator.generate(from: newValue)
                    }
                TextField("Nickname (1-2 chars)", text: $nickname)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: nickname) { _, newValue in
                        let filtered = String(newValue.filter { $0.isLetter || $0.isNumber }.prefix(2))
                        if filtered != newValue {
                            nickname = filtered
                        }
                    }
                TextField("Default Distance (yards)", text: $distanceText)
                    .keyboardType(.numberPad)
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
            Form {
                TextField("Shot Type Name", text: $name)
                TextField("Carry Distance (yards)", text: $distanceText)
                    .keyboardType(.numberPad)
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
                    .disabled(name.isEmpty || distanceText.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ClubListView()
        .environment(NavigationCoordinator())
        .modelContainer(for: [Club.self, ShotType.self], inMemory: true)
}
