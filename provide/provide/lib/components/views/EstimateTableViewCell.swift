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

    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!

    private func reload() {
        dateLabel?.text = "" //"\(expense.incurredAtDate.month) / \(expense.incurredAtDate.dayOfMonth) / \(expense.incurredAtDate.year)"
        if let amount = estimate.amount {
            amountLabel?.text = "$\(amount)"
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        dateLabel?.text = ""
        amountLabel?.text = ""
    }
}
