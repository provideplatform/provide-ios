//
//  CurrentEnvironment.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

private let defaultEnvironment = Environment.production
private let productionApiHostSuffix = "unicorn.provide.services"
private let productionMarketingHostSuffix = "provideapp.com"

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
        var hostName = productionApiHostSuffix
        switch self {
        case .qa:
            hostName = "\(prefixString).\(hostName)"
        default:
            break
        }

        return ENV("OVERRIDE_HOST") ?? hostName
    }

    private var apiUseSSL: Bool {
        return apiHostname.hasSuffix(productionApiHostSuffix)
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
        var hostName = productionMarketingHostSuffix
        switch self {
        case .qa:
            hostName = "\(prefixString).\(hostName)"
        default:
            break
        }

        return ENV("OVERRIDE_HOST") ?? hostName
    }

    private var marketingUseSSL: Bool {
        return marketingHostname.hasSuffix(productionMarketingHostSuffix)
    }

    var prefixString: String {
        return rawValue.lowercased()
    }
}
