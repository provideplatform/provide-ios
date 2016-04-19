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
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    func setName(name: String, value: String, valueFontSize: CGFloat = 13.0, showActivity: Bool = false) {
        nameLabel?.hidden = true
        valueLabel.hidden = true

        nameLabel?.text = name
        nameLabel?.sizeToFit()

        valueLabel?.text = value
        valueLabel?.font = valueLabel?.font.fontWithSize(valueFontSize)
        valueLabel?.sizeToFit()

//        if nameLabel != nil && valueLabel != nil {
//            if CGRectIntersectsRect(nameLabel.frame, valueLabel.frame) {
//                nameLabel.font = nameLabel.font.fontWithSize(valueLabel.font.pointSize * 0.9)
//                nameLabel.sizeToFit()
//
//                valueLabel.font = valueLabel.font.fontWithSize(valueLabel.font.pointSize * 0.9)
//                valueLabel.sizeToFit()
//            }
//        }

        if !showActivity {
            hideActivity()
        }

        nameLabel?.hidden = false
        valueLabel?.hidden = false
    }

    func showActivity(resetName: Bool = true) {
        let name = resetName ? "" : nameLabel?.text
        setName(name!, value: "")
        activityIndicatorView?.startAnimating()
    }

    func hideActivity() {
        activityIndicatorView?.stopAnimating()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.backgroundColor = UIColor.clearColor()

        backgroundView = UIView(frame: bounds)
        backgroundView?.backgroundColor = UIColor.clearColor()

        nameLabel?.text = ""
        nameLabel?.hidden = true

        valueLabel?.text = ""
        valueLabel?.hidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel?.text = ""
        nameLabel?.hidden = true

        valueLabel?.text = ""
        valueLabel.hidden = true

        activityIndicatorView?.stopAnimating()
    }
}
