//
//  Category.swift
//  provide
//
//  Created by Jawwad Ahmad on 10/19/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class Category: Model {

    var id = 0
    var name = ""
    var abbreviation = ""

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id",
            "name",
            "abbreviation",
        ])
        return mapping!
    }

    static func fetchAll(latitude: Double, longitude: Double, radius: Double, onSuccess: @escaping ([Category]) -> Void, onError: @escaping OnError) {
        let params: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "radius": radius,
        ]

        ApiService.shared.fetchCategories(params, onSuccess: { statusCode, mappingResult in
            let categories = mappingResult?.array() as! [Category]
            onSuccess(categories)
        }, onError: onError)
    }
}
