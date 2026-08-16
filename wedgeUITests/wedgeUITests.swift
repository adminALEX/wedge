//
//  wedgeUITests.swift
//  wedgeUITests
//
//  Created by Alex Savarimuthu on 16/08/26.
//

import XCTest

final class wedgeUITests: XCTestCase {

    @MainActor
    func testAppExists() throws {
        // Menu-bar apps are awkward in XCUITest; keep a placeholder disabled for v1.
        throw XCTSkip("UI coverage deferred; unit tests cover store/persistence.")
    }
}
