//
//  ManifestItemTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

class ManifestItemTableViewCell: UITableViewCell {

    @IBOutlet fileprivate weak var gtinLabel: UILabel!
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var sizeLabel: UILabel!

    var product: Product! {
        didSet {
            if let name = product.name {
                nameLabel?.text = name
            }

            if let gtin = product.gtin {
                gtinLabel?.text = gtin
            }

            if let size = product.size {
                sizeLabel?.text = size
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel?.text = ""
        gtinLabel?.text = ""
        sizeLabel?.text = ""
    }
}
