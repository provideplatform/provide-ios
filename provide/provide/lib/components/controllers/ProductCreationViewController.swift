//
//  ProductCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/14/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation

protocol ProductCreationViewControllerDelegate {
    func productCreationViewController(viewController: ProductCreationViewController, didCreateProduct product: Product)
}

class ProductCreationViewController: UITableViewController, UITextFieldDelegate, BarcodeScannerViewControllerDelegate {

    var delegate: ProductCreationViewControllerDelegate!

    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var gtinTextField: UITextField!
    @IBOutlet internal weak var priceTextField: UITextField!
    @IBOutlet internal weak var unitOfMeasureTextField: UITextField!

    @IBOutlet internal weak var saveButton: UIButton!

    private var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .Plain, target: self, action: #selector(ProductCreationViewController.dismiss(_:)))
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return dismissItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "CREATE PRODUCT"

        if !isIPad() {
            navigationItem.leftBarButtonItems = [dismissItem]
        }

        saveButton.addTarget(self, action: #selector(ProductCreationViewController.save(_:)), forControlEvents: .TouchUpInside)

        setupScanBarButtonItem()
    }

    internal func save() {
        tableView.endEditing(true)

        let user = currentUser()
        if user.defaultCompanyId > 0 {
            createProductWithCompanyId(user.defaultCompanyId)
        } else {
            print("WARNING: this user is associated with multiple companies as a provider so cannot attempt creation without user input")
        }
    }

    internal func save(sender: UIButton) {
        save()
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

    private func setupScanBarButtonItem() {
        let barcodeIconImage = FAKFontAwesome.barcodeIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0))
        let scanBarButtonItem = NavigationBarButton.barButtonItemWithImage(barcodeIconImage, target: self, action: "scanButtonTapped:")
        navigationItem.rightBarButtonItem = scanBarButtonItem
    }

    func scanButtonTapped(sender: UIBarButtonItem) {
        let barcodeScannerViewController = UIStoryboard("BarcodeScanner").instantiateInitialViewController() as! BarcodeScannerViewController
        barcodeScannerViewController.delegate = self

        presentViewController(barcodeScannerViewController, animated: true)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == tableView.numberOfSections - 1 {
            tableView.cellForRowAtIndexPath(indexPath)!.alpha = 0.8
        }
        return indexPath
    }

    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == tableView.numberOfSections - 1 {
            tableView.cellForRowAtIndexPath(indexPath)!.alpha = 1.0
        }
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == nameTextField {
            if let name = textField.text {
                if name.length > 0 {
                    textField.resignFirstResponder()
                    if gtinTextField.canBecomeFirstResponder() {
                        gtinTextField.becomeFirstResponder()
                    }
                    return true
                }
            }
        } else if textField == gtinTextField {
            if let gtin = textField.text {
                if gtin.length > 0 {
                    textField.resignFirstResponder()
                    if priceTextField.canBecomeFirstResponder() {
                        priceTextField.becomeFirstResponder()
                    }
                    return true
                }
            }
        } else if textField == priceTextField {
            if let price = Double(textField.text!) {
                if price > 0.0 {
                    textField.resignFirstResponder()
                    if unitOfMeasureTextField.canBecomeFirstResponder() {
                        unitOfMeasureTextField.becomeFirstResponder()
                    }
                    return true
                }
            }
        } else if textField == unitOfMeasureTextField {
            if let unitOfMeasure = textField.text {
                if unitOfMeasure.length > 0 {
                    textField.resignFirstResponder()
                    dispatch_after_delay(0.0) {
                        self.save()
                    }
                    return true
                }
            }
        }
        return false
    }

    // MARK: BarcodeScannerViewControllerDelegate

    func barcodeScannerViewController(viewController: BarcodeScannerViewController, didOutputMetadataObjects metadataObjects: [AnyObject], fromConnection connection: AVCaptureConnection) {
        print("saw barcode(s) \(metadataObjects)")
    }

    func barcodeScannerViewControllerShouldBeDismissed(viewController: BarcodeScannerViewController) {
        dismissViewController(animated: false)
    }

    private func createProductWithCompanyId(companyId: Int) {
        let product = Product()
        product.companyId = companyId
        product.gtin = gtinTextField?.text
        product.data = [String : AnyObject]()
        product.data["name"] = nameTextField?.text
        product.data["price"] = priceTextField?.text

        if let unitOfMeasure = unitOfMeasureTextField?.text {
            if unitOfMeasure.length > 0 {
                product.data["unit_of_measure"] = unitOfMeasure
            }
        }

        let productIsValid = product.companyId > 0 && product.gtin != nil && product.gtin!.length > 0 && product.name != nil && product.name!.length > 0

        if productIsValid {
            showActivityIndicator()

            product.save(
                onSuccess: { statusCode, mappingResult in
                    if statusCode == 201 {
                        self.hideActivityIndicator()
                        self.delegate?.productCreationViewController(self, didCreateProduct: mappingResult.firstObject as! Product)
                    }
                },
                onError: { error, statusCode, responseString in
                    self.hideActivityIndicator()
                }
            )
        } else {
            hideActivityIndicator()
        }
    }

    internal func showActivityIndicator() {
        let section = tableView.numberOfSections - 1
        for view in tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: section))!.contentView.subviews {
            if view.isKindOfClass(UIActivityIndicatorView) {
                (view as! UIActivityIndicatorView).startAnimating()
            } else if view.isKindOfClass(UIButton) {
                view.alpha = 0.0
                (view as! UIButton).enabled = false
            }
        }
    }

    internal func hideActivityIndicator() {
        let section = tableView.numberOfSections - 1
        for view in tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: section))!.contentView.subviews {
            if view.isKindOfClass(UIActivityIndicatorView) {
                (view as! UIActivityIndicatorView).stopAnimating()
            } else if view.isKindOfClass(UIButton) {
                view.alpha = 1.0
                (view as! UIButton).enabled = true
            }
        }
    }
}
