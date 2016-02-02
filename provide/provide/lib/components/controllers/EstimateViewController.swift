//
//  EstimateViewController.swift
//  provide
//
//  Created by Kyle Thomas on 2/2/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class EstimateViewController: ViewController {

    var estimate: Estimate! {
        didSet {
            if let estimate = estimate {
                navigationItem.title = "\(estimate.id)"

                reload()
            }
        }
    }

    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let _ = estimate {
            reload()
        }
    }

    func hideLabels() {

    }

    private func reload() {
        dateLabel?.text = ""
        if let amount = estimate.amount {
            amountLabel?.text = "$\(amount)"
        } else {
            amountLabel?.text = ""
        }
    }
}
