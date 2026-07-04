import Foundation

struct BagSetupClubOption: Identifiable, Hashable {
    let name: String
    let defaultFullDistance: Int

    var id: String { name }
}

enum BagSetupClubCategory: CaseIterable {
    case woods
    case hybrids
    case irons
    case wedges

    var title: String {
        switch self {
        case .woods: "Select the Woods in your bag?"
        case .hybrids: "Select the Hybrids in your bag?"
        case .irons: "Select the Irons in your bag?"
        case .wedges: "Select the Wedges in your bag?"
        }
    }

    var options: [BagSetupClubOption] {
        switch self {
        case .woods: BagSetupCatalog.woods
        case .hybrids: BagSetupCatalog.hybrids
        case .irons: BagSetupCatalog.irons
        case .wedges: BagSetupCatalog.wedges
        }
    }
}

enum BagSetupCatalog {
    static let woods: [BagSetupClubOption] = [
        BagSetupClubOption(name: "Driver", defaultFullDistance: 250)
    ] + numbered("Wood", from: 2, distances: [240, 230, 222, 215, 208, 201, 194, 187])

    static let hybrids: [BagSetupClubOption] =
        numbered("Hybrid", from: 1, distances: [230, 220, 210, 200, 193, 186, 179, 172, 165])

    static let irons: [BagSetupClubOption] =
        numbered("Iron", from: 1, distances: [225, 215, 205, 195, 185, 175, 165, 155, 145])

    static let wedges: [BagSetupClubOption] = [
        BagSetupClubOption(name: "Pitching Wedge", defaultFullDistance: 135),
        BagSetupClubOption(name: "Gap Wedge", defaultFullDistance: 120),
        BagSetupClubOption(name: "Sand Wedge", defaultFullDistance: 100),
        BagSetupClubOption(name: "Lob Wedge", defaultFullDistance: 80)
    ]

    /// Every selectable club in canonical bag order: woods, hybrids, irons, wedges.
    static let orderedOptions: [BagSetupClubOption] =
        BagSetupClubCategory.allCases.flatMap(\.options)

    static func defaultFullDistance(for name: String) -> Int? {
        orderedOptions.first { $0.name == name }?.defaultFullDistance
    }

    private static func numbered(_ suffix: String, from start: Int, distances: [Int]) -> [BagSetupClubOption] {
        zip(start..., distances).map { number, distance in
            BagSetupClubOption(name: "\(number) \(suffix)", defaultFullDistance: distance)
        }
    }
}
