//
//  ProductionsViewController.swift
//  startrack
//
//  Created by Kyle Thomas on 9/7/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ProductionsViewController: ViewController, UITableViewDelegate, UITableViewDataSource, ProductionViewControllerDelegate {

    private var page = 1
    private let rpp = 10
    private var lastProductionIndex = -1

    @IBOutlet private weak var tableView: UITableView!

    private var refreshControl: UIRefreshControl!

    private var workOrders = [WorkOrder]() {
        didSet {
            tableView?.reloadData()
            //collectionView?.layoutIfNeeded()
        }
    }

    private weak var selectedProduction: Production!
    private weak var selectedWorkOrder: WorkOrder!

    private var zeroStateViewController: ZeroStateViewController!

    private var stopBarButtonItem: UIBarButtonItem! {
        let stopBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: "dismiss")
        stopBarButtonItem.tintColor = Color.darkBlueBackground()
        return stopBarButtonItem
    }

    private var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: "dismiss:")
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        dismissItem.tintColor = Color.darkBlueBackground()
        return dismissItem
    }

    private var isColumnedLayout: Bool {
        return false //view.frame.width > 414.0
    }

    private var numberOfSections: Int {
        if isColumnedLayout {
            return Int(ceil(Double(workOrders.count) / Double(numberOfItemsPerSection)))
        }
        return workOrders.count
    }

    private var numberOfItemsPerSection: Int {
        if isColumnedLayout {
            return 2
        }
        return 1
    }

    private func productionIndexAtIndexPath(indexPath: NSIndexPath) -> Int {
        if isColumnedLayout {
            var i = indexPath.section * 2
            i += indexPath.row
            return i
        }
        return indexPath.section
    }

    private func productionForRowAtIndexPath(indexPath: NSIndexPath) -> WorkOrder {
        return workOrders[productionIndexAtIndexPath(indexPath)]
    }

    private func setupZeroStateView() {
        zeroStateViewController = UIStoryboard("Provider").instantiateViewControllerWithIdentifier("ZeroStateViewController") as! ZeroStateViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshNavigationItem()
        setupPullToRefresh()

        setupZeroStateView()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        selectedProduction = nil
        selectedWorkOrder = nil

        tableView.frame = view.bounds
    }

    private func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "reset", forControlEvents: .ValueChanged)

        tableView.addSubview(refreshControl)
        tableView.alwaysBounceVertical = true

        refresh()
    }

    func reset() {
        workOrders = [WorkOrder]()
        page = 1
        lastProductionIndex = -1
        refresh()
    }

    func refresh() {
        WorkOrderService.sharedService().fetch(page, rpp: rpp, status: "scheduled,in_progress,completed,canceled", today: false, excludeRoutes: true) { (workOrders) -> () in
            self.workOrders += workOrders

            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            self.refreshControl.endRefreshing()
        }
    }

//    func refresh2() {
//        if page == 1 {
//            refreshControl.beginRefreshing()
//        }
//
//        let params = [
//            "page": page,
//            "rpp": rpp,
//            "status": "scheduled,in_progress,completed,canceled",
//        ]
//
//        ApiService.sharedService().fetchProductions(params as! [String : AnyObject],
//            onSuccess: { statusCode, mappingResult in
//                let fetchedProductions = mappingResult.array() as! [Production]
//                self.productions += fetchedProductions
//
//                self.tableView.reloadData()
//                self.tableView.layoutIfNeeded()
//                self.refreshControl.endRefreshing()
//            },
//            onError: { error, statusCode, responseString in
//                // TODO
//            }
//        )
//    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ProductionViewControllerSegue" {
            (segue.destinationViewController as! ProductionViewController).delegate = self
        }
    }

    func refreshNavigationItem() {
        navigationItem.title = "PRODUCTIONS"
        navigationItem.leftBarButtonItems = [dismissItem]

        if let navigationController = navigationController {
            navigationController.setNavigationBarHidden(false, animated: true)
        }
    }

    func clearNavigationItem() {
        navigationItem.hidesBackButton = true
        navigationItem.prompt = nil
        navigationItem.leftBarButtonItems = []
        navigationItem.rightBarButtonItems = []
    }

    func dismiss(sender: UIBarButtonItem!) {
        tableView.delegate = nil

        clearNavigationItem()

        if let navigationController = navigationController {
            navigationController.popViewControllerAnimated(true)
        }
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let productionIndex = productionIndexAtIndexPath(indexPath)
        if productionIndex == workOrders.count - 1 && productionIndex > lastProductionIndex {
            page++
            lastProductionIndex = productionIndex
            refresh()
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isColumnedLayout {
            let productionIndex = productionIndexAtIndexPath(NSIndexPath(forRow: 1, inSection: section))
            if productionIndex > workOrders.count - 1 {
                return 1
            }
            return 2
        }
        return numberOfItemsPerSection
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("providerCastingDemandTableViewCellReuseIdentifier") as! ProviderCastingDemandTableViewCell
        cell.workOrder = productionForRowAtIndexPath(indexPath)
        return cell
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return numberOfSections
    }

    func navigationControllerForViewController(viewController: UIViewController) -> UINavigationController! {
        return navigationController
    }
}
