//
//  CategoryService.swift
//  provide
//
//  Created by Kyle Thomas on 3/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnCategoriesFetched = (_ categories: [Category]) -> ()

class CategoryService {

    fileprivate var categories = [Category]()

    fileprivate static let sharedInstance = CategoryService()

    class func sharedService() -> CategoryService {
        return sharedInstance
    }

    func fetch(_ page: Int = 1,
        rpp: Int = 50,
        companyId: Int!,
        includeCustomer: Bool = false,
        onCategoriesFetched: OnCategoriesFetched!)
    {
        if page == 1 {
            categories = [Category]()
        }

        var params: [String: AnyObject] = [
            "page": page as AnyObject,
            "rpp": rpp as AnyObject,
        ]

        if let companyId = companyId {
            params["company_id"] = companyId as AnyObject?
        }

        ApiService.sharedService().fetchCategories(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedCategories = mappingResult?.array() as! [Category]

                self.categories += fetchedCategories

                if let onCategoriesFetched = onCategoriesFetched {
                    onCategoriesFetched(fetchedCategories)
                }
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }
}
