//
//  Company.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class Company: Model {

    var id = 0
    var name: String!
    var contact: Contact!
    var hasQuickbooksIntegration: NSNumber!
    var config: NSDictionary!

    var isIntegratedWithQuickbooks: Bool {
        return hasQuickbooksIntegration?.boolValue ?? false
    }

    var flooringMaterialTier1CostPerSqFt: Double {
        if let config = config, let costPerSqFt = config["flooring_material_tier1_cost_per_sq_ft"] as? Double {
            return costPerSqFt
        }
        return -1.0
    }

    var flooringMaterialTier2CostPerSqFt: Double {
        if let config = config, let costPerSqFt = config["flooring_material_tier2_cost_per_sq_ft"] as? Double {
            return costPerSqFt
        }
        return -1.0
    }

    var flooringMaterialTier3CostPerSqFt: Double {
        if let config = config, let costPerSqFt = config["flooring_material_tier3_cost_per_sq_ft"] as? Double {
            return costPerSqFt
        }
        return -1.0
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id",
            "name",
            "has_quickbooks_integration",
            "config",
        ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "contact", mapping: Contact.mapping())
        return mapping!
    }
}
