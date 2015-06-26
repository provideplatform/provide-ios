//
//  RouteServiceTests.swift
//  provide
//
//  Created by Jawwad Ahmad on 6/24/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import XCTest
@testable import provide

class RouteServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()

        OHHTTPStubs.onStubActivation() { request, stub in
            logInfo("\(request.URL!) stubbed by \(stub.name!).")
        }

        stubRoute("GET", "/api/routes", withFile: "HTTPStubs/routes/routes.json", stubName: "RouteServiceTests")
    }

    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testFetch() {
        let expectation = expectationWithDescription("GET routes")

        var fetchedRoutes = [Route]()
        RouteService.sharedService().fetch(
            onRoutesFetched: { routes in
                fetchedRoutes = routes
                expectation.fulfill()
            }
        )

        waitForExpectationsWithTimeout(5) { error in
            XCTAssert(fetchedRoutes.count == 1)

            // Test Route
            let route = fetchedRoutes.first!

            XCTAssertEqual(route.id, 4)
            XCTAssertEqual(route.itemsLoaded, [])
            XCTAssertEqual(route.status, "scheduled")

            // Test WorkOrder
            let workOrder = route.workOrders.first!
            XCTAssertEqual(workOrder.id, 10)
            XCTAssertEqual(workOrder.companyId, 1)
            XCTAssertEqual(workOrder.customerId, 7)
            XCTAssertEqual(workOrder.components.count, 2)
            XCTAssertEqual(workOrder.currentComponentIdentifier, "PackingSlip")
            XCTAssertNil(workOrder.desc)
            XCTAssertNil(workOrder.startedAt)
            XCTAssertNil(workOrder.endedAt)
            XCTAssertNil(workOrder.duration)
            XCTAssertEqual(workOrder.estimatedDuration, 25)
            XCTAssertEqual(workOrder.status, "awaiting_schedule")
            XCTAssertNil(workOrder.endedAt)
            XCTAssertNil(workOrder.providerRating)

            // Test Customer
            let customer = workOrder.customer
            XCTAssertEqual(customer.id, 7)
            XCTAssertEqual(customer.name, "Trisha Jacobson")
            XCTAssertEqual(customer.displayName, "Trisha Jacobson")

            // Test Contact
            let contact = customer.contact
            XCTAssertEqual(contact.id, 17)
            XCTAssertEqual(contact.address1, "6891 Boyle Lodge")
            XCTAssertNil(contact.address2)
            XCTAssertEqual(contact.city, "Lake Garret")
            XCTAssertEqual(contact.state, "Maryland")
            XCTAssertEqual(contact.zip, "37003-1289")
            XCTAssertEqual(contact.email, "ron@borer.biz")
            XCTAssertEqual(contact.phone, "(597) 249-6748")
            XCTAssertNil(contact.fax)
            XCTAssertEqual(contact.mobile, "1-817-130-6064")
            XCTAssertEqual(contact.timeZoneId, "America/Guatemala")
            XCTAssertNil(contact.latitude)
            XCTAssertNil(contact.longitude)
            XCTAssertEqual(workOrder.itemsDelivered.count, 0)
            XCTAssertEqual(workOrder.workOrderProviders.count, 0)
            XCTAssertEqual(workOrder.itemsOrdered.count, 6)

            // Test Product
            let product = workOrder.itemsOrdered.first!
            XCTAssertEqual(product.id, 4)
            XCTAssertEqual(product.gtin, "V000028020")
            XCTAssertEqual(product.name!, "test123124g")
            for thing in [product.desc, product.mpn, product.size, product.sku, product.price] as [AnyObject?] {
                XCTAssertNil(thing)
            }
        }
    }
}
