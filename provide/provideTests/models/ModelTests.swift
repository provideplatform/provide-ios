//
//  ModelTests.swift
//  provideTests
//
//  Created by Jawwad Ahmad on 10/14/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation

import UIKit
import XCTest
@testable import provide

class ModelTests: XCTestCase {

    func testModelObjectsAreNotYetEquatableByIdWhyNot() {
        let p1 = Provider()
        p1.id = 5

        let p2 = Provider()
        p2.id = 5

        XCTAssertFalse(p1 == p2)
    }

    func testToDictionary() {
        // Moving the id property into the Model superclass will break this test
        let user = User.from(file: "HTTPStubs/api/users/user.json")
        XCTAssertEqual(user.id, 3)

        let dict = user.toDictionary()

        XCTAssertEqual(dict["id"] as? Int, 3)
    }
}
