//
//  ProvideTestCase.swift
//  provide
//
//  Created by Kyle Thomas on 6/25/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import XCTest

class ProvideTestCase: XCTestCase {
    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        XCUIApplication().launch()
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

        let emailTextField = app.tables.textFields["email"]
        emailTextField.typeText("kyle@unmarkedconsulting.com")

        app.buttons["Next"].tap()

        let xcuiSecureTextField = app.tables.textFields["_XCUI:Secure"]
        xcuiSecureTextField.typeText("test123")

        app.buttons["Go"].tap()

        isLoggedIn = app.navigationBars["provide.WorkOrdersView"].exists
    }

    func logout() {
        let app = XCUIApplication()
        app.navigationBars["provide.WorkOrdersView"].swipeRight()

        let logoutSliderStaticText = app.tables.childrenMatchingType(.Cell).elementAtIndex(2).staticTexts["logout_slider"]
        logoutSliderStaticText.tap()
    }
}
