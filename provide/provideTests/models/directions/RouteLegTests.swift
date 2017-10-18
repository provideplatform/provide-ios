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
        let object = RouteLeg.from(file: "HTTPStubs/api/directions/route_leg.json")
        XCTAssertEqual(object.distance, 1027428.0)
        XCTAssertEqual(object.duration, 38558.0)
        XCTAssertEqual(object.miles, 638.4142)
        XCTAssertEqual(object.minutes, 642.63336)
        XCTAssertEqual(object.maneuvers.count, 21)
    }
}
