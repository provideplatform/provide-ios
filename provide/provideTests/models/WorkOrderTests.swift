//
//  WorkOrderTests.swift
//  provideTests
//
//  Created by Jawwad Ahmad on 10/9/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation

import UIKit
import XCTest
@testable import provide

class WorkOrderTests: XCTestCase {

    func testObjectMapping() {
        let object = WorkOrder.from(file: "HTTPStubs/api/work_orders/work_order.json")
        XCTAssertEqual(object.abandonedAt, nil)
        // XCTAssertEqual(object.approvedAt, nil)
        // XCTAssertEqual(object.arrivedAt, "2017-10-09T00:53:41Z")
        XCTAssertEqual(object.canceledAt, nil)
        XCTAssertEqual(object.category, nil)
        XCTAssertEqual(object.categoryId, 991)
        XCTAssertNotNil(object.config)
        XCTAssertEqual(object.desc, nil)
        XCTAssertEqual(object.dueAt, nil)
        XCTAssertEqual(object.duration, 255.759392)
        XCTAssertEqual(object.endedAt, "2017-10-09T00:58:12Z")
        XCTAssertEqual(object.estimatedDistance, 3.9)
        XCTAssertEqual(object.estimatedDuration, 22)
        XCTAssertEqual(object.estimatedPrice, 6.76)
        // XCTAssertEqual(object.floorplanId, nil)
        XCTAssertEqual(object.id, 63)
        XCTAssertEqual(object.jobId, 994)
        XCTAssertEqual(object.priority, 0)
        XCTAssertEqual(object.providerRating, 0)
        // XCTAssertEqual(object.rejectedAt, nil)
        XCTAssertEqual(object.scheduledEndAt, nil)
        XCTAssertEqual(object.scheduledStartAt, nil)
        XCTAssertEqual(object.startedAt, "2017-10-09T00:53:56Z")
        XCTAssertEqual(object.status, .completed)
        // XCTAssertEqual(object.submittedForApprovalAt, nil)
        XCTAssertNotNil(object.user)
        XCTAssertEqual(object.userId, 6)
        // XCTAssertEqual(object.userRating, nil)
    }
}
