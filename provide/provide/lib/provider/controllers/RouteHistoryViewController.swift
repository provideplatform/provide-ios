//
//  RouteHistoryViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/26/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class RouteHistoryViewController: ViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    private var page = 1
    private let rpp = 10
    private var lastRouteIndex = -1

    @IBOutlet private weak var collectionView: UICollectionView!

    private var refreshControl: UIRefreshControl!

    private var routes = [Route]() {
        didSet {
            collectionView?.reloadData()
        }
    }

    private weak var selectedRoute: Route!

    private var zeroStateViewController: ZeroStateViewController!

    private var isColumnedLayout: Bool {
        return view.frame.width > 414.0
    }

    private var numberOfSections: Int {
        if isColumnedLayout {
            return Int(ceil(Double(routes.count) / Double(numberOfItemsPerSection)))
        }
        return routes.count
    }

    private var numberOfItemsPerSection: Int {
        if isColumnedLayout {
            return 2
        }
        return 1
    }

    private func routeIndexAtIndexPath(indexPath: NSIndexPath) -> Int {
        if isColumnedLayout {
            var i = indexPath.section * 2
            i += indexPath.row
            return i
        }
        return indexPath.section
    }

    private func routeForRowAtIndexPath(indexPath: NSIndexPath) -> Route {
        return routes[routeIndexAtIndexPath(indexPath)]
    }

    private func setupZeroStateView() {
        zeroStateViewController = UIStoryboard("Provider").instantiateViewControllerWithIdentifier("ZeroStateViewController") as! ZeroStateViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "ROUTE HISTORY"

        setupPullToRefresh()
        
        setupZeroStateView()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        selectedRoute = nil

        collectionView.frame = view.bounds
    }

    private func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "reset", forControlEvents: .ValueChanged)

        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true

        refresh()
    }

    func reset() {
        routes = [Route]()
        page = 1
        lastRouteIndex = -1
        refresh()
    }

    func refresh() {
        if page == 1 {
            refreshControl.beginRefreshing()
        }

        let params = [
            "page": page,
            "rpp": rpp,
            "status": "scheduled,loading,in_progress,unloading,pending_completion,completed,abandoned,canceled",
            "sort_started_at_desc": "true",
            "include_products": "true",
            "include_dispatcher_origin_assignment": "true",
            "include_provider_origin_assignment": "true",
            "include_work_orders": "true",
            "include_checkin_coordinates": "true",
            "douglas_peucker_tolerance": "1"
        ]

        ApiService.sharedService().fetchRoutes(params as! [String : AnyObject],
            onSuccess: { statusCode, mappingResult in
                let fetchedRoutes = mappingResult.array() as! [Route]
                self.routes += fetchedRoutes

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
        if segue.identifier == "RouteViewControllerSegue" {
            (segue.destinationViewController as! RouteViewController).route = selectedRoute
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
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
        let routeIndex = routeIndexAtIndexPath(indexPath)
        if routeIndex == routes.count - 1 && routeIndex > lastRouteIndex {
            page++
            lastRouteIndex = routeIndex
            refresh()
        }
    }

    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        selectedRoute = routeForRowAtIndexPath(indexPath)

        return true
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
    }

    // MARK: UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isColumnedLayout {
            let routeIndex = routeIndexAtIndexPath(NSIndexPath(forRow: 1, inSection: section))
            if routeIndex > routes.count - 1 {
                return 1
            }
            return 2
        }
        return numberOfItemsPerSection
    }

    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("routeHistoryCollectionViewCellReuseIdentifier", forIndexPath: indexPath) as! RouteHistoryCollectionViewCell
        cell.route = routeForRowAtIndexPath(indexPath)
        return cell
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return numberOfSections
    }

    deinit {
        collectionView.delegate = nil
    }

//    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
//    optional func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView
}
