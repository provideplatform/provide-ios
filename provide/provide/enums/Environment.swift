//
//  CurrentEnvironment.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

private let defaultEnvironment = Environment.Production
private let productionHostSuffix = "provide.services"

let CurrentEnvironment = Environment(rawValue: ENV("OVERRIDE_ENVIRONMENT") ?? "") ?? defaultEnvironment

enum Environment: String {
    case QA = "QA"
    case Production = "Production"
    
    var baseUrlString: String {
        let scheme = useSSL ? "https" : "http"
        return "\(scheme)://\(hostName)"
    }
    
    var hostName: String {
        var hostName = productionHostSuffix
        switch self {
        case .QA:
            hostName = "\(prefixString).\(hostName)"
        default:
            break
        }
        
        return ENV("OVERRIDE_HOST") ?? hostName
    }
    
    var prefixString: String {
        return rawValue.lowercaseString
    }
    
    var useSSL: Bool {
        return hostName.hasSuffix(productionHostSuffix)
    }
    
}
