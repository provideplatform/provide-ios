//
//  JobCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/12/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol JobCreationViewControllerDelegate: NSObjectProtocol {
    func jobCreationViewController(_ viewController: JobCreationViewController, didCreateJob job: Job)
}

class JobCreationViewController: UITableViewController,
                                 UISearchBarDelegate,
                                 UITextFieldDelegate,
                                 CustomerPickerViewControllerDelegate {

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

    fileprivate var customer: Customer!
    fileprivate var customers: [Customer]!

    fileprivate var totalCustomersCount = -1

    fileprivate var queryString: String!

    fileprivate var showsAllCustomers: Bool {
        return totalCustomersCount == -1 || totalCustomersCount <= maximumSearchlessCustomersCount
    }

    fileprivate var renderQueryResults: Bool {
        return queryString != nil || showsAllCustomers
    }

    fileprivate var reloadingCustomers = false
    fileprivate var reloadingCustomersCount = false

    fileprivate var customerPickerViewController: CustomerPickerViewController!

    @IBOutlet fileprivate weak var searchBar: UISearchBar!

    @IBOutlet fileprivate weak var nameTextField: UITextField!

    @IBOutlet fileprivate weak var createButton: UIButton!

    @IBOutlet fileprivate weak var customerTableViewCell: UITableViewCell!
    @IBOutlet fileprivate weak var typeTableViewCell: UITableViewCell!
    @IBOutlet fileprivate weak var nameTableViewCell: UITableViewCell!
    @IBOutlet fileprivate weak var quotedPricePerSqFtTableViewCell: UITableViewCell!
    @IBOutlet fileprivate weak var totalSqFtTableViewCell: UITableViewCell!
    @IBOutlet fileprivate weak var createButtonTableViewCell: UITableViewCell!

    fileprivate var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .plain, target: self, action: #selector(JobCreationViewController.dismiss(_:)))
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        return dismissItem
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "CREATE JOB"

        searchBar?.placeholder = ""

        createButton.addTarget(self, action: #selector(JobCreationViewController.createJob(_:)), for: .touchUpInside)

        if !isIPad() {
            navigationItem.leftBarButtonItems = [dismissItem]
        }
    }

    func typeChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }

    func dismiss(_ sender: UIBarButtonItem) {
        if let navigationController = navigationController {
            if navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            } else {
                navigationController.presentingViewController?.dismissViewController(true)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CustomerPickerViewControllerEmbedSegue" {
            customerPickerViewController = segue.destination as! CustomerPickerViewController
            customerPickerViewController.delegate = self

            if let _ = delegate {
                reloadCustomersForCustomerPickerViewController(customerPickerViewController)
            }
        }
    }

    func createJob(_ sender: UIButton) {
        tableView.endEditing(true)
        createJob()
    }

    fileprivate func createJob() {
        let job = Job()
        job.type = "punchlist"

        if let customer = customer {
            job.customerId = customer.id
            job.companyId = customer.companyId
        }
        job.name = nameTextField?.text

        if job.customerId > 0 && job.name != nil && job.name.length > 0 {
            showActivityIndicator()

            job.save(
                { statusCode, mappingResult in
                    if statusCode == 201 {
                        job.reload(
                            { statusCode, mappingResult in
                                self.delegate?.jobCreationViewController(self, didCreateJob: mappingResult?.firstObject as! Job)
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if (indexPath as NSIndexPath).section == tableView.numberOfSections - 1 {
            if nameTextField.isFirstResponder {
                nameTextField.resignFirstResponder()
            }
        }
        return indexPath
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == numberOfSections(in: tableView) - 1 {
            return nil
        }

        if section == 0 {
            return "CUSTOMER"
        } else if section == 1 {
            return "NAME"
        }

        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section == numberOfSections(in: tableView) - 1 {
            return createButtonTableViewCell
        }

        if (indexPath as NSIndexPath).section == 0 {
            return customerTableViewCell
        } else if (indexPath as NSIndexPath).section == 1 {
            return  nameTableViewCell
        }

        if let cell = tableView.cellForRow(at: indexPath) {
            return cell
        }

        return UITableViewCell()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    // MARK: UISearchBarDelegate

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return !showsAllCustomers
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
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
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(JobCreationViewController.resetTableViewFrame))
        tableView.addGestureRecognizer(tapGestureRecognizer)
    }

    func disableTapToDismissKeyboard() {
        tableView.disableTapToDismissKeyboard()
        tableView.removeGestureRecognizers()
    }

    func resetTableViewFrame() {
        tableView.endEditing(true)
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
            animations: {
                self.tableView.frame.origin.y = 0.0
            },
            completion: { (complete) -> Void in

            }
        )
    }

    // MARK: UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        enableTapToDismissKeyboard()

        var view: UIView! = textField
        var cell: UITableViewCell!
        while cell == nil {
            if let v = view?.superview {
                view = v
                if v is UITableViewCell {
                    cell = v as! UITableViewCell
                }
            }
        }

        if let cell = cell {
            if let indexPath = tableView.indexPath(for: cell) {
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            }
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {

    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            if let name = textField.text {
                if name.length > 0 {
                    textField.resignFirstResponder()
                    createJob()
                    return true
                }
            }
        }
        return false
    }

    // MARK: CustomerPickerViewControllerDelegate

    func queryParamsForCustomerPickerViewController(_ viewController: CustomerPickerViewController) -> [String : AnyObject]! {
        var params = [String : AnyObject]()
        if let queryString = queryString {
            params["q"] = queryString as AnyObject?
        }
        if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
            params["company_id"] = defaultCompanyId as AnyObject?
        }
        return params
    }

    func customerPickerViewController(_ viewController: CustomerPickerViewController, didSelectCustomer customer: Customer) {
        self.customer = customer

        if searchBar.isFirstResponder {
            searchBar.resignFirstResponder()
            if nameTextField.canBecomeFirstResponder {
                UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveEaseOut,
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

    func customerPickerViewController(_ viewController: CustomerPickerViewController, didDeselectCustomer customer: Customer) {
        self.customer = nil
    }

    func customerPickerViewControllerAllowsMultipleSelection(_ viewController: CustomerPickerViewController) -> Bool {
        return false
    }

    func customersForPickerViewController(_ viewController: CustomerPickerViewController) -> [Customer] {
        if let customers = customers {
            return customers
        } else {
            reloadCustomersForCustomerPickerViewController(viewController)
        }

        return [Customer]()
    }

    func selectedCustomersForPickerViewController(_ viewController: CustomerPickerViewController) -> [Customer] {
        if let customer = customer {
            return [customer]
        }
        return [Customer]()
    }

    func collectionViewScrollDirectionForPickerViewController(_ viewController: CustomerPickerViewController) -> UICollectionViewScrollDirection {
        return .horizontal
    }

//    optional func customerPickerViewControllerCanRenderResults(viewController: CustomerPickerViewController) -> Bool

    fileprivate func reloadCustomersForCustomerPickerViewController(_ viewController: CustomerPickerViewController) {
        if viewController == customerPickerViewController {
            reloadingCustomers = true
            reloadingCustomersCount = true

            customerPickerViewController?.customers = [Customer]()
            customerPickerViewController?.showActivityIndicator()
            tableView.reloadData()

            if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
                let _ = ApiService.sharedService().countCustomers(["company_id": defaultCompanyId as AnyObject],
                    onTotalResultsCount: { totalResultsCount, error in
                        self.totalCustomersCount = totalResultsCount
                        if totalResultsCount > -1 {
                            if totalResultsCount <= self.maximumSearchlessCustomersCount {
                                let _ = ApiService.sharedService().fetchCustomers(["company_id": defaultCompanyId as AnyObject, "page": 1 as AnyObject, "rpp": totalResultsCount as AnyObject],
                                    onSuccess: { (statusCode, mappingResult) -> () in
                                        self.customerPickerViewController?.customers = mappingResult?.array() as! [Customer]
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

    fileprivate func showActivityIndicator() {
        let section = tableView.numberOfSections - 1
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: section)) {
            for view in cell.contentView.subviews {
                if view.isKind(of: UIActivityIndicatorView.self) {
                    (view as! UIActivityIndicatorView).startAnimating()
                } else if view.isKind(of: UIButton.self) {
                    view.alpha = 0.0
                    (view as! UIButton).isEnabled = false
                }
            }
        }
    }

    fileprivate func hideActivityIndicator() {
        let section = tableView.numberOfSections - 1
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: section)) {
            for view in cell.contentView.subviews {
                if view.isKind(of: UIActivityIndicatorView.self) {
                    (view as! UIActivityIndicatorView).stopAnimating()
                } else if view.isKind(of: UIButton.self) {
                    view.alpha = 1.0
                    (view as! UIButton).isEnabled = true
                }
            }
        }
    }
}
