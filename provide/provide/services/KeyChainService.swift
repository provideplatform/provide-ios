//
//  KeyChainService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class KeyChainService {

    private let uicStore = UICKeyChainStore()

    class func sharedService() -> KeyChainService {
        struct Static {
            static let instance = KeyChainService()
        }
        return Static.instance
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

    var deviceId: String? {
        get {
            return self["deviceId"]
        }
        set {
            self["deviceId"] = newValue
        }
    }

    var token: Token? {
        get {
            if let tokenJsonString = self["token"] {
                return Token(string: tokenJsonString)
            } else {
                return nil
            }
        }
        set {
            self["token"] = newValue?.toJSONString()
        }
    }

    var user: User? {
        get {
            if let userJsonString = self["user"] {
                return User(string: userJsonString)
            } else {
                return nil
            }
        }
        set {
            self["user"] = newValue?.toJSONString()
        }
    }

    func clearStoredUserData() {
        if CurrentBuildConfig != .Debug {
            uicStore.removeAllItems()
        } else {
            for key in ["user", "token", "email", "deviceId"] {
                if let value = self[key] {
                    self[key] = nil
                }
            }
        }
    }

    func envPrefixedKey(key: String) -> String {
        if CurrentEnvironment == .Production {
            return key
        } else {
            return "\(CurrentEnvironment.prefixString)-\(key)"
        }
    }

}
