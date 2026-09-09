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

        XCTAssertTrue(identifiedElement(in: app, identifier: "empty-state").waitForExistence(timeout: 3))
        XCTAssertTrue(button(in: app, identifier: "empty-refresh-button").waitForExistence(timeout: 2))
    }

    @MainActor
    func testAllSimulationFixturesRenderPremiumOverview() throws {
        let app = simulatedApp()
        app.launch()

        let sidebar = identifiedElement(in: app, identifier: "sidebar-drive-list")
        XCTAssertTrue(sidebar.waitForExistence(timeout: 3), "The removable-storage sidebar should be exposed to accessibility")

        for index in 0...9 {
            let drive = identifiedElement(in: app, identifier: "sidebar-drive-sim-disk-\(index)")
            XCTAssertTrue(drive.waitForExistence(timeout: 3), "Simulation fixture \(index) should appear in the premium sidebar")
            click(drive, scrolling: sidebar, file: #filePath, line: #line)
            XCTAssertTrue(
                identifiedElement(in: app, identifier: "overview-card").waitForExistence(timeout: 3),
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
        XCTAssertTrue(firstDrive.waitForExistence(timeout: 3))
        click(firstDrive, file: #filePath, line: #line)

        XCTAssertTrue(identifiedElement(in: app, identifier: "overview-card").waitForExistence(timeout: 3))
        click(button(in: app, identifier: "health-check-button"), file: #filePath, line: #line)

        XCTAssertTrue(identifiedElement(in: app, identifier: "health-check-sheet").waitForExistence(timeout: 2))
        XCTAssertTrue(button(in: app, identifier: "confirm-start-benchmark-button").waitForExistence(timeout: 2))
    }

    @MainActor
    func testProgressAndCancellation() throws {
        let app = simulatedApp()
        app.launch()

        click(identifiedElement(in: app, identifier: "sidebar-drive-sim-disk-0"), file: #filePath, line: #line)
        click(button(in: app, identifier: "health-check-button"), file: #filePath, line: #line)
        click(button(in: app, identifier: "confirm-start-benchmark-button"), file: #filePath, line: #line)

        XCTAssertTrue(identifiedElement(in: app, identifier: "benchmark-progress").waitForExistence(timeout: 2))

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
        XCTAssertTrue(sidebar.waitForExistence(timeout: 3))

        let removed = identifiedElement(in: app, identifier: "sidebar-drive-sim-disk-9")
        XCTAssertTrue(removed.waitForExistence(timeout: 3))
        click(removed, scrolling: sidebar, file: #filePath, line: #line)
        click(button(in: app, identifier: "health-check-button"), file: #filePath, line: #line)
        click(button(in: app, identifier: "confirm-start-benchmark-button"), file: #filePath, line: #line)

        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
    }

    @MainActor
    func testFindingsAndDiagnosticViews() throws {
        let app = simulatedApp()
        app.launch()
        click(identifiedElement(in: app, identifier: "sidebar-drive-sim-disk-4"), file: #filePath, line: #line)

        XCTAssertTrue(identifiedElement(in: app, identifier: "findings-card").waitForExistence(timeout: 3))

        let diagnoseButton = app.buttons.matching(NSPredicate(format: "label == %@", "Diagnose")).firstMatch
        XCTAssertTrue(diagnoseButton.waitForExistence(timeout: 2))
        click(diagnoseButton, file: #filePath, line: #line)

        XCTAssertTrue(identifiedElement(in: app, identifier: "connection-card").waitForExistence(timeout: 2))
        XCTAssertTrue(identifiedElement(in: app, identifier: "filesystem-card").waitForExistence(timeout: 2))

        let technicalButton = app.buttons.matching(NSPredicate(format: "label == %@", "Technical")).firstMatch
        if technicalButton.exists {
            click(technicalButton, file: #filePath, line: #line)
            XCTAssertTrue(identifiedElement(in: app, identifier: "technical-evidence-card").waitForExistence(timeout: 2))
        }
    }

    @MainActor
    func testExportFlowOpensSavePanel() throws {
        let app = simulatedApp()
        app.launch()
        click(identifiedElement(in: app, identifier: "sidebar-drive-sim-disk-0"), file: #filePath, line: #line)

        let menu = identifiedElement(in: app, identifier: "export-menu")
        XCTAssertTrue(menu.waitForExistence(timeout: 3))
        click(menu, file: #filePath, line: #line)

        let jsonItem = app.menuItems.matching(NSPredicate(format: "label == %@", "JSON Diagnostic Report…")).firstMatch
        XCTAssertTrue(jsonItem.waitForExistence(timeout: 2))
        click(jsonItem, file: #filePath, line: #line)

        let sheetExists = app.sheets.firstMatch.waitForExistence(timeout: 2)
        let dialogExists = app.dialogs.firstMatch.waitForExistence(timeout: 2)
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
    private func click(
        _ element: XCUIElement,
        scrolling container: XCUIElement? = nil,
        timeout: TimeInterval = 3,
        file: StaticString,
        line: UInt
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Expected UI element to exist before clicking", file: file, line: line)

        if !element.isHittable, let container, container.exists {
            for _ in 0..<6 where !element.isHittable {
                container.scroll(byDeltaX: 0, deltaY: -220)
            }
        }

        XCTAssertTrue(element.isHittable, "Expected UI element to be hittable before clicking", file: file, line: line)
        element.click()
    }
}
