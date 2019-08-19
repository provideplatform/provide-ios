//
//  CategoryButton.swift
//  provide
//
//  Created by Kyle Thomas on 10/20/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CategoryButton: UIButton {

    private var category: Category?

    var categoryId: Int? {
        if let category = category {
            return category.id
        }
        return nil
    }

    func configure(category: Category) {
        self.category = category
        setTitle(category.name, for: .normal)
    }
}
