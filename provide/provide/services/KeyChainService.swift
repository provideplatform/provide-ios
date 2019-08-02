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
    
    var fbUserId: String? {
        get {
            return self["fb_user_id"]
        }
        set {
            self["fb_user_id"] = newValue
        }
    }
    
    var fbAccessToken: String? {
        get {
            return self["fb_access_token"]
        }
        set {
            self["fb_access_token"] = newValue
        }
    }
    
    var fbAccessTokenExpiresAt: String? {
        get {
            return self["fb_access_token_expires_at"]
        }
        set {
            self["fb_access_token_expires_at"] = newValue
        }
    }

    var mode: UserMode? {
        get {
            if let m = self["mode"] {
                return UserMode(rawValue: m)
            }
            if let mode = UserMode.mode {
                return mode
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
            for key in [
                "user",
                "token",
                "email",
                "deviceId",
                "cryptoOptIn",
                "fbUserId",
                "fbAccessToken",
                "fbAccessTokenExpiresAt"
            ] where self[key] != nil {
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
