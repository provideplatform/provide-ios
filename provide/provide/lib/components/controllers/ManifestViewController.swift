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

    optional func targetViewForViewController(viewController: ViewController!) -> UIView!
    optional func navigationControllerForViewController(viewController: ViewController!) -> UINavigationController!
    optional func navigationControllerNavigationItemForViewController(viewController: ViewController!) -> UINavigationItem!
    optional func routeForViewController(viewController: ViewController!) -> Route!
}

class ManifestViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

    enum Segment {
        case Delivered, OnTruck, Rejected

        static let allValues = [Delivered, OnTruck, Rejected]
    }

    var delegate: ManifestViewControllerDelegate!

    private var toolbarSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var tableView: UITableView!

    private var items: [Product]! {
        var items = [Product]()
        if let route = route {
            switch Segment.allValues[toolbarSegmentedControl.selectedSegmentIndex] {
            case .Delivered:
                for product in route.itemsDelivered {
                    items.append(product as Product)
                }
            case .OnTruck:
                if let itemsLoaded = route.itemsLoaded {
                    for product in itemsLoaded {
                        items.append(product as! Product)
                    }
                }
            case .Rejected:
                items = route.itemsNotLoaded
            default:
                return nil
            }
        }
        return items
    }

    private var route: Route! {
        return delegate?.routeForViewController?(self)
    }

    private var segment: Segment!

    private var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .Plain, target: self, action: "dismiss")
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return dismissItem
    }

    private var targetView: UIView! {
        return delegate?.targetViewForViewController?(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initToolbarSegmentedControl()

        refreshNavigationItem()
    }

    func segmentChanged() {
        segment = Segment.allValues[toolbarSegmentedControl.selectedSegmentIndex]

        dispatch_after_delay(0.0) {
            self.tableView.reloadData()
        }
    }

    private func initToolbarSegmentedControl() {
        toolbarSegmentedControl = UISegmentedControl(items: ["DELIVERED", "ON TRUCK", "REJECTED"])
        toolbarSegmentedControl.tintColor = UIColor.whiteColor()
        toolbarSegmentedControl.selectedSegmentIndex = 0
        toolbarSegmentedControl.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        toolbarSegmentedControl.addTarget(self, action: "segmentChanged", forControlEvents: .ValueChanged)
    }

    func refreshNavigationItem() {
        navigationItem.titleView = toolbarSegmentedControl
        navigationItem.prompt = "Manifest for \(route?.name)"

        navigationItem.leftBarButtonItems = [dismissItem]

        if let navigationController = delegate?.navigationControllerForViewController?(self) {
            navigationController.setNavigationBarHidden(false, animated: true)
        }
    }

    func clearNavigationItem() {
        navigationItem.hidesBackButton = true
        navigationItem.prompt = "Manifest for \(route?.name)"
        navigationItem.leftBarButtonItems = []
        navigationItem.rightBarButtonItems = []
    }

    func dismiss() {
        clearNavigationItem()

        if let navigationController = delegate?.navigationControllerForViewController?(self) {
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
