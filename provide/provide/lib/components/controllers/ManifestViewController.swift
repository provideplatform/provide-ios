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
    optional func routeForViewController(viewController: UIViewController) -> Route!
    optional func workOrderForManifestViewController(viewController: UIViewController) -> WorkOrder!
    optional func segmentsForManifestViewController(viewController: UIViewController) -> [String]!
    optional func segmentForManifestViewController(viewController: UIViewController, forSegmentIndex segmentIndex: Int) -> String
    optional func itemsForManifestViewController(viewController: UIViewController, forSegmentIndex segmentIndex: Int) -> [Product]!
}

class ManifestViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

    enum Segment {
        case Delivered, OnTruck, Rejected

        static let allValues = [Delivered, OnTruck, Rejected]
    }

    var delegate: ManifestViewControllerDelegate!

    private var toolbarSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    private var lastSelectedIndex = -1

    private var items: [Product] {
        if let items = delegate?.itemsForManifestViewController?(self, forSegmentIndex: toolbarSegmentedControl.selectedSegmentIndex) {
            return items
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

    override var navigationController: UINavigationController! {
        if let navigationController = delegate?.navigationControllerForViewController?(self) {
            return navigationController
        } else {
            return super.navigationController
        }
    }

    private var navigationItemPrompt: String! {
        var prompt: String! = "No Active Route"
        if let route = route {
            if let name = route.name {
                prompt = "Manifest for \(name)"
            } else {
                prompt = "Manifest for (unnamed route)"
            }
        } else if let _ = workOrder {
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

        navigationItem.titleView = toolbarSegmentedControl
        navigationItem.prompt = navigationItemPrompt

        tableView.reloadData()
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
        tableView.reloadData()
        hideActivityIndicator()
    }

    private func initToolbarSegmentedControl() {
        if let segments = delegate?.segmentsForManifestViewController?(self) {
            toolbarSegmentedControl = UISegmentedControl(items: segments)
        } else {
            toolbarSegmentedControl = UISegmentedControl(items: ["DELIVERED", "ON TRUCK", "REJECTED"])
        }

        toolbarSegmentedControl.tintColor = UIColor.whiteColor()
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
        let cell = tableView.dequeueReusableCellWithIdentifier("manifestTableViewCell") as! RouteManifestItemTableViewCell
        cell.product = items[indexPath.row]
        return cell
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75.0
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        log("selected loaded manifest item: \(items[indexPath.row])")
    }

}
