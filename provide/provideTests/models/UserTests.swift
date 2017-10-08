//
//  UserTests.swift
//  provideTests
//
//  Created by Jawwad Ahmad on 10/8/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation

import UIKit
import XCTest
@testable import provide

class UserTests: XCTestCase {

    func testObjectMapping() {
        let user = User.from(file: "HTTPStubs/api/users/user.json")
        XCTAssertEqual(user.id, 3)
        XCTAssertEqual(user.name, "TestUser")
        XCTAssertEqual(user.email, "test@example.com")

        XCTAssertEqual(user.lastCheckinLatitude.doubleValue, 38.891015)
        XCTAssertEqual(user.lastCheckinLongitude.doubleValue, -77.0882267)
        XCTAssertEqual(user.lastCheckinHeading.doubleValue, 9.99)

        XCTAssertEqual(user.profileImageUrlString, "http://test.example.com/image.png")

        XCTAssertEqual(user.companyIds.count, 2)
        XCTAssertEqual(user.companyIds.first, 999)

        XCTAssertEqual(user.menuItems.count, 2)

        let menuItem = user.menuItems.first!

        XCTAssertEqual(menuItem.label, "Jobs")
        XCTAssertEqual(menuItem.storyboard, "JobsStoryboard")

        XCTAssertEqual(user.defaultCompanyId, 999)

        XCTAssertEqual(user.lastCheckinAt, "2017-10-08T01:04:12Z")

        XCTAssertEqual(user.providerIds.count, 1)
        XCTAssertEqual(user.providerIds.first, 3)
    }
}
