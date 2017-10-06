//
//  WorkOrderHistoryViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/6/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol WorkOrderHistoryViewControllerDelegate: class {
    func navigationControllerForViewController(_ viewController: UIViewController) -> UINavigationController?
}

class WorkOrderHistoryViewController: ViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    fileprivate var page = 1
    fileprivate let rpp = 10
    fileprivate var lastWorkOrderIndex = -1

    @IBOutlet fileprivate weak var collectionView: UICollectionView!

    fileprivate var refreshControl: UIRefreshControl!

    fileprivate var workOrders = [WorkOrder]() {
        didSet {
            collectionView?.reloadData()
        }
    }

    fileprivate weak var selectedWorkOrder: WorkOrder!

    fileprivate var zeroStateViewController: ZeroStateViewController!

    fileprivate var isColumnedLayout: Bool {
        return view.frame.width > 414.0
    }

    fileprivate var numberOfSections: Int {
        if isColumnedLayout {
            return Int(ceil(Double(workOrders.count) / Double(numberOfItemsPerSection)))
        }
        return workOrders.count
    }

    fileprivate var numberOfItemsPerSection: Int {
        if isColumnedLayout {
            return 2
        }
        return 1
    }

    fileprivate func workOrderIndexAtIndexPath(_ indexPath: IndexPath) -> Int {
        if isColumnedLayout {
            var i = indexPath.section * 2
            i += indexPath.row
            return i
        }
        return indexPath.section
    }

    fileprivate func workOrderForRowAtIndexPath(_ indexPath: IndexPath) -> WorkOrder {
        return workOrders[workOrderIndexAtIndexPath(indexPath)]
    }

    fileprivate func setupZeroStateView() {
        zeroStateViewController = UIStoryboard("ZeroState").instantiateInitialViewController() as! ZeroStateViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "HISTORY"

        setupPullToRefresh()

        setupZeroStateView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        selectedWorkOrder = nil

        collectionView.frame = view.bounds
    }

    fileprivate func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reset), for: .valueChanged)

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

        let params: [String: AnyObject] = [
            "page": page as AnyObject,
            "rpp": rpp as AnyObject,
            "status": "awaiting_schedule,scheduled,delayed,en_route,in_progress,rejected,pending_approval,paused,completed" as AnyObject,
            "sort_priority_and_due_at_asc": "true" as AnyObject,
            "include_products": "false" as AnyObject,
            "include_work_order_providers": "false" as AnyObject,
            "include_checkin_coordinates": "true" as AnyObject,
        ]

        ApiService.shared.fetchWorkOrders(params, onSuccess: { statusCode, mappingResult in
            let fetchedWorkOrders = mappingResult?.array() as! [WorkOrder]
            self.workOrders += fetchedWorkOrders

            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
            self.refreshControl.endRefreshing()
        }, onError: { error, statusCode, responseString in
            logError(error)
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "WorkOrderDetailsViewControllerSegue" {
            (segue.destination as! WorkOrderDetailsViewController).workOrder = selectedWorkOrder
        }
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 5.0, bottom: 0.0, right: 5.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let inset = UIEdgeInsets(top: 10.0, left: 5.0, bottom: 10.0, right: 5.0)
        let insetWidthOffset = inset.left + inset.right
        _ = inset.top + inset.bottom
        return CGSize(width: collectionView.frame.width - insetWidthOffset, height: 175.0)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let workOrderIndex = workOrderIndexAtIndexPath(indexPath)
        if workOrderIndex == workOrders.count - 1 && workOrderIndex > lastWorkOrderIndex {
            page += 1
            lastWorkOrderIndex = workOrderIndex
            refresh()
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        selectedWorkOrder = workOrderForRowAtIndexPath(indexPath)

        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isColumnedLayout {
            let workOrderIndex = workOrderIndexAtIndexPath(IndexPath(row: 1, section: section))
            if workOrderIndex > workOrders.count - 1 {
                return 1
            }
            return 2
        }
        return numberOfItemsPerSection
    }

    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "workOrderHistoryCollectionViewCellReuseIdentifier", for: indexPath) as! WorkOrderHistoryCollectionViewCell
        cell.workOrder = workOrderForRowAtIndexPath(indexPath)
        return cell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return numberOfSections
    }

    //    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
    //    optional func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView

    func navigationControllerForViewController(_ viewController: UIViewController) -> UINavigationController? {
        return navigationController
    }

    deinit {
        collectionView?.delegate = nil
    }
}
