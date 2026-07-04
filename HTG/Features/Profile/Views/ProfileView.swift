import SwiftUI
import SwiftData
import AuthenticationServices

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var profileManager: ProfileManager?
    @State private var syncManager: AccountSyncManager?
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
            ZStack {
                GTCColor.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: JournalTheme.sectionSpacing) {
                    profileTitle
                        .padding(.top, 8)
                        .padding(.horizontal, JournalTheme.screenHorizontalPadding)

                    if let profile = profileManager?.profile {
                        List {
                            profileSection(profile: profile)
                            preShotRoutineSection(profile: profile)
                            mantraSection(profile: profile)
                            swingThoughtsSection(profile: profile)
                            accountSyncSection
                        }
                        .listStyle(.plain)
                        .listRowSpacing(-20)
                        .scrollContentBackground(.hidden)
                    } else if profileManager?.isLoading == true {
                        ProgressView("Loading profile...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Spacer()
                    }
                }
            }
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
                if syncManager == nil {
                    syncManager = AccountSyncManager(modelContext: modelContext)
                    await syncManager?.restoreSession()
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

    private var profileTitle: some View {
        Text("Profile")
            .font(JournalTheme.pageTitleFont)
            .foregroundStyle(GTCColor.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Profile Section

    private func profileSection(profile: UserProfile) -> some View {
        Section {
            Group {
                if isEditing {
                    editingInfoCard
                } else {
                    infoCard(profile: profile)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } header: {
            GTCSectionEyebrow("Your Information")
        }
    }

    private func infoCard(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            infoRow(label: "Name", value: profile.name)
            infoRow(label: "Handicap", value: "\(profile.handicap)")
            infoRow(label: "Primary Shot Type", value: profile.primaryShotType)

            Button("Edit Profile") {
                nameText = profile.name
                handicapText = "\(profile.handicap)"
                primaryShotTypeText = profile.primaryShotType
                isEditing = true
            }
            .gtcProminentActionButtonStyle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtcAccentCard(fill: GTCColor.background)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(JournalTheme.handwritten(size: 16))
                .foregroundStyle(GTCColor.text)
            Spacer()
            Text(value)
                .font(JournalTheme.handwritten(size: 16))
                .foregroundStyle(GTCColor.secondary)
        }
    }

    private var editingInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Name", text: $nameText)
                .font(JournalTheme.handwritten(size: 16))
                .foregroundStyle(GTCColor.text)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("Handicap")
                    .font(JournalTheme.handwritten(size: 16))
                    .foregroundStyle(GTCColor.text)
                Spacer()
                TextField("0-54", text: $handicapText)
                    .font(JournalTheme.handwritten(size: 16))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: JournalTheme.compactNumericInputWidth)
            }

            if let shotTypeNames = profileManager?.shotTypeNames, !shotTypeNames.isEmpty {
                HStack {
                    Text("Primary Shot Type")
                        .font(JournalTheme.handwritten(size: 16))
                        .foregroundStyle(GTCColor.text)
                    Spacer()
                    Picker("Primary Shot Type", selection: $primaryShotTypeText) {
                        ForEach(shotTypeNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(GTCColor.primary)
                }
            }

            HStack {
                Button("Cancel") {
                    isEditing = false
                }
                .buttonStyle(.bordered)
                .tint(GTCColor.primary)

                Spacer()

                Button("Save") {
                    saveProfile()
                }
                .gtcProminentActionButtonStyle()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtcAccentCard(fill: GTCColor.background)
    }

    // MARK: - Pre-Shot Routine Section

    private func preShotRoutineSection(profile: UserProfile) -> some View {
        Section {
            golfModeToggleRow(isOn: Binding(
                get: { profile.showPreShotRoutine },
                set: { newValue in
                    Task { await profileManager?.setShowPreShotRoutine(newValue) }
                }
            ))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            let sortedItems = profile.preShotRoutineItems.sorted { $0.sortOrder < $1.sortOrder }
            ForEach(sortedItems) { item in
                Text(item.text)
                    .font(JournalTheme.handwritten(size: 15))
                    .foregroundStyle(GTCColor.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .gtcNeutralCard(fill: GTCColor.background)
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
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            HStack {
                TextField("New step", text: $newRoutineItemText)
                    .font(JournalTheme.handwritten(size: 16))
                    .foregroundStyle(GTCColor.text)
                Button("Add") {
                    guard !newRoutineItemText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    Task {
                        await profileManager?.addRoutineItem(text: newRoutineItemText)
                        newRoutineItemText = ""
                    }
                }
                .gtcProminentActionButtonStyle()
                .disabled(newRoutineItemText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .gtcAccentCard(fill: GTCColor.background)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } header: {
            GTCSectionEyebrow("Pre-Shot Routine")
        }
    }

    // MARK: - Mantra Section

    private func mantraSection(profile: UserProfile) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                golfModeToggleRow(isOn: Binding(
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
                .font(JournalTheme.handwritten(size: 16))
                .foregroundStyle(GTCColor.text)
                .textFieldStyle(.roundedBorder)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .gtcAccentCard(fill: GTCColor.background)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } header: {
            GTCSectionEyebrow("Mantra")
        }
    }

    private func golfModeToggleRow(isOn: Binding<Bool>) -> some View {
        Toggle("Show in Golf Mode", isOn: isOn)
            .font(JournalTheme.handwritten(size: 16))
            .foregroundStyle(GTCColor.text)
            .tint(GTCColor.primary)
    }

    // MARK: - Swing Thoughts Section

    private func swingThoughtsSection(profile: UserProfile) -> some View {
        Section {
            if profile.swingThoughts.isEmpty {
                Text("No swing thoughts yet")
                    .font(JournalTheme.handwritten(size: 14))
                    .foregroundStyle(GTCColor.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .gtcNeutralCard(fill: GTCColor.background)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(profile.swingThoughts) { thought in
                    HStack {
                        Text(thought.text)
                            .font(JournalTheme.handwritten(size: 15))
                            .foregroundStyle(GTCColor.text)
                        Spacer()
                        GTCMetaChip(swingThoughtTagLabel(thought))
                    }
                    .gtcNeutralCard(fill: GTCColor.background)
                }
                .onDelete { indexSet in
                    let thoughts = Array(profile.swingThoughts)
                    for index in indexSet {
                        Task { await profileManager?.deleteSwingThought(thoughts[index]) }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Button {
                showingAddSwingThought = true
            } label: {
                Label("Add Swing Thought", systemImage: "plus")
            }
            .gtcProminentActionButtonStyle()
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } header: {
            GTCSectionEyebrow("Swing Thoughts")
        }
    }

    // MARK: - Account & Sync Section

    private var accountSyncSection: some View {
        Section {
            Group {
                if let syncManager, syncManager.isConfigured {
                    if syncManager.isSignedIn {
                        signedInCard(syncManager: syncManager)
                    } else {
                        signedOutCard(syncManager: syncManager)
                    }
                } else {
                    syncUnconfiguredCard
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } header: {
            GTCSectionEyebrow("Account & Sync")
        }
    }

    private var syncUnconfiguredCard: some View {
        Text("Cloud sync isn't set up yet. Add your Supabase project keys to enable backup across devices.")
            .font(JournalTheme.handwritten(size: 14))
            .foregroundStyle(GTCColor.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .gtcNeutralCard(fill: GTCColor.background)
    }

    private func signedOutCard(syncManager: AccountSyncManager) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sign in to back up your clubs, sessions, and profile across devices.")
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(GTCColor.text)

            SignInWithAppleButton(.signIn) { _ in
            } onCompletion: { result in
                Task { await syncManager.handleSignInWithApple(result) }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)

            if case .failure(let message) = syncManager.syncState {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(message)
                }
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(GTCColor.text)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtcAccentCard(fill: GTCColor.background)
    }

    private func signedInCard(syncManager: AccountSyncManager) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            syncStatusRow(state: syncManager.syncState)

            HStack {
                Button("Sign Out") {
                    Task { await syncManager.signOut() }
                }
                .buttonStyle(.bordered)
                .tint(GTCColor.primary)

                Spacer()

                Button("Sync Now") {
                    Task { await syncManager.sync() }
                }
                .gtcProminentActionButtonStyle()
                .disabled(syncManager.syncState == .syncing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gtcAccentCard(fill: GTCColor.background)
    }

    private func syncStatusRow(state: AccountSyncManager.SyncState) -> some View {
        HStack(spacing: 8) {
            switch state {
            case .idle:
                Text("Signed in — ready to sync")
            case .syncing:
                ProgressView()
                Text("Syncing…")
            case .success(let date):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(GTCColor.primary)
                Text("Synced \(date.formatted(date: .omitted, time: .shortened))")
            case .failure(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
            }
        }
        .font(JournalTheme.handwritten(size: 14))
        .foregroundStyle(GTCColor.text)
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
            ZStack {
                GTCColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: JournalTheme.sectionSpacing) {
                        Text("Add Swing Thought")
                            .font(JournalTheme.sheetTitleFont)
                            .foregroundStyle(GTCColor.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: JournalTheme.subsectionSpacing) {
                            GTCSectionEyebrow("Swing Thought")
                            TextField("Swing thought", text: $newSwingThoughtText)
                                .font(JournalTheme.handwritten(size: 16))
                                .foregroundStyle(GTCColor.text)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .gtcTintedAccentCard()

                        VStack(alignment: .leading, spacing: JournalTheme.subsectionSpacing) {
                            GTCSectionEyebrow("Applies To")
                            Picker("Applies to", selection: $newSwingThoughtTagType) {
                                Text("All Clubs").tag("all")
                                Text("Specific Club").tag("club")
                                Text("Shot Type").tag("shotType")
                            }
                            .pickerStyle(.menu)
                            .tint(GTCColor.primary)

                            if newSwingThoughtTagType == "club" {
                                Picker("Club", selection: $newSwingThoughtTagValue) {
                                    Text("Select Club").tag("")
                                    ForEach(profileManager?.clubNames ?? [], id: \.self) { name in
                                        Text(name).tag(name)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(GTCColor.primary)
                            } else if newSwingThoughtTagType == "shotType" {
                                Picker("Shot Type", selection: $newSwingThoughtTagValue) {
                                    Text("Select Shot Type").tag("")
                                    ForEach(profileManager?.shotTypeNames ?? [], id: \.self) { name in
                                        Text(name).tag(name)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(GTCColor.primary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .gtcTintedAccentCard()
                    }
                    .padding(.horizontal, JournalTheme.screenHorizontalPadding)
                    .padding(.vertical, JournalTheme.screenHorizontalPadding)
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
                    .gtcProminentActionButtonStyle()
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
