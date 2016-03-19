//
//  CategoryService.swift
//  provide
//
//  Created by Kyle Thomas on 3/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

class CategoryService {

    private var categories = [Category]()

    private static let sharedInstance = CategoryService()

    class func sharedService() -> CategoryService {
        return sharedInstance
    }
}
