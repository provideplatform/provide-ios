//
//  FloorplanViewController.swift
//  provide
//
//  Created by Kyle Thomas on 10/23/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol FloorplanViewControllerDelegate: NSObjectProtocol {
    func floorplanForFloorplanViewController(_ viewController: FloorplanViewController) -> Floorplan!
    func jobForFloorplanViewController(_ viewController: FloorplanViewController) -> Job!
    func floorplanImageForFloorplanViewController(_ viewController: FloorplanViewController) -> UIImage!
    func modeForFloorplanViewController(_ viewController: FloorplanViewController) -> FloorplanViewController.Mode!
    func scaleCanBeSetByFloorplanViewController(_ viewController: FloorplanViewController) -> Bool
    func scaleWasSetForFloorplanViewController(_ viewController: FloorplanViewController)
    func newWorkOrderCanBeCreatedByFloorplanViewController(_ viewController: FloorplanViewController) -> Bool
    func areaSelectorIsAvailableForFloorplanViewController(_ viewController: FloorplanViewController) -> Bool
    func navigationControllerForFloorplanViewController(_ viewController: FloorplanViewController) -> UINavigationController!
    func floorplanViewControllerCanDropWorkOrderPin(_ viewController: FloorplanViewController) -> Bool
    func toolbarForFloorplanViewController(_ viewController: FloorplanViewController) -> FloorplanToolbar!
    func hideToolbarForFloorplanViewController(_ viewController: FloorplanViewController)
    func showToolbarForFloorplanViewController(_ viewController: FloorplanViewController)
}

class FloorplanViewController: WorkOrderComponentViewController,
                               UIScrollViewDelegate,
                               FloorplanScaleViewDelegate,
                               FloorplanScrollViewDelegate,
                               FloorplanSelectorViewDelegate,
                               FloorplanThumbnailViewDelegate,
                               FloorplanPinViewDelegate,
                               FloorplanWorkOrdersViewControllerDelegate,
                               UIPopoverPresentationControllerDelegate {

    enum Mode {
        case setup, workOrders
        static let allValues = [setup, workOrders]
    }

    weak var floorplanViewControllerDelegate: FloorplanViewControllerDelegate! {
        didSet {
            if let delegate = floorplanViewControllerDelegate {
                if floorplan == nil {
                    if let floorplan = delegate.floorplanForFloorplanViewController(self) {
                        self.floorplan = floorplan
                    }
                }

                if !loadedFloorplan && !loadingFloorplan && scrollView != nil {
                    loadFloorplan()
                } else if loadedFloorplan {
                    dispatch_after_delay(0.0) {
                        self.scrollViewDidScroll(self.scrollView)
                    }
                }
            }
        }
    }

    fileprivate var mode: Mode {
        if let floorplanViewControllerDelegate = floorplanViewControllerDelegate {
            if let mode = floorplanViewControllerDelegate.modeForFloorplanViewController(self) {
                return mode
            }
        }
        return .setup
    }

    fileprivate var floorplanSelectorView: FloorplanSelectorView!
    fileprivate var thumbnailView: FloorplanThumbnailView!
    fileprivate var thumbnailTintView: UIView!

    fileprivate var imageView: UIImageView!
    fileprivate var floorplanTiledViews = [FloorplanTiledView]()
    fileprivate var floorplanTiledView: FloorplanTiledView! {
        var floorplanTiledView: FloorplanTiledView?
        if floorplanZoomLevel <= floorplanTiledViews.count - 1 {
            floorplanTiledView = floorplanTiledViews[floorplanZoomLevel]
        }
        return floorplanTiledView
    }
    fileprivate var floorplanZoomLevel: Int = 0 {
        didSet {
            for floorplanTiledView in floorplanTiledViews {
                if floorplanTiledView == self.floorplanTiledView {
                    removePinViews()

                    scrollView.contentSize = floorplanTiledView.frame.size
                    scrollView.addSubview(floorplanTiledView)
                    scrollView.bringSubview(toFront: floorplanTiledView)

                    floorplanTiledView.setNeedsDisplay()
                    floorplanTiledView.alpha = 1.0
                    floorplanTiledView.applyOffsetCorrection(scrollView)

                    refreshAnnotations()
                } else {
                    floorplanTiledView.alpha = 0.0
                    floorplanTiledView.removeFromSuperview()
                }
            }
        }
    }
    fileprivate var floorplanScrollViewZoomScale: CGFloat = 1.0 {
        didSet {
            floorplanZoomLevel = min(Int(round((Double(floorplanScrollViewZoomScale) * Double(floorplan.maxZoomLevel)))), floorplan.maxZoomLevel)
        }
    }

    @IBOutlet fileprivate weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var progressView: UIProgressView! {
        didSet {
            if let progressView = progressView {
                progressView.setProgress(0.0, animated: false)
            }
        }
    }

    @IBOutlet fileprivate weak var scrollView: FloorplanScrollView!

    @IBOutlet fileprivate weak var scaleView: FloorplanScaleView! {
        didSet {
            if let scaleView = self.scaleView {
                scaleView.delegate = self
                scaleView.backgroundColor = UIColor.white
                scaleView.clipsToBounds = true
                scaleView.roundCorners(5.0)
            }
        }
    }

    fileprivate var pinViews = [FloorplanPinView]()

    fileprivate var selectedPinView: FloorplanPinView! {
        didSet {
            if selectedPinView == nil {
                showPinViews()
            } else if selectedPinView != nil {
                hidePinViews(selectedPinView)
            }
        }
    }
    fileprivate var selectedPolygonView: FloorplanPolygonView!

    @IBOutlet fileprivate weak var floorplanWorkOrdersViewControllerContainer: UIView!
    fileprivate var floorplanWorkOrdersViewController: FloorplanWorkOrdersViewController!

    var floorplan: Floorplan!

    var floorplanImageUrl: URL! {
        if let floorplan = floorplan {
            return floorplan.imageUrl as URL!
        }
        return nil
    }

    var floorplanIsTiled: Bool {
        if let floorplan = floorplan {
            return floorplan.tilingCompletion == 1.0
        }
        return false
    }

    var floorplanScale: Float! {
        if let floorplan = floorplan {
            return Float(floorplan.scale)
        }
        return nil
    }

    fileprivate var maxContentSize: CGSize!

    weak var job: Job! {
        if let job = floorplanViewControllerDelegate?.jobForFloorplanViewController(self) {
            return job
        }
        if let workOrder = workOrder {
            return workOrder.job
        }
        return nil
    }

    var workOrder: WorkOrder!

    fileprivate var backsplashProductPickerViewController: ProductPickerViewController!

    fileprivate var enableScrolling = false {
        didSet {
            if let scrollView = scrollView {
                scrollView.isScrollEnabled = enableScrolling
            }
        }
    }

    fileprivate var hiddenNavigationControllerFrame: CGRect {
        return CGRect(
            x: 0.0,
            y: targetView.frame.height,
            width: targetView.frame.width,
            height: targetView.frame.height // / 1.333
        )
    }

    fileprivate var cachedNavigationItem: UINavigationItem!

    fileprivate var loadedFloorplan = false
    fileprivate var initializedAnnotations = false

    fileprivate var loadingFloorplan = false {
        didSet {
            if !loadingFloorplan && !loadingAnnotations {
                activityIndicatorView.stopAnimating()
            } else if !activityIndicatorView.isAnimating {
                if loadingFloorplan == true && oldValue == false {
                    progressView?.setProgress(0.0, animated: false)
                }
                activityIndicatorView.startAnimating()
            }
        }
    }

    fileprivate var loadingAnnotations = false {
        didSet {
            if !loadingFloorplan && !loadingAnnotations {
                activityIndicatorView?.stopAnimating()
                progressView?.isHidden = true
            } else if !activityIndicatorView.isAnimating {
                activityIndicatorView?.startAnimating()
            }
        }
    }

    fileprivate var loadingMaterials = false {
        didSet {
            if !loadingFloorplan && !loadingAnnotations && !loadingMaterials {
                activityIndicatorView.stopAnimating()
                progressView?.isHidden = true
            } else if !activityIndicatorView.isAnimating {
                activityIndicatorView.startAnimating()
            }
        }
    }

    fileprivate var newWorkOrderPending = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()

        let floorplanSelectorViewController = UIStoryboard("Floorplan").instantiateViewController(withIdentifier: "FloorplanSelectorViewController") as! FloorplanSelectorViewController
        floorplanSelectorView = floorplanSelectorViewController.selectorView
        floorplanSelectorView.delegate = self
        view.addSubview(floorplanSelectorView)

        let floorplanThumbnailViewController = UIStoryboard("Floorplan").instantiateViewController(withIdentifier: "FloorplanThumbnailViewController") as! FloorplanThumbnailViewController
        thumbnailView = floorplanThumbnailViewController.thumbnailView
        thumbnailView.delegate = self
        view.addSubview(thumbnailView)

        dispatch_after_delay(0.0) {
            let size = max(self.view.bounds.width, self.view.bounds.height)
            self.thumbnailTintView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: size, height: size))
            self.thumbnailTintView.backgroundColor = UIColor.black
            self.thumbnailTintView.alpha = 0.0
            self.view.addSubview(self.thumbnailTintView)
            self.view.sendSubview(toBack: self.thumbnailTintView)
            self.thumbnailTintView?.isUserInteractionEnabled = false
        }

        imageView = UIImageView()
        imageView.alpha = 0.0
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleToFill

        resetFloorplanTiledViews()

        scrollView?.floorplanScrollViewDelegate = self
        scrollView?.backgroundColor = UIColor.white
        scrollView?.addSubview(imageView)
        scrollView?.bringSubview(toFront: imageView)

        activityIndicatorView?.startAnimating()

        if floorplanViewControllerDelegate != nil && !loadedFloorplan && !loadingFloorplan && scrollView != nil {
            loadFloorplan()
        }

        NotificationCenter.default.addObserverForName("WorkOrderChanged") { notification in
            if let workOrder = notification.object as? WorkOrder {
                if let floorplan = self.floorplan {
                    if let annotations = floorplan.annotations {
                        for annotation in annotations {
                            if let wo = annotation.workOrder {
                                if workOrder.id == wo.id {
                                    dispatch_after_delay(0.0) {
                                        annotation.workOrder = workOrder

                                        if let pinView = self.pinViewForWorkOrder(workOrder) {
                                            pinView.annotation = annotation
                                            pinView.redraw()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        NotificationCenter.default.addObserverForName("FloorplanChanged") { notification in
            if let floorplan = notification.object as? Floorplan {
                if let f = self.floorplan {
                    if floorplan.id == f.id {
                        floorplan.annotations = self.floorplan.annotations
                        self.floorplan = floorplan
                        if !self.loadedFloorplan && !self.loadingFloorplan {
                            self.loadFloorplan()
                        }
                    }
                }
            }
        }
    }

    fileprivate func resetFloorplanTiledViews() {
        for floorplanTileView in floorplanTiledViews {
            floorplanTileView.removeGestureRecognizers()
            floorplanTileView.removeFromSuperview()
        }

        floorplanTiledViews = [FloorplanTiledView]()

        if !floorplanIsTiled {
            return
        }

        if floorplan?.zoomLevels != nil {
            var i = 0
            while i <= floorplan.maxZoomLevel {
                if let level = floorplan?.zoomLevels?[i] as? [String : AnyObject] {
                    let size =  CGSize(width: level["size"] as! Double,
                                       height: level["size"] as! Double)

                    let frame = CGRect(origin: CGPoint.zero, size: size)

                    let floorplanTiledView = FloorplanTiledView(frame: frame)
                    floorplanTiledView.alpha = 0.0
                    floorplanTiledView.backgroundColor = UIColor.clear
                    floorplanTiledView.isUserInteractionEnabled = true
                    floorplanTiledView.zoomLevel = i

                    if let canDropWorkOrderPin = floorplanViewControllerDelegate?.floorplanViewControllerCanDropWorkOrderPin(self) {
                        if canDropWorkOrderPin {
                            let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(FloorplanViewController.dropPin(_:)))
                            floorplanTiledView.addGestureRecognizer(gestureRecognizer)
                        }
                    }

                    scrollView?.addSubview(floorplanTiledView)
                    scrollView?.bringSubview(toFront: floorplanTiledView)

                    floorplanTiledViews.append(floorplanTiledView)
                }

                i += 1
            }

            for floorplanTiledView in floorplanTiledViews.reversed() {
                scrollView?.bringSubview(toFront: floorplanTiledView)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier! == "FloorplanWorkOrdersViewControllerSegue" {
            let navigationController = segue.destination as! UINavigationController
            floorplanWorkOrdersViewController = navigationController.viewControllers.first! as! FloorplanWorkOrdersViewController
            floorplanWorkOrdersViewController.delegate = self
        }
    }

    @discardableResult
    func teardown() -> UIImage? {
        let image = imageView?.image
        imageView?.image = nil
        thumbnailView?.floorplanImage = nil
        for floorplanTiledView in floorplanTiledViews {
            floorplanTiledView.removeGestureRecognizers()
            floorplanTiledView.removeFromSuperview()
        }
        loadedFloorplan = false
        return image
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(
            alongsideTransition: { context in
                self.hideToolbar()
                self.thumbnailView?.floorplanImage = self.imageView.image
                self.thumbnailTintView?.frame.size = size
            },
            completion: { context in
                self.showToolbar()

                if let scrollView = self.scrollView {
                    self.thumbnailView?.scrollViewDidZoom(scrollView)
                }
            }
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    fileprivate var isManagedByWorkOrdersViewController: Bool {
        if let navigationController = navigationController {
            return navigationController.viewControllers.first!.isKind(of: WorkOrdersViewController.self)
        }
        return false
    }

    func setupNavigationItem() {
        navigationItem.hidesBackButton = isManagedByWorkOrdersViewController

        navigationItem.leftBarButtonItems = []
        navigationItem.rightBarButtonItems = []
    }

    override func render() {
        let frame = hiddenNavigationControllerFrame

        view.alpha = 0.0
        view.frame = frame

        if let navigationController = navigationController {
            navigationController.view.alpha = 0.0
            navigationController.view.frame = hiddenNavigationControllerFrame
            targetView.addSubview(navigationController.view)
            targetView.bringSubview(toFront: navigationController.view)

            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
                animations: { [weak self] in
                    self!.view.alpha = 1
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
        }
    }

    override func unwind() {
        clearNavigationItem()

        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
                                   animations: { [weak self] in
                                        self!.view.alpha = 0.0

                                        if let navigationController = self!.navigationController {
                                            navigationController.view.alpha = 0.0
                                            navigationController.view.frame = self!.hiddenNavigationControllerFrame
                                        }
                                    },
                                   completion: { [weak self] completed in
                                        self!.view.removeFromSuperview()
                                    }
        )
    }

    fileprivate func loadFloorplan() {
        if floorplanIsTiled {
            renderTiledFloorplan()
        } else if let url = floorplanImageUrl {
            loadingFloorplan = true

            ImageService.sharedService().fetchImage(url, cacheOnDisk: true,
                onDownloadSuccess: { [weak self] image in
                    self!.maxContentSize = CGSize(width: image.size.width,
                                                  height: image.size.height)

                    dispatch_async_main_queue {
                        self!.activityIndicatorView?.stopAnimating()
                        self!.progressView?.setProgress(1.0, animated: false)
                        self!.setFloorplanImage(image)
                    }

                    if let floorplanWorkOrdersViewController = self!.floorplanWorkOrdersViewController {
                        floorplanWorkOrdersViewController.loadAnnotations()
                    }
                },
                onDownloadFailure: { error in
                    logWarn("Floorplan image download failed; \(error)")
                },
                onDownloadProgress: { [weak self] receivedSize, expectedSize in
                    if expectedSize != -1 {
                        dispatch_async_main_queue {
                            self!.progressView?.isHidden = false

                            let percentage: Float = Float(receivedSize) / Float(expectedSize)
                            self!.progressView?.setProgress(percentage, animated: true)
                        }
                    }
                }
            )
        }
    }

    fileprivate func renderFloorplanThumbnailImage() {
        if let imageUrlString = floorplan.imageUrlString72dpi {
            ImageService.sharedService().fetchImage(URL(string: imageUrlString)!, cacheOnDisk: true,
                onDownloadSuccess: { [weak self] image in
                    dispatch_async_main_queue {
                        self!.thumbnailView?.floorplanImage = image
                    }
                },
                onDownloadFailure: { error in
                    logWarn("Floorplan thumbnail image download failed; \(error)")
                },
                onDownloadProgress: { receivedSize, expectedSize in

                }
            )
        }
    }

    fileprivate func renderTiledFloorplan() {
        if floorplan.maxZoomLevel == -1 {
            return
        }

        ImageService.sharedService().fetchImage(floorplan.imageUrl, cacheOnDisk: true,
            onDownloadSuccess: { [weak self] image in
                dispatch_async_main_queue {
                    self!.activityIndicatorView?.stopAnimating()
                    self!.progressView?.setProgress(1.0, animated: false)

                    self!.maxContentSize = CGSize(width: image.size.width, height: image.size.height)

                    for floorplanTiledView in self!.floorplanTiledViews {
                        floorplanTiledView.floorplan = self!.floorplan
                    }

                    self!.renderFloorplanThumbnailImage()

                    self!.scrollView.isScrollEnabled = false
                    self!.scrollView.contentSize = self!.maxContentSize

                    self!.enableScrolling = true

                    self!.loadingFloorplan = false
                    self!.loadedFloorplan = true

                    self!.progressView?.isHidden = true

                    if let _ = self!.presentedViewController {
                        self!.dismissViewController(true)
                    }

                    dispatch_after_delay(0.0) {
                        self!.setZoomLevel()
                        self!.floorplanTiledView?.alpha = 1.0

                        if let floorplanWorkOrdersViewController = self!.floorplanWorkOrdersViewController {
                            floorplanWorkOrdersViewController.loadAnnotations()
                        }

                        if let toolbar = self!.floorplanViewControllerDelegate?.toolbarForFloorplanViewController(self!) {
                            toolbar.reload()
                        }

                        dispatch_after_delay(0.25) {
                            self!.showToolbar()
                        }
                    }
                }
            },
            onDownloadFailure: { error in
                logWarn("Floorplan image download failed; \(error)")
            },
            onDownloadProgress: { [weak self] receivedSize, expectedSize in
                if expectedSize != -1 {
                    dispatch_async_main_queue {
                        self!.progressView?.isHidden = false

                        let percentage: Float = Float(receivedSize) / Float(expectedSize)
                        self!.progressView?.setProgress(percentage, animated: true)
                    }
                }
            }
        )

    }

    fileprivate func setFloorplanImage(_ image: UIImage) {
        let size = CGSize(width: image.size.width, height: image.size.height)

        imageView!.image = image
        imageView!.frame = CGRect(origin: CGPoint.zero, size: size)

        renderFloorplanThumbnailImage()

        scrollView.isScrollEnabled = false
        scrollView.contentSize = size

        enableScrolling = true

        loadingFloorplan = false
        loadedFloorplan = true

        if let canDropWorkOrderPin = floorplanViewControllerDelegate?.floorplanViewControllerCanDropWorkOrderPin(self) {
            if canDropWorkOrderPin {
                let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(FloorplanViewController.dropPin(_:)))
                imageView.addGestureRecognizer(gestureRecognizer)
            }
        }

        self.progressView?.isHidden = true

        if let _ = presentedViewController {
            dismissViewController(true)
        }

        dispatch_after_delay(0.0) {
            self.setZoomLevel()
            self.imageView.alpha = 1.0

            if let toolbar = self.floorplanViewControllerDelegate?.toolbarForFloorplanViewController(self) {
                toolbar.reload()
            }

            dispatch_after_delay(0.25) {
                self.showToolbar()
            }
        }
    }

    func dropPin(_ gestureRecognizer: UIGestureRecognizer) {
        if !newWorkOrderPending {
            let targetView = floorplanIsTiled ? floorplanTiledView : imageView

            let point = gestureRecognizer.location(in: targetView)

            let annotation = Annotation()
            annotation.point = [point.x, point.y]

            newWorkOrderPending = true
            selectedPinView = FloorplanPinView(delegate: self, annotation: annotation)

            targetView.addSubview(selectedPinView)
            targetView.bringSubview(toFront: selectedPinView)

            selectedPinView.frame = CGRect(x: point.x, y: point.y, width: selectedPinView.bounds.width, height: selectedPinView.bounds.height)
            selectedPinView.frame.origin = CGPoint(x: selectedPinView.frame.origin.x - (selectedPinView.frame.size.width / 2.0),
                                                   y: selectedPinView.frame.origin.y - selectedPinView.frame.size.height)
            selectedPinView.alpha = 1.0
            selectedPinView.attachGestureRecognizer()
            pinViews.append(selectedPinView)

            floorplanWorkOrdersViewController?.createWorkOrder(gestureRecognizer)
        }
    }

    fileprivate func setZoomLevel() {
        if let job = job {
            if job.isResidential {
                scrollView.zoomScale = scrollView.minimumZoomScale
            } else if job.isCommercial || job.isPunchlist {
                if floorplanIsTiled {
                    scrollView.minimumZoomScale = 1.0 // CGFloat(floorplan.maxZoomLevel) //1.0 / pow(2.0, CGFloat(floorplan.maxZoomLevel) + 1.0)
                    scrollView.maximumZoomScale = 1.0

                    dispatch_after_delay(0.0) {
                        self.floorplanScrollViewZoomScale = 1.0
                    }
                } else {
                    scrollView.minimumZoomScale = 0.2
                    scrollView.maximumZoomScale = 1.0

                    scrollView.zoomScale = scrollView.minimumZoomScale
                }
            }
        }
    }

    fileprivate func pinViewForWorkOrder(_ workOrder: WorkOrder!) -> FloorplanPinView! {
        var pinView: FloorplanPinView!
        for view in pinViews {
            if let wo = view.workOrder {
                if wo.id == workOrder?.id {
                    pinView = view
                    break
                }
            } else if workOrder.id == 0 && view.annotation.id == 0 && newWorkOrderPending {
                pinView = view
                break
            }
        }
        if pinView == nil {
            if let annotations = workOrder.annotations {
                if annotations.count > 0 {
                    if let annotation = annotations.first {
                        if annotation.point != nil {
                            pinView = FloorplanPinView(delegate: self, annotation: annotation)
                        }
                    }
                }
            }
        }
        return pinView
    }

    fileprivate func removePinViews() {
        for view in pinViews {
            view.removeFromSuperview()
        }

        pinViews = [FloorplanPinView]()
    }

    fileprivate func refreshAnnotations() {
        if let floorplan = floorplan {
            if let annotations = floorplan.annotations {
                for annotation in annotations {
                    if annotation.point != nil {
                        let pinView = FloorplanPinView(delegate: self, annotation: annotation)
                        pinView.category = annotation.workOrder?.category

                        if let size = sizeForFloorplanWorkOrdersViewController(floorplanWorkOrdersViewController) {
                            pinView.frame = CGRect(x: annotation.point[0] * size.width,
                                                   y: annotation.point[1] * size.height,
                                                   width: pinView.bounds.width,
                                                   height: pinView.bounds.height)

                            pinView.frame.origin = CGPoint(x: pinView.frame.origin.x - (pinView.frame.size.width / 2.0),
                                                           y: pinView.frame.origin.y - pinView.frame.size.height)
                            pinView.alpha = 1.0

                            let targetView = floorplanIsTiled ? floorplanTiledView : imageView
                            targetView.addSubview(pinView)
                            targetView.bringSubview(toFront: pinView)

                            pinView.attachGestureRecognizer()
                            pinViews.append(pinView)
                        }
                    }
                }
            }

            dispatch_after_delay(0.0) {
                if let inProgressWorkOrder = WorkOrderService.sharedService().inProgressWorkOrder {
                    for workOrder in floorplan.workOrders {
                        if workOrder.id == inProgressWorkOrder.id {
                            self.openWorkOrder(inProgressWorkOrder)
                            break
                        }
                    }
                }
            }
        }
    }

    fileprivate func hideToolbar() {
        floorplanViewControllerDelegate?.hideToolbarForFloorplanViewController(self)
    }

    fileprivate func showToolbar() {
        floorplanViewControllerDelegate?.showToolbarForFloorplanViewController(self)
    }

    func cancelSetScale(_ sender: UIBarButtonItem) {
        let _ = scaleView.resignFirstResponder(false)
        restoreCachedNavigationItem()
    }

    func setScale(_ sender: UIBarButtonItem!) {
//        let scale = scaleView.scale
//        scaleView.resignFirstResponder(false)
//
//        restoreCachedNavigationItem()
//
//        if let floorplan = floorplan {
//            var metadata = floorplan.metadata.mutableCopy() as! [String : AnyObject]
//            metadata["scale"] = scale
//            floorplan.updateAttachment(["metadata": metadata],
//                onSuccess: { statusCode, mappingResult in
//                    self.toolbar.reload()
//                    self.floorplanViewControllerDelegate?.scaleWasSetForFloorplanViewController(self)
//                }, onError: { error, statusCode, responseString in
//
//                }
//            )
//        }
    }

    func dismissWorkOrderCreationPinView() {
        let _ = selectedPinView?.resignFirstResponder(false)
    }

    fileprivate func overrideNavigationItemForSettingScale(_ setScaleEnabled: Bool = false) {
        cacheNavigationItem(navigationItem)

        let cancelItem = UIBarButtonItem(title: "CANCEL", style: .plain, target: self, action: #selector(FloorplanViewController.cancelSetScale(_:)))
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), for: .disabled)

        let setScaleItem = UIBarButtonItem(title: "SET SCALE", style: .plain, target: self, action: #selector(FloorplanViewController.setScale(_:)))
        setScaleItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        setScaleItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), for: .disabled)
        setScaleItem.isEnabled = setScaleEnabled

        navigationItem.leftBarButtonItems = [cancelItem]
        navigationItem.rightBarButtonItems = [setScaleItem]
    }

    fileprivate func overrideNavigationItemForCreatingWorkOrder(_ setCreateEnabled: Bool = false) {
        cacheNavigationItem(navigationItem)

//        let cancelItem = UIBarButtonItem(title: "CANCEL", style: .Plain, target: self, action: #selector(FloorplanViewController.cancelCreateWorkOrder(_:)))
//        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
//        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Disabled)
//
//        let createWorkOrderItem = UIBarButtonItem(title: "CREATE WORK ORDER", style: .Plain, target: self, action: #selector(FloorplanViewController.createWorkOrder(_:)))
//        createWorkOrderItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
//        createWorkOrderItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Disabled)
//        createWorkOrderItem.enabled = setCreateEnabled
//
//        navigationItem.leftBarButtonItems = [cancelItem]
//        navigationItem.rightBarButtonItems = [createWorkOrderItem]
    }

    fileprivate func cacheNavigationItem(_ navigationItem: UINavigationItem) {
        if cachedNavigationItem == nil {
            cachedNavigationItem = UINavigationItem()
            cachedNavigationItem.leftBarButtonItems = navigationItem.leftBarButtonItems
            cachedNavigationItem.rightBarButtonItems = navigationItem.rightBarButtonItems
            cachedNavigationItem.title = navigationItem.title
            cachedNavigationItem.titleView = navigationItem.titleView
            cachedNavigationItem.prompt = navigationItem.prompt
        }
    }

    fileprivate func restoreCachedNavigationItem() {
        if let cachedNavigationItem = cachedNavigationItem {
            var navigationItem: UINavigationItem!
            if let navigationController = navigationController {
                navigationItem = navigationController.navigationItem
            } else {
                navigationItem = self.navigationItem
            }

            setupNavigationItem()

            navigationItem.leftBarButtonItems = cachedNavigationItem.leftBarButtonItems
            navigationItem.rightBarButtonItems = cachedNavigationItem.rightBarButtonItems
            navigationItem.title = cachedNavigationItem.title
            navigationItem.titleView = cachedNavigationItem.titleView
            navigationItem.prompt = cachedNavigationItem.prompt

            self.cachedNavigationItem = nil

//            if let navigationController = navController {
//                navigationController.setNavigationBarHidden(false, animated: false)
//            }
        }
    }

    // MARK: FloorplanScaleViewDelegate

    func floorplanImageViewForFloorplanScaleView(_ view: FloorplanScaleView) -> UIImageView! {
        return imageView
    }

    func floorplanScaleForFloorplanScaleView(_ view: FloorplanScaleView) -> CGFloat {
        if let floorplanScale = floorplanScale {
            return CGFloat(floorplanScale)
        }

        return 1.0
    }

    func floorplanScaleViewCanSetFloorplanScale(_ view: FloorplanScaleView) {
        overrideNavigationItemForSettingScale(true)
    }

    func floorplanScaleViewDidReset(_ view: FloorplanScaleView) {
        //toolbar?.toggleScaleVisibility()
    }

    func floorplanScaleView(_ view: FloorplanScaleView, didSetScale scale: CGFloat) {
        setScale(nil)
    }

    // MARK: FloorplanScrollViewDelegate

    func floorplanTiledViewForFloorplanScrollView(_ scrollView: FloorplanScrollView) -> FloorplanTiledView! {
        return floorplanTiledView
    }

    // MARK: FloorplanSelectorViewDelegate

    func jobForFloorplanSelectorView(_ selectorView: FloorplanSelectorView) -> Job! {
        return job
    }

    func floorplanSelectorView(_ selectorView: FloorplanSelectorView, didSelectFloorplan floorplan: Floorplan!, atIndexPath indexPath: IndexPath!) {
        if floorplan == nil {
            importFromDropbox()
        } else {
            if let toolbar = floorplanViewControllerDelegate?.toolbarForFloorplanViewController(self) {
                toolbar.presentFloorplanAtIndexPath(indexPath)
            }
        }
    }

    fileprivate func importFromDropbox() {
        presentDropboxChooser()
    }

    fileprivate func presentDropboxChooser() {
        DBChooser.default().open(for: DBChooserLinkTypeDirect, from: self) { results in
            if let results = results {
                for result in results {
                    let sourceURL = (result as! DBChooserResult).link
                    let filename = (result as! DBChooserResult).name
                    if let fileExtension = sourceURL?.pathExtension {
                        if fileExtension.lowercased() == "pdf" {
                            if let job = self.job {
                                let floorplan = Floorplan()
                                floorplan.jobId = job.id
                                floorplan.name = filename
                                floorplan.pdfUrlString = sourceURL?.absoluteString

                                floorplan.save(
                                    { statusCode, mappingResult in
                                        self.job.reloadFloorplans(
                                            { statusCode, mappingResult in
                                                NotificationCenter.default.postNotificationName("FloorplansPageViewControllerDidImportFromDropbox")
                                            },
                                            onError: { error, statusCode, responseString in
                                                
                                            }
                                        )
                                    },
                                    onError: { error, statusCode, responseString in

                                    }
                                )
                            }
                        } else {
                            self.showToast("Invalid file format specified; please choose a valid PDF document.", dismissAfter: 3.0)

                            dispatch_after_delay(3.25) {
                                self.presentDropboxChooser()
                            }
                        }
                    }
                }
            } else {
                print("No file selected for import from Dropbox")
            }
        }
    }

    // MARK: FloorplanThumbnailViewDelegate

    func floorplanThumbnailView(_ view: FloorplanThumbnailView, navigatedToFrame frame: CGRect) {
        let reenableScrolling = enableScrolling
        enableScrolling = false

        let xScale = frame.origin.x / view.frame.width
        let yScale = frame.origin.y / view.frame.height

        let contentSize = scrollView.contentSize
        var visibleFrame = CGRect(x: contentSize.width * xScale,
                                  y: contentSize.height * yScale,
                                  width: scrollView.frame.width,
                                  height: scrollView.frame.height)

        if floorplanIsTiled {
            if floorplanZoomLevel < floorplan.zoomLevels.count {
                if let level = floorplan.zoomLevels[floorplanZoomLevel] as? [String : AnyObject] {
                    let xOffset = CGFloat(level["x"] as! Double) / 2.0
                    let yOffset = CGFloat(level["y"] as! Double) / 2.0

                    visibleFrame = CGRect(x: (contentSize.width + xOffset) * xScale,
                                          y: (contentSize.height + yOffset) * yScale,
                                          width: scrollView.frame.width,
                                          height: scrollView.frame.height)
                }
            }
        }

        scrollView.setContentOffset(visibleFrame.origin, animated: false)

        if reenableScrolling {
            enableScrolling = true
        }
    }

    func floorplanThumbnailViewNavigationBegan(_ view: FloorplanThumbnailView) {
        hideToolbar()
    }

    func floorplanThumbnailViewNavigationEnded(_ view: FloorplanThumbnailView) {
        showToolbar()
    }

    func initialScaleForFloorplanThumbnailView(_ view: FloorplanThumbnailView) -> CGFloat {
        return scrollView.zoomScale / scrollView.maximumZoomScale
    }

    func sizeForFloorplanThumbnailView(_ view: FloorplanThumbnailView) -> CGSize {
        if let size = maxContentSize ?? imageView?.image?.size {
            let aspectRatio = CGFloat(size.width / size.height)
            let height = CGFloat(size.width > size.height ? 225.0 : 375.0)
            let width = aspectRatio * height
            return CGSize(width: width, height: height)
        }
        return CGSize.zero
    }

    func sizeForFloorplanThumbnailImageForFloorplanThumbnailView(_ view: FloorplanThumbnailView) -> CGSize! {
        if floorplanIsTiled {
            if floorplanZoomLevel < floorplan.zoomLevels.count {
                if let level = floorplan.zoomLevels[floorplanZoomLevel] as? [String : AnyObject] {
                    let width = CGFloat(level["width"] as! Double) / 2.0
                    let height = CGFloat(level["height"] as! Double) / 2.0
                    return CGSize(width: width,
                                  height: height)
                }
            }
        }
        return thumbnailView.floorplanImage.size
    }

    func offsetSizeForFloorplanThumbnailView(_ view: FloorplanThumbnailView) -> CGSize {
        if floorplanIsTiled {
            if floorplanZoomLevel < floorplan.zoomLevels.count {
                if let level = floorplan.zoomLevels[floorplanZoomLevel] as? [String : AnyObject] {
                    let xOffset = CGFloat(level["x"] as! Double) / 2.0
                    let yOffset = CGFloat(level["y"] as! Double) / 2.0
                    return CGSize(width: xOffset,
                                  height: yOffset)
                }
            }
        }
        return CGSize.zero
    }

    func setFloorplanSelectorVisibility(_ visible: Bool) {
        let alpha = CGFloat(visible ? 1.0 : 0.0)
        floorplanSelectorView?.redraw(view)
        floorplanSelectorView?.alpha = alpha
        if visible {
            setNavigatorVisibility(false)
            setWorkOrdersVisibility(false)

            thumbnailTintView?.alpha = 0.3
            view.bringSubview(toFront: thumbnailTintView)
            view.bringSubview(toFront: floorplanSelectorView)
        } else {
            thumbnailTintView?.alpha = 0.0
            view.sendSubview(toBack: thumbnailTintView)
        }
    }

    func setNavigatorVisibility(_ visible: Bool) {
        let alpha = CGFloat(visible ? 1.0 : 0.0)
        thumbnailView?.alpha = alpha
        if visible {
            setFloorplanSelectorVisibility(false)
            setWorkOrdersVisibility(false)

            thumbnailTintView?.alpha = 0.3
            view.bringSubview(toFront: thumbnailTintView)
            view.bringSubview(toFront: thumbnailView)
        } else {
            thumbnailTintView?.alpha = 0.0
            view.sendSubview(toBack: thumbnailTintView)
        }
    }

    func setWorkOrdersVisibility(_ visible: Bool, alpha: CGFloat! = nil) {
        let x = visible ? (view.frame.width - floorplanWorkOrdersViewControllerContainer.frame.size.width) : view.frame.width

        if visible {
            setFloorplanSelectorVisibility(false)
            setNavigatorVisibility(false)

            thumbnailTintView?.alpha = 0.2
            view.bringSubview(toFront: thumbnailTintView)
            view.bringSubview(toFront: floorplanWorkOrdersViewControllerContainer)
            insetScrollViewContentForFloorplanWorkOrdersPresentation()
        } else {
            thumbnailTintView?.alpha = 0.0
            scrollView.contentInset = UIEdgeInsets.zero
        }

        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut,
            animations: {
                self.floorplanWorkOrdersViewControllerContainer?.alpha = alpha != nil ? alpha : (visible ? 1.0 : 0.0)
                self.floorplanWorkOrdersViewControllerContainer?.frame.origin.x = x
            },
            completion:  { (completed) in

            }
        )
    }

    fileprivate func insetScrollViewContentForFloorplanWorkOrdersPresentation() {
        if scrollView.contentInset != UIEdgeInsets.zero {
            return
        }

        let widthInset = floorplanWorkOrdersViewControllerContainer.frame.width * 1.25
        let heightInset = widthInset

        scrollView.contentInset = UIEdgeInsets(top: heightInset,
                                               left: widthInset,
                                               bottom: heightInset,
                                               right: widthInset)
    }

    // MARK: FloorplanPinViewDelegate

    func tintColorForFloorplanPinView(_ view: FloorplanPinView) -> UIColor {
        if let workOrder = view.workOrder {
            return workOrder.statusColor
        }
        return UIColor.blue
    }

    func categoryForFloorplanPinView(_ view: FloorplanPinView) -> Category! {
        if let workOrder = view.workOrder {
            return workOrder.category
        }
        return nil
    }

    func floorplanImageViewForFloorplanPinView(_ view: FloorplanPinView) -> UIImageView! {
        if let index = pinViews.indexOfObject(view) {
            if let _ = pinViews[index].delegate {
                return imageView
            } else {
                return nil
            }
        } else {
            return imageView
        }
    }

    func floorplanPinViewWasSelected(_ view: FloorplanPinView) {
        var delay = 0.0

        if selectedPinView != nil && selectedPinView == view {
            if let toolbar = floorplanViewControllerDelegate?.toolbarForFloorplanViewController(self) {
                toolbar.setWorkOrdersVisibility(false, alpha: 0.0)
            }

            if let workOrder = view.workOrder {
                floorplanViewControllerShouldFocusOnWorkOrder(workOrder, forFloorplanWorkOrdersViewController: floorplanWorkOrdersViewController)
            }

            return
        } else {
            if let toolbar = floorplanViewControllerDelegate?.toolbarForFloorplanViewController(self) {
                toolbar.setWorkOrdersVisibility(false, alpha: 0.0)
            }
            delay = 0.15
        }

        selectedPinView = view

        if let workOrder = view.workOrder {
            dispatch_after_delay(delay) {
                self.openWorkOrder(workOrder, fromPinView: view, delay: delay)
            }
        }
    }

    fileprivate func openWorkOrder(_ workOrder: WorkOrder, fromPinView pinView: FloorplanPinView! = nil, delay: Double = 0.0) {
        floorplanWorkOrdersViewController?.openWorkOrder(workOrder)
        if let toolbar = floorplanViewControllerDelegate?.toolbarForFloorplanViewController(self) {
            dispatch_after_delay(delay) {
                toolbar.setWorkOrdersVisibility(true)
            }
        } else {
            dispatch_after_delay(delay) {
                self.setWorkOrdersVisibility(true)
            }
        }
    }

    fileprivate func hidePinViews(_ excludedPin: FloorplanPinView! = nil, alpha: CGFloat = 0.2) {
        for pinView in pinViews {
            if excludedPin == nil || pinView != excludedPin {
                pinView.alpha = alpha
                pinView.isUserInteractionEnabled = false
            }
        }
    }

    fileprivate func showPinViews() {
        for pinView in pinViews {
            pinView.alpha = 1.0
            pinView.isUserInteractionEnabled = true
        }
    }

    // MARK: UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if enableScrolling {
            thumbnailView?.scrollViewDidScroll(scrollView)
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if floorplanIsTiled {
            var viewForZooming: UIView?
            for floorplanTiledView in floorplanTiledViews {
                if floorplanTiledView == self.floorplanTiledView {
                    floorplanTiledView.alpha = 1.0

                    viewForZooming = floorplanTiledView
                } else {
                    floorplanTiledView.alpha = 0.0
                }
            }
            return viewForZooming
        }
        return imageView
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        hideToolbar()
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        thumbnailView?.scrollViewDidZoom(scrollView)

        floorplanScrollViewZoomScale = scrollView.zoomScale / scrollView.maximumZoomScale

        for pinView in pinViews {
            pinView.setScale(scrollView.zoomScale / scrollView.maximumZoomScale)
        }
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if floorplanIsTiled {
            //floorplanTiledView?.scrollViewDidZoom(scrollView)
        } else {
            if let imageView = imageView {
                let size = maxContentSize ?? imageView.image!.size
                let width = size.width * scale
                let height = size.height * scale
                imageView.frame.size = CGSize(width: width, height: height)
                scrollView.contentSize = maxContentSize ?? CGSize(width: width, height: height)
            }
        }

        showToolbar()
    }

    // MARK: FloorplanWorkOrdersViewControllerDelegate

    func floorplanForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) -> Floorplan! {
        return floorplan
    }

    func floorplanWorkOrdersViewControllerDismissedPendingWorkOrder(_ viewController: FloorplanWorkOrdersViewController) {
        newWorkOrderPending = false
    }

    func floorplanViewControllerShouldRedrawAnnotationPinsForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) {
        if !initializedAnnotations {
            initializedAnnotations = true
            if let floorplanWorkOrdersViewControllerContainer = floorplanWorkOrdersViewControllerContainer {
                if floorplanWorkOrdersViewControllerContainer.alpha == 0.0 {
                    dispatch_after_delay(0.0) {
                        floorplanWorkOrdersViewControllerContainer.frame.origin.x = self.view.frame.width
                        //floorplanWorkOrdersViewControllerContainer.alpha = 1.0
                    }
                }
            }
        }

        refreshAnnotations()
    }

    func floorplanViewControllerStartedReloadingAnnotationsForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) {
        loadingAnnotations = true
    }

    func floorplanViewControllerStoppedReloadingAnnotationsForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) {
        loadingAnnotations = false
    }

    func floorplanViewControllerShouldDeselectPinForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) {
        selectedPinView = nil
    }

    func floorplanViewControllerShouldDeselectPolygonForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) {
        selectedPolygonView = nil
    }

    func floorplanViewControllerShouldReloadToolbarForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) {
        //toolbar?.reload()
    }

    func jobForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) -> Job! {
        return job
    }

    func selectedPinViewForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) -> FloorplanPinView! {
        return selectedPinView
    }

    func selectedPolygonViewForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) -> FloorplanPolygonView! {
        return selectedPolygonView
    }

    func sizeForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) -> CGSize! {
        if floorplanIsTiled && floorplanTiledView != nil {
            if let level = floorplan?.zoomLevels?[floorplanTiledView.zoomLevel ?? 0] as? [String : AnyObject] {
                return CGSize(width: level["width"] as! Double,
                              height: level["height"] as! Double)
            }
        } else if let image = imageView?.image {
            return image.size
        }
        return nil
    }

    func floorplanViewControllerShouldRemovePinView(_ pinView: FloorplanPinView, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) {
        if let index = pinViews.indexOfObject(pinView) {
            pinViews.remove(at: index)
            selectedPinView.removeFromSuperview()
        }
    }

    func floorplanViewControllerShouldFocusOnWorkOrder(_ workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) {
        if let pinView = pinViewForWorkOrder(workOrder) {
            dispatch_after_delay(0.0) {
                UIView.animate(withDuration: 0.2, delay: 0.2, options: .curveEaseOut,
                    animations: {
                        self.scrollView.zoom(to: pinView.frame, animated: false)

                        let offsetX = (self.floorplanWorkOrdersViewControllerContainer.frame.width / 2.0) - (pinView.frame.width / 2.0)
                        self.scrollView.contentOffset.x += offsetX
                    },
                    completion: { completed in
                        if let toolbar = self.floorplanViewControllerDelegate?.toolbarForFloorplanViewController(self) {
                            toolbar.setWorkOrdersVisibility(true)
                        }
                    }
                )
            }

            if selectedPinView == nil {
                selectedPinView = pinView
            }
        }
    }

    func pinViewForWorkOrder(_ workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) -> FloorplanPinView! {
        return pinViewForWorkOrder(workOrder)
    }

    func polygonViewForWorkOrder(_ workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) -> FloorplanPolygonView! {
        return nil
    }

    func floorplanViewControllerShouldDismissWorkOrderCreationAnnotationViewsForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) {
        self.dismissWorkOrderCreationPinView()
    }

    func previewImageForWorkOrder(_ workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) -> UIImage! {
        let pinView = pinViewForWorkOrder(workOrder)

        if workOrder.previewImage == nil { // FIXME!!! This has to get moved
            if let pinView = pinView {
                if let overlayViewBoundingBox = pinView.overlayViewBoundingBox {
                    if let floorplanImageView = imageView {
                        if let previewImage = floorplanImageView.image?.crop(overlayViewBoundingBox) {
                            let previewView = UIImageView(image: previewImage)
                            if let annotation = pinView.annotation {
                                let pin = FloorplanPinView(annotation: annotation)
                                pin.delegate = self
                                previewView.addSubview(pin)
                                previewView.bringSubview(toFront: pin)
                                pin.alpha = 1.0
                                if let sublayers = pin.layer.sublayers {
                                    for sublayer in sublayers {
                                        sublayer.position.x -= overlayViewBoundingBox.origin.x
                                        sublayer.position.y -= overlayViewBoundingBox.origin.y
                                    }
                                }

                                workOrder.previewImage = previewView.toImage()
                            }
                        }
                    }
                }
            }
        }

        return nil
    }

    // MARK: UIPopoverPresentationControllerDelegate

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        if let presentedViewController = (controller.presentedViewController as? UINavigationController)?.viewControllers.first {
            if presentedViewController.isKind(of: ProductPickerViewController.self) {
                return .none
            }
        }


        return .currentContext
    }

    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {

    }

    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {

    }

    deinit {
        for floorplanTiledView in floorplanTiledViews {
            floorplanTiledView.removeFromSuperview()
        }

        imageView?.removeFromSuperview()
        thumbnailView?.removeFromSuperview()

        NotificationCenter.default.removeObserver(self)
    }
}
