//
//  CurrentEnvironment.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import KTSwiftExtensions

private let defaultEnvironment = Environment.Production
private let productionApiHostSuffix = "provide.services"
private let productionMarketingHostSuffix = "provideapp.com"

let CurrentEnvironment = Environment(rawValue: ENV("OVERRIDE_ENVIRONMENT") ?? "") ?? defaultEnvironment

enum Environment: String {
    case QA = "QA"
    case Production = "Production"

    var baseUrlString: String {
        return apiBaseUrlString
    }

    var apiBaseUrlString: String {
        let scheme = apiUseSSL ? "https" : "http"
        return "\(scheme)://\(apiHostname)"
    }

    var apiHostname: String {
        var hostName = productionApiHostSuffix
        switch self {
        case .QA:
            hostName = "\(prefixString).\(hostName)"
        default:
            break
        }

        return ENV("OVERRIDE_HOST") ?? hostName
    }

    var apiUseSSL: Bool {
        return apiHostname.hasSuffix(productionApiHostSuffix)
    }

    var websocketBaseUrlString: String {
        let scheme = apiUseSSL ? "wss" : "ws"
        return "\(scheme)://\(apiHostname)/websocket"
    }

    var marketingBaseUrlString: String {
        let scheme = marketingUseSSL ? "https" : "http"
        return "\(scheme)://\(marketingHostname)"
    }

    var marketingHostname: String {
        var hostName = productionMarketingHostSuffix
        switch self {
        case .QA:
            hostName = "\(prefixString).\(hostName)"
        default:
            break
        }

        return ENV("OVERRIDE_HOST") ?? hostName
    }

    var marketingUseSSL: Bool {
        return marketingHostname.hasSuffix(productionMarketingHostSuffix)
    }

    var prefixString: String {
        return rawValue.lowercaseString
    }
}
