//
//  RouteUITests.swift
//  provide
//
//  Created by Kyle Thomas on 6/25/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import XCTest

class RouteUITests: ProvideTestCase {
    override func setUp() {
        super.setUp()

        if !isLoggedIn {
            login()
        }
    }

    func testMfrmRoute() {
        let app = XCUIApplication()
        app.buttons["+ SCAN"].tap()
        app.buttons["START"].tap()
        app.otherElements["Map pin"].tap()
        app.buttons["START WORK ORDER"].tap()
    }
}
