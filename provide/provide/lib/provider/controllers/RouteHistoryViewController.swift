//
//  RouteHistoryViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/26/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class RouteHistoryViewController: ViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    fileprivate var page = 1
    fileprivate let rpp = 10
    fileprivate var lastRouteIndex = -1

    @IBOutlet fileprivate weak var collectionView: UICollectionView!

    fileprivate var refreshControl: UIRefreshControl!

    fileprivate var routes = [Route]() {
        didSet {
            collectionView?.reloadData()
        }
    }

    fileprivate weak var selectedRoute: Route!

    fileprivate var zeroStateViewController: ZeroStateViewController!

    fileprivate var isColumnedLayout: Bool {
        return view.frame.width > 414.0
    }

    fileprivate var numberOfSections: Int {
        if isColumnedLayout {
            return Int(ceil(Double(routes.count) / Double(numberOfItemsPerSection)))
        }
        return routes.count
    }

    fileprivate var numberOfItemsPerSection: Int {
        if isColumnedLayout {
            return 2
        }
        return 1
    }

    fileprivate func routeIndexAtIndexPath(_ indexPath: IndexPath) -> Int {
        if isColumnedLayout {
            var i = (indexPath as NSIndexPath).section * 2
            i += (indexPath as NSIndexPath).row
            return i
        }
        return (indexPath as NSIndexPath).section
    }

    fileprivate func routeForRowAtIndexPath(_ indexPath: IndexPath) -> Route {
        return routes[routeIndexAtIndexPath(indexPath)]
    }

    fileprivate func setupZeroStateView() {
        zeroStateViewController = UIStoryboard("ZeroState").instantiateInitialViewController() as! ZeroStateViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "ROUTE HISTORY"

        setupPullToRefresh()
        
        setupZeroStateView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        selectedRoute = nil

        collectionView.frame = view.bounds
    }

    fileprivate func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(RouteHistoryViewController.reset), for: .valueChanged)

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

        var params: [String : AnyObject] = [
            "page": page as AnyObject,
            "rpp": rpp as AnyObject,
            "status": "scheduled,loading,in_progress,unloading,pending_completion,completed,abandoned,canceled" as AnyObject,
            "sort_started_at_desc": "true" as AnyObject,
            "include_products": "true" as AnyObject,
            "include_dispatcher_origin_assignment": "true" as AnyObject,
            "include_provider_origin_assignment": "true" as AnyObject,
            "include_work_orders": "true" as AnyObject,
            "include_checkin_coordinates": "true" as AnyObject,
            "douglas_peucker_tolerance": "1" as AnyObject
        ]

        if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
            params["company_id"] = defaultCompanyId as AnyObject
        }

        ApiService.sharedService().fetchRoutes(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedRoutes = mappingResult?.array() as! [Route]
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RouteViewControllerSegue" {
            (segue.destination as! RouteViewController).route = selectedRoute
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10.0, 5.0, 0.0, 5.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let inset = UIEdgeInsetsMake(10.0, 5.0, 10.0, 5.0)
        let insetWidthOffset = inset.left + inset.right
        _ = inset.top + inset.bottom
        return CGSize(width: collectionView.frame.width - insetWidthOffset, height: 175.0)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let routeIndex = routeIndexAtIndexPath(indexPath)
        if routeIndex == routes.count - 1 && routeIndex > lastRouteIndex {
            page += 1
            lastRouteIndex = routeIndex
            refresh()
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        selectedRoute = routeForRowAtIndexPath(indexPath)

        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isColumnedLayout {
            let routeIndex = routeIndexAtIndexPath(IndexPath(row: 1, section: section))
            if routeIndex > routes.count - 1 {
                return 1
            }
            return 2
        }
        return numberOfItemsPerSection
    }

    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "routeHistoryCollectionViewCellReuseIdentifier", for: indexPath) as! RouteHistoryCollectionViewCell
        cell.route = routeForRowAtIndexPath(indexPath)
        return cell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return numberOfSections
    }

    deinit {
        collectionView?.delegate = nil
    }

//    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
//    optional func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView
}
