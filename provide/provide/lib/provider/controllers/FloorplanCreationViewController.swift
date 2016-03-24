//
//  FloorplanCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/18/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol FloorplanCreationViewControllerDelegate: NSObjectProtocol {
    optional func floorplanForFloorplanCreationViewController(viewController: FloorplanCreationViewController) -> Floorplan!
    func floorplanCreationViewController(viewController: FloorplanCreationViewController, didCreateFloorplan floorplan: Floorplan)
    func floorplanCreationViewController(viewController: FloorplanCreationViewController, didUpdateFloorplan floorplan: Floorplan)
}

class FloorplanCreationViewController: UITableViewController,
                                       UISearchBarDelegate,
                                       UITextFieldDelegate,
                                       CustomerPickerViewControllerDelegate {

    let maximumSearchlessCustomersCount = 10

    weak var delegate: FloorplanCreationViewControllerDelegate! {
        didSet {
            if let delegate = delegate {
                if let floorplan = delegate.floorplanForFloorplanCreationViewController?(self) {
                    nameTextField?.text = floorplan.name

                    if floorplan.totalSqFt > 0.0 {
                        totalSqFtTextField?.text = "\(floorplan.totalSqFt)"
                    } else {
                        totalSqFtTextField?.text = ""
                    }

                    createButton?.setTitle("SAVE", forState: .Normal)
                } else if let customerPickerViewController = customerPickerViewController {
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
    @IBOutlet private weak var totalSqFtTextField: UITextField!

    @IBOutlet private weak var createButton: UIButton!

    private var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .Plain, target: self, action: #selector(FloorplanCreationViewController.dismiss(_:)))
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return dismissItem
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "CREATE FLOORPLAN"

        searchBar?.placeholder = ""

        createButton.addTarget(self, action: #selector(FloorplanCreationViewController.saveFloorplan(_:)), forControlEvents: .TouchUpInside)

        if !isIPad() {
            navigationItem.leftBarButtonItems = [dismissItem]
        }

        // HACK
        if let delegate = delegate {
            self.delegate = delegate
        }
    }

    func dismiss(sender: UIBarButtonItem) {
        if let navigationController = navigationController {
            if navigationController.viewControllers.count > 1 {
                navigationController.popViewControllerAnimated(true)
            } else {
                navigationController.presentingViewController?.dismissViewController(animated: true)
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "CustomerPickerViewControllerEmbedSegue" {
            customerPickerViewController = segue.destinationViewController as! CustomerPickerViewController
            customerPickerViewController.delegate = self

            if let _ = delegate {
                if delegate.floorplanForFloorplanCreationViewController?(self) == nil {
                    reloadCustomersForCustomerPickerViewController(customerPickerViewController)
                }
            }
        }
    }

    func saveFloorplan(sender: UIButton) {
        tableView.endEditing(true)
        saveFloorplan()
    }

    internal func saveFloorplan() {
        var floorplan = Floorplan()
        if let fp = delegate?.floorplanForFloorplanCreationViewController?(self) {
            floorplan = fp
        } else {
            if let customer = customer {
                floorplan.customerId = customer.id
                floorplan.companyId = customer.companyId
            }
        }

        floorplan.name = nameTextField?.text
        navigationItem.title = floorplan.name

        if let totalSqFt = Double(totalSqFtTextField.text!) {
            floorplan.totalSqFt = totalSqFt
        }

        if floorplan.customerId > 0 && floorplan.name != nil && floorplan.name.length > 0 {
            showActivityIndicator()

            floorplan.save(
                onSuccess: { statusCode, mappingResult in
                    if statusCode == 201 {
                        self.delegate?.floorplanCreationViewController(self, didCreateFloorplan: mappingResult.firstObject as! Floorplan)
                    } else if statusCode == 204 {
                        self.hideActivityIndicator()
                        self.delegate?.floorplanCreationViewController(self, didUpdateFloorplan: floorplan)
                    }
                },
                onError: { error, statusCode, responseString in
                    self.hideActivityIndicator()
                }
            )
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == tableView.numberOfSections - 1 {
            if nameTextField.isFirstResponder() {
                nameTextField.resignFirstResponder()
            }
        }
        return indexPath
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

    func enableTapToDismissKeyboard() {
        disableTapToDismissKeyboard()
        tableView.enableTapToDismissKeyboard()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(FloorplanCreationViewController.resetTableViewFrame))
        tableView.addGestureRecognizer(tapGestureRecognizer)
    }

    func disableTapToDismissKeyboard() {
        tableView.disableTapToDismissKeyboard()
        tableView.removeGestureRecognizers()
    }

    func resetTableViewFrame() {
        tableView.endEditing(true)

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.tableView.frame.origin.y = 0.0
            },
            completion: { (complete) -> Void in

            }
        )
    }

    // MARK: UITextFieldDelegate

    func textFieldDidBeginEditing(textField: UITextField) {
        enableTapToDismissKeyboard()

        var view: UIView! = textField
        var cell: UITableViewCell!
        while cell == nil {
            view = view.superview!
            if view.isKindOfClass(UITableViewCell) {
                cell = view as! UITableViewCell
            }
        }

        if let cell = cell {
            let indexPath = tableView.indexPathForCell(cell)!
            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        }
    }

    func textFieldDidEndEditing(textField: UITextField) {
        dispatch_after_delay(0.0) {
            let hasFirstResponder = self.totalSqFtTextField.isFirstResponder()
            if textField == self.nameTextField && !hasFirstResponder {
                self.disableTapToDismissKeyboard()
                self.resetTableViewFrame()
            }
        }
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == nameTextField {
            if let name = textField.text {
                if name.length > 0 {
                    textField.resignFirstResponder()
                    if totalSqFtTextField.canBecomeFirstResponder() {
                        totalSqFtTextField.becomeFirstResponder()
                    }
                    return true
                }
            }
        } else if textField == totalSqFtTextField {
            if let totalSqFt = Double(textField.text!) {
                if totalSqFt > 0.0 {
                    textField.resignFirstResponder()
                    dispatch_after_delay(0.0) {
                        self.saveFloorplan()
                    }
                    return true
                }
            }
        }
        return false
    }

    // MARK: CustomerPickerViewControllerDelegate

    func queryParamsForCustomerPickerViewController(viewController: CustomerPickerViewController) -> [String : AnyObject]! {
        var params = [String : AnyObject]()
        if let queryString = queryString {
            params["q"] = queryString
        }
        if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
            params["company_id"] = defaultCompanyId
        }
        if let floorplan = delegate?.floorplanForFloorplanCreationViewController?(self) {
            params["customer_id"] = floorplan.customerId
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
                                self.customerPickerViewController?.hideActivityIndicator()
                            }
                        }
                    }
                )
            }
        }
    }

    private func showActivityIndicator() {
        let section = tableView.numberOfSections - 1
        if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: section)) {
            for view in cell.contentView.subviews {
                if view.isKindOfClass(UIActivityIndicatorView) {
                    (view as! UIActivityIndicatorView).startAnimating()
                } else if view.isKindOfClass(UIButton) {
                    view.alpha = 0.0
                    (view as! UIButton).enabled = false
                }
            }
        }
    }

    private func hideActivityIndicator() {
        let section = tableView.numberOfSections - 1
        if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: section)) {
            for view in cell.contentView.subviews {
                if view.isKindOfClass(UIActivityIndicatorView) {
                    (view as! UIActivityIndicatorView).stopAnimating()
                } else if view.isKindOfClass(UIButton) {
                    view.alpha = 1.0
                    (view as! UIButton).enabled = true
                }
            }
        }
    }
}
