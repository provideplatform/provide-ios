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
    static let shared = KeyChainService()

    private let uicStore = UICKeyChainStore()

    private var cachedToken: Token?

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
            if let mode = UserMode.mode {
                return mode
            }
            if let m = self["mode"] {
                return UserMode(rawValue: m)
            }
            return .consumer
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

    var cryptoOptIn: Bool {
        get {
            return self["cryptoOptIn"] != nil
        }
        set {
            self["cryptoOptIn"] = newValue ? "t" : nil
        }
    }

    var token: Token? {
        get {
            if let token = cachedToken {
                return token
            } else if let tokenJsonString = self["token"] {
                cachedToken = Token(json: tokenJsonString)
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
            for key in ["user", "token", "email", "deviceId", "cryptoOptIn"] where self[key] != nil {
                self[key] = nil
            }
        }
    }

    private func envPrefixedKey(_ key: String) -> String {
        if CurrentEnvironment == .production {
            return key
        } else {
            return "\(CurrentEnvironment.prefixString)-\(key)"
        }
    }
}
