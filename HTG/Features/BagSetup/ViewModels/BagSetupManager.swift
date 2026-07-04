import Foundation
import SwiftData

@MainActor
@Observable
final class BagSetupManager {

    enum Step {
        case woods
        case hybrids
        case irons
        case wedges
        case arrange
        case yardages
        case estimating
        case complete
    }

    struct ResolvedYardage: Identifiable, Equatable {
        let name: String
        let yardage: Int
        let isEstimated: Bool

        var id: String { name }
    }

    private(set) var step: Step = .woods
    private(set) var arrangedClubNames: [String] = []
    private(set) var resolvedYardages: [ResolvedYardage] = []
    private(set) var isSaving = false
    var yardageInputs: [String: String] = [:]
    var errorMessage: String?

    private var selectedClubNames: Set<String> = ["Driver"]
    private let clubDataService: ClubDataService

    init(modelContext: ModelContext) {
        self.clubDataService = ClubDataService(modelContext: modelContext)
    }

    // MARK: - Selection

    var selectedCount: Int { selectedClubNames.count }

    var isBagFull: Bool { selectedCount >= ClubDataService.maximumClubs }

    func isSelected(_ name: String) -> Bool {
        selectedClubNames.contains(name)
    }

    func toggle(_ name: String) {
        if selectedClubNames.contains(name) {
            selectedClubNames.remove(name)
        } else if !isBagFull {
            selectedClubNames.insert(name)
        }
    }

    // MARK: - Navigation

    var currentCategory: BagSetupClubCategory? {
        switch step {
        case .woods: .woods
        case .hybrids: .hybrids
        case .irons: .irons
        case .wedges: .wedges
        default: nil
        }
    }

    var canGoBack: Bool {
        step != .woods && step != .complete && !isSaving
    }

    var canAdvance: Bool {
        guard !isSaving else { return false }
        switch step {
        case .wedges: return selectedCount > 0
        case .complete: return false
        default: return true
        }
    }

    func advance() async {
        guard canAdvance else { return }
        switch step {
        case .woods: step = .hybrids
        case .hybrids: step = .irons
        case .irons: step = .wedges
        case .wedges:
            rebuildArrangement()
            step = .arrange
        case .arrange: step = .yardages
        case .yardages: await resolveAndContinue()
        case .estimating: await saveBag()
        case .complete: break
        }
    }

    func goBack() {
        guard canGoBack else { return }
        switch step {
        case .hybrids: step = .woods
        case .irons: step = .hybrids
        case .wedges: step = .irons
        case .arrange: step = .wedges
        case .yardages: step = .arrange
        case .estimating: step = .yardages
        case .woods, .complete: break
        }
    }

    // MARK: - Arrangement

    func moveClubs(fromOffsets source: IndexSet, toOffset destination: Int) {
        arrangedClubNames.move(fromOffsets: source, toOffset: destination)
    }

    /// Keeps any previous manual ordering for clubs that are still selected and
    /// slots newly selected clubs in at the end, in canonical catalog order.
    private func rebuildArrangement() {
        let kept = arrangedClubNames.filter(selectedClubNames.contains)
        let added = BagSetupCatalog.orderedOptions
            .map(\.name)
            .filter { selectedClubNames.contains($0) && !kept.contains($0) }
        arrangedClubNames = kept + added
    }

    // MARK: - Yardages & Saving

    private func resolveAndContinue() async {
        resolvedYardages = resolveYardages()
        if resolvedYardages.contains(where: \.isEstimated) {
            step = .estimating
        } else {
            await saveBag()
        }
    }

    private func resolveYardages() -> [ResolvedYardage] {
        let knownYardages = arrangedClubNames.map(parsedYardage(for:))
        let filledYardages = BagYardageEstimator.estimate(orderedYardages: knownYardages)
            ?? arrangedClubNames.map { BagSetupCatalog.defaultFullDistance(for: $0) ?? 150 }

        return arrangedClubNames.indices.map { index in
            ResolvedYardage(
                name: arrangedClubNames[index],
                yardage: filledYardages[index],
                isEstimated: knownYardages[index] == nil
            )
        }
    }

    private func parsedYardage(for name: String) -> Int? {
        let trimmed = (yardageInputs[name] ?? "").trimmingCharacters(in: .whitespaces)
        guard let yardage = Int(trimmed), yardage > 0 else { return nil }
        return yardage
    }

    private func saveBag() async {
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await clubDataService.replaceBag(
                with: resolvedYardages.map { (name: $0.name, fullDistance: $0.yardage) }
            )
            step = .complete
        } catch {
            errorMessage = "Could not save your bag. Please try again."
        }
    }
}
