//
//  StartrackTestCase.swift
//  startrack
//
//  Created by Kyle Thomas on 8/3/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import XCTest

class StartrackTestCase: XCTestCase {

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        let app = XCUIApplication()
        app.launch()

        isLoggedIn = app.otherElements["MenuContainerView"].exists
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()

        if isLoggedIn {
            logout()
        }
    }

    var isLoggedIn = false

    func login() {
        let app = XCUIApplication()
        app.buttons["SIGN IN"].tap()
        
        let tablesQuery = app.tables
        let emailTextField = tablesQuery.textFields["email"]
        emailTextField.typeText("kyle@unmarkedconsulting.com")

        app.buttons["Next"].tap()

        let passwordSecureTextField = tablesQuery.secureTextFields["password"]
        passwordSecureTextField.typeText("test123")

        app.buttons["Go"].tap()

        isLoggedIn = app.otherElements["MenuContainerView"].exists
    }

    func logout() {
        let app = XCUIApplication()
        let navbar = app.navigationBars["provide.WorkOrdersView"]
        if navbar.exists {
            navbar.childrenMatchingType(.Button).elementBoundByIndex(1).tap()
            app.tables.childrenMatchingType(.Cell).elementBoundByIndex(3).tap()
        } else {
//            app.otherElements["MenuContainerView"].swipeRight()
            app.otherElements["MenuContainerView"].tables.childrenMatchingType(.Cell).elementBoundByIndex(3).tap()
        }
        isLoggedIn = false
    }
}