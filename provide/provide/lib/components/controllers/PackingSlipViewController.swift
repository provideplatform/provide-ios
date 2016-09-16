//
//  PackingSlipViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import AVFoundation
import FontAwesomeKit
import KTSwiftExtensions

class PackingSlipViewController: WorkOrderComponentViewController,
                                 UITableViewDataSource,
                                 UITableViewDelegate,
                                 PackingSlipItemTableViewCellDelegate,
                                 BarcodeScannerViewControllerDelegate,
                                 CameraViewControllerDelegate,
                                 CommentCreationViewControllerDelegate {

    enum Segment {
        case onTruck, unloaded, rejected

        static let allValues = [unloaded, onTruck, rejected]
    }

    fileprivate var packingSlipToolbarSegmentedControl: UISegmentedControl!
    @IBOutlet fileprivate weak var packingSlipTableView: UITableView!

    fileprivate var cameraViewController: CameraViewController!

    fileprivate var barcodeScannerViewController: BarcodeScannerViewController!
    fileprivate var productToUnload: Product!

    fileprivate var deliverItem: UIBarButtonItem!
    fileprivate var abandonItem: UIBarButtonItem!

    fileprivate var segment: Segment!

    fileprivate var items: [Product]! {
        switch Segment.allValues[packingSlipToolbarSegmentedControl.selectedSegmentIndex] {
        case .unloaded:
            return workOrdersViewControllerDelegate?.workOrderItemsUnloadedForViewController?(self)
        case .onTruck:
            return workOrdersViewControllerDelegate?.workOrderItemsOnTruckForViewController?(self)
        case .rejected:
            return workOrdersViewControllerDelegate?.workOrderItemsRejectedForViewController?(self)
        }
    }

    fileprivate var usingCamera = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear

        packingSlipToolbarSegmentedControl = UISegmentedControl(items: ["UNLOADED", "ON TRUCK", "REJECTED"])
        packingSlipToolbarSegmentedControl.selectedSegmentIndex = 1
        packingSlipToolbarSegmentedControl.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        packingSlipToolbarSegmentedControl.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        packingSlipToolbarSegmentedControl.addTarget(self, action: #selector(PackingSlipViewController.segmentChanged(_:)), for: .valueChanged)
        navigationItem.titleView = packingSlipToolbarSegmentedControl

        let cameraIconImage = FAKFontAwesome.cameraRetroIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0))
        let cameraBarButtonItem = UIBarButtonItem(image: cameraIconImage, style: .plain, target: self, action: #selector(PackingSlipViewController.cameraButtonTapped(_:)))
        cameraBarButtonItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        navigationItem.rightBarButtonItem = cameraBarButtonItem

        barcodeScannerViewController = UIStoryboard("BarcodeScanner").instantiateInitialViewController() as! BarcodeScannerViewController
        barcodeScannerViewController.delegate = self

        cameraViewController = UIStoryboard("Camera").instantiateInitialViewController() as! CameraViewController
        cameraViewController.delegate = self
    }

    func segmentChanged(_ sender: UISegmentedControl) {
        segment = Segment.allValues[sender.selectedSegmentIndex]

        dispatch_after_delay(0.0) {
            self.packingSlipTableView.reloadData()
        }
    }

    func cameraButtonTapped(_ sender: UIButton) {
        usingCamera = true

        if let navigationController = navigationController {
            if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
                setupNavigationItem(workOrder.canBeDelivered, abandomItemEnabled: workOrder.canBeAbandoned)
            }

            navigationController.pushViewController(cameraViewController, animated: false)

            if let barcodeScannerViewController = barcodeScannerViewController {
                barcodeScannerViewController.stopScanner()
            }

            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
                animations: {
                    let offsetHeight =  UIApplication.shared.statusBarFrame.size.height
                    navigationController.view.frame = self.presentedViewFrame
                    navigationController.navigationBar.frame.size.height += offsetHeight
                    self.packingSlipTableView.frame.origin.y += offsetHeight
                },
                completion: nil
            )
        }
    }

    fileprivate var commentCreationViewController: CommentCreationViewController! {
        let commentCreationViewController = (UIStoryboard("CommentCreation").instantiateInitialViewController() as! UINavigationController).viewControllers.first as! CommentCreationViewController
        commentCreationViewController.commentCreationViewControllerDelegate = self
        return commentCreationViewController
    }

    fileprivate var hiddenNavigationControllerFrame: CGRect {
        return CGRect(
            x: 0.0,
            y: targetView.frame.height,
            width: targetView.frame.width,
            height: targetView.frame.height / 1.75
        )
    }

    fileprivate var renderedNavigationControllerFrame: CGRect {
        return CGRect(
            x: 0.0,
            y: hiddenNavigationControllerFrame.origin.y - hiddenNavigationControllerFrame.height,
            width: hiddenNavigationControllerFrame.width,
            height: hiddenNavigationControllerFrame.height
        )
    }

    fileprivate var presentedViewFrame: CGRect {
        if let navigationController = workOrdersViewControllerDelegate?.navigationControllerForViewController?(self) {
            return CGRect(
                x: 0.0,
                y: navigationController.view.frame.origin.y,
                width: targetView.frame.width,
                height: targetView.frame.height
            )
        }

        return CGRect(
            x: 0.0,
            y: targetView.frame.origin.y,
            width: targetView.frame.width,
            height: targetView.frame.height
        )
    }

    override func render() {
        let frame = hiddenNavigationControllerFrame

        view.alpha = 0.0
        view.frame = frame

        view.addDropShadow(CGSize(width: 1.0, height: 1.0), radius: 2.5, opacity: 1.0)

        if let navigationController = navigationController {
            navigationController.view.alpha = 0.0
            navigationController.view.frame = hiddenNavigationControllerFrame
            targetView.addSubview(navigationController.view)
            targetView.bringSubview(toFront: navigationController.view)

            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
                animations: {
                    self.view.alpha = 1
                    navigationController.view.alpha = 1
                    navigationController.view.frame = CGRect(
                        x: frame.origin.x,
                        y: frame.origin.y - navigationController.view.frame.height,
                        width: frame.width,
                        height: frame.height
                    )
                },
                completion: nil
            )
        } else {
            targetView.addSubview(view)

            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
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

        UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveEaseIn,
            animations: {
                if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
                    self.setupNavigationItem(workOrder.canBeDelivered, abandomItemEnabled: workOrder.canBeAbandoned)
                }
            },
            completion: nil
        )
    }

    override func unwind() {
        clearNavigationItem()
        workOrdersViewControllerDelegate.navigationControllerNavBarButtonItemsShouldBeResetForViewController?(self)

        if let barcodeScannerViewController = barcodeScannerViewController {
            barcodeScannerViewController.stopScanner()
        }

        if let navigationController = navigationController {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
                animations: {
                    self.view.alpha = 0.0
                    navigationController.view.alpha = 0.0
                    navigationController.view.frame = self.hiddenNavigationControllerFrame
                },
                completion: nil
            )
        } else {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
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
    }

    // MARK: Navigation item

    func setupNavigationItem(_ deliverItemEnabled: Bool = false, abandomItemEnabled: Bool = true) {
        if let navigationItem = workOrdersViewControllerDelegate.navigationControllerNavigationItemForViewController?(self) {
            if !usingCamera {
                if let navigationController = workOrdersViewControllerDelegate.navigationControllerForViewController?(self) {
                    navigationController.setNavigationBarHidden(false, animated: true)
                }

                deliverItem = UIBarButtonItem(title: "DELIVER", style: .plain, target: self, action: #selector(PackingSlipViewController.deliver(_:)))
                deliverItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
                deliverItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), for: .disabled)
                deliverItem.isEnabled = deliverItemEnabled

                abandonItem = UIBarButtonItem(title: "ABANDON", style: .plain, target: self, action: #selector(PackingSlipViewController.abandon(_:)))
                abandonItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
                abandonItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), for: .disabled)
                abandonItem.isEnabled = abandomItemEnabled

                var promptText = "You have arrived"
                if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
                    if workOrder.itemsDelivered.count > 0 || workOrder.itemsRejected.count > 0 {
                        promptText = "\(workOrder.itemsOrdered.count - workOrder.itemsDelivered.count - workOrder.itemsRejected.count) more item(s) to deliver"
                    }
                }

                navigationItem.prompt = promptText
                navigationItem.leftBarButtonItems = [deliverItem]
                navigationItem.rightBarButtonItems = [abandonItem]
            } else {
                navigationItem.prompt = ""
                navigationItem.leftBarButtonItems = []
                navigationItem.rightBarButtonItems = []

                if let navigationController = workOrdersViewControllerDelegate.navigationControllerForViewController?(self) {
                    navigationController.setNavigationBarHidden(true, animated: true)
                }
            }
        }
    }

    func deliver(_ sender: UIBarButtonItem) {
        workOrdersViewControllerDelegate?.workOrderDeliveryConfirmedForViewController?(self)
    }

    func abandon(_ sender: UIBarButtonItem) {
        workOrdersViewControllerDelegate?.workOrderAbandonedForViewController?(self)
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "packingSlipItemTableViewCell") as! PackingSlipItemTableViewCell

        if let items = items {
            cell.product = items[(indexPath as NSIndexPath).row]
            cell.packingSlipItemTableViewCellDelegate = self
        }

        return cell
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }

    // MARK: PackingSlipItemTableViewCellDelegate

    func segmentForPackingSlipItemTableViewCell(_ cell: PackingSlipItemTableViewCell) -> PackingSlipViewController.Segment! {
        if let packingSlipToolbarSegmentedControl = packingSlipToolbarSegmentedControl {
            return Segment.allValues[packingSlipToolbarSegmentedControl.selectedSegmentIndex]
        }
        return nil
    }

    func packingSlipItemTableViewCell(_ cell: PackingSlipItemTableViewCell, didRejectProduct rejectedProduct: Product) {
        dispatch_after_delay(0.0) {
            self.showHUD(inView: self.targetView)
        }

        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            if workOrder.canRejectGtin(rejectedProduct.gtin) {
                if let route = RouteService.sharedService().inProgressRoute {
                    route.loadManifestItemByGtin(rejectedProduct.gtin,
                        onSuccess: { statusCode, responseString in
                            workOrder.rejectItem(rejectedProduct,
                                onSuccess: { statusCode, mappingResult in
                                    dispatch_after_delay(0.0) {
                                        self.packingSlipTableView.reloadData()

                                        self.hideHUD(inView: self.targetView)

                                        if let navigationController = self.navigationController {
                                            navigationController.pushViewController(self.commentCreationViewController, animated: true)
                                        }
                                    }
                                },
                                onError: { error, statusCode, responseString in
                                    dispatch_after_delay(0.0) {
                                        self.packingSlipTableView.reloadData()
                                        self.setupNavigationItem(workOrder.canBeDelivered,
                                                                 abandomItemEnabled: workOrder.canBeAbandoned)

                                        self.hideHUD(inView: self.targetView)
                                    }
                                }
                            )
                        },
                        onError: { error, statusCode, responseString in
                            dispatch_after_delay(0.0) {
                                self.packingSlipTableView.reloadData()
                                self.hideHUD(inView: self.targetView)
                            }
                        }
                    )
                }
            }
        }
    }

    func packingSlipItemTableViewCell(_ cell: PackingSlipItemTableViewCell, shouldAttemptToUnloadProduct product: Product) {
        productToUnload = product

        if isSimulator() { // HACK!!!
            unloadItem(product.gtin)
        } else {
            if let cameraViewController = cameraViewController {
                if cameraViewController.isRunning {
                    cameraViewController.teardownBackCameraView()
                }
            }

            if let barcodeScannerViewController = barcodeScannerViewController {
                barcodeScannerViewController.setupBarcodeScannerView()
            }

            if let navigationController = navigationController {
                if let productName = product.name {
                    barcodeScannerViewController.navigationItem.title = "SCAN \(productName)"
                } else {
                    barcodeScannerViewController.navigationItem.title = "SCAN \(product.gtin)"
                }
                navigationController.pushViewController(barcodeScannerViewController, animated: true)
            } else {
                presentViewController(barcodeScannerViewController, animated: true)
            }
        }
    }

    func packingSlipItemTableViewCell(_ cell: PackingSlipItemTableViewCell, shouldAttemptToUnloadRejectedProduct product: Product) {
        packingSlipItemTableViewCell(cell, shouldAttemptToUnloadProduct: product)
    }

    // MARK: BarcodeScannerViewControllerDelegate

    func barcodeScannerViewController(_ barcodeScannerViewController: BarcodeScannerViewController, didOutputMetadataObjects metadataObjects: [AnyObject], fromConnection connection: AVCaptureConnection) {
        for object in metadataObjects {
            if let machineReadableCodeObject = object as? AVMetadataMachineReadableCodeObject {
                processCode(machineReadableCodeObject)
            }
        }
    }

    fileprivate func processCode(_ metadataObject: AVMetadataMachineReadableCodeObject!) {
        if let code = metadataObject {
            if code.type == AVMetadataObjectTypeEAN13Code || code.type == AVMetadataObjectTypeCode39Code {
                unloadItem(code.stringValue)
            }
        }
    }

    fileprivate func unloadItem(_ gtin: String) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            if let product = productToUnload {
                if product.gtin == gtin {
                    if workOrder.canUnloadGtin(gtin) {
                        dispatch_after_delay(0.0) {
                            self.showHUD(inView: self.targetView)
                        }

                        if let route = RouteService.sharedService().inProgressRoute {
                            route.unloadManifestItemByGtin(product.gtin,
                                onSuccess: { statusCode, responseString in
                                    workOrder.deliverItem(product,
                                        onSuccess: { statusCode, mappingResult in
                                            dispatch_after_delay(0.0) {
                                                self.setupNavigationItem(workOrder.canBeDelivered, abandomItemEnabled: false)
                                                self.packingSlipTableView.reloadData()

                                                self.hideHUD(inView: self.targetView)
                                            }
                                        },
                                        onError: { error, statusCode, responseString in
                                            dispatch_after_delay(0.0) {
                                                self.setupNavigationItem(workOrder.canBeDelivered, abandomItemEnabled: false)
                                                self.packingSlipTableView.reloadData()

                                                self.hideHUD(inView: self.targetView)
                                            }
                                        }
                                    )
                                },
                                onError: { error, statusCode, responseString in

                                }
                            )
                        }

                        dismissBarcodeScannerViewController()
                    } else {
                        // TODO-- show UI for state when gtin cannot be unloaded
                        //log("gtin cannot be unloaded for work order...")
                    }
                } else {
                    // TODO-- show UI for state when barcode does not match item being unloaded
                    //log("gtin does not match product being unloaded...")
                }
            }
        }
    }

    func barcodeScannerViewControllerShouldBeDismissed(_ viewController: BarcodeScannerViewController) {
        dismissBarcodeScannerViewController()
    }

    func rectOfInterestForBarcodeScannerViewController(_ viewController: BarcodeScannerViewController) -> CGRect {
        return CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height)
    }

    fileprivate func dismissBarcodeScannerViewController() {
        productToUnload = nil

        if let navigationController = navigationController {
            dispatch_after_delay(0.0) {
                navigationController.popViewController(animated: true)

                DispatchQueue.global(qos: DispatchQoS.default.qosClass).asyncAfter(deadline: .now()) {
                    self.barcodeScannerViewController.stopScanner()
                }
            }
        } else {
            dismissViewController(true)
        }
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(_ viewController: CameraViewController) -> CameraOutputMode {
        return .photo
    }

    func cameraViewControllerDidBeginAsyncStillImageCapture(_ viewController: CameraViewController) {
        cameraViewControllerCanceled(viewController)
    }

    func cameraViewController(_ viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            var params = [
                "tags": ["photo", "delivery"],
                "public": false
            ] as [String : Any]

            if let location = LocationService.sharedService().currentLocation {
                params["latitude"] = location.coordinate.latitude
                params["longitude"] = location.coordinate.longitude
            }

            workOrder.attach(image, params: params as [String : AnyObject],
                onSuccess: { (statusCode, mappingResult) -> () in
                    // TODO: show success
                },
                onError: { (error, statusCode, responseString) -> () in

                }
            )
        }
    }

    func cameraViewControllerCanceled(_ viewController: CameraViewController) {
        if let navigationController = navigationController {
            navigationController.popViewController(animated: false)
            usingCamera = false

            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
                animations: {
                    let offsetHeight = UIApplication.shared.statusBarFrame.size.height
                    navigationController.view.frame = self.renderedNavigationControllerFrame
                    navigationController.navigationBar.frame.size.height -= offsetHeight
                    self.packingSlipTableView.frame.origin.y -= offsetHeight
                },
                completion: nil
            )

            if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
                setupNavigationItem(workOrder.canBeDelivered, abandomItemEnabled: workOrder.canBeAbandoned)
            }
        }
    }

    func cameraViewController(_ viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage) {

    }

    func cameraViewControllerDidOutputFaceMetadata(_ viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject) {

    }

    func cameraViewControllerShouldOutputFaceMetadata(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldRenderFacialRecognition(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldOutputOCRMetadata(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewController(_ viewController: CameraViewController, didRecognizeText text: String!) {
        
    }

    func cameraViewController(_ cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: URL) {

    }

    func cameraViewController(_ cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: URL) {

    }

    // MARK: CommentCreationViewControllerDelegate

    func commentCreationViewController(_ viewController: CommentCreationViewController, didSubmitComment comment: String) {
        commentCreationViewControllerShouldBeDismissed(viewController)

        showHUD(inView: self.targetView)

        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            workOrder.addComment(comment,
                onSuccess: { statusCode, responseString in
                    self.hideHUD(inView: self.targetView)
                },
                onError: { error, statusCode, responseString in
                    self.hideHUD(inView: self.targetView)
                }
            )
        }
    }

    func commentCreationViewControllerShouldBeDismissed(_ viewController: CommentCreationViewController) {
        let _ = navigationController?.popViewController(animated: true)
    }

    func promptForCommentCreationViewController(_ viewController: CommentCreationViewController) -> String! {
        return nil
    }

    func titleForCommentCreationViewController(_ viewController: CommentCreationViewController) -> String! {
        return "COMMENT ON REJECTION"
    }
}
