//
//  RouteUITests.swift
//  provide
//
//  Created by Kyle Thomas on 6/25/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import XCTest

class RouteUITests: ProvideTestCase {
    override func setUp() {
        super.setUp()

        login()
    }

    func testMfrmRoute() {
        
        let app = XCUIApplication()
        let provideRoutemanifestviewNavigationBar = app.navigationBars["provide.RouteManifestView"]
        let scanButton = provideRoutemanifestviewNavigationBar.buttons["+ SCAN"]
        scanButton.tap()
        provideRoutemanifestviewNavigationBar.buttons["REQUIRED"].tap()
        
        let onTruckButton2 = provideRoutemanifestviewNavigationBar.buttons["ON TRUCK"]
        onTruckButton2.tap()
        provideRoutemanifestviewNavigationBar.buttons["START"].tap()
        app.otherElements["Map pin"].tap()
        app.buttons["START WORK ORDER"].tap()
        
        let providePackingslipviewNavigationBar = app.navigationBars["provide.PackingSlipView"]
        providePackingslipviewNavigationBar.childrenMatchingType(.Button).elementBoundByIndex(1).tap()
        app.navigationBars["TAKE PHOTO"].buttons["CANCEL"].tap()
        
        let unloadedButton = providePackingslipviewNavigationBar.buttons["UNLOADED"]
        unloadedButton.tap()
        
        let nextKeyboardButton = app.buttons["Next keyboard"]
        nextKeyboardButton.tap()
        
        let okButton = app.alerts["Alternate Keyboards"].collectionViews.buttons["OK"]
        okButton.tap()
        okButton.tap()
        nextKeyboardButton.tap()
        
        let element2 = app.windows.containingType(.Other, identifier:"MenuContainerView").childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.Other).element
        let element = element2.childrenMatchingType(.Other).elementBoundByIndex(1).childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).elementBoundByIndex(2)
        element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.Other).element.childrenMatchingType(.TextView).element.typeText("😎")
        
        let commentOnRejectionNavigationBar = app.navigationBars["COMMENT ON REJECTION"]
        commentOnRejectionNavigationBar.buttons["DISMISS + SAVE"].tap()
        
        let onTruckButton = providePackingslipviewNavigationBar.buttons["ON TRUCK"]
        onTruckButton.tap()
        
        let rejectedButton = providePackingslipviewNavigationBar.buttons["REJECTED"]
        rejectedButton.tap()
        unloadedButton.tap()
        element.tables.childrenMatchingType(.Cell).elementBoundByIndex(3).staticTexts["Sleek Plastic Shoes"].swipeLeft()
        commentOnRejectionNavigationBar.buttons["DISMISS"].tap()
        onTruckButton.tap()
        rejectedButton.tap()
        app.navigationBars["provide.WorkOrdersView"].buttons["DELIVER"].tap()
        element2.swipeDown()
        app.buttons["Done"].tap()
        app.buttons["10"].tap()
        provideRoutemanifestviewNavigationBar.buttons["DELIVERED"].tap()
        onTruckButton2.tap()
        scanButton.tap()

    }
}
