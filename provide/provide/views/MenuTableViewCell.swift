//
//  MenuTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 12/18/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class MenuTableViewCell: UITableViewCell {

    var menuItem: MenuItem! {
        didSet {
            if let menuItem = menuItem {
                label?.text = menuItem.label.uppercased()
            }
        }
    }

    @IBOutlet private weak var label: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()

        menuItem = nil

        label?.text = ""
    }
}
