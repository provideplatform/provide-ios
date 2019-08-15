//
//  AttachmentTests.swift
//  provideTests
//
//  Created by Kyle Thomas on 10/9/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import provide

class AttachmentTests: XCTestCase {

    func testObjectMapping() {
        let attachment = Attachment.from(file: "HTTPStubs/api/attachments/attachment.json")
        XCTAssertEqual(attachment.id, 5)
        XCTAssertEqual(attachment.desc, "the attachment...")
        XCTAssertEqual(attachment.displayUrlString, "https://path.to/vanity.jpg")
        XCTAssertEqual(attachment.key, "48d92f3e-6b83-42b9-8fc8-0044b640263a.jpg")
        XCTAssertEqual(attachment.mimeType, "image/jpeg")
        XCTAssertEqual(attachment.status, "pending")
        XCTAssertEqual(attachment.userId, 1)
        XCTAssertEqual(attachment.attachableId, 1)
        XCTAssertEqual(attachment.attachableType, "user")
        XCTAssertEqual(attachment.tags, ["profile_image", "default"])
        XCTAssertTrue(attachment.metadata is [String: String])
    }
}
