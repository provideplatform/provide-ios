//
//  CategoryService.swift
//  provide
//
//  Created by Kyle Thomas on 3/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnCategoriesFetched = (categories: [Category]) -> ()

class CategoryService {

    private var categories = [Category]()

    private static let sharedInstance = CategoryService()

    class func sharedService() -> CategoryService {
        return sharedInstance
    }

    func fetch(page: Int = 1,
        rpp: Int = 50,
        companyId: Int!,
        includeCustomer: Bool = false,
        onCategoriesFetched: OnCategoriesFetched!)
    {
        if page == 1 {
            categories = [Category]()
        }

        var params: [String: AnyObject] = [
            "page": page,
            "rpp": rpp,
        ]

        if let companyId = companyId {
            params["company_id"] = companyId
        }

        ApiService.sharedService().fetchCategories(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedCategories = mappingResult.array() as! [Category]

                self.categories += fetchedCategories

                if let onCategoriesFetched = onCategoriesFetched {
                    onCategoriesFetched(categories: fetchedCategories)
                }
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }
}
