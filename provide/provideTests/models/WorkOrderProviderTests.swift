//
//  WorkOrderProviderTests.swift
//  provideTests
//
//  Created by Jawwad Ahmad on 10/9/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import provide

class WorkOrderProviderTests: XCTestCase {

    func testObjectMapping() {
        let object = WorkOrderProvider.from(file: "HTTPStubs/api/work_orders/work_order_provider.json")
        XCTAssertEqual(object.checkinCoordinates.count, 5)
        XCTAssertEqual(object.duration, 99.99)
        XCTAssertEqual(object.estimatedCost, 999.99)
        XCTAssertEqual(object.estimatedDuration, 991)
        XCTAssertEqual(object.flatFee, 0.0)
        XCTAssertEqual(object.hourlyRate, 9.99)
        XCTAssertEqual(object.id, 44)
        XCTAssertEqual(object.rating, 4.5)
        XCTAssertEqual(object.timedOutAt, "2017-10-09T00:52:14Z")
        XCTAssertNotNil(object.provider)
        XCTAssertTrue(object.provider.isAvailable)
    }
}
