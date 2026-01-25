import Testing
import SwiftData
@testable import HTG

@Suite("ShotRecommendationService Tests")
@MainActor
struct ShotRecommendationServiceTests {

    private func makeTestContainer() throws -> ModelContainer {
        let schema = Schema([Club.self, ShotType.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func createClub(name: String, shotTypes: [(String, Int)], sortOrder: Int, in context: ModelContext) -> Club {
        let club = Club(name: name, sortOrder: sortOrder)
        for (index, (shotName, distance)) in shotTypes.enumerated() {
            let shotType = ShotType(name: shotName, carryDistance: distance, sortOrder: index, club: club)
            club.shotTypes.append(shotType)
        }
        context.insert(club)
        return club
    }

    @Test("Returns empty array when no clubs provided")
    func returnsEmptyWhenNoClubs() {
        let service = ShotRecommendationService()
        let recommendations = service.getRecommendations(targetYardage: 150, clubs: [], filter: .all)
        #expect(recommendations.isEmpty)
    }

    @Test("Returns single recommendation for single club")
    func returnsSingleRecommendation() throws {
        let container = try makeTestContainer()
        let club = createClub(name: "7 Iron", shotTypes: [("Full", 165)], sortOrder: 0, in: container.mainContext)

        let service = ShotRecommendationService()
        let recommendations = service.getRecommendations(targetYardage: 150, clubs: [club], filter: .all)

        #expect(recommendations.count == 1)
        #expect(recommendations.first?.clubName == "7 Iron")
        #expect(recommendations.first?.shotTypeName == "Full")
        #expect(recommendations.first?.carryDistance == 165)
        #expect(recommendations.first?.distanceDifference == 15)
    }

    @Test("Returns top 5 recommendations sorted by distance difference")
    func returnsTopFiveSortedByDifference() throws {
        let container = try makeTestContainer()
        _ = createClub(name: "Driver", shotTypes: [("Full", 250)], sortOrder: 0, in: container.mainContext)
        _ = createClub(name: "3 Wood", shotTypes: [("Full", 230)], sortOrder: 1, in: container.mainContext)
        _ = createClub(name: "5 Iron", shotTypes: [("Full", 185)], sortOrder: 2, in: container.mainContext)
        _ = createClub(name: "6 Iron", shotTypes: [("Full", 175)], sortOrder: 3, in: container.mainContext)
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 165)], sortOrder: 4, in: container.mainContext)
        _ = createClub(name: "8 Iron", shotTypes: [("Full", 155)], sortOrder: 5, in: container.mainContext)
        _ = createClub(name: "9 Iron", shotTypes: [("Full", 145)], sortOrder: 6, in: container.mainContext)

        let clubs = try container.mainContext.fetch(FetchDescriptor<Club>())
        let service = ShotRecommendationService()
        let recommendations = service.getRecommendations(targetYardage: 160, clubs: clubs, filter: .all)

        #expect(recommendations.count == 5)
        // Closest to 160: 165 (diff 5), 155 (diff 5), 175 (diff 15), 145 (diff 15), 185 (diff 25)
        #expect(recommendations[0].carryDistance == 165 || recommendations[0].carryDistance == 155)
        #expect(recommendations[1].carryDistance == 165 || recommendations[1].carryDistance == 155)
    }

    @Test("Calculates absolute distance difference")
    func calculatesAbsoluteDistanceDifference() throws {
        let container = try makeTestContainer()
        let club = createClub(name: "7 Iron", shotTypes: [("Full", 165)], sortOrder: 0, in: container.mainContext)

        let service = ShotRecommendationService()

        // Target below club distance
        let recsBelow = service.getRecommendations(targetYardage: 150, clubs: [club], filter: .all)
        #expect(recsBelow.first?.distanceDifference == 15)

        // Target above club distance
        let recsAbove = service.getRecommendations(targetYardage: 180, clubs: [club], filter: .all)
        #expect(recsAbove.first?.distanceDifference == 15)
    }

    @Test("Includes multiple shot types from same club")
    func includesMultipleShotTypesFromSameClub() throws {
        let container = try makeTestContainer()
        let club = createClub(
            name: "7 Iron",
            shotTypes: [("Full", 165), ("Three-Quarter", 150), ("Half", 130)],
            sortOrder: 0,
            in: container.mainContext
        )

        let service = ShotRecommendationService()
        let recommendations = service.getRecommendations(targetYardage: 140, clubs: [club], filter: .all)

        #expect(recommendations.count == 3)
        // Sorted by distance to 140: Half (130, diff 10), Three-Quarter (150, diff 10), Full (165, diff 25)
    }

    @Test("Filters by shot type - Full only")
    func filtersByFullShotType() throws {
        let container = try makeTestContainer()
        _ = createClub(
            name: "7 Iron",
            shotTypes: [("Full", 165), ("Three-Quarter", 150), ("Half", 130)],
            sortOrder: 0,
            in: container.mainContext
        )

        let clubs = try container.mainContext.fetch(FetchDescriptor<Club>())
        let service = ShotRecommendationService()
        let recommendations = service.getRecommendations(targetYardage: 140, clubs: clubs, filter: .full)

        #expect(recommendations.count == 1)
        #expect(recommendations.first?.shotTypeName == "Full")
    }

    @Test("Filters by shot type - Three-Quarter only")
    func filtersByThreeQuarterShotType() throws {
        let container = try makeTestContainer()
        _ = createClub(
            name: "7 Iron",
            shotTypes: [("Full", 165), ("Three-Quarter", 150), ("Half", 130)],
            sortOrder: 0,
            in: container.mainContext
        )

        let clubs = try container.mainContext.fetch(FetchDescriptor<Club>())
        let service = ShotRecommendationService()
        let recommendations = service.getRecommendations(targetYardage: 140, clubs: clubs, filter: .threeQuarter)

        #expect(recommendations.count == 1)
        #expect(recommendations.first?.shotTypeName == "Three-Quarter")
    }

    @Test("Filters by shot type - Half only")
    func filtersByHalfShotType() throws {
        let container = try makeTestContainer()
        _ = createClub(
            name: "7 Iron",
            shotTypes: [("Full", 165), ("Three-Quarter", 150), ("Half", 130)],
            sortOrder: 0,
            in: container.mainContext
        )

        let clubs = try container.mainContext.fetch(FetchDescriptor<Club>())
        let service = ShotRecommendationService()
        let recommendations = service.getRecommendations(targetYardage: 140, clubs: clubs, filter: .half)

        #expect(recommendations.count == 1)
        #expect(recommendations.first?.shotTypeName == "Half")
    }

    @Test("Filters by shot type - Punch only")
    func filtersByPunchShotType() throws {
        let container = try makeTestContainer()
        _ = createClub(
            name: "7 Iron",
            shotTypes: [("Full", 165), ("Punch", 140)],
            sortOrder: 0,
            in: container.mainContext
        )

        let clubs = try container.mainContext.fetch(FetchDescriptor<Club>())
        let service = ShotRecommendationService()
        let recommendations = service.getRecommendations(targetYardage: 140, clubs: clubs, filter: .punch)

        #expect(recommendations.count == 1)
        #expect(recommendations.first?.shotTypeName == "Punch")
    }

    @Test("Returns empty when filter matches no shot types")
    func returnsEmptyWhenFilterMatchesNothing() throws {
        let container = try makeTestContainer()
        _ = createClub(name: "7 Iron", shotTypes: [("Full", 165)], sortOrder: 0, in: container.mainContext)

        let clubs = try container.mainContext.fetch(FetchDescriptor<Club>())
        let service = ShotRecommendationService()
        let recommendations = service.getRecommendations(targetYardage: 160, clubs: clubs, filter: .punch)

        #expect(recommendations.isEmpty)
    }

    @Test("Handles exact distance match")
    func handlesExactDistanceMatch() throws {
        let container = try makeTestContainer()
        let club = createClub(name: "7 Iron", shotTypes: [("Full", 165)], sortOrder: 0, in: container.mainContext)

        let service = ShotRecommendationService()
        let recommendations = service.getRecommendations(targetYardage: 165, clubs: [club], filter: .all)

        #expect(recommendations.count == 1)
        #expect(recommendations.first?.distanceDifference == 0)
    }
}
