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
    @State private var showingBagSetup = false
    @State private var showingGolfModeSettings = false

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
                            golfModeSettingsSection(profile: profile)
                            accountSyncSection
                            bagSetupSection
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
                    await reloadProfileAfterSync()
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
            .navigationDestination(isPresented: $showingGolfModeSettings) {
                if let profileManager {
                    GolfModeSettingsView(profileManager: profileManager)
                }
            }
            .fullScreenCover(isPresented: $showingBagSetup) {
                BagSetupView()
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

    // MARK: - Golf Mode Section

    private func golfModeSettingsSection(profile: UserProfile) -> some View {
        Section {
            Button {
                showingGolfModeSettings = true
            } label: {
                HStack {
                    Label("Golf Mode Settings", systemImage: "flag")
                        .font(JournalTheme.handwritten(size: 16))
                        .foregroundStyle(GTCColor.primary)
                    Spacer()
                    Text("View: \(profile.golfModeViewStyle.title)")
                        .font(JournalTheme.handwritten(size: 14))
                        .foregroundStyle(GTCColor.secondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GTCColor.secondary)
                }
                .gtcAccentCard(fill: GTCColor.background)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } header: {
            GTCSectionEyebrow("Golf Mode")
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
                    Task {
                        await syncManager.sync()
                        await reloadProfileAfterSync()
                    }
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

    // MARK: - First Time Set Up Section

    private var bagSetupSection: some View {
        Section {
            Button {
                showingBagSetup = true
            } label: {
                HStack {
                    Label("Initial Bag Set Up", systemImage: "figure.golf")
                        .font(JournalTheme.handwritten(size: 16))
                        .foregroundStyle(GTCColor.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(GTCColor.secondary)
                }
                .gtcAccentCard(fill: GTCColor.background)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } header: {
            GTCSectionEyebrow("First Time Set Up")
        }
    }

    /// Sync can replace or consolidate the profile row, so re-resolve it and
    /// re-prime the display fields once a sync finishes.
    private func reloadProfileAfterSync() async {
        await profileManager?.loadProfile()
        guard !isEditing, let profile = profileManager?.profile else { return }
        nameText = profile.name
        handicapText = "\(profile.handicap)"
        primaryShotTypeText = profile.primaryShotType
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
