//
//  JobCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobCreationViewControllerDelegate {
    func jobCreationViewController(viewController: JobCreationViewController, didCreateJob job: Job)
}

class JobCreationViewController: UITableViewController, UITextFieldDelegate, CustomerPickerViewControllerDelegate {

    var delegate: JobCreationViewControllerDelegate!

    private var customer: Customer!
    private var customers: [Customer]!

    private var reloadingCustomers = false

    private var customerPickerViewController: CustomerPickerViewController!

    @IBOutlet private weak var nameTextField: UITextField!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "CustomerPickerViewControllerEmbedSegue" {
            customerPickerViewController = segue.destinationViewController as! CustomerPickerViewController
            customerPickerViewController.delegate = self
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 {
            let job = Job()
            if let customer = customer {
                job.customerId = customer.id
                job.companyId = customer.companyId
            }
            job.name = nameTextField?.text

            if job.customerId > 0 && job.name != nil && job.name.length > 0 {
                for view in tableView.cellForRowAtIndexPath(indexPath)!.contentView.subviews {
                    if view.isKindOfClass(UIActivityIndicatorView) {
                        (view as! UIActivityIndicatorView).startAnimating()
                    } else if view.isKindOfClass(UILabel) {
                        view.alpha = 0.0
                    }
                }

                job.save(
                    onSuccess: { statusCode, mappingResult in
                        if statusCode == 201 {
                            job.reload(
                                onSuccess: { statusCode, mappingResult in
                                    self.activityIndicatorView?.stopAnimating()
                                    self.delegate?.jobCreationViewController(self, didCreateJob: mappingResult.firstObject as! Job)
                                },
                                onError: { error, statusCode, responseString in
                                    self.activityIndicatorView?.stopAnimating()
                                }
                            )
                        }
                    },
                    onError: { error, statusCode, responseString in
                        self.activityIndicatorView?.stopAnimating()
                    }
                )
            }
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 2 {
            tableView.cellForRowAtIndexPath(indexPath)!.alpha = 0.8
        }
        return indexPath
    }

    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 {
            tableView.cellForRowAtIndexPath(indexPath)!.alpha = 1.0
        }
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == nameTextField {
            if let name = textField.text {
                return name.length > 0
            }
        }
        return false
    }

    // MARK: CustomerPickerViewControllerDelegate

    func queryParamsForCustomerPickerViewController(viewController: CustomerPickerViewController) -> [String : AnyObject]! {
        let params = [String : AnyObject]()
        return params
    }

    func customerPickerViewController(viewController: CustomerPickerViewController, didSelectCustomer customer: Customer) {
        self.customer = customer
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

//    optional func customerPickerViewControllerCanRenderResults(viewController: CustomerPickerViewController) -> Bool

    private func reloadCustomersForCustomerPickerViewController(viewController: CustomerPickerViewController) {
        if viewController == customerPickerViewController {
            reloadingCustomers = true

            ApiService.sharedService().fetchCustomers([:],
                onSuccess: { statusCode, mappingResult in
                    viewController.customers = mappingResult.array() as! [Customer]
                    viewController.reloadCollectionView()
                    self.reloadingCustomers = false
                },
                onError: { error, statusCode, responseString in
                    viewController.reloadCollectionView()
                    self.reloadingCustomers = false
                }
            )
        }
    }
}
