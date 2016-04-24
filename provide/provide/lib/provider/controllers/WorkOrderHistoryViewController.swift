//
//  WorkOrderHistoryViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/6/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol WorkOrderHistoryViewControllerDelegate {
    func navigationControllerForViewController(viewController: UIViewController) -> UINavigationController!
}

class WorkOrderHistoryViewController: ViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    private var page = 1
    private let rpp = 10
    private var lastWorkOrderIndex = -1

    @IBOutlet private weak var collectionView: UICollectionView!

    private var refreshControl: UIRefreshControl!

    private var workOrders = [WorkOrder]() {
        didSet {
            collectionView?.reloadData()
        }
    }

    private weak var selectedWorkOrder: WorkOrder!

    private var zeroStateViewController: ZeroStateViewController!

    private var isColumnedLayout: Bool {
        return view.frame.width > 414.0
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

    private func workOrderIndexAtIndexPath(indexPath: NSIndexPath) -> Int {
        if isColumnedLayout {
            var i = indexPath.section * 2
            i += indexPath.row
            return i
        }
        return indexPath.section
    }

    private func workOrderForRowAtIndexPath(indexPath: NSIndexPath) -> WorkOrder {
        return workOrders[workOrderIndexAtIndexPath(indexPath)]
    }

    private func setupZeroStateView() {
        zeroStateViewController = UIStoryboard("ZeroState").instantiateInitialViewController() as! ZeroStateViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "HISTORY"

        setupPullToRefresh()

        setupZeroStateView()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        selectedWorkOrder = nil

        collectionView.frame = view.bounds
    }

    private func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(WorkOrderHistoryViewController.reset), forControlEvents: .ValueChanged)

        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true

        refresh()
    }

    func reset() {
        workOrders = [WorkOrder]()
        page = 1
        lastWorkOrderIndex = -1
        refresh()
    }

    func refresh() {
        if page == 1 {
            refreshControl.beginRefreshing()
        }

        let params: [String : AnyObject] = [
            "page": page,
            "rpp": rpp,
            "status": "awaiting_schedule,scheduled,delayed,en_route,in_progress,rejected,pending_approval,paused,completed",
            "sort_priority_and_due_at_desc": "true",
            "include_products": "false",
            "include_work_order_providers": "false",
            "include_checkin_coordinates": "true",
        ]

        ApiService.sharedService().fetchWorkOrders(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedWorkOrders = mappingResult.array() as! [WorkOrder]
                self.workOrders += fetchedWorkOrders

                self.collectionView.reloadData()
                self.collectionView.layoutIfNeeded()
                self.refreshControl.endRefreshing()
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "WorkOrderDetailsViewControllerSegue" {
            (segue.destinationViewController as! WorkOrderDetailsViewController).workOrder = selectedWorkOrder
        }
    }

    // MARK: UICollectionViewDelegate

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10.0, 5.0, 0.0, 5.0)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let inset = UIEdgeInsetsMake(10.0, 5.0, 10.0, 5.0)
        let insetWidthOffset = inset.left + inset.right
        _ = inset.top + inset.bottom
        return CGSizeMake(collectionView.frame.width - insetWidthOffset, 175.0)
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let workOrderIndex = workOrderIndexAtIndexPath(indexPath)
        if workOrderIndex == workOrders.count - 1 && workOrderIndex > lastWorkOrderIndex {
            page += 1
            lastWorkOrderIndex = workOrderIndex
            refresh()
        }
    }

    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        selectedWorkOrder = workOrderForRowAtIndexPath(indexPath)

        return true
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
    }

    // MARK: UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isColumnedLayout {
            let workOrderIndex = workOrderIndexAtIndexPath(NSIndexPath(forRow: 1, inSection: section))
            if workOrderIndex > workOrders.count - 1 {
                return 1
            }
            return 2
        }
        return numberOfItemsPerSection
    }

    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("workOrderHistoryCollectionViewCellReuseIdentifier", forIndexPath: indexPath) as! WorkOrderHistoryCollectionViewCell
        cell.workOrder = workOrderForRowAtIndexPath(indexPath)
        return cell
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return numberOfSections
    }

    //    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
    //    optional func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView

    func navigationControllerForViewController(viewController: UIViewController) -> UINavigationController! {
        return navigationController
    }

    deinit {
        collectionView?.delegate = nil
    }
}
