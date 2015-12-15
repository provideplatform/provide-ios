//
//  JobProductCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/14/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol JobProductCreationViewControllerDelegate {
    optional func jobProductForJobProductCreationViewController(viewController: JobProductCreationViewController) -> JobProduct!
    func jobProductCreationViewController(viewController: JobProductCreationViewController, didUpdateJobProduct jobProduct: JobProduct)
}

class JobProductCreationViewController: ProductCreationViewController {

    var jobProductCreationViewControllerDelegate: JobProductCreationViewControllerDelegate! {
        didSet {
            if let jobProductCreationViewControllerDelegate = jobProductCreationViewControllerDelegate {
                if jobProduct == nil {
                    if let jobProduct = jobProductCreationViewControllerDelegate.jobProductForJobProductCreationViewController?(self) {
                        self.jobProduct = jobProduct
                    }
                }
            }
        }
    }

    var job: Job!

    var jobProduct: JobProduct! {
        didSet {
            if let jobProduct = jobProduct {
                quantityTextField?.text = "\(jobProduct.initialQuantity)"

                if jobProduct.price > -1.0 {
                    priceTextField?.text = "$\(jobProduct.price)"
                }
            }
        }
    }

    @IBOutlet private weak var quantityTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 {
            if let job = job {
                job.save(
                    onSuccess: { statusCode, mappingResult in
                        self.jobProductCreationViewControllerDelegate?.jobProductCreationViewController(self, didUpdateJobProduct: self.jobProduct)
                    },
                    onError: { error, statusCode, responseString in

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

    override func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == quantityTextField {
            if let quantity = textField.text {
                return quantity ~= "\\d+"
            }
        } else {
            // TODO-- validate price
            return true
        }
        return false
    }

}
