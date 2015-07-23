//
//  RouteViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/20/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol RouteViewControllerDelegate {
    func routeForViewController(viewController: ViewController!) -> Route!
    func navigationControllerForViewController(viewController: ViewController!) -> UINavigationController!
}

class RouteViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

    var delegate: RouteViewControllerDelegate! {
        didSet {
            if let delegate = delegate {
                refresh()
            }
        }
    }

    @IBOutlet private weak var tableView: UITableView!

    private var refreshControl: UIRefreshControl!

    private var zeroStateViewController: ZeroStateViewController! {
        didSet {
            if route == nil {
                refresh()
            }
        }
    }

    var route: Route! {
        return delegate?.routeForViewController(self)
    }

    private var selectedWorkOrder: WorkOrder!

    private var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .Plain, target: self, action: "dismiss")
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return dismissItem
    }

    private func setupZeroStateView() {
        zeroStateViewController = UIStoryboard("Provider").instantiateViewControllerWithIdentifier("ZeroStateViewController") as! ZeroStateViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.frame = view.bounds

        refreshNavigationItem()
        setupPullToRefresh()

        setupZeroStateView()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "WorkOrderDetailsViewControllerSegue" {
            (segue.destinationViewController as! WorkOrderDetailsViewController).workOrder = selectedWorkOrder
            selectedWorkOrder = nil
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let route = route {
            if let name = route.name {
                navigationItem.title = name
            } else {
                navigationItem.title = "(unnamed route)"
            }
        }
    }

    private func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)

        tableView.addSubview(refreshControl)
        tableView.alwaysBounceVertical = true
    }

    func refresh() {
        if let route = route {
            route.reload(
                onSuccess: { statusCode, mappingResult in
                    self.tableView.reloadData()

                    UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
                        animations: {
                            self.tableView.alpha = 1.0
                            self.zeroStateViewController.view.alpha = 0.0
                        },
                        completion: { complete in
                            self.refreshControl.endRefreshing()
                        }
                    )
                },
                onError: { error, statusCode, responseString in
                    self.refreshControl.endRefreshing()
                }
            )
        } else {
            zeroStateViewController?.render(view, animated: false)
            zeroStateViewController?.setLabelText("No active route")
            zeroStateViewController?.setMessage("")

            if let tableView = tableView {
                UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
                    animations: {
                        tableView.alpha = 0.0
                        self.zeroStateViewController.view.alpha = 1.0
                    },
                    completion: { complete in
                        self.refreshControl.endRefreshing()
                    }
                )
            }
        }
    }

    func refreshNavigationItem() {
        navigationItem.leftBarButtonItems = [dismissItem]

        if let navigationController = delegate?.navigationControllerForViewController(self) {
            navigationController.setNavigationBarHidden(false, animated: true)
        }
    }

    func clearNavigationItem() {
        navigationItem.hidesBackButton = true
        navigationItem.prompt = nil
        navigationItem.leftBarButtonItems = []
        navigationItem.rightBarButtonItems = []
    }

    func dismiss() {
        clearNavigationItem()

        if let navigationController = delegate?.navigationControllerForViewController(self) {
            navigationController.popViewControllerAnimated(true)
        }
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        selectedWorkOrder = route.workOrders[indexPath.row]
        return indexPath
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let route = route {
            return route.workOrders.count
        }
        return 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("workOrderTableViewCellReuseIdentifier") as! WorkOrderTableViewCell
        cell.workOrder = route.workOrders[indexPath.row]
        return cell
    }

//    optional func numberOfSectionsInTableView(tableView: UITableView) -> Int // Default is 1 if not implemented
//
//    optional func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? // fixed font style. use custom view (UILabel) if you want something different
//    optional func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String?
//
//    // Editing
//
//    // Individual rows can opt out of having the -editing property set for them. If not implemented, all rows are assumed to be editable.
//    optional func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
//
//    // Moving/reordering
//
//    // Allows the reorder accessory view to optionally be shown for a particular row. By default, the reorder control will be shown only if the datasource implements -tableView:moveRowAtIndexPath:toIndexPath:
//    optional func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool
//
//    // Index
//
//    optional func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! // return list of section titles to display in section index view (e.g. "ABCD...Z#")
//    optional func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int // tell table which section corresponds to section title/index (e.g. "B",1))
//
//    // Data manipulation - insert and delete support
//
//    // After a row has the minus or plus button invoked (based on the UITableViewCellEditingStyle for the cell), the dataSource must commit the change
//    // Not called for edit actions using UITableViewRowAction - the action's handler will be invoked instead
//    optional func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
//
//    // Data manipulation - reorder / moving support
//
//    optional func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath)
}
