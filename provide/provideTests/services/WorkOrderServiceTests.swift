//
//  WorkOrderServiceTests.swift
//  provide
//
//  Created by Jawwad Ahmad on 5/31/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import XCTest

class WorkOrderServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()

        OHHTTPStubs.onStubActivation() { request, stub in
            logInfo("\(request.URL!) stubbed by \(stub.name).")
        }

        let stub = OHHTTPStubs.stubRequestsPassingTest(
            { request in
                request.URL!.path! == "/api/work_orders"
            },
            withStubResponse: { request in
                let fixture = OHPathForFile("HTTPStubs/work_orders/work_orders.json", self.dynamicType)
                return OHHTTPStubsResponse(fileAtPath: fixture!, statusCode: 200, headers: ["Content-Type":"application/json"])
            }
        )
        stub.name = "WorkOrderServiceTests"
    }

    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testFetch() {
        let expectation = expectationWithDescription("GET work_orders")

        let fetchedWorkOrders = [WorkOrder]()
        WorkOrderService.sharedService().fetch { workOrders in
            fetchedWorkOrders = workOrders
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(5) { error in
            XCTAssert(fetchedWorkOrders.count == 1)

            let workOrder = fetchedWorkOrders.first!

            XCTAssertEqual(workOrder.customer.name, "Kyle Thomas")
            XCTAssertEqual(workOrder.id, 42)
            XCTAssertEqual(workOrder.customer.contact.address1, "111 Summer Dr NE")
            XCTAssertEqual(workOrder.status, "scheduled")

            let provider = (workOrder.workOrderProviders as! [WorkOrderProvider]).first!
            XCTAssertEqual(provider.provider.contact.address1, "123 Elm St")
        }
    }
}
