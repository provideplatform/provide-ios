//
//  JSONResponseWriter.swift
//  provide
//
//  Created by Jawwad Ahmad on 10/12/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation

class JSONResponseWriter {
    static func writeResponseToFile(_ operation: RKObjectRequestOperation) {
        guard let jsonBaseDir = ProcessInfo.processInfo.environment["WRITE_JSON_RESPONSES"], isSimulator() else { return }
        guard let responseString = operation.httpRequestOperation.responseString else { return }

        let request = operation.httpRequestOperation.request!
        let fullPath = pathForFile(withRequest: request, baseDir: jsonBaseDir)
        try! FileManager.default.createDirectory(atPath: (fullPath as NSString).deletingLastPathComponent, withIntermediateDirectories: true, attributes: nil)
        let prettyJson = prettyPrintedJson(responseString)
        try! prettyJson.write(toFile: fullPath, atomically: true, encoding: .utf8)
    }

    static func pathForFile(withRequest request: URLRequest, baseDir: String) -> String {
        let relativePathFromUrl = request.url!.absoluteString.replacingOccurrences(of: "https://", with: "")
        return "\(baseDir)/\(relativePathFromUrl).\(request.httpMethod!).json"
    }
}
