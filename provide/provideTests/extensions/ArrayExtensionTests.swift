//
//  ArrayExtensionTests.swift
//  provide
//
//  Created by Jawwad Ahmad on 5/24/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import provide

class ArrayExtensionTests: XCTestCase {

    let array = ["one", "two", "three", "four", "five"]

    func testFindFirst() {
        let fiveLetterWord = array.findFirst { $0.characters.count == 5 }
        XCTAssertEqual("three", fiveLetterWord!)

        let sixLetterWord = array.findFirst { $0.characters.count == 6 }
        XCTAssertNil(sixLetterWord)

        let beginsWithT = array.findFirst { $0.hasPrefix("t") }
        XCTAssertEqual("two", beginsWithT!)
    }
}
