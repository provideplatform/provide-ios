//
//  NameValueTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 7/23/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class NameValueTableViewCell: UITableViewCell {

    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var valueLabel: UILabel!
    @IBOutlet fileprivate weak var activityIndicatorView: UIActivityIndicatorView!

    func setName(_ name: String, value: String, valueFontSize: CGFloat = 13.0, showActivity: Bool = false) {
        nameLabel?.isHidden = true
        valueLabel.isHidden = true

        nameLabel?.text = name
        nameLabel?.sizeToFit()

        valueLabel?.text = value
        valueLabel?.font = valueLabel?.font.withSize(valueFontSize)
        valueLabel?.sizeToFit()

        //  if nameLabel != nil && valueLabel != nil {
        //     if CGRectIntersectsRect(nameLabel.frame, valueLabel.frame) {
        //         nameLabel.font = nameLabel.font.fontWithSize(valueLabel.font.pointSize * 0.9)
        //         nameLabel.sizeToFit()
        //
        //         valueLabel.font = valueLabel.font.fontWithSize(valueLabel.font.pointSize * 0.9)
        //         valueLabel.sizeToFit()
        //     }
        // }

        if !showActivity {
            hideActivity()
        }

        nameLabel?.isHidden = false
        valueLabel?.isHidden = false
    }

    func showActivity(_ resetName: Bool = true) {
        let name = resetName ? "" : nameLabel?.text
        setName(name!, value: "")
        activityIndicatorView?.startAnimating()
    }

    func hideActivity() {
        activityIndicatorView?.stopAnimating()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.backgroundColor = .clear

        backgroundView = UIView(frame: bounds)
        backgroundView?.backgroundColor = .clear

        nameLabel?.text = ""
        nameLabel?.isHidden = true

        valueLabel?.text = ""
        valueLabel?.isHidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel?.text = ""
        nameLabel?.isHidden = true

        valueLabel?.text = ""
        valueLabel.isHidden = true

        activityIndicatorView?.stopAnimating()
    }
}
