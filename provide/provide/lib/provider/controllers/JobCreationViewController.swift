//
//  JobCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobCreationViewControllerDelegate: NSObjectProtocol {
    func jobCreationViewController(viewController: JobCreationViewController, didCreateJob job: Job)
}

class JobCreationViewController: UITableViewController, UISearchBarDelegate, UITextFieldDelegate, CustomerPickerViewControllerDelegate {

    let maximumSearchlessCustomersCount = 10

    weak var delegate: JobCreationViewControllerDelegate! {
        didSet {
            if let _ = delegate {
                if let customerPickerViewController = customerPickerViewController {
                    reloadCustomersForCustomerPickerViewController(customerPickerViewController)
                }
            }
        }
    }

    private var customer: Customer!
    private var customers: [Customer]!

    private var totalCustomersCount = -1

    private var queryString: String!

    private var showsAllCustomers: Bool {
        return totalCustomersCount == -1 || totalCustomersCount <= maximumSearchlessCustomersCount
    }

    private var renderQueryResults: Bool {
        return queryString != nil || showsAllCustomers
    }

    private var reloadingCustomers = false
    private var reloadingCustomersCount = false

    private var customerPickerViewController: CustomerPickerViewController!

    @IBOutlet private weak var searchBar: UISearchBar!

    @IBOutlet private weak var nameTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "CREATE JOB"

        searchBar?.placeholder = ""
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "CustomerPickerViewControllerEmbedSegue" {
            customerPickerViewController = segue.destinationViewController as! CustomerPickerViewController
            customerPickerViewController.delegate = self

            if let _ = delegate {
                reloadCustomersForCustomerPickerViewController(customerPickerViewController)
            }
        }
    }

    private func createJob() {
        let job = Job()
        if let customer = customer {
            job.customerId = customer.id
            job.companyId = customer.companyId
        }
        job.name = nameTextField?.text

        if job.customerId > 0 && job.name != nil && job.name.length > 0 {
            showActivityIndicator()

            job.save(
                onSuccess: { statusCode, mappingResult in
                    if statusCode == 201 {
                        job.reload(
                            onSuccess: { statusCode, mappingResult in
                                self.hideActivityIndicator()
                                self.delegate?.jobCreationViewController(self, didCreateJob: mappingResult.firstObject as! Job)
                            },
                            onError: { error, statusCode, responseString in
                                self.hideActivityIndicator()
                            }
                        )
                    }
                },
                onError: { error, statusCode, responseString in
                    self.hideActivityIndicator()
                }
            )
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 {
            createJob()
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 2 {
            tableView.cellForRowAtIndexPath(indexPath)!.alpha = 0.8

            if nameTextField.isFirstResponder() {
                nameTextField.resignFirstResponder()
            }
        }
        return indexPath
    }

    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 {
            tableView.cellForRowAtIndexPath(indexPath)!.alpha = 1.0
        }
    }

    // MARK: UISearchBarDelegate

    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        return !showsAllCustomers
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        queryString = searchText
        if queryString.replaceString(" ", withString: "").length == 0 {
            queryString = nil
            customerPickerViewController?.customers = [Customer]()
            tableView.reloadData()
        } else {
            tableView.reloadData()
            customerPickerViewController?.reset()
        }
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == nameTextField {
            if let name = textField.text {
                textField.resignFirstResponder()
                dispatch_after_delay(0.0) {
                    self.createJob()
                }
                return name.length > 0
            }
        }
        return false
    }

    // MARK: CustomerPickerViewControllerDelegate

    func queryParamsForCustomerPickerViewController(viewController: CustomerPickerViewController) -> [String : AnyObject]! {
        var params = ["q": queryString != nil ? queryString : NSNull()]
        if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
            params["company_id"] = defaultCompanyId
        }
        return params
    }

    func customerPickerViewController(viewController: CustomerPickerViewController, didSelectCustomer customer: Customer) {
        self.customer = customer

        if searchBar.isFirstResponder() {
            searchBar.resignFirstResponder()
            if nameTextField.canBecomeFirstResponder() {

                UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
                    animations: { Void in
                        self.tableView.contentOffset = CGPoint(x: 0.0, y: self.customerPickerViewController.view.frame.height * 1.5)
                    },
                    completion: { complete in
                        self.nameTextField.becomeFirstResponder()
                    }
                )
            }
        }
    }

    func customerPickerViewController(viewController: CustomerPickerViewController, didDeselectCustomer customer: Customer) {
        self.customer = nil
    }

    func customerPickerViewControllerAllowsMultipleSelection(viewController: CustomerPickerViewController) -> Bool {
        return false
    }

    func customersForPickerViewController(viewController: CustomerPickerViewController) -> [Customer] {
        if let customers = customers {
            return customers
        } else {
            reloadCustomersForCustomerPickerViewController(viewController)
        }

        return [Customer]()
    }

    func selectedCustomersForPickerViewController(viewController: CustomerPickerViewController) -> [Customer] {
        if let customer = customer {
            return [customer]
        }
        return [Customer]()
    }

    func collectionViewScrollDirectionForPickerViewController(viewController: CustomerPickerViewController) -> UICollectionViewScrollDirection {
        return .Horizontal
    }

//    optional func customerPickerViewControllerCanRenderResults(viewController: CustomerPickerViewController) -> Bool

    private func reloadCustomersForCustomerPickerViewController(viewController: CustomerPickerViewController) {
        if viewController == customerPickerViewController {
            reloadingCustomers = true
            reloadingCustomersCount = true

            customerPickerViewController?.customers = [Customer]()
            customerPickerViewController?.showActivityIndicator()
            tableView.reloadData()

            if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
                ApiService.sharedService().countCustomers(["company_id": defaultCompanyId],
                    onTotalResultsCount: { totalResultsCount, error in
                        self.totalCustomersCount = totalResultsCount
                        if totalResultsCount > -1 {
                            if totalResultsCount <= self.maximumSearchlessCustomersCount {
                                ApiService.sharedService().fetchCustomers(["company_id": defaultCompanyId, "page": 1, "rpp": totalResultsCount],
                                    onSuccess: { (statusCode, mappingResult) -> () in
                                        self.customerPickerViewController?.customers = mappingResult.array() as! [Customer]
                                        self.tableView.reloadData()
                                        self.searchBar.placeholder = "Showing all \(totalResultsCount) customers"
                                        self.reloadingCustomersCount = false
                                        self.reloadingCustomers = false
                                    },
                                    onError: { (error, statusCode, responseString) -> () in
                                        self.customerPickerViewController?.customers = [Customer]()
                                        self.tableView.reloadData()
                                        self.reloadingCustomersCount = false
                                        self.reloadingCustomers = false
                                    }
                                )
                            } else {
                                self.searchBar.placeholder = "Search \(totalResultsCount) customers"
                                self.tableView.reloadData()
                                self.reloadingCustomersCount = false
                                self.reloadingCustomers = false
                            }
                        }
                    }
                )
            }
        }
    }

    private func showActivityIndicator() {
        if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2)) {
            for view in cell.contentView.subviews {
                if view.isKindOfClass(UIActivityIndicatorView) {
                    (view as! UIActivityIndicatorView).startAnimating()
                } else if view.isKindOfClass(UILabel) {
                    view.alpha = 0.0
                }
            }
        }
    }

    private func hideActivityIndicator() {
        if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2)) {
            for view in cell.contentView.subviews {
                if view.isKindOfClass(UIActivityIndicatorView) {
                    (view as! UIActivityIndicatorView).stopAnimating()
                } else if view.isKindOfClass(UILabel) {
                    view.alpha = 1.0
                }
            }
        }
    }
}
