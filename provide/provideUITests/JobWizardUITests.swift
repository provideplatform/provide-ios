//
//  JobWizardUITests.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import XCTest

class JobWizardUITests: ProvideTestCase {
    override func setUp() {
        super.setUp()

        if !isLoggedIn {
            login()
        }
    }

//    func testWorkOrdersTab() {
//        let app = XCUIApplication()
//
//        app.navigationBars["provide.WorkOrdersView"].childrenMatchingType(.Button).elementBoundByIndex(1).tap()
//        app.tables.childrenMatchingType(.Cell).elementBoundByIndex(3).staticTexts["tos_menu_item"].tap()
//        app.tables.staticTexts["yojob"].tap()
//        app.tabBars.buttons["Work Orders"].tap()
//
//    }
}
