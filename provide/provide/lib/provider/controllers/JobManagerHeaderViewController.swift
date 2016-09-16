//
//  JobManagerHeaderViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol JobManagerHeaderViewControllerDelegate: NSObjectProtocol {
    @discardableResult
    func jobManagerHeaderViewController(_ viewController: JobManagerHeaderViewController, delegateForExpensesViewController expensesViewController: ExpensesViewController) -> ExpensesViewControllerDelegate!
    @objc optional func navigationControllerNavigationItemForViewController(_ viewController: UIViewController) -> UINavigationItem!
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

    @IBOutlet fileprivate weak var profitLabel: UILabel!
    @IBOutlet fileprivate weak var profitValueLabel: UILabel!

    @IBOutlet fileprivate weak var profitPerSqFtLabel: UILabel!
    @IBOutlet fileprivate weak var profitPerSqFtValueLabel: UILabel!

    @IBOutlet fileprivate weak var profitMarginLabel: UILabel!
    @IBOutlet fileprivate weak var profitMarginValueLabel: UILabel!

    @IBOutlet fileprivate weak var profitMarginButton: UIButton!

    @IBOutlet fileprivate weak var expensesLabel: UILabel!
    @IBOutlet fileprivate weak var expensesValueLabel: UILabel!

    @IBOutlet fileprivate weak var laborLabel: UILabel!
    @IBOutlet fileprivate weak var laborValueLabel: UILabel!

    @IBOutlet fileprivate weak var laborCostPerSqFtLabel: UILabel!
    @IBOutlet fileprivate weak var laborCostPerSqFtValueLabel: UILabel!

    @IBOutlet fileprivate weak var laborCostPercentageOfRevenueLabel: UILabel!
    @IBOutlet fileprivate weak var laborCostPercentageOfRevenueValueLabel: UILabel!

    @IBOutlet fileprivate weak var materialsCostLabel: UILabel!
    @IBOutlet fileprivate weak var materialsCostValueLabel: UILabel!

    @IBOutlet fileprivate weak var materialsCostPercentageOfRevenueLabel: UILabel!
    @IBOutlet fileprivate weak var materialsCostPercentageOfRevenueValueLabel: UILabel!

    @IBOutlet fileprivate weak var materialsCostPerSqFtLabel: UILabel!
    @IBOutlet fileprivate weak var materialsCostPerSqFtValueLabel: UILabel!

    fileprivate var expensesViewController: ExpensesViewController! {
        didSet {
            if let expensesViewController = expensesViewController {
                if let jobManagerHeaderViewControllerDelegate = jobManagerHeaderViewControllerDelegate {
                    jobManagerHeaderViewControllerDelegate.jobManagerHeaderViewController(self, delegateForExpensesViewController: expensesViewController)
                }
            }
        }
    }

    fileprivate func renderFinancials() {
        tableView.reloadData()

        if tableView.numberOfRows(inSection: 0) > 0 {
            // profit

            if let humanReadableProfit = job.humanReadableProfit {
                profitValueLabel?.text = humanReadableProfit
            } else {
                profitValueLabel?.text = "--"
            }

            if let humanReadableProfitMargin = job.humanReadableProfitMargin {
                profitMarginValueLabel?.text = humanReadableProfitMargin
                profitMarginButton?.setTitle(humanReadableProfitMargin, for: UIControlState())
            } else {
                profitMarginValueLabel?.text = "--"
                profitMarginButton?.setTitle("", for: UIControlState())
            }

            if let humanReadableProfitPerSqFt = job.humanReadableProfitPerSqFt {
                profitPerSqFtValueLabel?.text = humanReadableProfitPerSqFt
            } else {
                profitPerSqFtValueLabel?.text = "--"
            }

            // job expenses

            if let humanReadableCost = job.humanReadableCost {
                expensesValueLabel?.text = humanReadableCost
            } else {
                expensesValueLabel?.text = "--"
            }

            // labor

            if let humanReadableLaborCost = job.humanReadableLaborCost {
                laborValueLabel?.text = humanReadableLaborCost
            } else {
                laborValueLabel?.text = "--"
            }

            if let humanReadableLaborCostPerSqFt = job.humanReadableLaborCostPerSqFt {
                laborCostPerSqFtValueLabel?.text = humanReadableLaborCostPerSqFt
            } else {
                laborCostPerSqFtValueLabel?.text = "--"
            }

            if let humanReadableLaborCostPercentageOfRevenue = job.humanReadableLaborCostPercentageOfRevenue {
                laborCostPercentageOfRevenueValueLabel?.text = humanReadableLaborCostPercentageOfRevenue
            } else {
                laborCostPercentageOfRevenueValueLabel?.text = "--"
            }

            // materials

            if let humanReadableMaterialsCost = job.humanReadableMaterialsCost {
                materialsCostValueLabel?.text = humanReadableMaterialsCost
            } else {
                materialsCostValueLabel?.text = "--"
            }

            if let humanReadableMaterialsCostPerSqFt = job.humanReadableMaterialsCostPerSqFt {
                materialsCostPerSqFtValueLabel?.text = humanReadableMaterialsCostPerSqFt
            } else {
                materialsCostPerSqFtValueLabel?.text = "--"
            }

            if let humanReadableMaterialsCostPercentageOfRevenue = job.humanReadableMaterialsCostPercentageOfRevenue {
                materialsCostPercentageOfRevenueValueLabel?.text = humanReadableMaterialsCostPercentageOfRevenue
            } else {
                materialsCostPercentageOfRevenueValueLabel?.text = "--"
            }

            tableView.alpha = 1.0
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.alpha = 0.0
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier! == "ExpensesViewControllerPopoverSegue" {
            let navigationController = segue.destination as! UINavigationController
            expensesViewController = navigationController.viewControllers.first! as! ExpensesViewController
            expensesViewController.expenses = job.expenses
            navigationController.preferredContentSize = CGSize(width: 400, height: 300)
            navigationController.popoverPresentationController!.permittedArrowDirections = [.up]
            navigationController.popoverPresentationController!.delegate = self

            if let expensesViewControllerDelegate = jobManagerHeaderViewControllerDelegate?.jobManagerHeaderViewController(self, delegateForExpensesViewController: expensesViewController) {
                expensesViewController.delegate = expensesViewControllerDelegate
            }
        }
    }

    func reloadJobFinancials() {
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

    func navigationControllerNavigationItemForViewController(_ viewController: UIViewController) -> UINavigationItem! {
        if let navigationItem = jobManagerHeaderViewControllerDelegate?.navigationControllerNavigationItemForViewController?(self) {
            return navigationItem
        }
        return nil
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return job != nil ? 1 : 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 28.0
        }
        return 0.0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return job.isCurrentUserCompanyAdmin ? 2 : (job.isCurrentUserSupervisor ? 1 : 0)
        }
        return 0
    }

    // MARK: UIPopoverPresentationControllerDelegate

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
