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
    var companyId = 0
    var gtin: String!
    var barcodeUri: String!
    var data: [String: AnyObject]!

    var rejected = false

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "company_id",
            "gtin",
            "barcode_uri",
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
