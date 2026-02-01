import Testing
import SwiftData
@testable import HTG

@Suite("ClubDistanceResolver Tests")
@MainActor
struct ClubDistanceResolverTests {

    @Test("Returns primary shot type distance when match exists")
    func returnsPrimaryShotTypeDistance() async throws {
        let club = Club(name: "7 Iron", sortOrder: 0)
        let fullShot = ShotType(name: "Full", carryDistance: 165, sortOrder: 0, club: club)
        let threeQuarter = ShotType(name: "Three-Quarter", carryDistance: 150, sortOrder: 1, club: club)
        club.shotTypes = [fullShot, threeQuarter]

        let distance = ClubDistanceResolver.resolveDisplayDistance(for: club, primaryShotType: "Three-Quarter")

        #expect(distance == 150)
    }

    @Test("Falls back to longest distance when no match")
    func fallsBackToLongestDistance() async throws {
        let club = Club(name: "7 Iron", sortOrder: 0)
        let fullShot = ShotType(name: "Full", carryDistance: 165, sortOrder: 0, club: club)
        let half = ShotType(name: "Half", carryDistance: 130, sortOrder: 1, club: club)
        club.shotTypes = [fullShot, half]

        let distance = ClubDistanceResolver.resolveDisplayDistance(for: club, primaryShotType: "Three-Quarter")

        #expect(distance == 165)
    }
}
