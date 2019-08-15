//
//  CategoryTests.swift
//  provideTests
//
//  Created by Jawwad Ahmad on 10/19/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import provide

class CategoryTests: XCTestCase {

    func testObjectMapping() {
        let object = Category.from(file: "HTTPStubs/api/categories/category.json")
        XCTAssertEqual(object.id, 1)
        XCTAssertEqual(object.name, "Sedan")
        XCTAssertEqual(object.abbreviation, "prvdX")
    }
}
