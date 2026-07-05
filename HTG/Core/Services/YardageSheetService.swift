import SwiftUI
import UIKit

/// One printable yardage line: a club + shot type + carry distance.
struct YardageSheetEntry: Equatable, Identifiable {
    let clubName: String
    let shotTypeName: String
    let carryDistance: Int

    var id: String { "\(clubName)-\(shotTypeName)" }
}

/// A club with its printable shot types, for the by-club layout.
struct YardageSheetClubGroup: Equatable {
    let clubName: String
    let entries: [YardageSheetEntry]

    /// Printed line count: one header line plus one line per entry.
    var lineCount: Int { 1 + entries.count }
}

enum YardageSheetLayout: String, CaseIterable, Identifiable {
    case byClub = "By Club"
    case byYardage = "By Yardage"

    var id: String { rawValue }
}

/// Builds print-ready data from the user's bag. Pure logic — no rendering, no persistence.
enum YardageSheetBuilder {
    /// Active clubs ordered by display distance descending, each with its
    /// active, dialed-in (distance > 0) shot types sorted longest first.
    static func clubGroups(from clubs: [Club], primaryShotType: String) -> [YardageSheetClubGroup] {
        clubs
            .filter { !$0.isArchived }
            .sorted {
                ClubDistanceResolver.resolveDisplayDistance(for: $0, primaryShotType: primaryShotType) >
                ClubDistanceResolver.resolveDisplayDistance(for: $1, primaryShotType: primaryShotType)
            }
            .map { YardageSheetClubGroup(clubName: $0.name, entries: printableEntries(for: $0)) }
            .filter { !$0.entries.isEmpty }
    }

    /// Every printable shot across the bag, flattened and sorted by distance descending.
    static func entriesByYardage(from clubs: [Club]) -> [YardageSheetEntry] {
        clubs
            .filter { !$0.isArchived }
            .flatMap(printableEntries(for:))
            .sorted { $0.carryDistance > $1.carryDistance }
    }

    /// Distributes club groups across print columns, filling each column to a
    /// balanced line target before moving on. Order is preserved (read top-down,
    /// then next column).
    static func splitGroupsIntoColumns(_ groups: [YardageSheetClubGroup], columnCount: Int) -> [[YardageSheetClubGroup]] {
        guard columnCount > 0 else { return [] }
        let totalLines = groups.reduce(0) { $0 + $1.lineCount }
        let targetLinesPerColumn = Int((Double(totalLines) / Double(columnCount)).rounded(.up))
        var columns: [[YardageSheetClubGroup]] = Array(repeating: [], count: columnCount)
        var columnIndex = 0
        var linesInColumn = 0
        for group in groups {
            if linesInColumn >= targetLinesPerColumn && columnIndex < columnCount - 1 {
                columnIndex += 1
                linesInColumn = 0
            }
            columns[columnIndex].append(group)
            linesInColumn += group.lineCount
        }
        return columns
    }

    /// Splits flat entries into sequential print-column chunks.
    static func splitEntriesIntoColumns(_ entries: [YardageSheetEntry], columnCount: Int) -> [[YardageSheetEntry]] {
        guard columnCount > 0 else { return [] }
        let perColumn = Int((Double(entries.count) / Double(columnCount)).rounded(.up))
        var columns: [[YardageSheetEntry]] = []
        var start = 0
        for _ in 0..<columnCount {
            let end = min(start + max(perColumn, 1), entries.count)
            columns.append(Array(entries[start..<max(end, start)]))
            start = end
        }
        return columns
    }

    private static func printableEntries(for club: Club) -> [YardageSheetEntry] {
        club.shotTypes
            .filter { !$0.isArchived && $0.carryDistance > 0 }
            .sorted { $0.carryDistance > $1.carryDistance }
            .map { YardageSheetEntry(clubName: club.name, shotTypeName: $0.name, carryDistance: $0.carryDistance) }
    }
}

/// Renders a SwiftUI page into single-page US Letter PDF data for printing/sharing.
@MainActor
enum YardageSheetPDFRenderer {
    /// US Letter at 72 points per inch.
    static let pageSize = CGSize(width: 612, height: 792)

    static func renderPDF(for page: some View) -> Data? {
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }

        // Printed output must always use the light (primary) palette, never the dark scheme,
        // regardless of the device's current appearance. The SwiftUI `\.colorScheme`
        // environment override alone does NOT reach GTCColor's dynamic `UIColor` providers —
        // ImageRenderer resolves those against `UITraitCollection.current`. So we also pin the
        // current trait collection to light for the entire render pass.
        let lightPage = page
            .frame(width: pageSize.width, height: pageSize.height)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: lightPage)
        renderer.proposedSize = ProposedViewSize(pageSize)

        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        lightTraits.performAsCurrent {
            renderer.render { _, renderInContext in
                context.beginPDFPage(nil)
                renderInContext(context)
                context.endPDFPage()
                context.closePDF()
            }
        }
        return data as Data
    }
}
