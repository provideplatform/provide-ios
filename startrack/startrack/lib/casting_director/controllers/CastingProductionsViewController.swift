//
//  CastingProductionsViewController.swift
//  startrack
//
//  Created by Kyle Thomas on 9/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CastingProductionsViewController: ViewController, UITableViewDelegate, UITableViewDataSource, ProductionViewControllerDelegate {

    private var page = 1
    private let rpp = 10
    private var lastProductionIndex = -1

    @IBOutlet private weak var tableView: UITableView!

    private var refreshControl: UIRefreshControl!

    private var productions = [Production]() {
        didSet {
            tableView?.reloadData()
            //collectionView?.layoutIfNeeded()
        }
    }

    private weak var selectedProduction: Production!

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
            return Int(ceil(Double(productions.count) / Double(numberOfItemsPerSection)))
        }
        return productions.count
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

    private func productionForRowAtIndexPath(indexPath: NSIndexPath) -> Production {
        return productions[productionIndexAtIndexPath(indexPath)]
    }

    private func setupZeroStateView() {
        zeroStateViewController = UIStoryboard("Provider").instantiateViewControllerWithIdentifier("ZeroStateViewController") as! ZeroStateViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshNavigationItem()
        setupPullToRefresh()

        setupZeroStateView()

        NSNotificationCenter.defaultCenter().addObserverForName("SegueToBarcodeScannerStoryboard") { sender in
            if self.navigationController?.viewControllers.last?.isKindOfClass(BarcodeScannerViewController) == false {
                let barcodeScannerViewController = UIStoryboard("CastingDirector").instantiateViewControllerWithIdentifier("BarcodeScannerViewController")
                self.navigationController!.pushViewController(barcodeScannerViewController, animated: true)
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShootingDaysViewControllerSegue" {
            (segue.destinationViewController as! CastingProductionViewController).production = selectedProduction
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        selectedProduction = nil

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
        productions = [Production]()
        page = 1
        lastProductionIndex = -1
        refresh()
    }

    func refresh() {
        if page == 1 {
            refreshControl.beginRefreshing()
        }

        let params = [
            "page": page,
            "rpp": rpp,
            "status": "scheduled,in_progress,completed,canceled",
        ]

        ApiService.sharedService().fetchProductions(params as! [String : AnyObject],
            onSuccess: { statusCode, mappingResult in
                let fetchedProductions = mappingResult.array() as! [Production]
                self.productions += fetchedProductions

                self.tableView.reloadData()
                self.tableView.layoutIfNeeded()
                self.refreshControl.endRefreshing()
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }

    func refreshNavigationItem() {
        navigationItem.title = "PRODUCTIONS"
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItems = []

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
        if productionIndex == productions.count - 1 && productionIndex > lastProductionIndex {
            page++
            lastProductionIndex = productionIndex
            refresh()
        }
    }

    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        selectedProduction = productionForRowAtIndexPath(indexPath)
        return indexPath
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isColumnedLayout {
            let productionIndex = productionIndexAtIndexPath(NSIndexPath(forRow: 1, inSection: section))
            if productionIndex > productions.count - 1 {
                return 1
            }
            return 2
        }
        return numberOfItemsPerSection
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("productionTableViewCellReuseIdentifier") as! ProductionTableViewCell
        cell.production = productionForRowAtIndexPath(indexPath)
        return cell
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return numberOfSections
    }
    
    func navigationControllerForViewController(viewController: UIViewController) -> UINavigationController! {
        return navigationController
    }
}
