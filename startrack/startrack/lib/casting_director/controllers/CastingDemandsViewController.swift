//
//  CastingDemandsViewController.swift
//  startrack
//
//  Created by Kyle Thomas on 9/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol CastingDemandsViewControllerDelegate {
    func queryParamsForCastingDemandsViewController(viewController: CastingDemandsViewController) -> [String: AnyObject]
}

class CastingDemandsViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

    private var page = 1
    private let rpp = 10
    private var lastCastingDemandIndex = -1

    var delegate: CastingDemandsViewControllerDelegate!

    @IBOutlet private weak var tableView: UITableView!

    private var refreshControl: UIRefreshControl!

    private var castingDemands = [CastingDemand]() {
        didSet {
            tableView?.reloadData()
        }
    }

    private weak var selectedCastingDemand: CastingDemand!

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
            return Int(ceil(Double(castingDemands.count) / Double(numberOfItemsPerSection)))
        }
        return castingDemands.count
    }

    private var numberOfItemsPerSection: Int {
        if isColumnedLayout {
            return 2
        }
        return 1
    }

    private func castingDemandIndexAtIndexPath(indexPath: NSIndexPath) -> Int {
        if isColumnedLayout {
            var i = indexPath.section * 2
            i += indexPath.row
            return i
        }
        return indexPath.section
    }

    private func castingDemandForRowAtIndexPath(indexPath: NSIndexPath) -> CastingDemand {
        return castingDemands[castingDemandIndexAtIndexPath(indexPath)]
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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "CastingDemandViewControllerSegue" {
            (segue.destinationViewController as! CastingDemandViewController).castingDemand = selectedCastingDemand
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        selectedCastingDemand = nil

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
        castingDemands = [CastingDemand]()
        page = 1
        lastCastingDemandIndex = -1
        refresh()
    }

    func refresh() {
        if page == 1 {
            refreshControl.beginRefreshing()
        }

        var params = [String : AnyObject]()
        if let delegate = delegate {
            params = delegate.queryParamsForCastingDemandsViewController(self)
        }

        params.updateValue(page, forKey: "page")
        params.updateValue(rpp, forKey: "rpp")

        ApiService.sharedService().fetchCastingDemands(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedCastingDemands = mappingResult.array() as! [CastingDemand]
                self.castingDemands += fetchedCastingDemands

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
        navigationItem.title = "ROLE DEMANDS"
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

    func castingDemandAtIndexPath(indexPath: NSIndexPath) -> CastingDemand! {
        return castingDemands[indexPath.row]
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let castingDemandIndex = indexPath.row
        if castingDemandIndex == castingDemands.count - 1 && castingDemandIndex > lastCastingDemandIndex {
            page++
            lastCastingDemandIndex = castingDemandIndex
            refresh()
        }
    }

    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        selectedCastingDemand = castingDemandForRowAtIndexPath(indexPath)
        return indexPath
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if isColumnedLayout {
//            let castingDemandIndex = castingDemandAtIndexPath(NSIndexPath(forRow: 1, inSection: section))
//            if castingDemandIndex > castingDemands.count - 1 {
//                return 1
//            }
//            return 2
//        }
        return numberOfItemsPerSection
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("castingDemandTableViewCellReuseIdentifier") as! CastingDemandTableViewCell
        cell.castingDemand = castingDemandForRowAtIndexPath(indexPath)
        return cell
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return numberOfSections
    }
    
    func navigationControllerForViewController(viewController: UIViewController) -> UINavigationController! {
        return navigationController
    }
}
