//
//  RouteManifestItemTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class RouteManifestItemTableViewCell: UITableViewCell {

    @IBOutlet private weak var gtinLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var sizeLabel: UILabel!

    var product: Product! {
        didSet {
            if let name = product.name {
                nameLabel?.text = product.name
            }

            if let gtin = product.gtin {
                gtinLabel?.text = product.gtin
            }

            if let desc = product.desc {
                sizeLabel?.text = product.desc
            }
        }
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
