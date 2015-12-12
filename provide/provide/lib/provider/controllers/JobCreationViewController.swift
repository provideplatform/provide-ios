//
//  JobCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobCreationViewControllerDelegate {

}

class JobCreationViewController: UITableViewController, CustomerPickerViewControllerDelegate {

    var delegate: JobCreationViewControllerDelegate!

    private var customer: Customer!
    private var customers: [Customer]!

    private var reloadingCustomers = false

    private var customerPickerViewController: CustomerPickerViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "CustomerPickerViewControllerEmbedSegue" {
            customerPickerViewController = segue.destinationViewController as! CustomerPickerViewController
            customerPickerViewController.delegate = self
        }
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
