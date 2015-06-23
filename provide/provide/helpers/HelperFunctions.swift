//
//  HelperFunctions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias VoidBlock = () -> Void

let logTimestampDateFormatter = NSDateFormatter(dateFormat: "HH:mm:ss.SSS")

func dispatch_after_delay(seconds: Double, block: dispatch_block_t) {
    let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
    dispatch_after(delay, dispatch_get_main_queue(), block)
}

func dispatch_async_main_queue(block: dispatch_block_t) {
    dispatch_async(dispatch_get_main_queue(), block)
}

func dispatch_async_global_queue(priority: Int, block: dispatch_block_t) {
    dispatch_async(dispatch_get_global_queue(priority, 0), block)
}

func log(message: String, _ fileName: String = __FILE__, _ functionName: String = __FUNCTION__, _ lineNumber: Int = __LINE__) {
    if CurrentBuildConfig == .Debug {
        let timestamp = logTimestampDateFormatter.stringFromDate(NSDate())
        var fileAndMethod = "[\(timestamp)] [\(fileName.lastPathComponent.stringByDeletingPathExtension):\(lineNumber)] "
        fileAndMethod = fileAndMethod.replaceString("ViewController", withString: "VC")
        fileAndMethod = fileAndMethod.stringByPaddingToLength(38, withString: "-", startingAtIndex: 0)
        let logStatement = "\(fileAndMethod)--> \(message)"
        print(logStatement)
    }
}

func why(message: String, fileName: String = __FILE__, functionName: String = __FUNCTION__, lineNumber: Int = __LINE__) {
    log("❓ WHY: \(message)", fileName, functionName, lineNumber)
}

func logError(error: NSError, fileName: String = __FILE__, functionName: String = __FUNCTION__, lineNumber: Int = __LINE__) {
    log("❌ NSError: \(error.localizedDescription)", fileName, functionName, lineNumber)
    fatalError("Encountered: NSError: \(error)")
}

func logError(errorMessage: String, fileName: String = __FILE__, functionName: String = __FUNCTION__, lineNumber: Int = __LINE__) {
    log("‼️ ERROR: \(errorMessage)", fileName, functionName, lineNumber)
}

func logWarn(errorMessage: String, fileName: String = __FILE__, functionName: String = __FUNCTION__, lineNumber: Int = __LINE__) {
    log("⚠️ WARNING: \(errorMessage)", fileName, functionName, lineNumber)
}

func logInfo(infoMessage: String, fileName: String = __FILE__, functionName: String = __FUNCTION__, lineNumber: Int = __LINE__) {
    log("🔵 INFO: \(infoMessage)", fileName, functionName, lineNumber)
}

func ENV(envVarName: String) -> String? {
    if var envVarValue = envVarRawValue(envVarName) {
        if envVarValue.hasPrefix("~") {
            let userHomeDir = envVarRawValue("SIMULATOR_HOST_HOME")!
            envVarValue = envVarValue.replaceString("~", withString: userHomeDir)
        }
        return envVarValue
    } else {
        return nil
    }
}

private func envVarRawValue(envVarName: String) -> String? {
    return NSProcessInfo.processInfo().environment[envVarName] as? NSString as? String
}

func stringFromFile(fileName: String, bundlePath: String? = nil, bundle: NSBundle = NSBundle.mainBundle()) -> String {
    let resourceName = fileName.stringByDeletingPathExtension
    let type = fileName.pathExtension
    let filePath = bundle.pathForResource(resourceName, ofType: type, inDirectory:bundlePath)
    assert(filePath != nil, "File not found: \(resourceName).\(type)")

    var error: NSError?
    let fileAsString: NSString?
    do {
        fileAsString = try NSString(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding)
    } catch let error1 as NSError {
        error = error1
        fileAsString = nil
    }
    if let error = error {
        logError(error)
    }

    return fileAsString as! String
}

func pluralizedPhrase(count: Int, phrase: String, _ suffix: String? = nil) -> String {
    let phrase = count == 1 ? "\(count) \(phrase)" : "\(count) \(phrase)s"
    return suffix == nil ? phrase : "\(phrase) \(suffix!)"
}

func isRunningKIFTests() -> Bool {
    if let injectBundle = ENV("XCInjectBundle") {
        return injectBundle.lastPathComponent.hasSuffix("KIFTests.xctest")
    }
    return false
}

func isRunningUnitTests() -> Bool {
    if let injectBundle = ENV("XCInjectBundle") {
        return injectBundle.lastPathComponent.hasSuffix("Tests.xctest")
    }
    return false
}

func isSimulator() -> Bool {
    let modelName = UIDevice.currentDevice().model
    return modelName == "iPhone Simulator" || modelName == "iPad Simulator"
}

func prettyPrintedJson(uglyJsonStr: String?) -> String! {
    if let uglyJsonString = uglyJsonStr {
        do {
            let uglyJson: AnyObject = try NSJSONSerialization.JSONObjectWithData(uglyJsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: [])
            let prettyPrintedJson = encodeJSON(uglyJson, options: .PrettyPrinted)
            return NSString(data: prettyPrintedJson, encoding: NSUTF8StringEncoding) as! String
        } catch _ {
        }
    }

    return nil
}

func displayNameForProperty(propertyName: String) -> String {
    return propertyName.stringByReplacingOccurrencesOfString("_", withString: " ").capitalizedString
}

func assertUnhandledSegue(segueIdentifier: String?) {
    if let segueIdentifier = segueIdentifier {
        if !segueIdentifier.isEmpty {
            assertionFailure("Unhandled Segue: \(segueIdentifier)")
        }
    }
}

func assertionFailure(message: String, logToAnalytics: Bool) {
    if CurrentBuildConfig == .Debug {
        assertionFailure(message)
    } else if logToAnalytics {
        logWarn("TODO: analytics logging")
    }
}

func swizzleMethodSelector(origSelector: String, withSelector: String, forClass: AnyClass) {
    let originalMethod = class_getInstanceMethod(forClass, Selector(origSelector))
    let swizzledMethod = class_getInstanceMethod(forClass, Selector(withSelector))
    method_exchangeImplementations(originalMethod, swizzledMethod)
}

func classNameForObject(object: AnyObject) -> String {
    let objectName = NSStringFromClass(object.dynamicType)

    if let injectBundle = ENV("XCInjectBundle") {
        let testBundleName = injectBundle.lastPathComponent.stringByDeletingPathExtension
        return objectName.replaceString("\(testBundleName).", withString: "")
    } else {
        return objectName.componentsSeparatedByString(".").last!
    }
}

func decodeJSON(data: NSData) -> [String: AnyObject] {
    let error: NSError?
    let json = NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject]
    if let error = error {
        logError(error)
    }
    return json!
}

func encodeJSON(input: AnyObject, options: NSJSONWritingOptions = []) -> NSData {
    var error: NSError?
    let data: NSData?
    do {
        data = try NSJSONSerialization.dataWithJSONObject(input, options: options)
    } catch let error1 as NSError {
        error = error1
        data = nil
    }
    if let error = error {
        logError(error)
    }
    return data!
}
