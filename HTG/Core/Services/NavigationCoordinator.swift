import SwiftUI

@Observable
final class NavigationCoordinator {
    var selectedTab: AppTab = .golf

    var rangePreselectedClubName: String?
    var rangePreselectedShotTypeName: String?
    var rangeAutoStartSession: Bool = false

    func navigateToRange(clubName: String, shotTypeName: String? = nil, autoStart: Bool = false) {
        rangePreselectedClubName = clubName
        rangePreselectedShotTypeName = shotTypeName
        rangeAutoStartSession = autoStart
        selectedTab = .range
    }

    func clearRangePreselection() {
        rangePreselectedClubName = nil
        rangePreselectedShotTypeName = nil
        rangeAutoStartSession = false
    }
}

enum AppTab: Hashable {
    case golf
    case range
    case clubs
    case profile
}
