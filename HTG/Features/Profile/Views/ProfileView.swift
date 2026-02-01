import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var profileManager: ProfileManager?
    @State private var nameText: String = ""
    @State private var handicapText: String = ""
    @State private var primaryShotTypeText: String = "Full"
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            Form {
                if let profile = profileManager?.profile {
                    profileSection(profile: profile)
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
        }
    }

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
        .modelContainer(for: [UserProfile.self, Club.self, ShotType.self], inMemory: true)
}
