//
//  ExpenseViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/8/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ExpenseViewController: ViewController {

    var expense: Expense! {
        didSet {
            if let expense = expense {
                navigationItem.title = "\(expense.desc)"
                navigationItem.title = "\(navigationItem.title!) - $\(expense.amount)"

                reload()
            }
        }
    }

    @IBOutlet fileprivate weak var dateLabel: UILabel!
    @IBOutlet fileprivate weak var timeLabel: UILabel!
    @IBOutlet fileprivate weak var descriptionLabel: UILabel!
    @IBOutlet fileprivate weak var amountLabel: UILabel!
    @IBOutlet fileprivate weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let _ = expense {
            reload()
        }
    }

    func hideLabels() {
        descriptionLabel?.isHidden = true
        amountLabel?.isHidden = true
    }

    fileprivate func reload() {
        if let incurredAtDate = expense.incurredAtDate {
            dateLabel?.text = "\(incurredAtDate.month) / \(incurredAtDate.dayOfMonth) / \(incurredAtDate.year)"
            timeLabel?.text = "\(incurredAtDate.timeString!)"
        } else {
            dateLabel?.text = ""
            timeLabel?.text = ""
        }

        descriptionLabel?.text = expense.desc
        amountLabel?.text = "$\(expense.amount)"

        imageView?.alpha = 0.0
        imageView?.contentMode = .scaleAspectFit

        if let attachment = expense.attachments?.first {
            imageView?.sd_setImage(with: attachment.url,
                completed: { image, error, imageCacheType, url in
                    self.imageView?.alpha = 1.0
                }
            )
        } else if let receiptImage = expense.receiptImage {
            imageView?.image = receiptImage
            imageView?.alpha = 1.0
        }
    }
}
