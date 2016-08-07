//
//  Product.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class Product: Model {

    var id = 0
    var companyId = 0
    var gtin: String!
    var tier: String!
    var barcodeUri: String!
    var imageUrlString: String!
    var data: [String: AnyObject]!

    var rejected = false

    var imageUrl: NSURL! {
        if let imageUrlString = imageUrlString {
            return NSURL(imageUrlString)
        }
        return nil
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "company_id",
            "gtin",
            "tier",
            "barcode_uri",
            "data",
            ]
        )
        mapping.addAttributeMappingsFromDictionary([
            "image_url": "imageUrlString"
            ])
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

    var style: String? {
        return data["style"] as? String
    }

    var color: String? {
        return data["color"] as? String
    }

    var sku: String? {
        return data["sku"] as? String
    }

    var unitOfMeasure: String? {
        return data["unit_of_measure"] as? String
    }

    var barcodeDataURL: NSURL! {
        if let barcodeUri = barcodeUri {
            return NSURL(string: barcodeUri)
        }
        return nil
    }

    var barcodeImage: UIImage! {
        if let barcodeDataURL = barcodeDataURL {
            return UIImage.imageFromDataURL(barcodeDataURL)
        }
        return nil
    }

    var isTierOne: Bool {
        if let tier = tier {
            return tier == "1"
        }
        return false
    }

    var isTierTwo: Bool {
        if let tier = tier {
            return tier == "2"
        }
        return false
    }

    var isTierThree: Bool {
        if let tier = tier {
            return tier == "3"
        }
        return false
    }

    func save(onSuccess onSuccess: OnSuccess, onError: OnError) {
        var params = toDictionary()
        params.removeValueForKey("id")

        if id > 0 {
            ApiService.sharedService().updateProductWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        } else {
            ApiService.sharedService().createProduct(params,
                onSuccess: { statusCode, mappingResult in
                    let product = mappingResult.firstObject as! Product
                    self.id = product.id
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }
}

// MARK: - Equatable
func == (lhs: Product, rhs: Product) -> Bool {
    return lhs.gtin == rhs.gtin
}
