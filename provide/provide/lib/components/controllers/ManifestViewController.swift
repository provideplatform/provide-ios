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
}

class ManifestViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

    enum Segment {
        case Delivered, OnTruck, Rejected

        static let allValues = [Delivered, OnTruck, Rejected]
    }

    var delegate: ManifestViewControllerDelegate!

    private var toolbarSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var tableView: UITableView!

    private var items: [Product] {
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

    private var dismissItem: UIBarButtonItem! {
        var title = "DISMISS"
        if let backItemTitle = delegate?.navigationControllerBackItemTitleForManifestViewController?(self) {
            title = backItemTitle
        }

        let dismissItem = UIBarButtonItem(title: title, style: .Plain, target: self, action: "dismiss:")
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return dismissItem
    }

    private var targetView: UIView! {
        return delegate?.targetViewForViewController?(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initToolbarSegmentedControl()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        refreshNavigationItem()
    }

    func segmentChanged(sender: UISegmentedControl) {
        segment = Segment.allValues[sender.selectedSegmentIndex]

        dispatch_after_delay(0.0) {
            self.tableView.reloadData()
        }
    }

    private func initToolbarSegmentedControl() {
        toolbarSegmentedControl = UISegmentedControl(items: ["DELIVERED", "ON TRUCK", "REJECTED"])
        toolbarSegmentedControl.tintColor = UIColor.whiteColor()
        toolbarSegmentedControl.selectedSegmentIndex = 0
        toolbarSegmentedControl.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        toolbarSegmentedControl.addTarget(self, action: "segmentChanged:", forControlEvents: .ValueChanged)
    }

    func refreshNavigationItem() {
        navigationItem.titleView = toolbarSegmentedControl
        navigationItem.prompt = navigationItemPrompt

        navigationItem.leftBarButtonItem = UIBarButtonItem.plainBarButtonItem(title: "DISMISS", target: self, action: "dismiss:")

        if let navigationController = navigationController {
            navigationController.setNavigationBarHidden(false, animated: true)
        }
    }

    func clearNavigationItem() {
        navigationItem.hidesBackButton = true
        navigationItem.prompt = navigationItemPrompt
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

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("routeManifestTableViewCell") as! RouteManifestItemTableViewCell
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
