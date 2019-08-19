//
//  CategorySelectionControl.swift
//  provide
//
//  Created by Jawwad Ahmad on 10/20/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CategorySelectionControl: UIControl {

    var selectedIndex = 0
    private var selectedButton: CategoryButton?

    var selectedCategoryId: Int? {
        return selectedButton?.categoryId
    }

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

        if selectedButton == nil {
            // FIXME-- implement a way to remember the user's last category selection and select it by default
            selectedButton = stackView.arrangedSubviews.filter { $0 is CategoryButton }.map { $0 as! CategoryButton }.first
            if let selectedButton = selectedButton {
                selectedButton.isSelected = true
                categoryButtonTapped(selectedButton)
            }
        }
    }
}
