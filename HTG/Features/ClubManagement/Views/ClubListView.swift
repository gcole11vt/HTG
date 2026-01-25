import SwiftUI
import SwiftData

struct ClubListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var clubManager: ClubManager?
    @State private var showingAddClub = false
    @State private var selectedClub: Club?

    var body: some View {
        NavigationStack {
            List {
                if let clubs = clubManager?.clubs, !clubs.isEmpty {
                    ForEach(clubs) { club in
                        NavigationLink(value: club) {
                            ClubRowView(club: club)
                        }
                    }
                    .onDelete(perform: deleteClubs)
                    .onMove(perform: moveClubs)
                } else if clubManager?.isLoading == true {
                    ProgressView("Loading clubs...")
                } else {
                    ContentUnavailableView(
                        "No Clubs",
                        systemImage: "bag.fill",
                        description: Text("Add clubs to get started")
                    )
                }
            }
            .navigationTitle("My Clubs")
            .navigationDestination(for: Club.self) { club in
                ClubDetailView(club: club, clubManager: clubManager)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
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
            .task {
                if clubManager == nil {
                    clubManager = ClubManager(modelContext: modelContext)
                    await clubManager?.loadDefaultClubsIfNeeded()
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

    private func deleteClubs(at offsets: IndexSet) {
        guard let clubs = clubManager?.clubs else { return }
        for index in offsets {
            let club = clubs[index]
            Task {
                await clubManager?.deleteClub(club)
            }
        }
    }

    private func moveClubs(from source: IndexSet, to destination: Int) {
        guard var clubs = clubManager?.clubs else { return }
        clubs.move(fromOffsets: source, toOffset: destination)
        Task {
            await clubManager?.reorderClubs(clubs)
        }
    }
}

struct ClubRowView: View {
    let club: Club

    var body: some View {
        VStack(alignment: .leading) {
            Text(club.name)
                .font(.headline)
            Text("\(club.shotTypes.count) shot type\(club.shotTypes.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ClubDetailView: View {
    let club: Club
    let clubManager: ClubManager?
    @State private var showingAddShotType = false
    @State private var editedName: String = ""
    @State private var isEditingName = false
    @Environment(\.dismiss) private var dismiss

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
            }

            Section("Shot Types") {
                ForEach(club.shotTypes.sorted(by: { $0.sortOrder < $1.sortOrder })) { shotType in
                    ShotTypeRowView(shotType: shotType)
                }
                .onDelete(perform: deleteShotTypes)

                if club.shotTypes.count < 5 {
                    Button {
                        showingAddShotType = true
                    } label: {
                        Label("Add Shot Type", systemImage: "plus")
                    }
                }
            }
        }
        .navigationTitle(club.name)
        .sheet(isPresented: $showingAddShotType) {
            AddShotTypeSheet(club: club, clubManager: clubManager)
        }
    }

    private func deleteShotTypes(at offsets: IndexSet) {
        let sortedShotTypes = club.shotTypes.sorted(by: { $0.sortOrder < $1.sortOrder })
        for index in offsets {
            let shotType = sortedShotTypes[index]
            Task {
                await clubManager?.deleteShotType(shotType, from: club)
            }
        }
    }
}

struct ShotTypeRowView: View {
    let shotType: ShotType

    var body: some View {
        HStack {
            Text(shotType.name)
            Spacer()
            Text("\(shotType.carryDistance) yds")
                .foregroundStyle(.secondary)
        }
    }
}

struct AddClubSheet: View {
    let clubManager: ClubManager?
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var distanceText: String = "150"

    var body: some View {
        NavigationStack {
            Form {
                TextField("Club Name", text: $name)
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
                            await clubManager?.addClub(name: name, defaultDistance: distance)
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
        .modelContainer(for: [Club.self, ShotType.self], inMemory: true)
}
