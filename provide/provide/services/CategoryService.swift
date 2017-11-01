//
//  CategoryService.swift
//  provide
//
//  Created by Kyle Thomas on 10/31/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation

class CategoryService {
    static let shared = CategoryService()

    private var categories = [Category]()

    func iconForCategoryId(_ categoryId: Int) -> UIImage? {
        for category in categories {
            if category.id == categoryId {
                return UIImage(category.abbreviation)
            }
        }
        return nil
    }

    func nearby(coordinate: CLLocationCoordinate2D, radius: Double, onSuccess: @escaping ([Category]) -> Void, onError: @escaping OnError) {
        let params: [String: Any] = [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "radius": radius,
        ]

        ApiService.shared.fetchCategories(params, onSuccess: { [weak self] statusCode, mappingResult in
            if let strongSelf = self {
                strongSelf.categories = mappingResult?.array() as! [Category]
                onSuccess(strongSelf.categories)
            }
        }, onError: onError)
    }
}
