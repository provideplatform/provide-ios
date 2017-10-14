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

    func testObjectsWithoutIdAreNotEquatable() {
        let p1 = Provider()
        let p2 = Provider()

        XCTAssertTrue(p1 != p2)
    }

    func testEquatable() {
        let p1 = Provider()
        p1.id = 5

        let p2 = Provider()
        p2.id = 5

        XCTAssertTrue(p1 == p2)
    }
}
