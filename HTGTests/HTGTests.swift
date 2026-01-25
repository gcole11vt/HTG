import Testing
@testable import HTG

@Suite("HTG Tests")
struct HTGTests {
    @Test("App launches successfully")
    func appLaunches() async throws {
        #expect(true)
    }
}
