//
//  TaskListViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/11/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

@objc
protocol TaskListViewControllerDelegate {
    @objc optional func jobForTaskListViewController(_ viewController: TaskListViewController) -> Job!
    @objc optional func workOrderForTaskListViewController(_ viewController: TaskListViewController) -> WorkOrder!
}

class TaskListViewController: UITableViewController, TaskListTableViewCellDelegate {

    var taskListViewControllerDelegate: TaskListViewControllerDelegate! {
        didSet {
            if let _ = taskListViewControllerDelegate {
                reset()
            }
        }
    }

    fileprivate var page = 1
    fileprivate let rpp = 10
    fileprivate var lastTaskIndex = -1

    fileprivate var tasks = [Task]() {
        didSet {
            tableView?.reloadData()
        }
    }

    fileprivate var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .plain, target: self, action: #selector(TaskListViewController.dismiss(_:)))
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        return dismissItem
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "PUNCH LIST"

        if !isIPad() {
            navigationItem.leftBarButtonItems = [dismissItem]
        }
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskListTableViewCellReuseIdentifier") as! TaskListTableViewCell
        cell.delegate = self
        cell.enableEdgeToEdgeDividers()
        
        if (indexPath as NSIndexPath).section == 0 && (indexPath as NSIndexPath).row == 0 {
            let task = Task()
            task.status = "incomplete"

            cell.task = task
            return cell
        }

        cell.task = tasks[(indexPath as NSIndexPath).row - 1]
        return cell
    }

    fileprivate func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(TaskListViewController.reset), for: .valueChanged)

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

        params["page"] = page as AnyObject?
        params["rpp"] = rpp as AnyObject?

        if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
            params["company_id"] = defaultCompanyId as AnyObject?
        }

        if let job = taskListViewControllerDelegate?.jobForTaskListViewController?(self) {
            params["job_id"] = String(job.id) as AnyObject?
        }

        if let workOrder = taskListViewControllerDelegate?.workOrderForTaskListViewController?(self) {
            params["work_order_id"] = String(workOrder.id) as AnyObject?
        } else if let _ = params["job_id"] {
            params["exclude_work_orders"] = "true" as AnyObject?
        }

        ApiService.sharedService().fetchTasks(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedTasks = mappingResult?.array() as! [Task]
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

    func taskListTableViewCell(_ tableViewCell: TaskListTableViewCell, didCreateTask task: Task) {
        dispatch_after_delay(0.0) {
            self.tableView.beginUpdates()
            self.tasks.insert(task, at: 0)
            self.tableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
            self.tableView.endUpdates()
        }
    }

    func taskListTableViewCell(_ tableViewCell: TaskListTableViewCell, didUpdateTask task: Task) {
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

    func jobForTaskListTableViewCell(_ tableViewCell: TaskListTableViewCell) -> Job! {
        return taskListViewControllerDelegate?.jobForTaskListViewController?(self)
    }

    func workOrderForTaskListTableViewCell(_ tableViewCell: TaskListTableViewCell) -> WorkOrder! {
        return taskListViewControllerDelegate?.workOrderForTaskListViewController?(self)
    }
}
