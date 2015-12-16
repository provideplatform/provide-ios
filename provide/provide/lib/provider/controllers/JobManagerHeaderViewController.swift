//
//  JobManagerHeaderViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/16/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobManagerHeaderViewController: UITableViewController {

    var job: Job! {
        didSet {
            if let job = job {
                reloadJobExpenses()

                if let humanReadableProfit = job.humanReadableProfit {
                    profitValueLabel?.text = humanReadableProfit
                }

                if let humanReadableExpenses = job.humanReadableExpenses {
                    expensesValueLabel?.text = humanReadableExpenses
                }

                if let humanReadableLabor = job.humanReadableLabor {
                    laborValueLabel?.text = humanReadableLabor
                }
            }
        }
    }

    @IBOutlet private weak var profitLabel: UILabel!
    @IBOutlet private weak var profitValueLabel: UILabel!

    @IBOutlet private weak var expensesLabel: UILabel!
    @IBOutlet private weak var expensesValueLabel: UILabel!

    @IBOutlet private weak var laborLabel: UILabel!
    @IBOutlet private weak var laborValueLabel: UILabel!

    private var expensesViewController: ExpensesViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "ExpensesViewControllerPopoverSegue" {
            expensesViewController = segue.destinationViewController as! ExpensesViewController
            expensesViewController.expenses = job.expenses
            expensesViewController.preferredContentSize = CGSize(width: 400, height: 300)
            expensesViewController.popoverPresentationController!.permittedArrowDirections = [.Up]
            //expensesViewController.delegate = self
        }
    }

    private func reloadJobExpenses() {
        if let job = job {
            job.reloadExpenses(
                { statusCode, mappingResult in
                    if let expensesViewController = self.expensesViewController {
                        expensesViewController.expenses = job.expenses
                    }
                },
                onError: { error, statusCode, responseString in

                }
            )
        }
    }
}
