//
//  RouteViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import AVFoundation
import KTSwiftExtensions

protocol RouteManifestViewControllerDelegate {
    func targetViewForViewController(viewController: UIViewController) -> UIView
    func navigationControllerForViewController(viewController: UIViewController) -> UINavigationController!
    func navigationControllerNavigationItemForViewController(viewController: UIViewController) -> UINavigationItem!
    func routeForViewController(viewController: UIViewController) -> Route!
    func routeUpdated(route: Route!, byViewController viewController: UIViewController)
}

class RouteManifestViewController: ViewController, UITableViewDelegate, UITableViewDataSource, BarcodeScannerViewControllerDelegate {

    enum Mode {
        case Loading, Unloading

        static let allValues = [Loading, Unloading]
    }

    enum LoadingSegment {
        case OnTruck, Required

        static let allValues = [OnTruck, Required]
    }

    enum UnloadingSegment {
        case OnTruck, Delivered

        static let allValues = [OnTruck, Delivered]
    }

    private let loadingSegmentedControlItems = ["ON TRUCK", "REQUIRED"]
    private let unloadingSegmentedControlItems = ["ON TRUCK", "DELIVERED"]

    var delegate: RouteManifestViewControllerDelegate!

    private var mode: Mode {
        if let route = route {
            if route.status == "unloading" {
                return .Unloading
            }
        }
        return .Loading
    }

    private var barcodeScannerViewController: BarcodeScannerViewController!

    private var acceptingCodes = false

    private var processingCode: Bool = false {
        didSet {
            if !processingCode {
                dismissBarcodeScannerViewController()
            }
        }
    }

    private var toolbarSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var tableView: UITableView!

    private var items: [Product]! {
        var items = [Product]()
        if let route = route {
            switch mode {
            case .Loading:
                switch LoadingSegment.allValues[toolbarSegmentedControl.selectedSegmentIndex] {
                case .OnTruck:
                    for product in route.itemsLoaded {
                        items.append(product)
                    }
                case .Required:
                    items = route.itemsNotLoaded
                }
            case .Unloading:
                switch UnloadingSegment.allValues[toolbarSegmentedControl.selectedSegmentIndex] {
                case .OnTruck:
                    for product in route.itemsLoaded {
                        items.append(product)
                    }
                case .Delivered:
                    items = route.itemsDelivered
                }
            }
        }
        return items
    }

    private var route: Route! {
        return delegate?.routeForViewController(self)
    }

    private var loadingSegment: LoadingSegment!
    private var unloadingSegment: UnloadingSegment!

    private var completeItem: UIBarButtonItem! {
        let completeItem = UIBarButtonItem(title: "COMPLETE", style: .Plain, target: self, action: #selector(RouteManifestViewController.complete(_:)))
        completeItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return completeItem
    }

    private var scanItem: UIBarButtonItem! {
        let scanItem = UIBarButtonItem(title: "+ SCAN", style: .Plain, target: self, action: #selector(RouteManifestViewController.scan(_:)))
        scanItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return scanItem
    }

    private var startItem: UIBarButtonItem! {
        let startItem = UIBarButtonItem(title: "START", style: .Plain, target: self, action: #selector(RouteManifestViewController.start(_:)))
        startItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return startItem
    }

    private var targetView: UIView! {
        return delegate?.targetViewForViewController(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.frame = view.bounds

        initToolbarSegmentedControl()

        refreshNavigationItem()

        barcodeScannerViewController = UIStoryboard("BarcodeScanner").instantiateInitialViewController() as! BarcodeScannerViewController
        barcodeScannerViewController.delegate = self
    }

    func loadingSegmentChanged(_: UISegmentedControl) {
        loadingSegment = LoadingSegment.allValues[toolbarSegmentedControl.selectedSegmentIndex]

        dispatch_after_delay(0.0) {
            self.tableView.reloadData()
        }
    }

    func unloadingSegmentChanged(_: UISegmentedControl) {
        unloadingSegment = UnloadingSegment.allValues[toolbarSegmentedControl.selectedSegmentIndex]

        dispatch_after_delay(0.0) {
            self.tableView.reloadData()
        }
    }

    private func initToolbarSegmentedControl() {
        switch mode {
        case .Loading:
            toolbarSegmentedControl = UISegmentedControl(items: loadingSegmentedControlItems)
            toolbarSegmentedControl.tintColor = Color.applicationDefaultBarButtonItemTintColor()
            toolbarSegmentedControl.selectedSegmentIndex = 1
            toolbarSegmentedControl.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
            toolbarSegmentedControl.addTarget(self, action: #selector(RouteManifestViewController.loadingSegmentChanged(_:)), forControlEvents: .ValueChanged)
        case .Unloading:
            toolbarSegmentedControl = UISegmentedControl(items: unloadingSegmentedControlItems)
            toolbarSegmentedControl.tintColor = Color.applicationDefaultBarButtonItemTintColor()
            toolbarSegmentedControl.selectedSegmentIndex = 0
            toolbarSegmentedControl.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
            toolbarSegmentedControl.addTarget(self, action: #selector(RouteManifestViewController.unloadingSegmentChanged(_:)), forControlEvents: .ValueChanged)
        }
    }

    private func dismissBarcodeScannerViewController() {
        refreshNavigationItem()

        dismissViewController(animated: true) {
            self.tableView.reloadData()
        }
    }

    private var navigationItemPrompt: String! {
        var prompt: String!
        switch mode {
        case .Loading:
            prompt = "\(route.itemsToLoadCountRemaining) item(s) missing from manifest"
            if let name = route?.name {
                prompt = "\(route.itemsToLoadCountRemaining) item(s) missing from manifest for \(name)"
            }
        case .Unloading:
            prompt = "\(route.itemsToUnloadCountRemaining) item(s) to receive back into inventory"
            if let name = route?.name {
                prompt = "\(route.itemsToUnloadCountRemaining) item(s) to receive back into inventory for \(name)"
            }
        }
        return prompt
    }

    func refreshNavigationItem() {
        navigationItem.hidesBackButton = true
        navigationItem.titleView = toolbarSegmentedControl
        navigationItem.prompt = nil

        if let route = route {
            navigationItem.prompt = navigationItemPrompt

            if route.status == "unloading" {
                if route.itemsLoaded.count == 0 {
                    //navigationItem.leftBarButtonItems = [completeItem]
                    complete(nil)
                } else {
                    navigationItem.leftBarButtonItems = [scanItem]
                }
            } else if route.itemsToLoadCountRemaining == 0 {
                toolbarSegmentedControl.selectedSegmentIndex = 0
                navigationItem.leftBarButtonItems = [startItem]
            } else {
                navigationItem.leftBarButtonItems = [scanItem]
            }
        }
    }

    func clearNavigationItem() {
        navigationItem.hidesBackButton = true
        navigationItem.prompt = navigationItemPrompt
        navigationItem.leftBarButtonItems = []
        navigationItem.rightBarButtonItems = []
    }

    func render() {
        if mode == .Loading && route.status != "loading" {
            load()
        } else if mode == .Unloading && route.itemsLoaded.count == 0 {
            complete(nil)
        }

        if let navigationController = delegate?.navigationControllerForViewController(self) {
            for viewController in navigationController.viewControllers {
                if viewController.isKindOfClass(RouteManifestViewController) {
                    return
                }
            }
            navigationController.pushViewController(self, animated: false)
        }
    }

    func scan(sender: UIBarButtonItem!) {
        clearNavigationItem()

        if isSimulator() { // HACK!!!
            simulateScanningAllItems()
        } else {
            acceptingCodes = true
            presentViewController(barcodeScannerViewController, animated: true)
        }
    }

    private func simulateScanningAllItems() { // HACK!!! only for being able to fly thru demos on the simulator
        if let route = route {
            switch mode {
            case .Loading:
                var gtins = [String]()
                for item in route.itemsOrdered {
                    gtins.append(item.gtin)
                }

                showHUD()

                ApiService.sharedService().updateRouteWithId(String(route.id), params: ["gtins_loaded": gtins],
                    onSuccess: { statusCode, responseString in
                        var itemsLoaded = [Product]()
                        for product in route.itemsOrdered {
                            itemsLoaded.append(product)
                        }
                        route.itemsLoaded = itemsLoaded
                        self.refreshNavigationItem()
                        self.tableView.reloadData()

                        self.hideHUD()
                    },
                    onError: { error, statusCode, responseString in
                        self.hideHUD()
                    }
                )
            case .Unloading:
                showHUD()

                for item in route.itemsLoaded {
                    route.unloadManifestItemByGtin(item.gtin,
                        onSuccess: { statusCode, mappingResult in
                            self.hideHUD()

                            if route.itemsLoaded.count == 0 {
                                self.complete(nil)
                            }
                        },
                        onError: { (error, statusCode, responseString) -> () in
                            self.hideHUD()
                        }
                    )
                }
            }
        }
    }

    func start(sender: UIBarButtonItem!) {
        clearNavigationItem()

        showHUD()

        route.start(
            onSuccess: { statusCode, responseString in
                self.dismiss()
            },
            onError: { error, statusCode, responseString in
                self.hideHUD()
            }
        )
    }

    func load() {
        if let route = route {
            showHUD()

            route.load(
                { statusCode, mappingResult in
                    self.refreshNavigationItem()
                    self.hideHUD()
                },
                onError: { error, statusCode, responseString in
                    self.refreshNavigationItem()
                    self.hideHUD()
                }
            )
        }
    }

    func complete(sender: UIBarButtonItem!) {
        if let route = route {
            if route.itemsLoaded.count == 0 {
                showHUD()

                route.complete(
                    onSuccess: { statusCode, mappingResult in
                        self.dismiss()
                    },
                    onError: { error, statusCode, responseString in
                        self.dismiss()
                    }
                )
            }
        }
    }

    private func dismiss() {
        refreshNavigationItem()
        hideHUD()
        tableView.delegate = nil
        delegate?.routeUpdated(route, byViewController: self)
    }

    // MARK: BarcodeScannerViewControllerDelegate

    func barcodeScannerViewController(barcodeScannerViewController: BarcodeScannerViewController, didOutputMetadataObjects metadataObjects: [AnyObject], fromConnection connection: AVCaptureConnection) {
        if acceptingCodes {
            if let machineReadableCodeObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
                processCode(machineReadableCodeObject)
            }
        }
    }

    private func processCode(metadataObject: AVMetadataMachineReadableCodeObject?) {
        if let code = metadataObject {
            if code.type == AVMetadataObjectTypeEAN13Code || code.type == AVMetadataObjectTypeCode39Code {
                let value = code.stringValue

                if let route = route {
                    switch mode {
                    case .Loading:
                        if route.isGtinRequired(value) {
                            acceptingCodes = false
                            processingCode = true

                            showHUD()

                            route.loadManifestItemByGtin(value,
                                onSuccess: { statusCode, responseString in
                                    self.processingCode = false
                                    self.hideHUD()
                                },
                                onError: { error, statusCode, responseString in
                                    self.processingCode = false
                                    self.hideHUD()
                                }
                            )
                        }
                    case .Unloading:
                        if route.gtinLoadedCount(value) > 0 {
                            acceptingCodes = false
                            processingCode = true

                            showHUD()

                            route.unloadManifestItemByGtin(value,
                                onSuccess: { statusCode, responseString in
                                    self.processingCode = false
                                    self.hideHUD()
                                    if route.itemsLoaded.count == 0 {
                                        self.complete(nil)
                                    }
                                },
                                onError: { error, statusCode, responseString in
                                    self.processingCode = false
                                    self.hideHUD()
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    func barcodeScannerViewControllerShouldBeDismissed(viewController: BarcodeScannerViewController) {
        dismissBarcodeScannerViewController()
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("manifestTableViewCell") as! ManifestItemTableViewCell
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
