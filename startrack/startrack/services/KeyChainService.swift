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

    private static let sharedInstance = KeyChainService()

    private var cachedToken: Token?

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
            if let token = cachedToken {
                return token
            } else if let tokenJsonString = self["token"] {
                let json = migrateProfileImageUrl(tokenJsonString)
                cachedToken = Token(string: json)
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

        if CurrentBuildConfig != .Debug {
            uicStore.removeAllItems()
        } else {
            for key in ["user", "token", "email", "deviceId"] {
                if self[key] != nil {
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

    private func migrateProfileImageUrl(var tokenJsonString: String) -> String! {
        let tokenDict = NSMutableDictionary(dictionary: tokenJsonString.toJSONObject())
        if let user = tokenDict["user"] as? NSDictionary {
            let newUser = NSMutableDictionary(dictionary: user)
            if let profileImageUrlString = newUser["profileImageUrl"] as? String {
                newUser.removeObjectForKey("profileImageUrl")
                newUser.setObject(profileImageUrlString, forKey: "profileImageUrlString")
                tokenDict["user"] = newUser

                tokenJsonString = tokenDict.toJSON()
                token = Token(string: tokenJsonString)
                return tokenJsonString
            }
        }
        return tokenJsonString
    }
}
