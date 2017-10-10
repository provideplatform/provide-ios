//
//  RouteLegStepTests.swift
//  provideTests
//
//  Created by Jawwad Ahmad on 10/9/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import provide

class RouteLegStepTests: XCTestCase {

    func testObjectMapping() {
        let object = RouteLegStep.from(file: "HTTPStubs/api/directions/routes/legs/step.json")
        XCTAssertEqual(object.maneuver, "depart")
        XCTAssertEqual(object.baseTime, 75)
        XCTAssertEqual(object.direction, "forward")
        XCTAssertEqual(object.identifier, "M1")

        let expectedInstruction = """
Head toward <span class="toward_street">9th St N</span> on <span class="street">N Quincy St</span>. <span class="distance-description">Go for <span class="length">184 m</span>.</span>
"""
        XCTAssertEqual(object.instruction, expectedInstruction)
        XCTAssertEqual(object.distanceInMeters, 184)
        XCTAssertEqual(object.nextManeuver, "M2")
        XCTAssertEqual(object.position["latitude"], 38.8807907)
        XCTAssertEqual(object.position["longitude"], -77.1076455)
        XCTAssertEqual(object.shape.count, 5)
        XCTAssertEqual(object.time, "2017-10-08T21:55:06-04:00")
        XCTAssertEqual(object.toLink, "+762764135")
        XCTAssertEqual(object.duration, 75)
    }
}
