//
//  ExpenseTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 12/8/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
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

    @IBOutlet fileprivate weak var dateLabel: UILabel!
    @IBOutlet fileprivate weak var timeLabel: UILabel!
    @IBOutlet fileprivate weak var descriptionLabel: UILabel!
    @IBOutlet fileprivate weak var amountLabel: UILabel!

    fileprivate func reload() {
        dateLabel?.text = "\(expense.incurredAtDate.month) / \(expense.incurredAtDate.dayOfMonth) / \(expense.incurredAtDate.year)"
        timeLabel?.text = "\(expense.incurredAtDate.timeString!)"
        descriptionLabel?.text = expense.desc
        amountLabel?.text = "$\(expense.amount)"
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        dateLabel?.text = ""
        timeLabel?.text = ""
        descriptionLabel?.text = ""
        amountLabel?.text = ""
    }
}
