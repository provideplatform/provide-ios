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
    dispatch_async_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT) {
        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
        dispatch_after(delay, dispatch_get_main_queue(), block)
    }
}

func dispatch_async_main_queue(block: dispatch_block_t) {
    dispatch_async(dispatch_get_main_queue(), block)
}

func dispatch_async_global_queue(priority: Int, block: dispatch_block_t) {
    dispatch_async(dispatch_get_global_queue(priority, 0), block)
}

func log(message: String, _ fileName: String = #file, _ functionName: String = #function, _ lineNumber: Int = #line) {
    if CurrentBuildConfig == .Debug {
        let timestamp = logTimestampDateFormatter.stringFromDate(NSDate())
        var fileAndMethod = "[\(timestamp)] [\(NSString(string: NSString(string: fileName).lastPathComponent).stringByDeletingPathExtension):\(lineNumber)] "
        fileAndMethod = fileAndMethod.replaceString("ViewController", withString: "VC")
        fileAndMethod = fileAndMethod.stringByPaddingToLength(38, withString: "-", startingAtIndex: 0)
        let logStatement = "\(fileAndMethod)--> \(message)"
        print(logStatement)
    }
}

func why(message: String, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
    log("❓ WHY: \(message)", fileName, functionName, lineNumber)
}

func logError(error: NSError, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
    log("❌ NSError: \(error.localizedDescription)", fileName, functionName, lineNumber)
    fatalError("Encountered: NSError: \(error)")
}

func logError(errorMessage: String, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
    log("‼️ ERROR: \(errorMessage)", fileName, functionName, lineNumber)
}

func logWarn(errorMessage: String, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
    log("⚠️ WARNING: \(errorMessage)", fileName, functionName, lineNumber)
}

func logInfo(infoMessage: String, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line) {
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
    return NSProcessInfo.processInfo().environment[envVarName]
}

func stringFromFile(fileName: String, bundlePath: String? = nil, bundle: NSBundle = NSBundle.mainBundle()) -> String {
    let resourceName = NSString(string: fileName).stringByDeletingPathExtension
    let type = NSString(string: fileName).pathExtension
    let filePath = bundle.pathForResource(resourceName, ofType: type, inDirectory:bundlePath)
    assert(filePath != nil, "File not found: \(resourceName).\(type)")

    let fileAsString: NSString?
    do {
        fileAsString = try NSString(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding)
    } catch let error as NSError {
        logError(error.localizedDescription)
        fileAsString = nil
    }

    assert(fileAsString != nil)

    return fileAsString as! String
}

func totalDeviceMemoryInGigabytes() -> CGFloat {
    return CGFloat(NSProcessInfo.processInfo().physicalMemory) / 1073741824.0
}

//func totalMemory() -> UInt32 { // total device memory in bytes
//    var hostPort: mach_port_t
//    var hostSize: UInt32
//    var pageSize: vm_size_t
//    var vmStat: Int32
//
//    hostPort = mach_host_self()
//    hostSize = UInt32(sizeof(vm_statistics_data_t) / sizeof(integer_t))
//    host_page_size(hostPort, &pageSize)
//
//    if host_statistics(hostPort, HOST_VM_INFO, &vmStat, &hostSize) != KERN_SUCCESS {
//        logWarn("Failed to fetch VM statistics")
//    }
//
//    let memoryUsed = (vmStat.active_count + vmStat.inactive_count + vmStat.wire_count) * UInt32(pageSize)
//    let memoryFree = vmStat.free_count * UInt32(pageSize)
//    let memoryTotal = memoryUsed + memoryFree
//    log("used: \(memoryUsed) free: \(memoryFree) total: \(memoryTotal)")
//
//    return memoryTotal
//}

func windowBounds() -> CGRect {
    return UIApplication.sharedApplication().keyWindow!.bounds
}

func pluralizedPhrase(count: Int, phrase: String, _ suffix: String? = nil) -> String {
    let phrase = count == 1 ? "\(count) \(phrase)" : "\(count) \(phrase)s"
    return suffix == nil ? phrase : "\(phrase) \(suffix!)"
}

func isRunningKIFTests() -> Bool {
    if let injectBundle = ENV("XCInjectBundle") {
        return NSString(string: injectBundle).lastPathComponent.hasSuffix("KIFTests.xctest")
    }
    return false
}

func isRunningUnitTests() -> Bool {
    if let injectBundle = ENV("XCInjectBundle") {
        return NSString(string: injectBundle).lastPathComponent.hasSuffix("Tests.xctest")
    }
    return false
}

func isSimulator() -> Bool {
    #if (arch(i386) || arch(x86_64)) && os(iOS)
        return true
    #else
        return false
    #endif
}

func isIPad() -> Bool {
    return UI_USER_INTERFACE_IDIOM() == .Pad
}

func isIPhone() -> Bool {
    return UI_USER_INTERFACE_IDIOM() == .Phone
}

func prettyPrintedJson(uglyJsonStr: String?) -> String {
    if let uglyJsonString = uglyJsonStr {
        let uglyJson: AnyObject = try! NSJSONSerialization.JSONObjectWithData(uglyJsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: [])
        let prettyPrintedJson = encodeJSON(uglyJson, options: .PrettyPrinted)
        return NSString(data: prettyPrintedJson, encoding: NSUTF8StringEncoding) as! String
    }

    return ""
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
        let testBundleName = NSString(string: NSString(string: injectBundle).lastPathComponent).stringByDeletingPathExtension
        return objectName.replaceString("\(testBundleName).", withString: "")
    } else {
        return objectName.componentsSeparatedByString(".").last!
    }
}

func decodeJSON(data: NSData) -> [String: AnyObject] {
    do {
        return try NSJSONSerialization.JSONObjectWithData(data, options: []) as! [String : AnyObject]
    } catch {
        log("\(error)")
        fatalError()
    }
}

func encodeJSON(input: AnyObject, options: NSJSONWritingOptions = []) -> NSData {
    let data: NSData?
    do {
        data = try NSJSONSerialization.dataWithJSONObject(input, options: options)
    } catch let error as NSError {
        logError(error)
        data = nil
    }
    return data!
}
