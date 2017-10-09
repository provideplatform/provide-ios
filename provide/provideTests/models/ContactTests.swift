//
//  ContactTests.swift
//  provideTests
//
//  Created by Jawwad Ahmad on 10/9/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import provide

class ContactTests: XCTestCase {

    func testObjectMapping() {
        let object = Contact.from(file: "HTTPStubs/api/contacts/contact.json")
        XCTAssertEqual(object.address1, "123 Sesame Street")
        XCTAssertEqual(object.address2, nil)
        XCTAssertEqual(object.city, "Springfield")
        XCTAssertEqual(object.data["key"] as! String, "value")
        XCTAssertEqual(object.desc, "the description")
        XCTAssertEqual(object.email, "kyle@provide.services")
        XCTAssertEqual(object.fax, nil)
        XCTAssertEqual(object.id, 5)
        XCTAssertEqual(object.latitude, 77.77)
        XCTAssertEqual(object.longitude, 88.88)
        XCTAssertEqual(object.mobile, nil)
        XCTAssertEqual(object.name, "Kyle Thomas")
        XCTAssertEqual(object.phone, nil)
        XCTAssertEqual(object.state, "DC")
        XCTAssertEqual(object.timeZoneId, "Pacific Time (US & Canada)")
        XCTAssertEqual(object.zip, "12345")
    }
}
