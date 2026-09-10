import XCTest

final class FlashScopeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEmptyState() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--simulate-empty"]
        app.launch()

        XCTAssertTrue(identifiedElement(in: app, identifier: "empty-state").waitForExistence(timeout: 5))
        XCTAssertTrue(button(in: app, identifier: "empty-refresh-button").waitForExistence(timeout: 3))
    }

    @MainActor
    func testAllSimulationFixturesRenderPremiumOverview() throws {
        let app = simulatedApp()
        app.launch()

        let sidebar = identifiedElement(in: app, identifier: "sidebar-drive-list")
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5), "The removable-storage sidebar should be exposed to accessibility")

        for index in 0...9 {
            let drive = identifiedElement(in: app, identifier: "sidebar-drive-sim-disk-\(index)")
            XCTAssertTrue(
                waitForElement(drive, scrolling: sidebar, timeout: 4),
                "Simulation fixture \(index) should appear in the premium sidebar"
            )
            click(drive, scrolling: sidebar, file: #filePath, line: #line)
            XCTAssertTrue(
                identifiedElement(in: app, identifier: "overview-card").waitForExistence(timeout: 5),
                "Simulation fixture \(index) should render the verdict-first overview"
            )
        }

        XCTAssertTrue(identifiedElement(in: app, identifier: "simulation-mode-banner").exists)
    }

    @MainActor
    func testDriveSelectionAndHealthCheckConfirmation() throws {
        let app = simulatedApp()
        app.launch()

        let firstDrive = identifiedElement(in: app, identifier: "sidebar-drive-sim-disk-0")
        XCTAssertTrue(firstDrive.waitForExistence(timeout: 5))
        click(firstDrive, file: #filePath, line: #line)

        XCTAssertTrue(identifiedElement(in: app, identifier: "overview-card").waitForExistence(timeout: 5))
        click(button(in: app, identifier: "health-check-button"), file: #filePath, line: #line)

        XCTAssertTrue(identifiedElement(in: app, identifier: "health-check-sheet").waitForExistence(timeout: 5))
        XCTAssertTrue(
            benchmarkConfirmationButton(in: app).waitForExistence(timeout: 5),
            "The benchmark confirmation button should remain visible in the diagnostic sheet footer"
        )
    }

    @MainActor
    func testProgressAndCancellation() throws {
        let app = simulatedApp()
        app.launch()

        click(identifiedElement(in: app, identifier: "sidebar-drive-sim-disk-0"), file: #filePath, line: #line)
        click(button(in: app, identifier: "health-check-button"), file: #filePath, line: #line)
        XCTAssertTrue(identifiedElement(in: app, identifier: "health-check-sheet").waitForExistence(timeout: 5))
        click(benchmarkConfirmationButton(in: app), timeout: 5, file: #filePath, line: #line)

        XCTAssertTrue(identifiedElement(in: app, identifier: "benchmark-progress").waitForExistence(timeout: 5))

        let cancelButton = button(in: app, identifier: "cancel-benchmark-button")
        if cancelButton.exists && cancelButton.isHittable {
            cancelButton.click()
        }
    }

    @MainActor
    func testDriveRemovalFixturePresentsStorageError() throws {
        let app = simulatedApp()
        app.launch()

        let sidebar = identifiedElement(in: app, identifier: "sidebar-drive-list")
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5))

        let removed = identifiedElement(in: app, identifier: "sidebar-drive-sim-disk-9")
        XCTAssertTrue(waitForElement(removed, scrolling: sidebar, timeout: 4))
        click(removed, scrolling: sidebar, file: #filePath, line: #line)
        click(button(in: app, identifier: "health-check-button"), file: #filePath, line: #line)
        XCTAssertTrue(identifiedElement(in: app, identifier: "health-check-sheet").waitForExistence(timeout: 5))
        click(benchmarkConfirmationButton(in: app), timeout: 5, file: #filePath, line: #line)

        let alertExists = app.alerts.firstMatch.waitForExistence(timeout: 5)
        let dialogExists = app.dialogs.firstMatch.waitForExistence(timeout: alertExists ? 0 : 2)
        XCTAssertTrue(alertExists || dialogExists, "The simulated drive-removal storage error should be presented as a macOS alert or dialog")
    }

    @MainActor
    func testFindingsAndDiagnosticViews() throws {
        let app = simulatedApp()
        app.launch()
        click(identifiedElement(in: app, identifier: "sidebar-drive-sim-disk-4"), file: #filePath, line: #line)

        let dashboard = app.scrollViews.element(boundBy: 1)
        XCTAssertTrue(dashboard.waitForExistence(timeout: 5), "The diagnostic dashboard should expose its detail scroll view")

        let diagnoseButton = app.buttons.matching(NSPredicate(format: "label == %@", "Diagnose")).firstMatch
        XCTAssertTrue(waitForElement(diagnoseButton, scrolling: dashboard, timeout: 5))
        click(diagnoseButton, scrolling: dashboard, file: #filePath, line: #line)

        let findings = identifiedElement(in: app, identifier: "findings-card")
        XCTAssertTrue(waitForElement(findings, scrolling: dashboard, timeout: 5))

        let connection = identifiedElement(in: app, identifier: "connection-card")
        XCTAssertTrue(waitForElement(connection, scrolling: dashboard, timeout: 5))

        let filesystem = identifiedElement(in: app, identifier: "filesystem-card")
        XCTAssertTrue(waitForElement(filesystem, scrolling: dashboard, timeout: 5))

        let technicalButton = app.buttons.matching(NSPredicate(format: "label == %@", "Technical")).firstMatch
        if waitForElement(technicalButton, scrolling: dashboard, timeout: 3) {
            click(technicalButton, scrolling: dashboard, file: #filePath, line: #line)
            XCTAssertTrue(
                waitForElement(
                    identifiedElement(in: app, identifier: "technical-evidence-card"),
                    scrolling: dashboard,
                    timeout: 5
                )
            )
        }
    }

    @MainActor
    func testExportFlowOpensSavePanel() throws {
        let app = simulatedApp()
        app.launch()
        click(identifiedElement(in: app, identifier: "sidebar-drive-sim-disk-0"), file: #filePath, line: #line)

        let menu = app.popUpButtons.matching(identifier: "export-menu").firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        click(menu, file: #filePath, line: #line)

        let jsonItem = app.menuItems
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "JSON Diagnostic Report"))
            .firstMatch
        XCTAssertTrue(jsonItem.waitForExistence(timeout: 5), "The JSON export command should be exposed as a macOS menu item after opening Export")
        click(jsonItem, file: #filePath, line: #line)

        let sheetExists = app.sheets.firstMatch.waitForExistence(timeout: 4)
        let dialogExists = app.dialogs.firstMatch.waitForExistence(timeout: 4)
        XCTAssertTrue(sheetExists || dialogExists)
        app.typeKey(.escape, modifierFlags: [])
    }

    @MainActor
    private func simulatedApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--simulate"]
        return app
    }

    @MainActor
    private func identifiedElement(in app: XCUIApplication, identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor
    private func button(in app: XCUIApplication, identifier: String) -> XCUIElement {
        app.buttons.matching(identifier: identifier).firstMatch
    }

    @MainActor
    private func benchmarkConfirmationButton(in app: XCUIApplication) -> XCUIElement {
        let byIdentifier = button(in: app, identifier: "confirm-start-benchmark-button")
        if byIdentifier.waitForExistence(timeout: 3) {
            return byIdentifier
        }

        return app.buttons
            .matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Start Standard Check"))
            .firstMatch
    }

    @MainActor
    private func waitForElement(
        _ element: XCUIElement,
        scrolling container: XCUIElement,
        timeout: TimeInterval
    ) -> Bool {
        if element.waitForExistence(timeout: timeout) && element.isHittable {
            return true
        }

        let deltas: [CGFloat] =
            Array(repeating: 240, count: 8) +
            Array(repeating: -240, count: 16) +
            Array(repeating: 240, count: 8)

        for delta in deltas {
            guard container.exists else { break }
            container.scroll(byDeltaX: 0, deltaY: delta)
            if element.waitForExistence(timeout: 0.25) && element.isHittable {
                return true
            }
        }

        return element.exists && element.isHittable
    }

    @MainActor
    private func click(
        _ element: XCUIElement,
        scrolling container: XCUIElement? = nil,
        timeout: TimeInterval = 4,
        file: StaticString,
        line: UInt
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Expected UI element to exist before clicking", file: file, line: line)

        if !element.isHittable, let container, container.exists {
            _ = waitForElement(element, scrolling: container, timeout: 0.5)
        }

        XCTAssertTrue(element.isHittable, "Expected UI element to be hittable before clicking", file: file, line: line)
        element.click()
    }
}
