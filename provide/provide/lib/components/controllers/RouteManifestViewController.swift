//
//  RouteViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import AVFoundation

@objc
protocol RouteManifestViewControllerDelegate {

    optional func targetViewForViewController(viewController: ViewController!) -> UIView!
    optional func navigationControllerForViewController(viewController: ViewController!) -> UINavigationController!
    optional func navigationControllerNavigationItemForViewController(viewController: ViewController!) -> UINavigationItem!
    optional func routeForViewController(viewController: ViewController!) -> Route!
    optional func routeUpdated(route: Route!, byViewController viewController: ViewController!)

}

class RouteManifestViewController: ViewController, UITableViewDelegate, UITableViewDataSource, BarcodeScannerViewControllerDelegate {

    enum Segment {
        case OnTruck, Required

        static let allValues = [OnTruck, Required]
    }

    var delegate: RouteManifestViewControllerDelegate!

    private var barcodeScannerViewController: BarcodeScannerViewController!

    private var processingCode: Bool = false {
        didSet {
            if processingCode == false {
                dismissBarcodeScannerViewController()
            }
        }
    }

    private var toolbarSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var tableView: UITableView!

    private var items: [Product]! {
        get {
            var items = [Product]()
            switch Segment.allValues[toolbarSegmentedControl.selectedSegmentIndex] {
            case .OnTruck:
                if let itemsLoaded = route.itemsLoaded {
                    for product in itemsLoaded {
                        items.append(product as! Product)
                    }
                }
            case .Required:
                items = route.itemsNotLoaded
            default:
                return nil
            }
            return items
        }
    }

    private var route: Route! {
        get {
            return delegate?.routeForViewController?(self)
        }
    }

    private var segment: Segment!

    private var completeItem: UIBarButtonItem! {
        var completeItem = UIBarButtonItem(title: "Complete", style: .Plain, target: self, action: "complete")
        completeItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return completeItem
    }

    private var scanItem: UIBarButtonItem! {
        var scanItem = UIBarButtonItem(title: "+ SCAN", style: .Plain, target: self, action: "scan")
        scanItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return scanItem
    }

    private var startItem: UIBarButtonItem! {
        var startItem = UIBarButtonItem(title: "START", style: .Plain, target: self, action: "start")
        startItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return startItem
    }

    private var targetView: UIView! {
        get {
            return delegate?.targetViewForViewController?(self)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initToolbarSegmentedControl()

        refreshNavigationItem()

        barcodeScannerViewController = UIStoryboard(name: "BarcodeScanner", bundle: nil).instantiateInitialViewController() as! BarcodeScannerViewController
        barcodeScannerViewController.delegate = self
    }

    func segmentChanged() {
        segment = Segment.allValues[toolbarSegmentedControl.selectedSegmentIndex]

        dispatch_after_delay(0.0) {
            self.tableView.reloadData()
        }
    }

    private func initToolbarSegmentedControl() {
        toolbarSegmentedControl = UISegmentedControl(items: ["ON TRUCK", "REQUIRED"])
        toolbarSegmentedControl.tintColor = UIColor.whiteColor()
        toolbarSegmentedControl.selectedSegmentIndex = 0
        toolbarSegmentedControl.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        toolbarSegmentedControl.addTarget(self, action: "segmentChanged", forControlEvents: .ValueChanged)
    }

    private func dismissBarcodeScannerViewController() {
        self.refreshNavigationItem()

        self.dismissViewController(animated: true, completion: { () -> Void in
            self.tableView.reloadData()
        })
    }

    func refreshNavigationItem() {
        navigationItem.titleView = toolbarSegmentedControl
        navigationItem.prompt = "\(route.itemsToLoadCountRemaining) item(s) missing from manifest"

        if route.status == "in_progress" {
            navigationItem.leftBarButtonItems = [completeItem]
        } else if route.itemsToLoadCountRemaining == 0 {
            navigationItem.leftBarButtonItems = [startItem]
        } else {
            navigationItem.leftBarButtonItems = [scanItem]
        }
    }

    func clearNavigationItem() {
        navigationItem.hidesBackButton = true
        navigationItem.prompt = "\(route.itemsToLoadCountRemaining) item(s) missing from manifest"
        navigationItem.leftBarButtonItems = []
        navigationItem.rightBarButtonItems = []
    }

    func render() {
        if let navigationController = delegate?.navigationControllerForViewController?(self) {
            navigationController.pushViewController(self, animated: false)
        }
    }

    func scan() {
        clearNavigationItem()

        if isSimulator() == true { // HACK!!!
            simulateScanningAllItems()
        } else {
            presentViewController(barcodeScannerViewController, animated: true)
        }
    }

    private func simulateScanningAllItems() { // HACK!!! only for being able to fly thru demos on the simulator
        var gtins = [String]()
        for item in route.itemsOrdered {
            gtins.append(item.gtin)
        }

        ApiService.sharedService().updateRouteWithId(route.id.stringValue, params: ["gtins_loaded": gtins], onSuccess: { statusCode, responseString in
            var itemsLoaded = NSMutableArray()
            for product in self.route.itemsOrdered {
                itemsLoaded.addObject(product)
            }
            self.route.itemsLoaded = itemsLoaded as [AnyObject]
            self.refreshNavigationItem()
            self.tableView.reloadData()
        }, onError: { error, statusCode, responseString in

        })
    }

    func start() {
        clearNavigationItem()
        route.start({ statusCode, responseString in
            if let navigationController = self.delegate?.navigationControllerForViewController?(self) {
                self.delegate?.routeUpdated?(self.route, byViewController: self)
            }
        }, onError: { error, statusCode, responseString in

        })
    }

    func complete() {
        clearNavigationItem()
        route.complete({ statusCode, responseString in
            if let navigationController = self.delegate?.navigationControllerForViewController?(self) {
                self.delegate?.routeUpdated?(self.route, byViewController: self)
            }
        }, onError: { error, statusCode, responseString in
                
        })
    }

    // MARK: BarcodeScannerViewControllerDelegate

    func barcodeScannerViewController(barcodeScannerViewController: BarcodeScannerViewController!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if self.processingCode == false {
            for object in metadataObjects {
                if let machineReadableCodeObject = object as? AVMetadataMachineReadableCodeObject {
                    self.processCode(machineReadableCodeObject)
                }
            }
        }
    }

    private func processCode(metadataObject: AVMetadataMachineReadableCodeObject!) {
        if let code = metadataObject {
            if code.type == "org.gs1.EAN-13" {
                let value = code.stringValue

                if self.route.isGtinRequired(value) {
                    self.processingCode = true

                    self.route.loadManifestItemByGtin(value, onSuccess: { statusCode, responseString in
                        self.processingCode = false
                    }, onError: { error, statusCode, responseString in
                        self.processingCode = false
                    })
                }
            }
        }
    }

    func barcodeScannerViewControllerShouldBeDismissed(viewController: BarcodeScannerViewController!) {
        dismissBarcodeScannerViewController()
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("routeManifestTableViewCell") as! RouteManifestItemTableViewCell
        cell.product = items[indexPath.row]
        return cell
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75.0
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("selected loaded manifest item: \(items[indexPath.row])")
    }

}
