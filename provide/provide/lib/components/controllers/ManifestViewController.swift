//
//  ManifestViewController.swift
//  provide
//
//  Created by Kyle Thomas on 6/19/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol ManifestViewControllerDelegate {
    optional func targetViewForViewController(viewController: UIViewController) -> UIView
    optional func navigationControllerForViewController(viewController: UIViewController) -> UINavigationController!
    optional func navigationControllerNavigationItemForViewController(viewController: UIViewController) -> UINavigationItem!
    optional func navigationControllerBackItemTitleForManifestViewController(viewController: UIViewController) -> String!
    optional func jobForManifestViewController(viewController: UIViewController) -> Job!
    optional func routeForViewController(viewController: UIViewController) -> Route!
    optional func workOrderForManifestViewController(viewController: UIViewController) -> WorkOrder!
    optional func segmentsForManifestViewController(viewController: UIViewController) -> [String]!
    optional func segmentForManifestViewController(viewController: UIViewController, forSegmentIndex segmentIndex: Int) -> String
    optional func itemsForManifestViewController(viewController: UIViewController, forSegmentIndex segmentIndex: Int) -> [Product]!
    optional func manifestViewController(viewController: UIViewController, tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell!
    optional func manifestViewController(viewController: UIViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    optional func queryParamsForManifestViewController(viewController: UIViewController) -> [String : AnyObject]!
}

class ManifestViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

    enum Segment {
        case Delivered, OnTruck, Rejected

        static let allValues = [Delivered, OnTruck, Rejected]
    }

    var delegate: ManifestViewControllerDelegate! {
        didSet {
            if let _ = delegate {
                reload()
            }
        }
    }

    var expenseCaptureViewControllerDelegate: ExpenseCaptureViewControllerDelegate! {
        didSet {
            if let _ = expenseCaptureViewControllerDelegate {
                reload()
            }
        }
    }

    var products: [Product]! {
        didSet {
            if let _ = products {
                reloadTableView()
            }
        }
    }

    var selectedSegmentIndex: Int {
        if let toolbarSegmentedControl = toolbarSegmentedControl {
            return toolbarSegmentedControl.selectedSegmentIndex
        }
        return -1
    }

    private var toolbarSegmentedControl: UISegmentedControl!

    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            if let _ = tableView {
                if products != nil || delegate != nil {
                    reloadTableView()
                }
            }
        }
    }
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    private var lastSelectedIndex = -1

    private var page = 1
    private let rpp = 10
    private var lastProductIndex = -1

    private var refreshControl: UIRefreshControl!

    private var inFlightRequestOperation: RKObjectRequestOperation!

    private var items: [Product] {
        if let items = delegate?.itemsForManifestViewController?(self, forSegmentIndex: toolbarSegmentedControl.selectedSegmentIndex) {
            return items
        } else if let products = products {
            return products
        }

        var items = [Product]()
        if let route = route {
            switch Segment.allValues[toolbarSegmentedControl.selectedSegmentIndex] {
            case .Delivered:
                items = route.itemsDelivered
            case .OnTruck:
                items = route.itemsLoaded
            case .Rejected:
                items = route.itemsRejected
            }
        } else if let workOrder = workOrder {
            switch Segment.allValues[toolbarSegmentedControl.selectedSegmentIndex] {
            case .Delivered:
                items = workOrder.itemsDelivered
            case .OnTruck:
                items = workOrder.itemsOnTruck
            case .Rejected:
                items = workOrder.itemsRejected
            }
        }
        return items
    }

    private var navigationItemPrompt: String! {
        var prompt: String! = nil //"No Active Route"
        if let route = route {
            if let name = route.name {
                prompt = "Manifest for \(name)"
            } else {
                prompt = "Manifest for (unnamed route)"
            }
        } else if let _ = workOrder {
            prompt = nil
        } else if let _ = job {
            prompt = nil
        }
        return prompt
    }

    private var route: Route! {
        return delegate?.routeForViewController?(self)
    }

    private var workOrder: WorkOrder! {
        return delegate?.workOrderForManifestViewController?(self)
    }

    private var job: Job! {
        return delegate?.jobForManifestViewController?(self)
    }

    private var segment: Segment!

    private var targetView: UIView! {
        return delegate?.targetViewForViewController?(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initToolbarSegmentedControl()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        reload()
    }

    private func setupPullToRefresh() {
        activityIndicatorView?.stopAnimating()

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "reset", forControlEvents: .ValueChanged)

        tableView.addSubview(refreshControl)
        tableView.alwaysBounceVertical = true
    }

    func reset() {
        if refreshControl == nil {
            setupPullToRefresh()
        }

        products = [Product]()
        page = 1
        lastProductIndex = -1
        refresh()
    }

    func refresh() {
        if page == 1 {
            refreshControl?.beginRefreshing()
        }

        if var params = delegate?.queryParamsForManifestViewController?(self) {
            params["page"] = page
            params["rpp"] = rpp

            if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
                params["company_id"] = defaultCompanyId
            }

            if let inFlightRequestOperation = inFlightRequestOperation {
                inFlightRequestOperation.cancel()
            }

            inFlightRequestOperation = ApiService.sharedService().fetchProducts(params,
                onSuccess: { statusCode, mappingResult in
                    self.inFlightRequestOperation = nil
                    let fetchedProducts = mappingResult.array() as! [Product]
                    if self.page == 1 {
                        self.products = [Product]()
                    }
                    for product in fetchedProducts {
                        self.products.append(product)
                    }

                    self.reloadTableView()
                },
                onError: { error, statusCode, responseString in
                    self.inFlightRequestOperation = nil
                }
            )
        }
    }

    func reload() {
        initToolbarSegmentedControl()

        if let navigationItem = delegate?.navigationControllerNavigationItemForViewController?(self) {
            self.navigationItem.leftBarButtonItems = navigationItem.leftBarButtonItems
            self.navigationItem.rightBarButtonItems = navigationItem.rightBarButtonItems
            self.navigationItem.title = navigationItem.title
            self.navigationItem.titleView = navigationItem.titleView
            self.navigationItem.prompt = navigationItem.prompt
        } else {
            navigationItem.titleView = toolbarSegmentedControl
            navigationItem.prompt = navigationItemPrompt
        }

        reloadTableView()
    }

    func segmentChanged(sender: UISegmentedControl) {
        if delegate == nil {
            segment = Segment.allValues[sender.selectedSegmentIndex]
        }

        if lastSelectedIndex != sender.selectedSegmentIndex {
            reloadTableView()
        }

        lastSelectedIndex = sender.selectedSegmentIndex
    }

    func showActivityIndicator() {
        dispatch_after_delay(0.0) {
            self.tableView.alpha = 0.0
            self.activityIndicatorView.startAnimating()
        }
    }

    func hideActivityIndicator() {
        dispatch_after_delay(0.0) {
            self.activityIndicatorView.stopAnimating()
            self.tableView.alpha = 1.0
        }
    }

    func reloadTableView() {
        if let tableView = tableView {
            tableView.reloadData()
            refreshControl?.endRefreshing()
            hideActivityIndicator()
        }
    }

    private func initToolbarSegmentedControl() {
        if let toolbarSegmentedControl = toolbarSegmentedControl {
            toolbarSegmentedControl.removeAllSegments()
            
            var segments = [String]()
            if let segmentsForManifestViewController = delegate?.segmentsForManifestViewController?(self) {
                segments = segmentsForManifestViewController
            } else {
                segments = ["DELIVERED", "ON TRUCK", "REJECTED"]
            }

            for segment in segments {
                toolbarSegmentedControl.insertSegmentWithTitle(segment, atIndex: segments.indexOf(segment)!, animated: false)
            }
        } else {
            if let segments = delegate?.segmentsForManifestViewController?(self) {
                toolbarSegmentedControl = UISegmentedControl(items: segments)
            } else {
                toolbarSegmentedControl = UISegmentedControl(items: ["DELIVERED", "ON TRUCK", "REJECTED"])
            }
        }

        toolbarSegmentedControl.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        toolbarSegmentedControl.selectedSegmentIndex = 0
        toolbarSegmentedControl.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        toolbarSegmentedControl.addTarget(self, action: "segmentChanged:", forControlEvents: .ValueChanged)

        lastSelectedIndex = toolbarSegmentedControl.selectedSegmentIndex
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = delegate?.manifestViewController?(self, tableView: tableView, cellForRowAtIndexPath: indexPath) {
            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier("manifestTableViewCell") as! ManifestItemTableViewCell
        cell.product = items[indexPath.row]
        return cell
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75.0
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.manifestViewController?(self, tableView: tableView, didSelectRowAtIndexPath: indexPath)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
