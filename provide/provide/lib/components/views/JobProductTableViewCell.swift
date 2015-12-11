//
//  JobProductTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 12/11/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobProductTableViewCell: UITableViewCell {

    @IBOutlet private weak var gtinLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var quantityLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!

    var jobProduct: JobProduct! {
        didSet {
            if let jobProduct = jobProduct {
                if let name = product.name {
                    nameLabel?.text = name
                }

                if let gtin = product.gtin {
                    gtinLabel?.text = gtin
                }

                quantityLabel?.text = "\(jobProduct.initialQuantity)"
                priceLabel?.text = jobProduct.price == 0.0 ? "--" : "$\(jobProduct.price)"
            }
        }
    }

    var product: Product! {
        if let jobProduct = jobProduct {
            return jobProduct.product
        }
        return nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel?.text = ""
        gtinLabel?.text = ""
        quantityLabel?.text = ""
        priceLabel?.text = ""
    }
}
