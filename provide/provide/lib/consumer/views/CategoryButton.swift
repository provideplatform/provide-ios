//
//  CategoryButton.swift
//  provide
//
//  Created by Kyle Thomas on 10/20/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CategoryButton: UIButton {

    func configure(category: Category) {
        setTitle(category.name, for: .normal)
    }
}
