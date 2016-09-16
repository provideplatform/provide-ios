//
//  WorkOrderProviderCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/27/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol WorkOrderProviderCreationViewControllerDelegate: NSObjectProtocol {
    func workOrderProviderCreationViewController(_ viewController: WorkOrderProviderCreationViewController, didUpdateWorkOrderProvider workOrderProvider: WorkOrderProvider)
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
    
    fileprivate var durationPickerView: DurationPickerView!

    fileprivate var estimatedDuration: Double!

    @IBOutlet fileprivate weak var rateTextField: UITextField!

    fileprivate var hourlyRate: Double! {
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier! == "DurationPickerViewControllerEmbedSegue" {
            durationPickerView = segue.destination.view as! DurationPickerView
            durationPickerView.durationPickerViewDelegate = self
        }
    }

    fileprivate func populateTextFields() {
        if let workOrderProvider = workOrderProvider {
            if workOrderProvider.estimatedDuration > -1.0 {
                durationPickerView.selectRowWithValue(CGFloat(workOrderProvider.estimatedDuration))
            }

            if workOrderProvider.hourlyRate > -1.0 {
                rateTextField?.text = "\(workOrderProvider.hourlyRate)"
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == tableView.numberOfSections - 1 {
            saveWorkOrderProvider()
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if (indexPath as NSIndexPath).section == tableView.numberOfSections - 1 {
            tableView.cellForRow(at: indexPath)!.alpha = 0.8
        }
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == tableView.numberOfSections - 1 {
            tableView.cellForRow(at: indexPath)!.alpha = 1.0
        }
    }

    fileprivate func saveWorkOrderProvider() {
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

    fileprivate func showActivityIndicator() {
        let section = tableView.numberOfSections - 1
        for view in tableView.cellForRow(at: IndexPath(row: 0, section: section))!.contentView.subviews {
            if view.isKind(of: UIActivityIndicatorView.self) {
                (view as! UIActivityIndicatorView).startAnimating()
            } else if view.isKind(of: UILabel.self) {
                view.alpha = 0.0
            }
        }
    }

    fileprivate func hideActivityIndicator() {
        let section = tableView.numberOfSections - 1
        for view in tableView.cellForRow(at: IndexPath(row: 0, section: section))!.contentView.subviews {
            if view.isKind(of: UIActivityIndicatorView.self) {
                (view as! UIActivityIndicatorView).stopAnimating()
            } else if view.isKind(of: UILabel.self) {
                view.alpha = 1.0
            }
        }
    }

    // MARK: UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveWorkOrderProvider()
        return true
    }

    // MARK: DurationPickerViewDelegate

    func durationPickerView(_ view: DurationPickerView, didPickDuration duration: CGFloat) {
        estimatedDuration = Double(duration) * 60.0 // convert to seconds
    }
}
