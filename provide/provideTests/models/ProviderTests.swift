//
//  ProviderTests.swift
//  provideTests
//
//  Created by Jawwad Ahmad on 10/9/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import provide

class ProviderTests: XCTestCase {

    func testObjectMapping() {
        let object = Provider.from(file: "HTTPStubs/api/providers/provider.json")
        XCTAssertEqual(object.available, true)
        XCTAssertEqual(object.id, 5)
        XCTAssertEqual(object.lastCheckinAt, "2017-10-09T03:46:46Z")
        XCTAssertEqual(object.lastCheckinHeading, 99.0)
        XCTAssertEqual(object.lastCheckinLatitude, 38.891614)
        XCTAssertEqual(object.lastCheckinLongitude, -77.0855337)
        XCTAssertEqual(object.profileImageUrl, nil)
        XCTAssertEqual(object.userId, 5)
        XCTAssertEqual(object.contact.name, "Kyle Thomas")
    }
}
