import XCTest

final class HTGUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testInitialBagSetupFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate: Profile tab -> scroll to bottom -> Initial Bag Set Up
        // (retry: the launch screen overlay can swallow the first tap)
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 15))
        Thread.sleep(forTimeInterval: 2)
        let profileTitle = app.staticTexts["Profile"]
        for _ in 0..<4 where !profileTitle.exists {
            profileTab.tap()
            _ = profileTitle.waitForExistence(timeout: 2)
        }
        XCTAssertTrue(profileTitle.waitForExistence(timeout: 5))

        let setupButton = app.buttons["Initial Bag Set Up"]
        var scrollAttempts = 0
        while (!setupButton.exists || !setupButton.isHittable) && scrollAttempts < 8 {
            app.swipeUp()
            scrollAttempts += 1
        }
        attach(app, named: "01-profile-entry")
        Thread.sleep(forTimeInterval: 1)
        setupButton.tap()

        // Woods step: Driver auto-selected, counter live-updates
        let woodsTitle = app.staticTexts["Select the Woods in your bag?"]
        if !woodsTitle.waitForExistence(timeout: 3) {
            setupButton.tap()
        }
        XCTAssertTrue(woodsTitle.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(app.staticTexts["1/13"].exists)
        tap(app.buttons["3 Wood"], until: app.staticTexts["2/13"])
        tap(app.buttons["3 Wood"], until: app.staticTexts["1/13"])
        tap(app.buttons["3 Wood"], until: app.staticTexts["2/13"])
        attach(app, named: "02-woods")

        // Every navigation tap goes through tap(_:until:) — a bare tap can fire
        // during the previous step's transition animation and miss.
        let next = app.buttons["bagSetupNextButton"]
        let back = app.buttons["bagSetupBackButton"]
        XCTAssertFalse(back.isEnabled)
        let hybridsTitle = app.staticTexts["Select the Hybrids in your bag?"]
        tap(next, until: hybridsTitle)

        // Hybrids step, check Back returns to Woods and Next again
        tap(back, until: woodsTitle)
        tap(next, until: hybridsTitle)
        tap(next, until: app.staticTexts["Select the Irons in your bag?"])

        // Irons step
        tap(app.buttons["7 Iron"], until: app.staticTexts["3/13"])
        tap(app.buttons["8 Iron"], until: app.staticTexts["4/13"])
        tap(app.buttons["9 Iron"], until: app.staticTexts["5/13"])
        tap(next, until: app.staticTexts["Select the Wedges in your bag?"])

        // Wedges step
        tap(app.buttons["Pitching Wedge"], until: app.staticTexts["6/13"])
        attach(app, named: "03-wedges")
        tap(next, until: app.staticTexts["Arrange your bag by carry distance"])

        // Arrange step
        attach(app, named: "04-arrange")
        tap(next, until: app.staticTexts["Pre-fill any full yardages you know"])

        // Yardage step: fill Driver and 9 Iron, leave the rest for the estimator
        enterText("250", into: app.textFields["yardageInput-Driver"])
        enterText("120", into: app.textFields["yardageInput-9 Iron"])
        attach(app, named: "05-yardages")
        tap(next, until: app.staticTexts["Estimating other yardages"])

        // Estimating step
        attach(app, named: "06-estimating")

        // Complete step
        let rangeMessage = app.staticTexts["Head to the Range to Dial In Your Yardages"]
        tap(next, until: rangeMessage)
        attach(app, named: "07-complete")
        app.buttons["Done"].tap()

        // Persistence: Clubs tab shows the new 6-club bag
        // (retry: a tap during the fullScreenCover dismissal animation can miss)
        let threeWood = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "3 Wood")).firstMatch
        Thread.sleep(forTimeInterval: 1)
        for _ in 0..<4 where !threeWood.exists {
            app.tabBars.buttons["Clubs"].tap()
            _ = threeWood.waitForExistence(timeout: 3)
        }
        XCTAssertTrue(threeWood.waitForExistence(timeout: 5))
        let pitchingWedge = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Pitching Wedge")).firstMatch
        XCTAssertTrue(pitchingWedge.waitForExistence(timeout: 5))
        attach(app, named: "08-clubs-after")
    }

    @MainActor
    private func tap(_ element: XCUIElement, until expected: XCUIElement) {
        for _ in 0..<3 {
            element.tap()
            if expected.waitForExistence(timeout: 2) { return }
        }
        XCTFail("Expected \(expected) after tapping \(element)")
    }

    @MainActor
    private func enterText(_ text: String, into field: XCUIElement) {
        for _ in 0..<4 {
            field.tap()
            if (field.value(forKey: "hasKeyboardFocus") as? Bool) == true { break }
            Thread.sleep(forTimeInterval: 0.5)
        }
        field.typeText(text)
    }

    @MainActor
    private func attach(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
