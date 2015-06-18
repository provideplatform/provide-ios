//
//  PackingSlipViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import AVFoundation

//@objc
//protocol PackingSlipViewControllerDelegate {
//
//    optional func workOrderDeliveryConfirmedForViewController(packingSlipViewController: PackingSlipViewController!)
//    optional func workOrderAbandonedForViewController(packingSlipViewController: PackingSlipViewController!)
//    optional func workOrderItemsOrderedForViewController(packingSlipViewController: PackingSlipViewController!) -> [Product]!
//
//}

class PackingSlipViewController: WorkOrderComponentViewController,
                                 UITableViewDataSource,
                                 UITableViewDelegate,
                                 PackingSlipItemTableViewCellDelegate,
                                 BarcodeScannerViewControllerDelegate {

    enum Segment {
        case OnTruck, Unloaded, Rejected

        static let allValues = [Unloaded, OnTruck, Rejected]
    }

    @IBOutlet private weak var packingSlipToolbarView: UIView!
    @IBOutlet private weak var packingSlipToolbarSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var packingSlipTableView: UITableView!

    private var barcodeScannerViewController: BarcodeScannerViewController!
    private var productToUnload: Product!

    private var deliverItem: UIBarButtonItem!
    private var abandonItem: UIBarButtonItem!

    private var segment: Segment!

    private var items: [Product]! {
        switch Segment.allValues[packingSlipToolbarSegmentedControl.selectedSegmentIndex] {
        case .Unloaded:
            return workOrdersViewControllerDelegate?.workOrderItemsUnloadedForViewController?(self)
        case .OnTruck:
            return workOrdersViewControllerDelegate?.workOrderItemsOnTruckForViewController?(self)
        case .Rejected:
            return workOrdersViewControllerDelegate?.workOrderItemsRejectedForViewController?(self)
        default:
            return nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clearColor()

        packingSlipToolbarView.backgroundColor = UIColor.resizedColorWithPatternImage(Color.annotationViewBackgroundImage(),
                                                                                     rect: CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: view.frame.height)).colorWithAlphaComponent(0.7)

        packingSlipToolbarSegmentedControl.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        packingSlipToolbarSegmentedControl.addTarget(self, action: "segmentChanged", forControlEvents: .ValueChanged)

        packingSlipTableView.backgroundView = UIImageView(image: UIImage("navbar-background"))

        barcodeScannerViewController = UIStoryboard("BarcodeScanner").instantiateInitialViewController() as! BarcodeScannerViewController
        barcodeScannerViewController.delegate = self
    }

    func segmentChanged() {
        segment = Segment.allValues[packingSlipToolbarSegmentedControl.selectedSegmentIndex]

        dispatch_after_delay(0.0) {
            self.packingSlipTableView.reloadData()
        }
    }

    override func render() {
        let frame = CGRect(
            x: 0.0,
            y: targetView.frame.height,
            width: targetView.frame.width,
            height: view.frame.height
        )

        view.alpha = 0.0
        view.frame = frame

        view.addDropShadow(CGSizeMake(1.0, 1.0), radius: 2.5, opacity: 1.0)

        targetView.addSubview(view)

        setupNavigationItem()

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.view.alpha = 1
                self.view.frame = CGRect(
                    x: frame.origin.x,
                    y: frame.origin.y - self.view.frame.height,
                    width: frame.width,
                    height: frame.height
                )
            },
            completion: nil
        )
    }

    override func unwind() {
        clearNavigationItem()

        if let barcodeScannerViewController = barcodeScannerViewController {
            barcodeScannerViewController.stopScanner()
        }

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.view.alpha = 0
                self.view.frame = CGRect(
                    x: 0.0,
                    y: self.view.frame.origin.y + self.view.frame.height,
                    width: self.view.frame.width,
                    height: self.view.frame.height
                )
            },
            completion: nil
        )
    }

    // MARK: Navigation item

    func setupNavigationItem(deliverItemEnabled: Bool = false, abandomItemEnabled: Bool = true) {
        if let navigationItem = workOrdersViewControllerDelegate.navigationControllerNavigationItemForViewController?(self) {
            deliverItem = UIBarButtonItem(title: "DELIVER", style: .Plain, target: self, action: "deliver:")
            deliverItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
            deliverItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Disabled)
            deliverItem.enabled = deliverItemEnabled

            abandonItem = UIBarButtonItem(title: "ABANDON", style: .Plain, target: self, action: "abandon:")
            abandonItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
            abandonItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Disabled)
            abandonItem.enabled = abandomItemEnabled

            navigationItem.leftBarButtonItems = [deliverItem]
            navigationItem.rightBarButtonItems = [abandonItem]
        }
    }

    func deliver(sender: UIBarButtonItem) {
        workOrdersViewControllerDelegate?.workOrderDeliveryConfirmedForViewController?(self)
    }

    func abandon(sender: UIBarButtonItem) {
        workOrdersViewControllerDelegate?.workOrderAbandonedForViewController?(self)
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let items = items {
            return items.count
        }
        return 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("packingSlipItemTableViewCell") as! PackingSlipItemTableViewCell

        if let items = items {
            cell.product = items[indexPath.row]
            cell.packingSlipItemTableViewCellDelegate = self
        }

        return cell
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75.0
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    }

    // MARK: PackingSlipItemTableViewCellDelegate

    func packingSlipItemTableViewCell(cell: PackingSlipItemTableViewCell!, didRejectProduct rejectedProduct: Product!) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            if workOrder.canRejectGtin(rejectedProduct.gtin) {
                workOrder.rejectItem(rejectedProduct)
                workOrder.loadItem(rejectedProduct)

                packingSlipTableView.reloadData()

                if let route = RouteService.sharedService().inProgressRoute {
                    route.loadManifestItemByGtin(rejectedProduct.gtin,
                        onSuccess: { statusCode, responseString in
                            println("loaded manifest item by gtin...")
                        },
                        onError: { error, statusCode, responseString in

                        }
                    )
                }

                dispatch_after_delay(0.0) {
                    self.setupNavigationItem(deliverItemEnabled: workOrder.canBeDelivered, abandomItemEnabled: !workOrder.canBeDelivered)
                }
            }
        }
    }

    func packingSlipItemTableViewCell(cell: PackingSlipItemTableViewCell!, shouldAttemptToUnloadProduct product: Product!) {
        productToUnload = product

        if isSimulator() { // HACK!!!
            unloadItem(product.gtin)
        } else {
            presentViewController(barcodeScannerViewController, animated: true)
        }
    }

    // MARK: BarcodeScannerViewControllerDelegate

    func barcodeScannerViewController(barcodeScannerViewController: BarcodeScannerViewController!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        for object in metadataObjects {
            if let machineReadableCodeObject = object as? AVMetadataMachineReadableCodeObject {
                processCode(machineReadableCodeObject)
            }
        }
    }

    private func processCode(metadataObject: AVMetadataMachineReadableCodeObject!) {
        if let code = metadataObject {
            if code.type == AVMetadataObjectTypeEAN13Code || code.type == AVMetadataObjectTypeCode39Code {
                unloadItem(code.stringValue)
            }
        }
    }

    private func unloadItem(gtin: String!) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            if let product = productToUnload {
                if product.gtin == gtin {
                    if workOrder.canUnloadGtin(gtin) {
                        workOrder.approveItem(product)
                        workOrder.unloadItem(product)

                        dispatch_after_delay(0.0) {
                            self.packingSlipTableView.reloadData()
                        }

                        if let route = RouteService.sharedService().inProgressRoute {
                            route.unloadManifestItemByGtin(product.gtin,
                                onSuccess: { statusCode, responseString in

                                },
                                onError: { error, statusCode, responseString in

                                }
                            )
                        }

                        dispatch_after_delay(0.0) {
                            self.setupNavigationItem(deliverItemEnabled: workOrder.canBeDelivered, abandomItemEnabled: false)
                        }

                        dismissBarcodeScannerViewController()
                    } else {
                        // TODO-- show UI for state when gtin cannot be unloaded
                        //println("gtin cannot be unloaded for work order...")
                    }
                } else {
                    // TODO-- show UI for state when barcode does not match item being unloaded
                    //println("gtin does not match product being unloaded...")
                }
            }
        }
    }

    func barcodeScannerViewControllerShouldBeDismissed(viewController: BarcodeScannerViewController!) {
        dismissBarcodeScannerViewController()
    }

    func rectOfInterestForBarcodeScannerViewController(viewController: BarcodeScannerViewController!) -> CGRect {
        return view.frame
    }

    private func dismissBarcodeScannerViewController() {
        productToUnload = nil

        dismissViewController(animated: true)
    }

}
