//
//  RouteViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/20/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class RouteViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet fileprivate weak var tableView: UITableView!

    fileprivate var refreshControl: UIRefreshControl!

    fileprivate var zeroStateViewController: ZeroStateViewController! {
        didSet {
            if route == nil {
                refresh()
            }
        }
    }

    var route: Route! {
        didSet {
            if let _ = route {
                refresh()
            }
        }
    }

    fileprivate var selectedWorkOrder: WorkOrder!

    fileprivate func setupZeroStateView() {
        zeroStateViewController = UIStoryboard("ZeroState").instantiateInitialViewController() as! ZeroStateViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.frame = view.bounds

        setupPullToRefresh()

        setupZeroStateView()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "WorkOrderDetailsViewControllerSegue" {
            (segue.destination as! WorkOrderDetailsViewController).workOrder = selectedWorkOrder
            selectedWorkOrder = nil
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let route = route {
            if let name = route.name {
                navigationItem.title = name
            } else {
                navigationItem.title = "(unnamed route)"
            }
        }
    }

    fileprivate func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(RouteViewController.refresh), for: .valueChanged)

        tableView.addSubview(refreshControl)
        tableView.alwaysBounceVertical = true
    }

    func refresh() {
        if let route = route {
            route.reload(
                { statusCode, mappingResult in
                    self.tableView?.reloadData()

                    UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
                        animations: {
                            self.tableView?.alpha = 1.0
                            self.zeroStateViewController?.view.alpha = 0.0
                        },
                        completion: { complete in
                            self.refreshControl?.endRefreshing()
                        }
                    )
                },
                onError: { error, statusCode, responseString in
                    self.refreshControl?.endRefreshing()
                }
            )
        } else {
            zeroStateViewController?.render(view, animated: false)
            zeroStateViewController?.setLabelText("No active route")
            zeroStateViewController?.setMessage("")

            if let tableView = tableView {
                UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
                    animations: {
                        tableView.alpha = 0.0
                        self.zeroStateViewController?.view.alpha = 1.0
                    },
                    completion: { complete in
                        self.refreshControl?.endRefreshing()
                    }
                )
            }
        }
    }

//    func refreshNavigationItem() {
//        if let navigationController = delegate?.navigationControllerForViewController(self) {
//            navigationController.setNavigationBarHidden(false, animated: true)
//        }
//    }

//    func dismiss() {
//        tableView.delegate = nil
//        
//        clearNavigationItem()
//
//        if let navigationController = delegate?.navigationControllerForViewController(self) {
//            navigationController.popViewControllerAnimated(true)
//        }
//    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        selectedWorkOrder = route.workOrders[(indexPath as NSIndexPath).row]
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let route = route {
            return route.workOrders.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "workOrderTableViewCellReuseIdentifier") as! WorkOrderTableViewCell
        cell.workOrder = route.workOrders[(indexPath as NSIndexPath).row]
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
