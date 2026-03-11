import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var profileManager: ProfileManager?
    @State private var nameText: String = ""
    @State private var handicapText: String = ""
    @State private var primaryShotTypeText: String = "Full"
    @State private var isEditing = false
    @State private var newRoutineItemText: String = ""
    @State private var showingAddSwingThought = false
    @State private var newSwingThoughtText: String = ""
    @State private var newSwingThoughtTagType: String = "all"
    @State private var newSwingThoughtTagValue: String = ""

    var body: some View {
        NavigationStack {
            Form {
                if let profile = profileManager?.profile {
                    profileSection(profile: profile)
                    preShotRoutineSection(profile: profile)
                    mantraSection(profile: profile)
                    swingThoughtsSection(profile: profile)
                    statsSection
                } else if profileManager?.isLoading == true {
                    Section {
                        ProgressView("Loading profile...")
                    }
                }
            }
            .navigationTitle("Profile")
            .task {
                if profileManager == nil {
                    profileManager = ProfileManager(modelContext: modelContext)
                    await profileManager?.loadProfile()
                    if let profile = profileManager?.profile {
                        nameText = profile.name
                        handicapText = "\(profile.handicap)"
                        primaryShotTypeText = profile.primaryShotType
                    }
                }
            }
            .alert("Error", isPresented: .init(
                get: { profileManager?.errorMessage != nil },
                set: { if !$0 { profileManager?.errorMessage = nil } }
            )) {
                Button("OK") { profileManager?.errorMessage = nil }
            } message: {
                Text(profileManager?.errorMessage ?? "")
            }
            .sheet(isPresented: $showingAddSwingThought) {
                addSwingThoughtSheet
            }
        }
    }

    // MARK: - Profile Section

    private func profileSection(profile: UserProfile) -> some View {
        Section("Your Information") {
            if isEditing {
                TextField("Name", text: $nameText)
                HStack {
                    Text("Handicap")
                    Spacer()
                    TextField("0-54", text: $handicapText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
                if let shotTypeNames = profileManager?.shotTypeNames, !shotTypeNames.isEmpty {
                    Picker("Primary Shot Type", selection: $primaryShotTypeText) {
                        ForEach(shotTypeNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
                HStack {
                    Button("Cancel") {
                        nameText = profile.name
                        handicapText = "\(profile.handicap)"
                        primaryShotTypeText = profile.primaryShotType
                        isEditing = false
                    }
                    Spacer()
                    Button("Save") {
                        saveProfile()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(profile.name)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Handicap")
                    Spacer()
                    Text("\(profile.handicap)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Primary Shot Type")
                    Spacer()
                    Text(profile.primaryShotType)
                        .foregroundStyle(.secondary)
                }
                Button("Edit Profile") {
                    isEditing = true
                }
            }
        }
    }

    // MARK: - Pre-Shot Routine Section

    private func preShotRoutineSection(profile: UserProfile) -> some View {
        Section("Pre-Shot Routine") {
            Toggle("Show in Golf Mode", isOn: Binding(
                get: { profile.showPreShotRoutine },
                set: { newValue in
                    Task { await profileManager?.setShowPreShotRoutine(newValue) }
                }
            ))

            let sortedItems = profile.preShotRoutineItems.sorted { $0.sortOrder < $1.sortOrder }
            ForEach(sortedItems) { item in
                Text(item.text)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let item = sortedItems[index]
                    Task { await profileManager?.deleteRoutineItem(item) }
                }
            }
            .onMove { from, to in
                var reordered = sortedItems
                reordered.move(fromOffsets: from, toOffset: to)
                Task { await profileManager?.reorderRoutineItems(reordered) }
            }

            HStack {
                TextField("New step", text: $newRoutineItemText)
                Button("Add") {
                    guard !newRoutineItemText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    Task {
                        await profileManager?.addRoutineItem(text: newRoutineItemText)
                        newRoutineItemText = ""
                    }
                }
                .disabled(newRoutineItemText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Mantra Section

    private func mantraSection(profile: UserProfile) -> some View {
        Section("Mantra") {
            Toggle("Show in Golf Mode", isOn: Binding(
                get: { profile.showMantra },
                set: { newValue in
                    Task { await profileManager?.setShowMantra(newValue) }
                }
            ))

            TextField("Your mantra", text: Binding(
                get: { profile.mantra },
                set: { newValue in
                    Task { await profileManager?.updateMantra(newValue) }
                }
            ))
        }
    }

    // MARK: - Swing Thoughts Section

    private func swingThoughtsSection(profile: UserProfile) -> some View {
        Section("Swing Thoughts") {
            if profile.swingThoughts.isEmpty {
                Text("No swing thoughts yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(profile.swingThoughts) { thought in
                    HStack {
                        Text(thought.text)
                        Spacer()
                        Text(swingThoughtTagLabel(thought))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    let thoughts = Array(profile.swingThoughts)
                    for index in indexSet {
                        Task { await profileManager?.deleteSwingThought(thoughts[index]) }
                    }
                }
            }

            Button {
                showingAddSwingThought = true
            } label: {
                Label("Add Swing Thought", systemImage: "plus")
            }
        }
    }

    private func swingThoughtTagLabel(_ thought: SwingThought) -> String {
        switch thought.tagType {
        case "club": return thought.tagValue
        case "shotType": return thought.tagValue
        default: return "All"
        }
    }

    // MARK: - Add Swing Thought Sheet

    private var addSwingThoughtSheet: some View {
        NavigationStack {
            Form {
                TextField("Swing thought", text: $newSwingThoughtText)

                Picker("Applies to", selection: $newSwingThoughtTagType) {
                    Text("All Clubs").tag("all")
                    Text("Specific Club").tag("club")
                    Text("Shot Type").tag("shotType")
                }

                if newSwingThoughtTagType == "club" {
                    Picker("Club", selection: $newSwingThoughtTagValue) {
                        Text("Select Club").tag("")
                        ForEach(profileManager?.clubNames ?? [], id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                } else if newSwingThoughtTagType == "shotType" {
                    Picker("Shot Type", selection: $newSwingThoughtTagValue) {
                        Text("Select Shot Type").tag("")
                        ForEach(profileManager?.shotTypeNames ?? [], id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
            }
            .navigationTitle("Add Swing Thought")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetSwingThoughtForm()
                        showingAddSwingThought = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let tagValue = newSwingThoughtTagType == "all" ? "" : newSwingThoughtTagValue
                        Task {
                            await profileManager?.addSwingThought(
                                text: newSwingThoughtText,
                                tagType: newSwingThoughtTagType,
                                tagValue: tagValue
                            )
                            resetSwingThoughtForm()
                            showingAddSwingThought = false
                        }
                    }
                    .disabled(newSwingThoughtText.trimmingCharacters(in: .whitespaces).isEmpty ||
                              (newSwingThoughtTagType != "all" && newSwingThoughtTagValue.isEmpty))
                }
            }
        }
    }

    private func resetSwingThoughtForm() {
        newSwingThoughtText = ""
        newSwingThoughtTagType = "all"
        newSwingThoughtTagValue = ""
    }

    // MARK: - Existing Sections

    private var statsSection: some View {
        Section("About Handicap") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your handicap represents your playing ability.")
                    .font(.subheadline)
                Text("Valid range: 0 (scratch) to 54 (beginner)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func saveProfile() {
        guard let handicap = Int(handicapText) else { return }
        Task {
            await profileManager?.updateProfile(
                name: nameText,
                handicap: handicap,
                primaryShotType: primaryShotTypeText
            )
            isEditing = false
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, Club.self, ShotType.self, PreShotRoutineItem.self, SwingThought.self], inMemory: true)
}
