import XCTest

/// Smoke tests over the real panel. Each test launches Wedge with its seeded in-memory list
/// ("Draft Q4 launch email", "Review onboarding PR", "Book dentist") and the panel already open.
/// Rows are found by accessibility identifier: `nowHeader` is row 1, `upNextRow-<n>` the Up Next
/// row numbered n (from 2).
final class WedgeUITests: XCTestCase {
    private static let timeout: TimeInterval = 10

    @MainActor
    func testAddEditReorderDoneUndo() {
        let app = launchWithPanel()
        let addField = app.textFields["addField"]
        XCTAssertTrue(addField.waitForExistence(timeout: Self.timeout), "The panel's add field never appeared")

        // 1. Add a row: it lands at the bottom of Up Next.
        addField.click()
        addField.typeText("Write release notes")
        app.typeKey(.return, modifierFlags: [])
        expect(row("upNextRow-4", in: app), labelContains: "Write release notes")

        // 2. Click the row's title to edit it in place; ↩ saves.
        snapshot(app, "before-click")
        row("upNextRow-4", in: app).click()
        snapshot(app, "after-click")
        app.typeKey(.rightArrow, modifierFlags: .command)  // to the end of the text
        app.typeKey(.delete, modifierFlags: .command)  // delete to the start of the line
        app.typeText("Write notes")
        app.typeKey(.return, modifierFlags: [])
        expect(row("upNextRow-4", in: app), labelContains: "Write notes")

        // 3. Saving the edit leaves the row selected and the list focused: ⌥⌘↑ moves it up one place.
        app.typeKey(.upArrow, modifierFlags: [.command, .option])
        expect(row("upNextRow-3", in: app), labelContains: "Write notes")
        expect(row("upNextRow-4", in: app), labelContains: "Book dentist")

        // 4. ⌘↩ marks Now done; the next row becomes Now.
        app.typeKey(.return, modifierFlags: .command)
        expect(row("nowHeader", in: app), labelContains: "Review onboarding PR")

        // 5. ⌘Z undoes the Done.
        app.typeKey("z", modifierFlags: .command)
        expect(row("nowHeader", in: app), labelContains: "Draft Q4 launch email")
    }

    @MainActor
    func testSettingsOpensWithCommandComma() {
        let app = launchWithPanel()
        XCTAssertTrue(
            app.textFields["addField"].waitForExistence(timeout: Self.timeout),
            "The panel's add field never appeared")

        app.typeKey(",", modifierFlags: .command)

        let settings = app.windows.matching(NSPredicate(format: "title == %@", "Wedge Settings")).firstMatch
        XCTAssertTrue(
            settings.waitForExistence(timeout: Self.timeout),
            "No window titled Wedge Settings; windows: \(app.windows.allElementsBoundByIndex.map(\.title))")
    }

    // MARK: - Helpers

    @MainActor
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = name + "-tree"
        tree.lifetime = .keepAlways
        add(tree)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name + "-screen"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    private func launchWithPanel() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-WedgeUITest", "-WedgeUITestShowPanel"]
        app.launch()
        return app
    }

    @MainActor
    private func row(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Waits for the element to exist with a label containing `text` (row labels read "n of m, title").
    @MainActor
    private func expect(
        _ element: XCUIElement, labelContains text: String, file: StaticString = #filePath, line: UInt = #line
    ) {
        let matches = NSPredicate(format: "exists == true AND label CONTAINS %@", text)
        let result = XCTWaiter().wait(
            for: [XCTNSPredicateExpectation(predicate: matches, object: element)], timeout: Self.timeout)
        let found = element.exists ? "label \"\(element.label)\"" : "no such element"
        XCTAssertEqual(result, .completed, "Expected a label containing \"\(text)\"; found \(found)", file: file, line: line)
    }
}
