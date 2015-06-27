//
//  Product.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Product: Model {

    var id = 0
    var gtin: String!
    var data: [String: AnyObject]!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "gtin",
            "data",
            ]
        )
        return mapping
    }

    var name: String? {
        return data["name"] as? String
    }

    var desc: String? {
        return data["description"] as? String
    }

    var mpn: String? {
        return data["mpn"] as? String
    }

    var price: Double? {
        return data["price"] as? Double
    }

    var size: String? {
        return data["size"] as? String
    }

    var sku: String? {
        return data["sku"] as? String
    }
}

// MARK: - Equatable
func == (lhs: Product, rhs: Product) -> Bool {
    return lhs.gtin == rhs.gtin
}
