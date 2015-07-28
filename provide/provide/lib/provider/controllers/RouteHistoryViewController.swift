//
//  RouteHistoryViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/26/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol RouteHistoryViewControllerDelegate {
    func navigationControllerForViewController(viewController: ViewController!) -> UINavigationController!
}

class RouteHistoryViewController: ViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    private var page = 1
    private let rpp = 10
    private var lastRouteIndex = -1

    @IBOutlet private weak var collectionView: UICollectionView!

    private var refreshControl: UIRefreshControl!

    private var routes = [Route]() {
        didSet {
            collectionView?.reloadData()
            //collectionView?.layoutIfNeeded()
        }
    }

    private var zeroStateViewController: ZeroStateViewController!

    private var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .Plain, target: self, action: "dismiss")
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return dismissItem
    }

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

        refreshNavigationItem()
        setupPullToRefresh()
        
        setupZeroStateView()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

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

        let params = NSMutableDictionary(dictionary: [
            "page": page,
            "rpp": rpp,
            "status": "scheduled,loading,in_progress,unloading,pending_completion,completed,canceled,abandoned",
            "sort_started_at_desc": "true",
            "include_work_orders": "true"
        ])

        ApiService.sharedService().fetchRoutes(params,
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

    func refreshNavigationItem() {
        navigationItem.title = "HISTORY"
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

    func dismiss() {
        clearNavigationItem()

        if let navigationController = navigationController {
            navigationController.popViewControllerAnimated(true)
        }
    }


    // MARK: UICollectionViewDelegate

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10.0, 5.0, 0.0, 5.0)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var inset = UIEdgeInsetsMake(10.0, 5.0, 10.0, 5.0)
        var insetWidthOffset = inset.left + inset.right
        var insetHeightOffset = inset.top + inset.bottom
        return CGSizeMake(collectionView.frame.width - insetWidthOffset, 175.0)
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        var routeIndex = routeIndexAtIndexPath(indexPath)
        if routeIndex == routes.count - 1 && routeIndex > lastRouteIndex {
            page++
            lastRouteIndex = routeIndex
            refresh()
        }
    }

    // MARK: UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isColumnedLayout {
            var routeIndex = routeIndexAtIndexPath(NSIndexPath(forRow: 1, inSection: section))
            if routeIndex > routes.count - 1 {
                return 1
            }
            return 2
        }
        return numberOfItemsPerSection
    }

    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("routeHistoryCollectionViewCellReuseIdentifier", forIndexPath: indexPath) as! RouteHistoryCollectionViewCell
        cell.route = routeForRowAtIndexPath(indexPath)
        return cell
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return numberOfSections
    }
//
//    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
//    optional func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView
}
