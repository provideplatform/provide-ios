//
//  RouteTests.swift
//  provideTests
//
//  Created by Jawwad Ahmad on 10/9/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import provide

class RouteTests: XCTestCase {

    func testObjectMapping() {
        let object = Route.from(file: "HTTPStubs/api/directions/route.json")
        XCTAssertEqual(object.legs.count, 1)
        XCTAssertEqual(object.legs.first!.duration, 749)
    }
}
