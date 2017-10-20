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
    private var selectedButton: UIButton?

    @IBOutlet var stackView: UIStackView!

    @IBAction func categoryButtonTapped(_ sender: UIButton) {
        selectedButton?.isSelected = false
        sender.isSelected = true
        selectedButton = sender

        selectedIndex = stackView.arrangedSubviews.indexOfObject(sender) ?? 0
        sendActions(for: .valueChanged)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        selectedButton = stackView.arrangedSubviews.filter { $0 is UIButton }.map { $0 as! UIButton }.first
        selectedButton?.isSelected = true
    }
}
