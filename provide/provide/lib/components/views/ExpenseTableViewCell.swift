//
//  ExpenseTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 12/8/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ExpenseTableViewCell: UITableViewCell {

    var expense: Expense! {
        didSet {
            if let _ = expense {
                reload()
            }
        }
    }

    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!

    private func reload() {
        dateLabel?.text = "\(expense.incurredAtDate.month) / \(expense.incurredAtDate.dayOfMonth) / \(expense.incurredAtDate.year)"
        timeLabel?.text = "\(expense.incurredAtDate.timeString!)"
        descriptionLabel?.text = expense.desc
        priceLabel?.text = expense.amount != nil ? "$\(expense.amount)" : "--"
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        dateLabel?.text = ""
        timeLabel?.text = ""
        descriptionLabel?.text = ""
        priceLabel?.text = ""
    }
}
