//
//  WorkOrderProviderCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/27/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol WorkOrderProviderCreationViewControllerDelegate: NSObjectProtocol {
    func workOrderProviderCreationViewController(viewController: WorkOrderProviderCreationViewController, didUpdateWorkOrderProvider workOrderProvider: WorkOrderProvider)
}

class WorkOrderProviderCreationViewController: UITableViewController, UITextFieldDelegate, DurationPickerViewDelegate {

    var workOrderProviderCreationViewControllerDelegate: WorkOrderProviderCreationViewControllerDelegate!

    var workOrderProvider: WorkOrderProvider! {
        didSet {
            if let _ = workOrderProvider {
                populateTextFields()
            }
        }
    }

    weak var workOrder: WorkOrder!
    
    private var durationPickerView: DurationPickerView!

    private var estimatedDuration: Double!

    @IBOutlet private weak var rateTextField: UITextField!

    private var hourlyRate: Double! {
        if let rateTextField = rateTextField {
            if let rate = Double(rateTextField.text!) {
                return rate
            }
        }
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        populateTextFields()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "DurationPickerViewControllerEmbedSegue" {
            durationPickerView = segue.destinationViewController.view as! DurationPickerView
            durationPickerView.durationPickerViewDelegate = self
        }
    }

    private func populateTextFields() {
        if let workOrderProvider = workOrderProvider {
            if workOrderProvider.estimatedDuration > -1.0 {
                durationPickerView.selectRowWithValue(CGFloat(workOrderProvider.estimatedDuration))
            }

            if workOrderProvider.hourlyRate > -1.0 {
                rateTextField?.text = "\(workOrderProvider.hourlyRate)"
            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 {
            saveWorkOrderProvider()
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

    private func saveWorkOrderProvider() {
        if let workOrderProvider = workOrderProvider {
            if let estimatedDuration = estimatedDuration {
                workOrderProvider.estimatedDuration = estimatedDuration
            }
            if let hourlyRate = hourlyRate {
                workOrderProvider.hourlyRate = hourlyRate
            }

            showActivityIndicator()

            workOrder.updateWorkOrderProvider(workOrderProvider,
                onSuccess: { statusCode, mappingResult in
                    self.workOrderProviderCreationViewControllerDelegate?.workOrderProviderCreationViewController(self, didUpdateWorkOrderProvider: workOrderProvider)
                },
                onError: { error, statusCode, responseString in
                    self.hideActivityIndicator()
                }
            )
        }
    }

    private func showActivityIndicator() {
        for view in tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2))!.contentView.subviews {
            if view.isKindOfClass(UIActivityIndicatorView) {
                (view as! UIActivityIndicatorView).startAnimating()
            } else if view.isKindOfClass(UILabel) {
                view.alpha = 0.0
            }
        }
    }

    private func hideActivityIndicator() {
        for view in tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2))!.contentView.subviews {
            if view.isKindOfClass(UIActivityIndicatorView) {
                (view as! UIActivityIndicatorView).stopAnimating()
            } else if view.isKindOfClass(UILabel) {
                view.alpha = 1.0
            }
        }
    }

    // MARK: UITextFieldDelegate

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return true
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        saveWorkOrderProvider()
        return true
    }

    // MARK: DurationPickerViewDelegate

    func durationPickerView(view: DurationPickerView, didPickDuration duration: CGFloat) {
        estimatedDuration = Double(duration)
    }
}
