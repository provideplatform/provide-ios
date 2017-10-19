//
//  ManeuverTests.swift
//  provideTests
//
//  Created by Jawwad Ahmad on 10/9/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import provide

class ManeuverTests: XCTestCase {

    func testObjectMapping() {
        let object = Maneuver.from(file: "HTTPStubs/api/directions/maneuver.json")
        XCTAssertEqual(object.action, "depart")
        XCTAssertEqual(object.coordinates["latitude"], 33.74886)
        XCTAssertEqual(object.coordinates["longitude"], -84.38747)
        XCTAssertEqual(object.distance, 1027428)
        XCTAssertEqual(object.duration, 38354)
        XCTAssertEqual(object.miles, 638.4167)
        XCTAssertEqual(object.minutes, 639.23334)
        XCTAssertEqual(object.direction, "forward")
        XCTAssertEqual(object.id, "M1")

        let expectedInstruction = "Head north on Capitol Ave SE. Go for 23 m."
        XCTAssertEqual(object.instruction, expectedInstruction)
        XCTAssertEqual(object.nextManeuver, "M2")
        XCTAssertEqual(object.shapes.count, 2)
        XCTAssertEqual(object.time, "2017-10-17T20:44:28-04:00")
        XCTAssertEqual(object.toLink, "+723646681")
    }
}
