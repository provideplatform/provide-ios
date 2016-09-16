//
//  RouteViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import AVFoundation
import KTSwiftExtensions

protocol RouteManifestViewControllerDelegate {
    func targetViewForViewController(_ viewController: UIViewController) -> UIView
    func navigationControllerForViewController(_ viewController: UIViewController) -> UINavigationController!
    func navigationControllerNavigationItemForViewController(_ viewController: UIViewController) -> UINavigationItem!
    func routeForViewController(_ viewController: UIViewController) -> Route!
    func routeUpdated(_ route: Route!, byViewController viewController: UIViewController)
}

class RouteManifestViewController: ViewController, UITableViewDelegate, UITableViewDataSource, BarcodeScannerViewControllerDelegate {

    enum Mode {
        case loading, unloading

        static let allValues = [loading, unloading]
    }

    enum LoadingSegment {
        case onTruck, required

        static let allValues = [onTruck, required]
    }

    enum UnloadingSegment {
        case onTruck, delivered

        static let allValues = [onTruck, delivered]
    }

    fileprivate let loadingSegmentedControlItems = ["ON TRUCK", "REQUIRED"]
    fileprivate let unloadingSegmentedControlItems = ["ON TRUCK", "DELIVERED"]

    var delegate: RouteManifestViewControllerDelegate!

    fileprivate var mode: Mode {
        if let route = route {
            if route.status == "unloading" {
                return .unloading
            }
        }
        return .loading
    }

    fileprivate var barcodeScannerViewController: BarcodeScannerViewController!

    fileprivate var acceptingCodes = false

    fileprivate var processingCode: Bool = false {
        didSet {
            if !processingCode {
                dismissBarcodeScannerViewController()
            }
        }
    }

    fileprivate var toolbarSegmentedControl: UISegmentedControl!
    @IBOutlet fileprivate weak var tableView: UITableView!

    fileprivate var items: [Product]! {
        var items = [Product]()
        if let route = route {
            switch mode {
            case .loading:
                switch LoadingSegment.allValues[toolbarSegmentedControl.selectedSegmentIndex] {
                case .onTruck:
                    for product in route.itemsLoaded {
                        items.append(product)
                    }
                case .required:
                    items = route.itemsNotLoaded
                }
            case .unloading:
                switch UnloadingSegment.allValues[toolbarSegmentedControl.selectedSegmentIndex] {
                case .onTruck:
                    for product in route.itemsLoaded {
                        items.append(product)
                    }
                case .delivered:
                    items = route.itemsDelivered
                }
            }
        }
        return items
    }

    fileprivate var route: Route! {
        return delegate?.routeForViewController(self)
    }

    fileprivate var loadingSegment: LoadingSegment!
    fileprivate var unloadingSegment: UnloadingSegment!

    fileprivate var completeItem: UIBarButtonItem! {
        let completeItem = UIBarButtonItem(title: "COMPLETE", style: .plain, target: self, action: #selector(RouteManifestViewController.complete(_:)))
        completeItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        return completeItem
    }

    fileprivate var scanItem: UIBarButtonItem! {
        let scanItem = UIBarButtonItem(title: "+ SCAN", style: .plain, target: self, action: #selector(RouteManifestViewController.scan(_:)))
        scanItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        return scanItem
    }

    fileprivate var startItem: UIBarButtonItem! {
        let startItem = UIBarButtonItem(title: "START", style: .plain, target: self, action: #selector(RouteManifestViewController.start(_:)))
        startItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        return startItem
    }

    fileprivate var targetView: UIView! {
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

    fileprivate func initToolbarSegmentedControl() {
        switch mode {
        case .loading:
            toolbarSegmentedControl = UISegmentedControl(items: loadingSegmentedControlItems)
            toolbarSegmentedControl.tintColor = Color.applicationDefaultBarButtonItemTintColor()
            toolbarSegmentedControl.selectedSegmentIndex = 1
            toolbarSegmentedControl.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
            toolbarSegmentedControl.addTarget(self, action: #selector(RouteManifestViewController.loadingSegmentChanged(_:)), for: .valueChanged)
        case .unloading:
            toolbarSegmentedControl = UISegmentedControl(items: unloadingSegmentedControlItems)
            toolbarSegmentedControl.tintColor = Color.applicationDefaultBarButtonItemTintColor()
            toolbarSegmentedControl.selectedSegmentIndex = 0
            toolbarSegmentedControl.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
            toolbarSegmentedControl.addTarget(self, action: #selector(RouteManifestViewController.unloadingSegmentChanged(_:)), for: .valueChanged)
        }
    }

    fileprivate func dismissBarcodeScannerViewController() {
        refreshNavigationItem()

        dismissViewController(true) {
            self.tableView.reloadData()
        }
    }

    fileprivate var navigationItemPrompt: String! {
        var prompt: String!
        switch mode {
        case .loading:
            prompt = "\(route.itemsToLoadCountRemaining) item(s) missing from manifest"
            if let name = route?.name {
                prompt = "\(route.itemsToLoadCountRemaining) item(s) missing from manifest for \(name)"
            }
        case .unloading:
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
        if mode == .loading && route.status != "loading" {
            load()
        } else if mode == .unloading && route.itemsLoaded.count == 0 {
            complete(nil)
        }

        if let navigationController = delegate?.navigationControllerForViewController(self) {
            for viewController in navigationController.viewControllers {
                if viewController.isKind(of: RouteManifestViewController.self) {
                    return
                }
            }
            navigationController.pushViewController(self, animated: false)
        }
    }

    func scan(_ sender: UIBarButtonItem!) {
        clearNavigationItem()

        if isSimulator() { // HACK!!!
            simulateScanningAllItems()
        } else {
            acceptingCodes = true
            presentViewController(barcodeScannerViewController, animated: true)
        }
    }

    fileprivate func simulateScanningAllItems() { // HACK!!! only for being able to fly thru demos on the simulator
        if let route = route {
            switch mode {
            case .loading:
                var gtins = [String]()
                for item in route.itemsOrdered {
                    gtins.append(item.gtin)
                }

                showHUD()

                ApiService.sharedService().updateRouteWithId(String(route.id), params: ["gtins_loaded": gtins as AnyObject],
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
            case .unloading:
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

    func start(_ sender: UIBarButtonItem!) {
        clearNavigationItem()

        showHUD()

        route.start(
            { statusCode, responseString in
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

    func complete(_ sender: UIBarButtonItem!) {
        if let route = route {
            if route.itemsLoaded.count == 0 {
                showHUD()

                route.complete(
                    { statusCode, mappingResult in
                        self.dismiss()
                    },
                    onError: { error, statusCode, responseString in
                        self.dismiss()
                    }
                )
            }
        }
    }

    fileprivate func dismiss() {
        refreshNavigationItem()
        hideHUD()
        tableView.delegate = nil
        delegate?.routeUpdated(route, byViewController: self)
    }

    // MARK: BarcodeScannerViewControllerDelegate

    func barcodeScannerViewController(_ barcodeScannerViewController: BarcodeScannerViewController, didOutputMetadataObjects metadataObjects: [AnyObject], fromConnection connection: AVCaptureConnection) {
        if acceptingCodes {
            if let machineReadableCodeObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
                processCode(machineReadableCodeObject)
            }
        }
    }

    fileprivate func processCode(_ metadataObject: AVMetadataMachineReadableCodeObject?) {
        if let code = metadataObject {
            if code.type == AVMetadataObjectTypeEAN13Code || code.type == AVMetadataObjectTypeCode39Code {
                let value = code.stringValue

                if let route = route {
                    switch mode {
                    case .loading:
                        if route.isGtinRequired(value!) {
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
                    case .unloading:
                        if route.gtinLoadedCount(value!) > 0 {
                            acceptingCodes = false
                            processingCode = true

                            showHUD()

                            route.unloadManifestItemByGtin(value!,
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

    func barcodeScannerViewControllerShouldBeDismissed(_ viewController: BarcodeScannerViewController) {
        dismissBarcodeScannerViewController()
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "manifestTableViewCell") as! ManifestItemTableViewCell
        cell.product = items[(indexPath as NSIndexPath).row]
        return cell
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log("selected loaded manifest item: \(items[(indexPath as NSIndexPath).row])")
    }
}
