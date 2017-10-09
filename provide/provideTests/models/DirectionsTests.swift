//
//  DirectionsTests.swift
//  provideTests
//
//  Created by Jawwad Ahmad on 10/9/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import provide

class DirectionsTests: XCTestCase {

    func testObjectMapping() {
        let object = Directions.from(file: "HTTPStubs/api/directions.json")
        XCTAssertEqual(object.routes.count, 1)
        XCTAssertNotNil(object.routes.first?.legs)
    }
}
