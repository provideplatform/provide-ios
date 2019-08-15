//
//  CurrentEnvironment.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import Foundation

private let configuredApiHostSuffix = infoDictionaryValueFor("xApiHostSuffix")
private let configuredMarketingHostSuffix = infoDictionaryValueFor("xMarketingHostSuffix")
private let defaultEnvironment = Environment.production

private let apiHostSuffix = configuredApiHostSuffix != "" ? configuredApiHostSuffix : "unicorn.provide.services"
private let marketingHostSuffix = configuredMarketingHostSuffix != "" ? configuredMarketingHostSuffix : "provide.services"

let CurrentEnvironment = Environment(rawValue: ENV("OVERRIDE_ENVIRONMENT") ?? "") ?? defaultEnvironment

enum Environment: String {
    case qa = "QA"
    case production = "Production"

    var baseUrlString: String {
        return apiBaseUrlString
    }

    var apiBaseUrlString: String {
        let scheme = apiUseSSL ? "https" : "http"
        return "\(scheme)://\(apiHostname)"
    }

    private var apiHostname: String {
        var hostName = apiHostSuffix
        switch self {
        case .qa:
            hostName = "\(prefixString).\(hostName)"
        default:
            break
        }

        return ENV("OVERRIDE_HOST") ?? hostName
    }

    private var apiUseSSL: Bool {
        return apiHostname.hasSuffix(apiHostSuffix)
    }

    var websocketBaseUrlString: String {
        let scheme = apiUseSSL ? "wss" : "ws"
        return "\(scheme)://\(apiHostname)/websocket"
    }

    private var marketingBaseUrlString: String {
        let scheme = marketingUseSSL ? "https" : "http"
        return "\(scheme)://\(marketingHostname)"
    }

    private var marketingHostname: String {
        var hostName = marketingHostSuffix
        switch self {
        case .qa:
            hostName = "\(prefixString).\(hostName)"
        default:
            break
        }

        return ENV("OVERRIDE_HOST") ?? hostName
    }

    private var marketingUseSSL: Bool {
        return marketingHostname.hasSuffix(marketingHostSuffix)
    }

    var prefixString: String {
        return rawValue.lowercased()
    }
}
