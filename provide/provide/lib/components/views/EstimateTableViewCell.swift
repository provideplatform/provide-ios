//
//  EstimateTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 2/2/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class EstimateTableViewCell: UITableViewCell {

    var estimate: Estimate! {
        didSet {
            if let _ = estimate {
                reload()
            }
        }
    }

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!

    private func reload() {
        if estimate.id == 0 {
            activityIndicatorView?.startAnimating()
        } else {
            activityIndicatorView?.stopAnimating()
        }

        if let createdAt = estimate.createdAt {
            dateLabel?.text = "\(createdAt.monthName) \(createdAt.dayOfMonth), \(createdAt.year)"
        } else {
            dateLabel?.text = ""
        }

        if let amount = estimate.amount {
            amountLabel?.text = "$\(amount)"
        } else if let humanReadableTotalSqFt = estimate.humanReadableTotalSqFt {
            amountLabel?.text = humanReadableTotalSqFt
        } else {
            amountLabel?.text = "--"
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        activityIndicatorView?.stopAnimating()
        dateLabel?.text = ""
        amountLabel?.text = ""
    }
}
