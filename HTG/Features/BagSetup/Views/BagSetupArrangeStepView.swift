import SwiftUI

struct BagSetupArrangeStepView: View {
    let manager: BagSetupManager

    var body: some View {
        VStack(alignment: .leading, spacing: JournalTheme.sectionSpacing) {
            header
            clubList
        }
        .padding(.horizontal, JournalTheme.screenHorizontalPadding)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Arrange your bag by carry distance")
                .font(JournalTheme.sheetTitleFont)
                .foregroundStyle(GTCColor.primary)
            Text("Drag to reorder — longest club at the top.")
                .font(JournalTheme.handwritten(size: 14))
                .foregroundStyle(GTCColor.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var clubList: some View {
        List {
            ForEach(manager.arrangedClubNames, id: \.self) { name in
                Text(name)
                    .font(JournalTheme.handwritten(size: 16))
                    .foregroundStyle(GTCColor.text)
                    .listRowBackground(GTCColor.surface)
            }
            .onMove { source, destination in
                manager.moveClubs(fromOffsets: source, toOffset: destination)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
    }
}
