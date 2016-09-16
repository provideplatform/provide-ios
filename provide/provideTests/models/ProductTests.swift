//
//  ProductTests.swift
//  provide
//
//  Created by Jawwad Ahmad on 6/26/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import XCTest
@testable import provide

class ProductTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEquatable() {
        let product1 = productWithGtin("V000000001")
        let product2 = productWithGtin("V000000001")
        let product3 = productWithGtin("V000000002")

        XCTAssertTrue(product1 !== product2)
        XCTAssertTrue(product1 == product2)
        XCTAssertTrue(product1 != product3)
    }
}

// MARK: - Helper Functions

private func productWithGtin(_ gtin: String) -> Product {
    let product = Product()
    product.gtin = gtin
    return product
}
