import SwiftUI

/// Pushed from Profile: Golf Mode view style, pre-shot routine, mantra and swing thoughts.
struct GolfModeSettingsView: View {
    let profileManager: ProfileManager
    @State private var newRoutineItemText: String = ""
    @State private var editingRoutineItem: PreShotRoutineItem?
    @State private var editingRoutineItemText: String = ""
    @State private var showingAddSwingThought = false

    var body: some View {
        ZStack {
            GTCColor.background.ignoresSafeArea()

            if let profile = profileManager.profile {
                List {
                    viewStyleSection
                    preShotRoutineSection(profile: profile)
                    mantraSection(profile: profile)
                    swingThoughtsSection(profile: profile)
                }
                .listStyle(.plain)
                .listRowSpacing(-20)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Golf Mode")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Edit Step", isPresented: .init(
            get: { editingRoutineItem != nil },
            set: { if !$0 { editingRoutineItem = nil } }
        )) {
            TextField("Step", text: $editingRoutineItemText)
            Button("Save") { saveEditedRoutineItem() }
            Button("Cancel", role: .cancel) { editingRoutineItem = nil }
        }
        .alert("Error", isPresented: .init(
            get: { profileManager.errorMessage != nil },
            set: { if !$0 { profileManager.errorMessage = nil } }
        )) {
            Button("OK") { profileManager.errorMessage = nil }
        } message: {
            Text(profileManager.errorMessage ?? "")
        }
        .sheet(isPresented: $showingAddSwingThought) {
            AddSwingThoughtSheetView(profileManager: profileManager)
        }
    }

    // MARK: - View Style Section

    private var viewStyleSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Picker("View", selection: Binding(
                    get: { profileManager.golfModeViewStyle },
                    set: { newValue in
                        Task { await profileManager.setGolfModeViewStyle(newValue) }
                    }
                )) {
                    ForEach(DistanceViewStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .gtcAccentCard(fill: GTCColor.background)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } header: {
            GTCSectionEyebrow("View")
        }
    }

    // MARK: - Pre-Shot Routine Section

    private func preShotRoutineSection(profile: UserProfile) -> some View {
        Section {
            golfModeToggleRow(isOn: Binding(
                get: { profile.showPreShotRoutine },
                set: { newValue in
                    Task { await profileManager.setShowPreShotRoutine(newValue) }
                }
            ))
            .gtcAccentCard(fill: GTCColor.background)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            let sortedItems = profile.preShotRoutineItems.sorted { $0.sortOrder < $1.sortOrder }
            ForEach(sortedItems) { item in
                routineItemRow(item: item)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let item = sortedItems[index]
                    Task { await profileManager.deleteRoutineItem(item) }
                }
            }
            .onMove { from, to in
                var reordered = sortedItems
                reordered.move(fromOffsets: from, toOffset: to)
                Task { await profileManager.reorderRoutineItems(reordered) }
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
                        await profileManager.addRoutineItem(text: newRoutineItemText)
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

    private func routineItemRow(item: PreShotRoutineItem) -> some View {
        HStack(spacing: 14) {
            Text(item.text)
                .font(JournalTheme.handwritten(size: 15))
                .foregroundStyle(GTCColor.text)
            Spacer()
            Button {
                editingRoutineItemText = item.text
                editingRoutineItem = item
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundStyle(GTCColor.secondary)
            }
            .buttonStyle(.plain)
            Button {
                Task { await profileManager.deleteRoutineItem(item) }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(GTCColor.secondary)
            }
            .buttonStyle(.plain)
        }
        .gtcNeutralCard(fill: GTCColor.background)
    }

    private func saveEditedRoutineItem() {
        guard let item = editingRoutineItem else { return }
        let text = editingRoutineItemText.trimmingCharacters(in: .whitespaces)
        editingRoutineItem = nil
        guard !text.isEmpty else { return }
        Task { await profileManager.updateRoutineItemText(item, text: text) }
    }

    // MARK: - Mantra Section

    private func mantraSection(profile: UserProfile) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                golfModeToggleRow(isOn: Binding(
                    get: { profile.showMantra },
                    set: { newValue in
                        Task { await profileManager.setShowMantra(newValue) }
                    }
                ))

                TextField("Your mantra", text: Binding(
                    get: { profile.mantra },
                    set: { newValue in
                        Task { await profileManager.updateMantra(newValue) }
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
                        Task { await profileManager.deleteSwingThought(thoughts[index]) }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Button {
                showingAddSwingThought = true
            } label: {
                HStack {
                    Label("Add Swing Thought", systemImage: "plus")
                        .font(JournalTheme.handwritten(size: 16))
                        .foregroundStyle(GTCColor.primary)
                    Spacer()
                }
                .gtcAccentCard(fill: GTCColor.background)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } header: {
            GTCSectionEyebrow("Swing Thoughts")
        }
    }

    private func swingThoughtTagLabel(_ thought: SwingThought) -> String {
        switch thought.tagType {
        case "club": return thought.tagValue
        case "shotType": return thought.tagValue
        default: return "All"
        }
    }
}
