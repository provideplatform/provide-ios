//
//  TaskListTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 1/11/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol TaskListTableViewCellDelegate {
    func taskListTableViewCell(tableViewCell: TaskListTableViewCell, didCreateTask task: Task)
    func taskListTableViewCell(tableViewCell: TaskListTableViewCell, didUpdateTask task: Task)
    optional func jobForTaskListTableViewCell(tableViewCell: TaskListTableViewCell) -> Job!
    optional func workOrderForTaskListTableViewCell(tableViewCell: TaskListTableViewCell) -> WorkOrder!
}

class TaskListTableViewCell: UITableViewCell, UITextFieldDelegate, TaskTableViewCellCheckboxViewDelegate, ProviderSearchViewControllerDelegate {

    private let taskOperationQueue = dispatch_queue_create("taskOperationQueue", DISPATCH_QUEUE_SERIAL)

    var delegate: TaskListTableViewCellDelegate!

    private var providerSearchViewController: ProviderSearchViewController!

    private var providerQueryString: String!
    private var provider: Provider!

    private var usesStaticProvidersList: Bool {
        if let _ = delegate?.jobForTaskListTableViewCell?(self) {
            return true
        } else if let _ = delegate?.workOrderForTaskListTableViewCell?(self) {
            return true
        }
        return false
    }

    var task: Task! {
        didSet {
            if let task = task {
                checkboxView?.renderForTask(task)

                if task.id > 0 {
                    nameTextField?.text = task.name

                    if task.providerId > 0 {
                        let provider = Provider()
                        provider.id = task.providerId

                        self.provider = provider
                    }
                }
            }
        }
    }

    @IBOutlet private weak var nameTextField: UITextField! {
        didSet {
            if let nameTextField = nameTextField {
                providerSearchViewController = UIStoryboard("ProviderSearch").instantiateInitialViewController() as! ProviderSearchViewController
                providerSearchViewController.providerSearchViewControllerDelegate = self
                providerSearchViewController.setInputAccessoryMode()

                showNameInputAccessoryView()
                hideNameInputAccessoryView()

                nameTextField.addTarget(self, action: "textFieldChanged:", forControlEvents: .EditingChanged)
            }
        }
    }

    @IBOutlet private weak var checkboxView: TaskTableViewCellCheckboxView! {
        didSet {
            if let checkboxView = checkboxView {
                checkboxView.delegate = self
                
                checkboxView.alpha = 0.0
                contentView.bringSubviewToFront(checkboxView)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        if task == nil {
            task = Task()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        checkboxView?.alpha = 0.0

        nameTextField?.text = ""
    }

    private func saveTask() {
        task.name = nameTextField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())

        if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
            task.companyId = defaultCompanyId
        }

        if let provider = provider {
            task.providerId = provider.id
        }

        if let job = delegate?.jobForTaskListTableViewCell?(self) {
            task.jobId = job.id
            task.companyId = job.companyId
        }

        if let workOrder = delegate?.workOrderForTaskListTableViewCell?(self) {
            task.workOrderId = workOrder.id
            task.companyId = workOrder.companyId
        }

        let isNewTask = task.id == 0

        dispatch_async(taskOperationQueue) {
            self.task.save(
                onSuccess: { statusCode, mappingResult in
                    if isNewTask {
                        let task = mappingResult.firstObject as! Task
                        self.delegate?.taskListTableViewCell(self, didCreateTask: task)
                    } else {
                        self.delegate?.taskListTableViewCell(self, didUpdateTask: self.task)
                    }
                },
                onError: { error, statusCode, responseString in
                    
                }
            )
        }
    }

    func textFieldChanged(textField: UITextField) {
        if let text = textField.text {
            let string = NSString(string: text)
            if string.containsString("@") {
                if usesStaticProvidersList {
                    showNameInputAccessoryView()
                    providerQueryString = ""
                    providerSearchViewController.query("")
                } else {
                    let range = string.rangeOfString("@")
                    let startIndex = range.location + 1
                    if startIndex <= string.length - 1 {
                        var query: String!
                        let components = string.substringFromIndex(startIndex).componentsSeparatedByString(" ")
                        if components.count == 1 {
                            query = "\(components[0])"
                        } else if components.count >= 2 {
                            query = "\(components[0]) \(components[1])"
                        }
                        if let query = query {
                            showNameInputAccessoryView()
                            providerQueryString = query
                            providerSearchViewController.query(query)
                        }
                    } else {
                        hideNameInputAccessoryView()
                    }
                }
            } else {
                hideNameInputAccessoryView()
            }
        }
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if task.id > 0 {
            return currentUser().id == task.userId
        }
        return true
    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text {
            if NSString(string: text).containsString("@") {
                return string != "@"
            }
        }
        return true
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == nameTextField {
            if textField.text!.length == 0 {
                return false
            }
        }
        textField.resignFirstResponder()
        saveTask()
        return true
    }

    // MARK: TaskTableViewCellCheckboxViewDelegate

    func taskTableViewCellCheckboxView(view: TaskTableViewCellCheckboxView, didBecomeChecked checked: Bool) {
        task.status = checked ? "completed" : "incomplete"
        dispatch_async(taskOperationQueue) {
            self.task.save(
                onSuccess: { statusCode, mappingResult in
                    //let task = mappingResult.firstObject as! Task

                    self.prepareForReuse()
                    self.delegate?.taskListTableViewCell(self, didUpdateTask: self.task)
                },
                onError: { error, statusCode, responseString in
                    
                }
            )
        }
    }

    // MARK: ProviderSearchViewControllerDelegate

    func providersForProviderSearchViewController(viewController: ProviderSearchViewController) -> [Provider]! {
        if let job = delegate?.jobForTaskListTableViewCell?(self) {
            var providers = job.supervisors
            if let workOrder = delegate?.workOrderForTaskListTableViewCell?(self) {
                for provider in workOrder.providers {
                    var isSupervisor = false
                    for supervisor in providers {
                        if supervisor.id == provider.id {
                            isSupervisor = true
                        }
                    }
                    if !isSupervisor {
                        providers.append(provider)
                    }
                }
            }
            return providers
        } else if let workOrder = delegate?.workOrderForTaskListTableViewCell?(self) {
            return workOrder.providers
        }
        return nil
    }

    func providerSearchViewController(viewController: ProviderSearchViewController, didSelectProvider provider: Provider) {
        self.provider = provider

        if let queryString = providerQueryString {
            nameTextField.text = nameTextField.text!.replaceString("@\(queryString)", withString: "@\(provider.contact.name) ")
            providerQueryString = nil

            hideNameInputAccessoryView()
        }
    }

    private func hideNameInputAccessoryView() {
        if let inputAccessoryView = nameTextField.inputAccessoryView {
            inputAccessoryView.alpha = 0.0
            inputAccessoryView.hidden = true
            nameTextField.layoutIfNeeded()
        }
    }

    private func showNameInputAccessoryView() {
        if nameTextField.inputAccessoryView == nil {
            nameTextField.inputAccessoryView = providerSearchViewController.view
            nameTextField.inputAccessoryView!.frame.size.height = 120.0
            nameTextField.inputAccessoryView!.autoresizingMask = .None
        }

        nameTextField.inputAccessoryView!.hidden = false
        nameTextField.inputAccessoryView!.alpha = 1.0

        nameTextField.layoutIfNeeded()
    }
}
