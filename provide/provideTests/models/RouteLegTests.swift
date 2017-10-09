//
//  RouteLegTests.swift
//  provideTests
//
//  Created by Jawwad Ahmad on 10/9/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import provide

class RouteLegTests: XCTestCase {

    func testObjectMapping() {
        let object = RouteLeg.from(file: "HTTPStubs/api/directions/routes/leg.json")
        XCTAssertEqual(object.steps.count, 7)
        XCTAssertEqual(object.distanceInMeters, 2260)
        XCTAssertEqual(object.duration, 749)
    }
}
