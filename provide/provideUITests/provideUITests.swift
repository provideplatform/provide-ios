//
//  provideUITests.swift
//  provideUITests
//
//  Created by Kyle Thomas on 6/23/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import XCTest

// NOTICE: make sure "Hardware -> Keyboard -> Connect hardware keyboard" is unchecked in the target iOS simulator prior to running!!!

class provideUITests: XCTestCase {

    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        XCUIApplication().launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()

        // TODO-- make sure any existing token is destroyed
    }
    
}
