//
//  Product.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Product: Model {

    var id: NSNumber!
    var gtin: String!
    var data: NSDictionary!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "gtin": "gtin",
            "data": "data"
            ])
        return mapping
    }

    var name: String! {
        return data != nil ? data["name"] as? String : nil
    }

    var desc: String! {
        return data != nil ? data["description"] as? String : nil
    }

    var mpn: String! {
        return data != nil ? data["mpn"] as? String : nil
    }

    var price: Double! {
        return data != nil ? data["price"] as? Double : nil
    }

    var size: String! {
        return data != nil ? data["size"] as? String : nil
    }

    var sku: String! {
        return data != nil ? data["sku"] as? String : nil
    }

}
