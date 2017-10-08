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
        let url = Bundle.main.url(forResource: "user", withExtension: "json", subdirectory: "HTTPStubs/api/users")!
        let data = try! Data(contentsOf: url)
        let dictionary = decodeJSON(data)

        let mapper = RKMapperOperation(representation: dictionary, mappingsDictionary: ["user": User.mapping()])!
        try! mapper.execute()

        let user = mapper.mappingResult.firstObject as! User
        XCTAssertEqual(user.id, 3)
        XCTAssertEqual(user.name, "TestUser")
        XCTAssertEqual(user.email, "test@example.com")

        XCTAssertEqual(user.lastCheckinLatitude.doubleValue, 38.891015)
        XCTAssertEqual(user.lastCheckinLongitude.doubleValue, -77.0882267)
        XCTAssertEqual(user.lastCheckinHeading.doubleValue, 9.99)
    }
}
