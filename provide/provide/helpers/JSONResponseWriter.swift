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
        let outputFilePath = pathForFile(withRequest: request, baseDir: jsonBaseDir)
        writeString(responseString, toFile: outputFilePath)
    }

    static func writeWebsocketMessageToFile(_ messageName: String, _ fullMessage: String) {
        guard let jsonBaseDir = ProcessInfo.processInfo.environment["WRITE_JSON_RESPONSES"], isSimulator() else { return }
        let outputFilePath = "\(jsonBaseDir)/provide.services/websocket/\(messageName).json"
        writeString(fullMessage, toFile: outputFilePath)
    }

    private static func writeString(_ jsonString: String, toFile filePath: String) {
        try! FileManager.default.createDirectory(atPath: (filePath as NSString).deletingLastPathComponent, withIntermediateDirectories: true, attributes: nil)

        let uniqueFilePath: String
        if FileManager.default.fileExists(atPath: filePath) {
            let timestamp = Date().format("yyyy-MM-dd_HH:mm:ss.SSS")
            uniqueFilePath = filePath.replacingOccurrences(of: ".json", with: ".\(timestamp).json")
        } else {
            uniqueFilePath = filePath
        }

        let prettyJsonString = prettyPrintedJson(jsonString)
        try! prettyJsonString.write(toFile: uniqueFilePath, atomically: true, encoding: .utf8)
    }

    static func pathForFile(withRequest request: URLRequest, baseDir: String) -> String {
        let relativePathFromUrl = request.url!.absoluteString.replacingOccurrences(of: "https://", with: "")
        return "\(baseDir)/\(relativePathFromUrl).\(request.httpMethod!).json"
    }
}
