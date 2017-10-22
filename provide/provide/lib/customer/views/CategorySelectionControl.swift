//
//  CategorySelectionControl.swift
//  provide
//
//  Created by Jawwad Ahmad on 10/20/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CategorySelectionControl: UIControl {

    var selectedIndex = 0
    private var selectedButton: CategoryButton?

    @IBOutlet var stackView: UIStackView!

    @IBAction func categoryButtonTapped(_ sender: CategoryButton) {
        selectedButton?.isSelected = false
        sender.isSelected = true
        selectedButton = sender

        selectedIndex = stackView.arrangedSubviews.index(of: sender) ?? 0
        sendActions(for: .valueChanged)
    }

    func configure(categories: [Category]) {
        guard !categories.isEmpty else { return }

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for category in categories {
            let button = CategoryButton(type: .system)
            button.configure(category: category)
            button.addTarget(self, action: #selector(categoryButtonTapped), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }

        /* BUG: If a category is selected, the work_order_changed notification continuously gets pushed and the trip never ends
        if selectedButton == nil {
            selectedButton = stackView.arrangedSubviews.filter { $0 is CategoryButton }.map { $0 as! CategoryButton }.first
            selectedButton?.isSelected = true
        }
         */
    }
}
