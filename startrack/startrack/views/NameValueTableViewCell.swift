//
//  NameValueTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 7/23/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class NameValueTableViewCell: UITableViewCell {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!

    func setName(name: String, value: String, valueFontSize: CGFloat = 17.0) {
        nameLabel.text = name

        valueLabel.text = value
        valueLabel.font = valueLabel.font.fontWithSize(valueFontSize)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.backgroundColor = UIColor.clearColor()

        backgroundView = UIView(frame: bounds)
        backgroundView?.backgroundColor = UIColor.clearColor()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = ""
        valueLabel.text = ""
    }
}