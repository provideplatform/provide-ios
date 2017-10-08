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

        let mapperOperation = RKMapperOperation(representation: ["object": dictionary], mappingsDictionary: ["object": mapping()])!
        try! mapperOperation.execute()
        return object(from: mapperOperation, type: self)
    }

    @nonobjc private class func object<T: Model>(from mapperOperation: RKMapperOperation, type: T.Type) -> T {
        return mapperOperation.mappingResult.firstObject as! T
    }
}


private func componentsFrom(filePath: String) -> (String, String, String) {
    var url = URL(fileURLWithPath: filePath)

    let ext = url.pathExtension
    url.deletePathExtension()

    let fileName = url.lastPathComponent
    url.deleteLastPathComponent()

    return (url.relativeString, fileName, ext)
}
