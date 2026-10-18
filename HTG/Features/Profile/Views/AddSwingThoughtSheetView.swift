import SwiftUI

struct AddSwingThoughtSheetView: View {
    let profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    @State private var newSwingThoughtText: String = ""
    @State private var newSwingThoughtTagType: String = "all"
    @State private var newSwingThoughtTagValue: String = ""

    var body: some View {
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
                                    ForEach(profileManager.clubNames ?? [], id: \.self) { name in
                                        Text(name).tag(name)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(GTCColor.primary)
                            } else if newSwingThoughtTagType == "shotType" {
                                Picker("Shot Type", selection: $newSwingThoughtTagValue) {
                                    Text("Select Shot Type").tag("")
                                    ForEach(profileManager.shotTypeNames ?? [], id: \.self) { name in
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
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let tagValue = newSwingThoughtTagType == "all" ? "" : newSwingThoughtTagValue
                        Task {
                            await profileManager.addSwingThought(
                                text: newSwingThoughtText,
                                tagType: newSwingThoughtTagType,
                                tagValue: tagValue
                            )
                            dismiss()
                        }
                    }
                    .gtcProminentActionButtonStyle()
                    .disabled(newSwingThoughtText.trimmingCharacters(in: .whitespaces).isEmpty ||
                              (newSwingThoughtTagType != "all" && newSwingThoughtTagValue.isEmpty))
                }
            }
        }
    }
}
