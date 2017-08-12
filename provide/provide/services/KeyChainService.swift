//
//  KeyChainService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import UICKeyChainStore

class KeyChainService {

    fileprivate let uicStore = UICKeyChainStore()

    fileprivate static let sharedInstance = KeyChainService()

    fileprivate var cachedToken: Token?

    class func sharedService() -> KeyChainService {
        return sharedInstance
    }

    subscript(key: String) -> String? {
        get {
            return uicStore[envPrefixedKey(key)]
        }
        set {
            uicStore[envPrefixedKey(key)] = newValue
        }
    }

    var email: String? {
        get {
            return self["email"]
        }
        set {
            self["email"] = newValue
        }
    }

    var mode: UserMode? {
        get {
            if let m = self["mode"] {
                return UserMode(rawValue: m)
            }
            return .Customer
        }
        set {
            self["mode"] = newValue?.rawValue
        }
    }

    var pin: String? {
        get {
            return self["pin"]
        }
        set {
            self["pin"] = newValue
        }
    }

    var token: Token? {
        get {
            if let token = cachedToken {
                return token
            } else if let tokenJsonString = self["token"] {
                cachedToken = Token(string: tokenJsonString)
                return cachedToken
            } else {
                return nil
            }
        }
        set {
            self["token"] = newValue?.toJSONString()
        }
    }

    func clearStoredUserData() {
        cachedToken = nil

        if CurrentBuildConfig != .debug {
            uicStore.removeAllItems()
        } else {
            for key in ["user", "token", "email", "deviceId"] {
                if self[key] != nil {
                    self[key] = nil
                }
            }
        }
    }

    func envPrefixedKey(_ key: String) -> String {
        if CurrentEnvironment == .production {
            return key
        } else {
            return "\(CurrentEnvironment.prefixString)-\(key)"
        }
    }
}
