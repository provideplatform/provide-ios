//
//  ExpenseViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/8/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ExpenseViewController: ViewController {

    var expense: Expense! {
        didSet {
            if let expense = expense {
                navigationItem.title = "\(expense.desc)"
                if let amount = expense.amount {
                    navigationItem.title = "\(navigationItem.title) - $\(amount)"
                }

                reload()
            }
        }
    }

    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let _ = expense {
            reload()
        }
    }

    private func reload() {
        dateLabel?.text = "\(expense.incurredAtDate.month) / \(expense.incurredAtDate.dayOfMonth) / \(expense.incurredAtDate.year)"
        timeLabel?.text = "\(expense.incurredAtDate.timeString!)"
        descriptionLabel?.text = expense.desc
        priceLabel?.text = expense.amount != nil ? "$\(expense.amount)" : "--"

        imageView?.alpha = 0.0
        imageView?.contentMode = .ScaleAspectFit
        imageView?.sd_setImageWithURL(expense.attachments.first!.url, placeholderImage: nil,
            completed: { image, error, imageCacheType, url in
                self.imageView?.alpha = 1.0
            }
        )
    }
}
