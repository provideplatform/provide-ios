//
//  CategoryButton.swift
//  provide
//
//  Created by Kyle Thomas on 10/20/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CategoryButton: UIButton {

    func configure(category: Category, selectionControl: CategorySelectionControl) {
        setTitle(category.name, for: .normal)
        addTarget(selectionControl, action: Selector(("categoryButtonTapped:")), for: .touchUpInside)
    }
}
