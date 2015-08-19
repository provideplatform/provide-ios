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

        isLoggedIn = app.otherElements["MenuContainerView"].exists
        if isLoggedIn {
            logout()
        }

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
        app.navigationBars["provide.WorkOrdersView"].childrenMatchingType(.Button).elementBoundByIndex(1).tap()
        app.tables.childrenMatchingType(.Cell).elementBoundByIndex(3).tap()
        isLoggedIn = false
    }
}
