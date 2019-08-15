//
//  ModelDescriptions.swift
//  provide
//
//  Created by Jawwad Ahmad on 10/22/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import Foundation

extension WorkOrder {
    override var description: String {
        let address = (config?["destination"] as? [String: Any])?["formatted_address"] ?? ""
        return "🗓 { id: \(id), status: \(status), distance: \(estimatedDistance), address: \(address) }"
    }
}
