//
//  WorkOrderServiceTests.swift
//  provide
//
//  Created by Jawwad Ahmad on 5/31/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import provide

class WorkOrderServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()

        OHHTTPStubs.onStubActivation { request, stub in
            logInfo("\(request.URL!) stubbed by \(stub.name).")
        }

        stubRoute("GET", path: "/api/work_orders", withFile: "HTTPStubs/work_orders/work_orders.json", stubName: "WorkOrderServiceTests")
    }

    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testFetch() {
        let expectation = self.expectation(description: "GET work_orders")

        var fetchedWorkOrders = [WorkOrder]()
        WorkOrderService.shared.fetch { workOrders in
            fetchedWorkOrders = workOrders
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5) { error in
            XCTAssert(fetchedWorkOrders.count == 1)

            let workOrder = fetchedWorkOrders.first!

            XCTAssertEqual(workOrder.customer.name, "Kyle Thomas")
            XCTAssertEqual(workOrder.id, 42)
            XCTAssertEqual(workOrder.customer.contact.address1, "111 Summer Dr NE")
            XCTAssertEqual(workOrder.status, "scheduled")

            let provider = workOrder.workOrderProviders.first!
            XCTAssertEqual(provider.provider.contact.address1, "123 Elm St")
        }
    }
}
