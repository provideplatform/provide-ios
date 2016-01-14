//
//  TaskListViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/11/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol TaskListViewControllerDelegate {
    optional func jobForTaskListViewController(viewController: TaskListViewController) -> Job!
    optional func workOrderForTaskListViewController(viewController: TaskListViewController) -> WorkOrder!
}

class TaskListViewController: UITableViewController, TaskListTableViewCellDelegate {

    var taskListViewControllerDelegate: TaskListViewControllerDelegate! {
        didSet {
            if let _ = taskListViewControllerDelegate {
                reset()
            }
        }
    }

    private var page = 1
    private let rpp = 10
    private var lastTaskIndex = -1

    private var tasks = [Task]() {
        didSet {
            tableView?.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "TASKS"
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count + 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("taskListTableViewCellReuseIdentifier") as! TaskListTableViewCell
        cell.delegate = self
        cell.enableEdgeToEdgeDividers()
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let task = Task()
            task.status = "incomplete"

            cell.task = task
            return cell
        }

        cell.task = tasks[indexPath.row - 1]
        return cell
    }

    private func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: "reset", forControlEvents: .ValueChanged)

        tableView.addSubview(refreshControl!)
        tableView.alwaysBounceVertical = true
    }

    func reset() {
        if refreshControl == nil {
            setupPullToRefresh()
        }

        tasks = [Task]()
        page = 1
        lastTaskIndex = -1
        refresh()
    }

    func refresh() {
        if page == 1 {
            refreshControl?.beginRefreshing()
        }

        var params: [String : AnyObject] = [String : AnyObject]()

        params["page"] = page
        params["rpp"] = rpp

        if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
            params["company_id"] = defaultCompanyId
        }

        if let job = taskListViewControllerDelegate?.jobForTaskListViewController?(self) {
            params["job_id"] = String(job.id)
        }

        if let workOrder = taskListViewControllerDelegate?.workOrderForTaskListViewController?(self) {
            params["work_order_id"] = String(workOrder.id)
        }

        ApiService.sharedService().fetchTasks(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedTasks = mappingResult.array() as! [Task]
                if self.page == 1 {
                    self.tasks = [Task]()
                }
                for task in fetchedTasks {
                    self.tasks.append(task)
                }

                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            },
            onError: { error, statusCode, responseString in
                self.refreshControl?.endRefreshing()
            }
        )
    }

    // MARK: TaskListTableViewCellDelegate

    func taskListTableViewCell(tableViewCell: TaskListTableViewCell, didCreateTask task: Task) {
        dispatch_after_delay(0.0) {
            self.tableView.beginUpdates()
            self.tasks.insert(task, atIndex: 0)
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: 0)], withRowAnimation: .Automatic)
            self.tableView.endUpdates()
        }
    }

    func taskListTableViewCell(tableViewCell: TaskListTableViewCell, didUpdateTask task: Task) {
        var index: Int?
        for t in tasks {
            if t.id == task.id {
                index = tasks.indexOfObject(t)
                break
            }
        }
        if let index = index {
            tasks[index] = task
        }
        tableView.reloadData()
    }

    func jobForTaskListTableViewCell(tableViewCell: TaskListTableViewCell) -> Job! {
        return taskListViewControllerDelegate?.jobForTaskListViewController?(self)
    }

    func workOrderForTaskListTableViewCell(tableViewCell: TaskListTableViewCell) -> WorkOrder! {
        return taskListViewControllerDelegate?.workOrderForTaskListViewController?(self)
    }
}
