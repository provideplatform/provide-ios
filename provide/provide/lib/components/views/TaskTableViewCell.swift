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

class TaskListTableViewCell: UITableViewCell, UITextFieldDelegate, TaskTableViewCellCheckboxViewDelegate {

    private let taskOperationQueue = dispatch_queue_create("taskOperationQueue", DISPATCH_QUEUE_SERIAL)

    var delegate: TaskListTableViewCellDelegate!

    var task: Task! {
        didSet {
            if let task = task {
                checkboxView?.renderForTask(task)

                if task.id > 0 {
                    nameTextField?.text = task.name
                }
            }
        }
    }

    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var checkboxView: TaskTableViewCellCheckboxView! {
        didSet {
            if let checkboxView = checkboxView {
                checkboxView.delegate = self
                
                checkboxView.alpha = 0.0
                contentView.bringSubviewToFront(checkboxView)
            }
        }
    }

    private var provider: Provider!

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
        task.name = nameTextField.text

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
                    let task = mappingResult.firstObject as! Task

                    if isNewTask {
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

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == nameTextField {
            if textField.text!.length == 0 {
                return false
            }
        }
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
                    
            })
        }
    }
}
