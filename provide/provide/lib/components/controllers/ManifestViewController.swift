//
//  ManifestViewController.swift
//  provide
//
//  Created by Kyle Thomas on 6/19/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import RestKit
import KTSwiftExtensions

@objc
protocol ManifestViewControllerDelegate {
    @objc optional func targetViewForViewController(_ viewController: UIViewController) -> UIView
    @objc optional func navigationControllerForViewController(_ viewController: UIViewController) -> UINavigationController!
    @objc optional func navigationControllerNavigationItemForViewController(_ viewController: UIViewController) -> UINavigationItem!
    @objc optional func navigationControllerBackItemTitleForManifestViewController(_ viewController: UIViewController) -> String!
    @objc optional func jobForManifestViewController(_ viewController: UIViewController) -> Job!
    @objc optional func routeForViewController(_ viewController: UIViewController) -> Route!
    @objc optional func workOrderForManifestViewController(_ viewController: UIViewController) -> WorkOrder!
    @objc optional func segmentsForManifestViewController(_ viewController: UIViewController) -> [String]!
    @objc optional func segmentForManifestViewController(_ viewController: UIViewController, forSegmentIndex segmentIndex: Int) -> String
    @objc optional func itemsForManifestViewController(_ viewController: UIViewController, forSegmentIndex segmentIndex: Int) -> [Product]!
    @objc optional func manifestViewController(_ viewController: UIViewController, tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell!
    @objc optional func manifestViewController(_ viewController: UIViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath)
    @objc optional func queryParamsForManifestViewController(_ viewController: UIViewController) -> [String : AnyObject]!
}

class ManifestViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

    enum Segment {
        case delivered, onTruck, rejected

        static let allValues = [delivered, onTruck, rejected]
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

    fileprivate var toolbarSegmentedControl: UISegmentedControl!

    @IBOutlet fileprivate weak var tableView: UITableView! {
        didSet {
            if let _ = tableView {
                if products != nil || delegate != nil {
                    reloadTableView()
                }
            }
        }
    }
    @IBOutlet fileprivate weak var activityIndicatorView: UIActivityIndicatorView!

    fileprivate var lastSelectedIndex = -1

    fileprivate var page = 1
    fileprivate let rpp = 10
    fileprivate var lastProductIndex = -1

    fileprivate var refreshControl: UIRefreshControl!

    fileprivate var inFlightRequestOperation: RKObjectRequestOperation!

    fileprivate var items: [Product] {
        if let items = delegate?.itemsForManifestViewController?(self, forSegmentIndex: toolbarSegmentedControl.selectedSegmentIndex) {
            return items
        } else if let products = products {
            return products
        }

        var items = [Product]()
        if let route = route {
            switch Segment.allValues[toolbarSegmentedControl.selectedSegmentIndex] {
            case .delivered:
                items = route.itemsDelivered
            case .onTruck:
                items = route.itemsLoaded
            case .rejected:
                items = route.itemsRejected
            }
        } else if let workOrder = workOrder {
            switch Segment.allValues[toolbarSegmentedControl.selectedSegmentIndex] {
            case .delivered:
                items = workOrder.itemsDelivered
            case .onTruck:
                items = workOrder.itemsOnTruck
            case .rejected:
                items = workOrder.itemsRejected
            }
        }
        return items
    }

    fileprivate var navigationItemPrompt: String! {
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

    fileprivate var route: Route! {
        return delegate?.routeForViewController?(self)
    }

    fileprivate var workOrder: WorkOrder! {
        return delegate?.workOrderForManifestViewController?(self)
    }

    fileprivate var job: Job! {
        return delegate?.jobForManifestViewController?(self)
    }

    fileprivate var segment: Segment!

    fileprivate var targetView: UIView! {
        return delegate?.targetViewForViewController?(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initToolbarSegmentedControl()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reload()
    }

    fileprivate func setupPullToRefresh() {
        activityIndicatorView?.stopAnimating()

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ManifestViewController.reset), for: .valueChanged)

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
            params["page"] = page as AnyObject
            params["rpp"] = rpp as AnyObject

            if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
                params["company_id"] = defaultCompanyId as AnyObject
            }

            if let inFlightRequestOperation = inFlightRequestOperation {
                inFlightRequestOperation.cancel()
            }

            inFlightRequestOperation = ApiService.sharedService().fetchProducts(params,
                onSuccess: { statusCode, mappingResult in
                    self.inFlightRequestOperation = nil
                    let fetchedProducts = mappingResult?.array() as! [Product]
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

    func segmentChanged(_ sender: UISegmentedControl) {
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

    fileprivate func initToolbarSegmentedControl() {
        if let toolbarSegmentedControl = toolbarSegmentedControl {
            toolbarSegmentedControl.removeAllSegments()
            
            var segments = [String]()
            if let segmentsForManifestViewController = delegate?.segmentsForManifestViewController?(self) {
                segments = segmentsForManifestViewController
            } else {
                segments = ["DELIVERED", "ON TRUCK", "REJECTED"]
            }

            for segment in segments {
                toolbarSegmentedControl.insertSegment(withTitle: segment, at: segments.index(of: segment)!, animated: false)
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
        toolbarSegmentedControl.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        toolbarSegmentedControl.addTarget(self, action: #selector(ManifestViewController.segmentChanged(_:)), for: .valueChanged)

        lastSelectedIndex = toolbarSegmentedControl.selectedSegmentIndex
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = delegate?.manifestViewController?(self, tableView: tableView, cellForRowAtIndexPath: indexPath) {
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "manifestTableViewCell") as! ManifestItemTableViewCell
        cell.product = items[(indexPath as NSIndexPath).row]
        return cell
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.manifestViewController?(self, tableView: tableView, didSelectRowAtIndexPath: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
