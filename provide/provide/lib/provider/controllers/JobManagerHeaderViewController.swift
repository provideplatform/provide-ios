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

class JobManagerHeaderViewController: UITableViewController, ExpensesViewControllerDelegate, UIPopoverPresentationControllerDelegate {

    weak var jobManagerHeaderViewControllerDelegate: JobManagerHeaderViewControllerDelegate!

    var job: Job! {
        didSet {
            if let _ = job {
                reloadJobFinancials()

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

    @IBOutlet private weak var profitPerSqFtLabel: UILabel!
    @IBOutlet private weak var profitPerSqFtValueLabel: UILabel!

    @IBOutlet private weak var profitMarginLabel: UILabel!
    @IBOutlet private weak var profitMarginValueLabel: UILabel!

    @IBOutlet private weak var profitMarginButton: UIButton!

    @IBOutlet private weak var expensesLabel: UILabel!
    @IBOutlet private weak var expensesValueLabel: UILabel!

    @IBOutlet private weak var laborLabel: UILabel!
    @IBOutlet private weak var laborValueLabel: UILabel!

    @IBOutlet private weak var laborCostPerSqFtLabel: UILabel!
    @IBOutlet private weak var laborCostPerSqFtValueLabel: UILabel!

    @IBOutlet private weak var laborCostPercentageOfRevenueLabel: UILabel!
    @IBOutlet private weak var laborCostPercentageOfRevenueValueLabel: UILabel!

    @IBOutlet private weak var materialsCostLabel: UILabel!
    @IBOutlet private weak var materialsCostValueLabel: UILabel!

    @IBOutlet private weak var materialsCostPercentageOfRevenueLabel: UILabel!
    @IBOutlet private weak var materialsCostPercentageOfRevenueValueLabel: UILabel!

    @IBOutlet private weak var materialsCostPerSqFtLabel: UILabel!
    @IBOutlet private weak var materialsCostPerSqFtValueLabel: UILabel!

    private var expensesViewController: ExpensesViewController! {
        didSet {
            if let expensesViewController = expensesViewController {
                if let jobManagerHeaderViewControllerDelegate = jobManagerHeaderViewControllerDelegate {
                    jobManagerHeaderViewControllerDelegate.jobManagerHeaderViewController(self, delegateForExpensesViewController: expensesViewController)
                }
            }
        }
    }

    private func renderFinancials() {
        tableView.reloadData()

        if tableView.numberOfRowsInSection(0) > 0 {
            if isIPad() {
                // profit

                if let humanReadableProfit = job.humanReadableProfit {
                    profitValueLabel?.text = humanReadableProfit
                }

                if let humanReadableProfitMargin = job.humanReadableProfitMargin {
                    profitMarginValueLabel?.text = humanReadableProfitMargin
                    profitMarginButton?.setTitle(humanReadableProfitMargin, forState: .Normal)
                }

                if let humanReadableProfitPerSqFt = job.humanReadableProfitPerSqFt {
                    profitPerSqFtValueLabel?.text = humanReadableProfitPerSqFt
                }

                // job expenses

                if let humanReadableCost = job.humanReadableCost {
                    expensesValueLabel?.text = humanReadableCost
                }

                // labor

                if let humanReadableLaborCost = job.humanReadableLaborCost {
                    laborValueLabel?.text = humanReadableLaborCost
                }

                if let humanReadableLaborCostPerSqFt = job.humanReadableLaborCostPerSqFt {
                    laborCostPerSqFtValueLabel?.text = humanReadableLaborCostPerSqFt
                }

                if let humanReadableLaborCostPercentageOfRevenue = job.humanReadableLaborCostPercentageOfRevenue {
                    laborCostPercentageOfRevenueValueLabel?.text = humanReadableLaborCostPercentageOfRevenue
                }

                // materials

                if let humanReadableMaterialsCost = job.humanReadableMaterialsCost {
                    materialsCostValueLabel?.text = humanReadableMaterialsCost
                }

                if let humanReadableMaterialsCostPerSqFt = job.humanReadableMaterialsCostPerSqFt {
                    materialsCostPerSqFtValueLabel?.text = humanReadableMaterialsCostPerSqFt
                }

                if let humanReadableMaterialsCostPercentageOfRevenue = job.humanReadableMaterialsCostPercentageOfRevenue {
                    materialsCostPercentageOfRevenueValueLabel?.text = humanReadableMaterialsCostPercentageOfRevenue
                }
            }

            tableView.alpha = 1.0
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.alpha = 0.0
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "ExpensesViewControllerPopoverSegue" {
            let navigationController = segue.destinationViewController as! UINavigationController
            expensesViewController = navigationController.viewControllers.first! as! ExpensesViewController
            expensesViewController.expenses = job.expenses
            navigationController.preferredContentSize = CGSize(width: 400, height: 300)
            navigationController.popoverPresentationController!.permittedArrowDirections = [.Up]
            navigationController.popoverPresentationController!.delegate = self

            if let expensesViewControllerDelegate = jobManagerHeaderViewControllerDelegate?.jobManagerHeaderViewController(self, delegateForExpensesViewController: expensesViewController) {
                expensesViewController.delegate = expensesViewControllerDelegate
            }
        }
    }

    private func reloadJobFinancials() {
        if let job = job {
            job.reloadFinancials(
                { statusCode, mappingResult in
                    if let expensesViewController = self.expensesViewController {
                        expensesViewController.expenses = job.expenses
                    }

                    self.renderFinancials()
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

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return job != nil && isIPad() ? 1 : 0
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

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 28.0
        }
        return 0.0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return isIPad() ? (job.isCurrentUserCompanyAdmin ? 2 : (job.isCurrentUserSupervisor ? 1 : 0)) : 0
        }
        return 0
    }

    // MARK: UIPopoverPresentationControllerDelegate

    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
}
