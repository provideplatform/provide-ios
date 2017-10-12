//
//  Model+provideTests.swift
//  provideTests
//
//  Created by Jawwad Ahmad on 10/9/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation
@testable import provide

extension Model {
    class func from(file filePath: String) -> Self {
        let (subdir, fileName, ext) = componentsFrom(filePath: filePath)

        let fileURL = Bundle.main.url(forResource: fileName, withExtension: ext, subdirectory: subdir)!
        let data = try! Data(contentsOf: fileURL)
        let dictionary = decodeJSON(data)


        // Uncomment when creating a test to get an initial test body
        // testWriter(dictionary: dictionary)

        let mapperOperation = RKMapperOperation(representation: ["object": dictionary], mappingsDictionary: ["object": mapping()])!
        try! mapperOperation.execute()
        return object(from: mapperOperation, type: self)
    }

    @nonobjc private class func object<T: Model>(from mapperOperation: RKMapperOperation, type: T.Type) -> T {
        return mapperOperation.mappingResult.firstObject as! T
    }
}


private func testWriter(dictionary: [String: Any]) {
    print("\n" + String(repeating: "🚀", count: 40))

    for key in dictionary.keys.sorted() {
        let value = dictionary[key]!
        let camelKey = key.snakeCaseToCamelCaseString()
        let variableName = "object"

        switch value {
        case is NSNull:
            print("XCTAssertEqual(\(variableName).\(camelKey), nil)")
        case is String:
            print("XCTAssertEqual(\(variableName).\(camelKey), \"\(value)\")")
        case is NSNumber:
            print("XCTAssertEqual(\(variableName).\(camelKey), \(value))")
        case let array as [Any]:
            print("XCTAssertEqual(\(variableName).\(camelKey).count, \(array.count))")
        case is NSDictionary:
            print("Property not mapped to object: \(camelKey)")
        default:
            print("XCTAssertNotNil(\(variableName).\(camelKey))")
        }
    }

    print(String(repeating: "🚀", count: 40) + "\n")
}


private func componentsFrom(filePath: String) -> (String, String, String) {
    private var url = URL(fileURLWithPath: filePath)

    let ext = url.pathExtension
    url.deletePathExtension()

    let fileName = url.lastPathComponent
    url.deleteLastPathComponent()

    return (url.relativeString, fileName, ext)
}
