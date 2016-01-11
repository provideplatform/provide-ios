//
//  JobManagerHeaderViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/16/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol JobManagerHeaderViewControllerDelegate: NSObjectProtocol {
    func jobManagerHeaderViewController(viewController: JobManagerHeaderViewController, delegateForExpensesViewController expensesViewController: ExpensesViewController) -> ExpensesViewControllerDelegate!
    optional func navigationControllerNavigationItemForViewController(viewController: UIViewController) -> UINavigationItem!
}

class JobManagerHeaderViewController: UITableViewController, ExpensesViewControllerDelegate {

    weak var jobManagerHeaderViewControllerDelegate: JobManagerHeaderViewControllerDelegate!

    var job: Job! {
        didSet {
            if let job = job {
                reloadJobExpenses()

                let cell = tableView(tableView, cellForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))

                if isIPad() {
                    if let humanReadableProfit = job.humanReadableProfit {
                        profitValueLabel?.text = humanReadableProfit
                    }

                    if let humanReadableExpenses = job.humanReadableExpenses {
                        expensesValueLabel?.text = humanReadableExpenses
                    }

                    if let humanReadableLabor = job.humanReadableLabor {
                        laborValueLabel?.text = humanReadableLabor
                    }

                    cell.contentView.alpha = 1.0
                } else {
                    cell.contentView.alpha = 0.0
                }

                if let expenses = job.expenses {
                    expensesViewController?.expenses = expenses
                } else {
                    reloadJobExpenses()
                }

                if let expensesViewController = expensesViewController {
                    if let jobManagerHeaderViewControllerDelegate = jobManagerHeaderViewControllerDelegate {
                        jobManagerHeaderViewControllerDelegate.jobManagerHeaderViewController(self, delegateForExpensesViewController: expensesViewController)
                    }
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

    private var expensesViewController: ExpensesViewController! {
        didSet {
            if let expensesViewController = expensesViewController {
                if let jobManagerHeaderViewControllerDelegate = jobManagerHeaderViewControllerDelegate {
                    jobManagerHeaderViewControllerDelegate.jobManagerHeaderViewController(self, delegateForExpensesViewController: expensesViewController)
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "ExpensesViewControllerPopoverSegue" {
            let navigationController = segue.destinationViewController as! UINavigationController
            expensesViewController = navigationController.viewControllers.first! as! ExpensesViewController
            expensesViewController.expenses = job.expenses
            navigationController.preferredContentSize = CGSize(width: 400, height: 300)
            navigationController.popoverPresentationController!.permittedArrowDirections = [.Up]

            if let expensesViewControllerDelegate = jobManagerHeaderViewControllerDelegate?.jobManagerHeaderViewController(self, delegateForExpensesViewController: expensesViewController) {
                expensesViewController.delegate = expensesViewControllerDelegate
            }
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

    func navigationControllerNavigationItemForViewController(viewController: UIViewController) -> UINavigationItem! {
        if let navigationItem = jobManagerHeaderViewControllerDelegate?.navigationControllerNavigationItemForViewController?(self) {
            return navigationItem
        }
        return nil
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String?
        if section == 0 {
            if let humanReadableContractRevenue = job.humanReadableContractRevenue {
                title = "CONTRACT REVENUE: \(humanReadableContractRevenue)"
            } else {
                title = "CONTRACT REVENUE: --"
            }
        }
        return title
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return isIPad() ? 1 : 0
        }
        return 0
    }
}
