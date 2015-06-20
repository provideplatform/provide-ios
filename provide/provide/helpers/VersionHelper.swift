//
//  VersionHelper.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

private let infoDictionary = NSBundle.mainBundle().infoDictionary!

class VersionHelper {

    class func buildNumber() -> String {
        return infoDictionaryValueFor("CFBundleVersion")
    }

    class func shortVersion() -> String {
        return infoDictionaryValueFor("CFBundleShortVersionString")
    }

    // mm/dd/yy
    class func buildTime() -> String {
        return infoDictionaryValueFor("xBuildShortTime")
    }

    class func gitSha() -> String {
        return infoDictionaryValueFor("xGitShortSHA")
    }

    class func fullVersion() -> String {
        return "\(shortVersion()).\(buildNumber()) \(buildTime()) (\(gitSha()))"
    }
}

// MARK: Private Functions

private func infoDictionaryValueFor(key: String) -> String {
    return (NSBundle.mainBundle().infoDictionary![key] ?? "") as! String
}
