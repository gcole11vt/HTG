import SwiftUI
import SwiftData

/// Options + preview sheet for printing tournament-legal yardage cards.
struct YardageSheetView: View {
    let clubs: [Club]
    let primaryShotType: String

    @Environment(\.dismiss) private var dismiss
    @State private var layout: YardageSheetLayout = .byClub
    @State private var pdfFileURL: URL?

    private var clubGroups: [YardageSheetClubGroup] {
        YardageSheetBuilder.clubGroups(from: clubs, primaryShotType: primaryShotType)
    }

    private var yardageEntries: [YardageSheetEntry] {
        YardageSheetBuilder.entriesByYardage(from: clubs)
    }

    private var hasPrintableContent: Bool {
        !yardageEntries.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GTCColor.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: JournalTheme.sectionSpacing) {
                    layoutPicker
                    sheetPreview
                    actionButtons
                }
                .padding(.horizontal, JournalTheme.screenHorizontalPadding)
                .padding(.bottom, JournalTheme.screenHorizontalPadding)
            }
            .navigationTitle("Print Yardages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task(id: layout) {
                regeneratePDF()
            }
        }
    }

    // MARK: - Sections

    private var layoutPicker: some View {
        VStack(alignment: .leading, spacing: JournalTheme.subsectionSpacing) {
            GTCSectionEyebrow("Layout")
            Picker("Layout", selection: $layout) {
                ForEach(YardageSheetLayout.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var pageView: some View {
        YardageSheetPageView(
            layout: layout,
            groups: clubGroups,
            entries: yardageEntries,
            generatedDate: Date()
        )
    }

    private var sheetPreview: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / YardageSheetPDFRenderer.pageSize.width
            ScrollView {
                pageView
                    .frame(
                        width: YardageSheetPDFRenderer.pageSize.width,
                        height: YardageSheetPDFRenderer.pageSize.height
                    )
                    .scaleEffect(scale, anchor: .topLeading)
                    .frame(
                        width: geometry.size.width,
                        height: YardageSheetPDFRenderer.pageSize.height * scale,
                        alignment: .topLeading
                    )
                    .overlay(
                        Rectangle()
                            .stroke(GTCColor.border, lineWidth: 1)
                    )
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                printSheet()
            } label: {
                Label("Print", systemImage: "printer")
                    .frame(maxWidth: .infinity)
            }
            .gtcProminentActionButtonStyle()
            .disabled(!hasPrintableContent)

            if let pdfFileURL {
                ShareLink(item: pdfFileURL) {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(GTCColor.primary)
                .disabled(!hasPrintableContent)
            }
        }
    }

    // MARK: - PDF generation

    private func regeneratePDF() {
        guard hasPrintableContent,
              let data = YardageSheetPDFRenderer.renderPDF(for: pageView) else {
            pdfFileURL = nil
            return
        }
        let fileName = layout == .byClub ? "HTG-Yardages-By-Club.pdf" : "HTG-Yardages-By-Yardage.pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            pdfFileURL = url
        } catch {
            pdfFileURL = nil
        }
    }

    private func printSheet() {
        guard let data = YardageSheetPDFRenderer.renderPDF(for: pageView) else { return }
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "HTG Yardages"
        printInfo.outputType = .general
        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        controller.printingItem = data
        controller.present(animated: true)
    }
}

// MARK: - Printable Page

/// The actual printed page. Print styling is intentionally self-contained:
/// black-on-white, compact, two columns, US Letter.
struct YardageSheetPageView: View {
    let layout: YardageSheetLayout
    let groups: [YardageSheetClubGroup]
    let entries: [YardageSheetEntry]
    let generatedDate: Date

    private enum PrintMetrics {
        static let pagePadding: CGFloat = 36
        static let columnSpacing: CGFloat = 28
        static let columnCount = 2
        static let titleFont = Font.system(size: 22, weight: .semibold, design: .serif)
        static let clubFont = Font.system(size: 12, weight: .bold)
        static let rowFont = Font.system(size: 11, weight: .regular)
        static let distanceFont = Font.system(size: 11, weight: .semibold)
        static let footnoteFont = Font.system(size: 9, weight: .regular)
        static let distanceColumnWidth: CGFloat = 30
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if entries.isEmpty {
                Text("No yardages to print yet")
                    .font(PrintMetrics.rowFont)
                    .foregroundStyle(GTCColor.secondary)
            } else {
                switch layout {
                case .byClub:
                    byClubContent
                case .byYardage:
                    byYardageContent
                }
            }

            Spacer(minLength: 0)
        }
        .padding(PrintMetrics.pagePadding)
        .frame(
            width: YardageSheetPDFRenderer.pageSize.width,
            height: YardageSheetPDFRenderer.pageSize.height,
            alignment: .topLeading
        )
        .background(Color.white)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Yardages")
                .font(PrintMetrics.titleFont)
                .foregroundStyle(GTCColor.primary)
            Spacer()
            Text(generatedDate.formatted(date: .abbreviated, time: .omitted))
                .font(PrintMetrics.footnoteFont)
                .foregroundStyle(GTCColor.secondary)
        }
    }

    private var byClubContent: some View {
        HStack(alignment: .top, spacing: PrintMetrics.columnSpacing) {
            let columns = YardageSheetBuilder.splitGroupsIntoColumns(groups, columnCount: PrintMetrics.columnCount)
            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(column, id: \.clubName) { group in
                        clubBlock(group)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private func clubBlock(_ group: YardageSheetClubGroup) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(group.clubName)
                .font(PrintMetrics.clubFont)
                .foregroundStyle(GTCColor.text)
            Rectangle()
                .fill(GTCColor.border)
                .frame(height: 0.5)
            ForEach(group.entries) { entry in
                HStack {
                    Text(entry.shotTypeName)
                        .font(PrintMetrics.rowFont)
                    Spacer()
                    Text("\(entry.carryDistance)")
                        .font(PrintMetrics.distanceFont)
                        .monospacedDigit()
                }
                .foregroundStyle(GTCColor.text)
            }
        }
    }

    private var byYardageContent: some View {
        HStack(alignment: .top, spacing: PrintMetrics.columnSpacing) {
            let columns = YardageSheetBuilder.splitEntriesIntoColumns(entries, columnCount: PrintMetrics.columnCount)
            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(column) { entry in
                        HStack(spacing: 8) {
                            Text("\(entry.carryDistance)")
                                .font(PrintMetrics.distanceFont)
                                .monospacedDigit()
                                .frame(width: PrintMetrics.distanceColumnWidth, alignment: .trailing)
                            Text(entry.clubName)
                                .font(PrintMetrics.rowFont)
                            Text(entry.shotTypeName)
                                .font(PrintMetrics.rowFont)
                                .foregroundStyle(GTCColor.secondary)
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(GTCColor.text)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}

#Preview("Yardage Sheet") {
    let container: ModelContainer = {
        let schema = Schema([Club.self, ShotType.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let base: [(String, Int)] = [("Driver", 250), ("3 Wood", 230), ("7 Iron", 165), ("Pitching Wedge", 135)]
        for (index, entry) in base.enumerated() {
            let club = Club(name: entry.0, sortOrder: index)
            club.shotTypes = [
                ShotType(name: "Full", carryDistance: entry.1, sortOrder: 0, club: club),
                ShotType(name: "3/4", carryDistance: Int(Double(entry.1) * 0.93), sortOrder: 1, club: club)
            ]
            container.mainContext.insert(club)
        }
        return container
    }()
    let clubs = (try? container.mainContext.fetch(FetchDescriptor<Club>())) ?? []
    return YardageSheetView(clubs: clubs, primaryShotType: "Full")
}
