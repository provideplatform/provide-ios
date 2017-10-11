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
        return view.width > 414.0
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

    private func workOrderIndexAtIndexPath(_ indexPath: IndexPath) -> Int {
        if isColumnedLayout {
            var i = indexPath.section * 2
            i += indexPath.row
            return i
        }
        return indexPath.section
    }

    private func workOrderForRowAtIndexPath(_ indexPath: IndexPath) -> WorkOrder {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        selectedWorkOrder = nil

        collectionView.frame = view.bounds
    }

    private func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reset), for: .valueChanged)

        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true

        refresh()
    }

    @objc func reset() {
        workOrders = [WorkOrder]()
        page = 1
        lastWorkOrderIndex = -1
        refresh()
    }

    private func refresh() {
        if page == 1 {
            refreshControl.beginRefreshing()
        }

        let params: [String: Any] = [
            "page": page,
            "rpp": rpp,
            "status": "awaiting_schedule,scheduled,delayed,en_route,in_progress,rejected,pending_approval,paused,completed",
            "sort_priority_and_due_at_asc": "true",
            "include_products": "false",
            "include_work_order_providers": "false",
            "include_checkin_coordinates": "true",
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
        return CGSize(width: collectionView.width - insetWidthOffset, height: 175.0)
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
        let cell = collectionView.dequeue(WorkOrderHistoryCollectionViewCell.self, for: indexPath)
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
