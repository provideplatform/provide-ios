//
//  provideUITests.swift
//  provideUITests
//
//  Created by Kyle Thomas on 6/23/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import XCTest

class provideUITests: ProvideTestCase {
    func testLoginLogout() {
        login()
        logout()
    }
}
