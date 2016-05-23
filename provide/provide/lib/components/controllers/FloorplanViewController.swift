//
//  FloorplanViewController.swift
//  provide
//
//  Created by Kyle Thomas on 10/23/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol FloorplanViewControllerDelegate: NSObjectProtocol {
    func floorplanForFloorplanViewController(viewController: FloorplanViewController) -> Floorplan!
    func jobForFloorplanViewController(viewController: FloorplanViewController) -> Job!
    func floorplanImageForFloorplanViewController(viewController: FloorplanViewController) -> UIImage!
    func modeForFloorplanViewController(viewController: FloorplanViewController) -> FloorplanViewController.Mode!
    func scaleCanBeSetByFloorplanViewController(viewController: FloorplanViewController) -> Bool
    func scaleWasSetForFloorplanViewController(viewController: FloorplanViewController)
    func newWorkOrderCanBeCreatedByFloorplanViewController(viewController: FloorplanViewController) -> Bool
    func areaSelectorIsAvailableForFloorplanViewController(viewController: FloorplanViewController) -> Bool
    func navigationControllerForFloorplanViewController(viewController: FloorplanViewController) -> UINavigationController!
    func floorplanViewControllerCanDropWorkOrderPin(viewController: FloorplanViewController) -> Bool
    func toolbarForFloorplanViewController(viewController: FloorplanViewController) -> FloorplanToolbar!
    func hideToolbarForFloorplanViewController(viewController: FloorplanViewController)
    func showToolbarForFloorplanViewController(viewController: FloorplanViewController)
}

class FloorplanViewController: WorkOrderComponentViewController,
                               UIScrollViewDelegate,
                               FloorplanScaleViewDelegate,
                               FloorplanSelectorViewDelegate,
                               FloorplanThumbnailViewDelegate,
                               FloorplanPinViewDelegate,
                               FloorplanWorkOrdersViewControllerDelegate,
                               UIPopoverPresentationControllerDelegate {

    enum Mode {
        case Setup, WorkOrders
        static let allValues = [Setup, WorkOrders]
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

    private var mode: Mode {
        if let floorplanViewControllerDelegate = floorplanViewControllerDelegate {
            if let mode = floorplanViewControllerDelegate.modeForFloorplanViewController(self) {
                return mode
            }
        }
        return .Setup
    }

    private var floorplanSelectorView: FloorplanSelectorView!
    private var thumbnailView: FloorplanThumbnailView!
    private var thumbnailTintView: UIView!

    private var imageView: UIImageView!
    private var floorplanTiledView: FloorplanTiledView!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var progressView: UIProgressView! {
        didSet {
            if let progressView = progressView {
                progressView.setProgress(0.0, animated: false)
            }
        }
    }

    @IBOutlet private weak var scrollView: FloorplanScrollView!

    @IBOutlet private weak var scaleView: FloorplanScaleView! {
        didSet {
            if let scaleView = scaleView {
                scaleView.delegate = self
                scaleView.backgroundColor = UIColor.whiteColor()
                scaleView.clipsToBounds = true
                scaleView.roundCorners(5.0)
            }
        }
    }

    private var pinViews = [FloorplanPinView]()

    private var selectedPinView: FloorplanPinView! {
        didSet {
            if selectedPinView == nil {
                showPinViews()
            } else if selectedPinView != nil {
                hidePinViews(selectedPinView)
            }
        }
    }
    private var selectedPolygonView: FloorplanPolygonView!

    @IBOutlet private weak var floorplanWorkOrdersViewControllerContainer: UIView!
    private var floorplanWorkOrdersViewController: FloorplanWorkOrdersViewController!

    var floorplan: Floorplan!

    var floorplanImageUrl: NSURL! {
        if let floorplan = floorplan {
            return floorplan.imageUrl
        }
        return nil
    }

    var floorplanScale: Float! {
        if let floorplan = floorplan {
            return Float(floorplan.scale)
        }
        return nil
    }

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

    private var backsplashProductPickerViewController: ProductPickerViewController!

    private var enableScrolling = false {
        didSet {
            if let scrollView = scrollView {
                scrollView.scrollEnabled = enableScrolling
            }
        }
    }

    private var hiddenNavigationControllerFrame: CGRect {
        return CGRect(
            x: 0.0,
            y: targetView.frame.height,
            width: targetView.frame.width,
            height: targetView.frame.height // / 1.333
        )
    }

    private var cachedNavigationItem: UINavigationItem!

    private var loadedFloorplan = false
    private var initializedAnnotations = false

    private var loadingFloorplan = false {
        didSet {
            if !loadingFloorplan && !loadingAnnotations {
                activityIndicatorView.stopAnimating()
            } else if !activityIndicatorView.isAnimating() {
                if loadingFloorplan == true && oldValue == false {
                    progressView?.setProgress(0.0, animated: false)
                }
                activityIndicatorView.startAnimating()
            }
        }
    }

    private var loadingAnnotations = false {
        didSet {
            if !loadingFloorplan && !loadingAnnotations {
                activityIndicatorView?.stopAnimating()
                progressView?.hidden = true
            } else if !activityIndicatorView.isAnimating() {
                activityIndicatorView?.startAnimating()
            }
        }
    }

    private var loadingMaterials = false {
        didSet {
            if !loadingFloorplan && !loadingAnnotations && !loadingMaterials {
                activityIndicatorView.stopAnimating()
                progressView?.hidden = true
            } else if !activityIndicatorView.isAnimating() {
                activityIndicatorView.startAnimating()
            }
        }
    }

    private var newWorkOrderPending = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()

        let floorplanSelectorViewController = UIStoryboard("Floorplan").instantiateViewControllerWithIdentifier("FloorplanSelectorViewController") as! FloorplanSelectorViewController
        floorplanSelectorView = floorplanSelectorViewController.selectorView
        floorplanSelectorView.delegate = self
        view.addSubview(floorplanSelectorView)

        let floorplanThumbnailViewController = UIStoryboard("Floorplan").instantiateViewControllerWithIdentifier("FloorplanThumbnailViewController") as! FloorplanThumbnailViewController
        thumbnailView = floorplanThumbnailViewController.thumbnailView
        thumbnailView.delegate = self
        view.addSubview(thumbnailView)

        dispatch_after_delay(0.0) {
            let size = max(self.view.bounds.width, self.view.bounds.height)
            self.thumbnailTintView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: size, height: size))
            self.thumbnailTintView.backgroundColor = UIColor.blackColor()
            self.thumbnailTintView.alpha = 0.0
            self.view.addSubview(self.thumbnailTintView)
            self.view.sendSubviewToBack(self.thumbnailTintView)
            self.thumbnailTintView?.userInteractionEnabled = false
        }

        imageView = UIImageView()
        imageView.alpha = 0.0
        imageView.userInteractionEnabled = true
        imageView.contentMode = .ScaleToFill

        floorplanTiledView = FloorplanTiledView()
        floorplanTiledView.alpha = 0.0
        floorplanTiledView.userInteractionEnabled = true

        scrollView?.backgroundColor = UIColor.whiteColor()
        scrollView?.addSubview(imageView)
        scrollView?.bringSubviewToFront(imageView)

        scrollView?.addSubview(floorplanTiledView)
        scrollView?.bringSubviewToFront(floorplanTiledView)

        activityIndicatorView?.startAnimating()

        if floorplanViewControllerDelegate != nil && !loadedFloorplan && !loadingFloorplan && scrollView != nil {
            loadFloorplan()
        }

        NSNotificationCenter.defaultCenter().addObserverForName("WorkOrderChanged") { notification in
            if let workOrder = notification.object as? WorkOrder {
                if let floorplan = self.floorplan {
                    for annotation in floorplan.annotations {
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

        NSNotificationCenter.defaultCenter().addObserverForName("FloorplanChanged") { notification in
            if let floorplan = notification.object as? Floorplan {
                if let f = self.floorplan {
                    if floorplan.id == f.id {
                        self.floorplan = floorplan
                        if !self.loadedFloorplan {
                            self.loadFloorplan()
                        }
                    }
                }
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "FloorplanWorkOrdersViewControllerSegue" {
            let navigationController = segue.destinationViewController as! UINavigationController
            floorplanWorkOrdersViewController = navigationController.viewControllers.first! as! FloorplanWorkOrdersViewController
            floorplanWorkOrdersViewController.delegate = self
        }
    }

    func teardown() -> UIImage? {
        let image = imageView?.image
        imageView?.image = nil
        thumbnailView?.floorplanImage = nil
        loadedFloorplan = false
        return image
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        coordinator.animateAlongsideTransition(
            { context in
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

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    private var isManagedByWorkOrdersViewController: Bool {
        if let navigationController = navigationController {
            return navigationController.viewControllers.first!.isKindOfClass(WorkOrdersViewController)
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
            targetView.bringSubviewToFront(navigationController.view)

            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
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

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
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

    private func loadFloorplan() {
        //renderTiledFloorplan()
        //return

        if let url = floorplanImageUrl {
            loadingFloorplan = true

            ImageService.sharedService().fetchImage(url, cacheOnDisk: true,
                onDownloadSuccess: { [weak self] image in
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
                            self!.progressView?.hidden = false

                            let percentage: Float = Float(receivedSize) / Float(expectedSize)
                            self!.progressView?.setProgress(percentage, animated: true)
                        }
                    }
                }
            )
        }
    }

    private func renderTiledFloorplan() {
        if floorplan.maxZoomLevel == -1 {
            return
        }

        ImageService.sharedService().fetchImage(floorplan.imageUrl, cacheOnDisk: true,
                                                onDownloadSuccess: { [weak self] image in
                                                    dispatch_async_main_queue {
                                                        self!.activityIndicatorView?.stopAnimating()
                                                        self!.progressView?.setProgress(1.0, animated: false)

                                                        let size = CGSize(width: image.size.width, height: image.size.height)

                                                        self!.floorplanTiledView.frame = CGRect(origin: CGPointZero, size: size)
                                                        self!.floorplanTiledView.backgroundColor = UIColor.clearColor()
                                                        self!.floorplanTiledView.floorplan = self!.floorplan
                                                        self!.floorplanTiledView.setNeedsDisplay()
                                                        //floorplanTiledView.image = image

                                                        //        let floorplanTiledLayer = floorplanTiledView.layer as! CATiledLayer
                                                        //        floorplanTiledLayer.bounds = CGRect(origin: CGPointZero, size: size)
                                                        //        floorplanTiledLayer.frame = floorplanTiledLayer.bounds

//                                                        if let urlString = self!.floorplan.imageUrlString72dpi {
//                                                            ImageService.sharedService().fetchImage(NSURL(urlString), cacheOnDisk: true,
//                                                                onDownloadSuccess: { [weak self] image in
//                                                                    dispatch_async_main_queue {
//                                                                        self!.thumbnailView?.floorplanImage = image
//                                                                    }
//                                                                },
//                                                                onDownloadFailure: { error in
//                                                                    logWarn("Floorplan thumbnail image download failed; \(error)")
//                                                                },
//                                                                onDownloadProgress: { receivedSize, expectedSize in
//
//                                                                }
//                                                            )
//                                                        }

                                                        self!.scrollView.scrollEnabled = false
                                                        self!.scrollView.contentSize = size
                                                        
                                                        self!.enableScrolling = true
                                                        
                                                        self!.loadingFloorplan = false
                                                        self!.loadedFloorplan = true
                                                        
                                                        if let canDropWorkOrderPin = self!.floorplanViewControllerDelegate?.floorplanViewControllerCanDropWorkOrderPin(self!) {
                                                            if canDropWorkOrderPin {
                                                                let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(FloorplanViewController.dropPin(_:)))
                                                                //                imageView.addGestureRecognizer(gestureRecognizer)
                                                            }
                                                        }
                                                        
                                                        self!.progressView?.hidden = true
                                                        
                                                        if let _ = self!.presentedViewController {
                                                            self!.dismissViewController(animated: true)
                                                        }
                                                        
                                                        dispatch_after_delay(0.0) {
                                                            self!.setZoomLevel()
                                                            self!.floorplanTiledView.alpha = 1.0
                                                            
                                                            if let toolbar = self!.floorplanViewControllerDelegate?.toolbarForFloorplanViewController(self!) {
                                                                toolbar.reload()
                                                            }
                                                            
                                                            dispatch_after_delay(0.25) {
                                                                self!.showToolbar()
                                                            }
                                                        }
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
                                                            self!.progressView?.hidden = false
                                                            
                                                            let percentage: Float = Float(receivedSize) / Float(expectedSize)
                                                            self!.progressView?.setProgress(percentage, animated: true)
                                                        }
                                                    }
            }
        )

    }

    private func setFloorplanImage(image: UIImage) {
        let size = CGSize(width: image.size.width, height: image.size.height)

        imageView!.image = image
        imageView!.frame = CGRect(origin: CGPointZero, size: size)

        thumbnailView?.floorplanImage = image

        scrollView.scrollEnabled = false
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

        self.progressView?.hidden = true

        if let _ = presentedViewController {
            dismissViewController(animated: true)
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

    func dropPin(gestureRecognizer: UIGestureRecognizer) {
        if !newWorkOrderPending {
            let point = gestureRecognizer.locationInView(imageView)

            let annotation = Annotation()
            annotation.point = [point.x, point.y]

            newWorkOrderPending = true
            selectedPinView = FloorplanPinView(delegate: self, annotation: annotation)

            imageView.addSubview(selectedPinView)
            imageView.bringSubviewToFront(selectedPinView)
            selectedPinView.frame = CGRect(x: point.x, y: point.y, width: selectedPinView.bounds.width, height: selectedPinView.bounds.height)
            selectedPinView.frame.origin = CGPoint(x: selectedPinView.frame.origin.x - (selectedPinView.frame.size.width / 2.0),
                                                   y: selectedPinView.frame.origin.y - selectedPinView.frame.size.height)
            selectedPinView.alpha = 1.0
            selectedPinView.attachGestureRecognizer()
            pinViews.append(selectedPinView)

            floorplanWorkOrdersViewController?.createWorkOrder(gestureRecognizer)
        }
    }

    private func setZoomLevel() {
        if let job = job {
            if job.isResidential {
                scrollView.zoomScale = scrollView.minimumZoomScale
            } else if job.isCommercial || job.isPunchlist {
                scrollView.minimumZoomScale = 0.2
                scrollView.maximumZoomScale = 1.0

                scrollView.zoomScale = scrollView.maximumZoomScale / 2.0
            }
        }
    }

    private func pinViewForWorkOrder(workOrder: WorkOrder!) -> FloorplanPinView! {
        var pinView: FloorplanPinView!
        for view in pinViews {
            if let wo = view.workOrder {
                if wo.id == workOrder?.id {
                    pinView = view
                    break
                }
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

    private func removePinViews() {
        for view in pinViews {
            view.removeFromSuperview()
        }

        pinViews = [FloorplanPinView]()
    }

    private func refreshAnnotations() {
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

                            imageView.addSubview(pinView)
                            imageView.bringSubviewToFront(pinView)

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

    private func hideToolbar() {
        floorplanViewControllerDelegate?.hideToolbarForFloorplanViewController(self)
    }

    private func showToolbar() {
        floorplanViewControllerDelegate?.showToolbarForFloorplanViewController(self)
    }

    func cancelSetScale(sender: UIBarButtonItem) {
        scaleView.resignFirstResponder(false)
        restoreCachedNavigationItem()
    }

    func setScale(sender: UIBarButtonItem!) {
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
        selectedPinView?.resignFirstResponder(false)
    }

    private func overrideNavigationItemForSettingScale(setScaleEnabled: Bool = false) {
        cacheNavigationItem(navigationItem)

        let cancelItem = UIBarButtonItem(title: "CANCEL", style: .Plain, target: self, action: #selector(FloorplanViewController.cancelSetScale(_:)))
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Disabled)

        let setScaleItem = UIBarButtonItem(title: "SET SCALE", style: .Plain, target: self, action: #selector(FloorplanViewController.setScale(_:)))
        setScaleItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        setScaleItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Disabled)
        setScaleItem.enabled = setScaleEnabled

        navigationItem.leftBarButtonItems = [cancelItem]
        navigationItem.rightBarButtonItems = [setScaleItem]
    }

    private func overrideNavigationItemForCreatingWorkOrder(setCreateEnabled: Bool = false) {
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

    private func cacheNavigationItem(navigationItem: UINavigationItem) {
        if cachedNavigationItem == nil {
            cachedNavigationItem = UINavigationItem()
            cachedNavigationItem.leftBarButtonItems = navigationItem.leftBarButtonItems
            cachedNavigationItem.rightBarButtonItems = navigationItem.rightBarButtonItems
            cachedNavigationItem.title = navigationItem.title
            cachedNavigationItem.titleView = navigationItem.titleView
            cachedNavigationItem.prompt = navigationItem.prompt
        }
    }

    private func restoreCachedNavigationItem() {
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

    func floorplanImageViewForFloorplanScaleView(view: FloorplanScaleView) -> UIImageView! {
        return imageView
    }

    func floorplanScaleForFloorplanScaleView(view: FloorplanScaleView) -> CGFloat {
        if let floorplanScale = floorplanScale {
            return CGFloat(floorplanScale)
        }

        return 1.0
    }

    func floorplanScaleViewCanSetFloorplanScale(view: FloorplanScaleView) {
        overrideNavigationItemForSettingScale(true)
    }

    func floorplanScaleViewDidReset(view: FloorplanScaleView) {
        //toolbar?.toggleScaleVisibility()
    }

    func floorplanScaleView(view: FloorplanScaleView, didSetScale scale: CGFloat) {
        setScale(nil)
    }

    // MARK: floorplanSelectorViewDelegate

    func jobForFloorplanSelectorView(selectorView: FloorplanSelectorView) -> Job! {
        return job
    }

    func floorplanSelectorView(selectorView: FloorplanSelectorView, didSelectFloorplan floorplan: Floorplan!, atIndexPath indexPath: NSIndexPath!) {
        if floorplan == nil {
            importFromDropbox()
        } else {
            if let toolbar = floorplanViewControllerDelegate?.toolbarForFloorplanViewController(self) {
                toolbar.presentFloorplanAtIndexPath(indexPath)
            }
        }
    }

    private func importFromDropbox() {
        presentDropboxChooser()
    }

    private func presentDropboxChooser() {
        DBChooser.defaultChooser().openChooserForLinkType(DBChooserLinkTypeDirect, fromViewController: self) { results in
            if let results = results {
                for result in results {
                    let sourceURL = (result as! DBChooserResult).link
                    let filename = (result as! DBChooserResult).name
                    if let fileExtension = sourceURL.pathExtension {
                        if fileExtension.lowercaseString == "pdf" {
                            if let job = self.job {
                                let floorplan = Floorplan()
                                floorplan.jobId = job.id
                                floorplan.name = filename
                                floorplan.pdfUrlString = sourceURL.absoluteString

                                floorplan.save(
                                    onSuccess: { statusCode, mappingResult in
                                        self.job.reloadFloorplans(
                                            { statusCode, mappingResult in
                                                NSNotificationCenter.defaultCenter().postNotificationName("FloorplansPageViewControllerDidImportFromDropbox")
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

    func floorplanThumbnailView(view: FloorplanThumbnailView, navigatedToFrame frame: CGRect) {
        let reenableScrolling = enableScrolling
        enableScrolling = false

        let xScale = frame.origin.x / view.frame.width
        let yScale = frame.origin.y / view.frame.height

        let contentSize = scrollView.contentSize
        let visibleFrame = CGRect(x: contentSize.width * xScale,
                                  y: contentSize.height * yScale,
                                  width: scrollView.frame.width,
                                  height: scrollView.frame.height)

        scrollView.setContentOffset(visibleFrame.origin, animated: false)

        if reenableScrolling {
            enableScrolling = true
        }
    }

    func floorplanThumbnailViewNavigationBegan(view: FloorplanThumbnailView) {
        hideToolbar()
    }

    func floorplanThumbnailViewNavigationEnded(view: FloorplanThumbnailView) {
        showToolbar()
    }

    func initialScaleForFloorplanThumbnailView(view: FloorplanThumbnailView) -> CGFloat {
        return scrollView.minimumZoomScale
    }

    func sizeForFloorplanThumbnailView(view: FloorplanThumbnailView) -> CGSize {
        if let imageView = imageView {
            if let image = imageView.image {
                let imageSize = image.size
                let aspectRatio = CGFloat(imageSize.width / imageSize.height)
                let height = CGFloat(imageSize.width > imageSize.height ? 225.0 : 375.0)
                let width = aspectRatio * height
                return CGSize(width: width, height: height)
            }
        }
        return CGSizeZero
    }

    func setFloorplanSelectorVisibility(visible: Bool) {
        let alpha = CGFloat(visible ? 1.0 : 0.0)
        floorplanSelectorView?.redraw(view)
        floorplanSelectorView?.alpha = alpha
        if visible {
            setNavigatorVisibility(false)
            setWorkOrdersVisibility(false)

            thumbnailTintView?.alpha = 0.3
            view.bringSubviewToFront(thumbnailTintView)
            view.bringSubviewToFront(floorplanSelectorView)
        } else {
            thumbnailTintView?.alpha = 0.0
            view.sendSubviewToBack(thumbnailTintView)
        }
    }

    func setNavigatorVisibility(visible: Bool) {
        let alpha = CGFloat(visible ? 1.0 : 0.0)
        thumbnailView?.alpha = alpha
        if visible {
            setFloorplanSelectorVisibility(false)
            setWorkOrdersVisibility(false)

            thumbnailTintView?.alpha = 0.3
            view.bringSubviewToFront(thumbnailTintView)
            view.bringSubviewToFront(thumbnailView)
        } else {
            thumbnailTintView?.alpha = 0.0
            view.sendSubviewToBack(thumbnailTintView)
        }
    }

    func setWorkOrdersVisibility(visible: Bool, alpha: CGFloat! = nil) {
        let x = visible ? (view.frame.width - floorplanWorkOrdersViewControllerContainer.frame.size.width) : view.frame.width

        if visible {
            setFloorplanSelectorVisibility(false)
            setNavigatorVisibility(false)

            thumbnailTintView?.alpha = 0.2
            view.bringSubviewToFront(thumbnailTintView)
            view.bringSubviewToFront(floorplanWorkOrdersViewControllerContainer)
            insetScrollViewContentForFloorplanWorkOrdersPresentation()
        } else {
            thumbnailTintView?.alpha = 0.0
            scrollView.contentInset = UIEdgeInsetsZero
        }

        UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.floorplanWorkOrdersViewControllerContainer?.alpha = alpha != nil ? alpha : (visible ? 1.0 : 0.0)
                self.floorplanWorkOrdersViewControllerContainer?.frame.origin.x = x
            },
            completion:  { (completed) in

            }
        )
    }

    private func insetScrollViewContentForFloorplanWorkOrdersPresentation() {
        if scrollView.contentInset != UIEdgeInsetsZero {
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

    func tintColorForFloorplanPinView(view: FloorplanPinView) -> UIColor {
        if let workOrder = view.workOrder {
            return workOrder.statusColor
        }
        return UIColor.blueColor()
    }

    func categoryForFloorplanPinView(view: FloorplanPinView) -> Category! {
        if let workOrder = view.workOrder {
            return workOrder.category
        }
        return nil
    }

    func floorplanImageViewForFloorplanPinView(view: FloorplanPinView) -> UIImageView! {
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

    func floorplanPinViewWasSelected(view: FloorplanPinView) {
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

    private func openWorkOrder(workOrder: WorkOrder, fromPinView pinView: FloorplanPinView! = nil, delay: Double = 0.0) {
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

    private func hidePinViews(excludedPin: FloorplanPinView! = nil) {
        for pinView in pinViews {
            if excludedPin == nil || pinView != excludedPin {
                pinView.alpha = 0.2
                pinView.userInteractionEnabled = false
            }
        }
    }

    private func showPinViews() {
        for pinView in pinViews {
            pinView.alpha = 1.0
            pinView.userInteractionEnabled = true
        }
    }

    // MARK: UIScrollViewDelegate

    func scrollViewDidScroll(scrollView: UIScrollView) {
        if enableScrolling {
            thumbnailView?.scrollViewDidScroll(scrollView)
        }
    }

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
        hideToolbar()
    }

    func scrollViewDidZoom(scrollView: UIScrollView) {
        thumbnailView?.scrollViewDidZoom(scrollView)

        for pinView in pinViews {
            pinView.setScale(scrollView.zoomScale)
        }
    }

    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        if let imageView = imageView {
            let size = imageView.image!.size
            let width = size.width * scale
            let height = size.height * scale
            imageView.frame.size = CGSize(width: width, height: height)
            scrollView.contentSize = CGSize(width: width, height: height)

            showToolbar()
        }
    }

    // MARK: FloorplanWorkOrdersViewControllerDelegate

    func floorplanForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) -> Floorplan! {
        return floorplan
    }

    func floorplanWorkOrdersViewControllerDismissedPendingWorkOrder(viewController: FloorplanWorkOrdersViewController) {
        newWorkOrderPending = false
    }

    func floorplanViewControllerShouldRedrawAnnotationPinsForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) {
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

    func floorplanViewControllerStartedReloadingAnnotationsForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) {
        loadingAnnotations = true
    }

    func floorplanViewControllerStoppedReloadingAnnotationsForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) {
        loadingAnnotations = false
    }

    func floorplanViewControllerShouldDeselectPinForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) {
        selectedPinView = nil
    }

    func floorplanViewControllerShouldDeselectPolygonForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) {
        selectedPolygonView = nil
    }

    func floorplanViewControllerShouldReloadToolbarForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) {
        //toolbar?.reload()
    }

    func jobForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) -> Job! {
        return job
    }

    func selectedPinViewForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) -> FloorplanPinView! {
        return selectedPinView
    }

    func selectedPolygonViewForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) -> FloorplanPolygonView! {
        return selectedPolygonView
    }

    func sizeForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) -> CGSize! {
        if let image = imageView?.image {
            return image.size
        }
        return nil
    }

    func floorplanViewControllerShouldRemovePinView(pinView: FloorplanPinView, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) {
        if let index = pinViews.indexOfObject(pinView) {
            pinViews.removeAtIndex(index)
            selectedPinView.removeFromSuperview()
        }
    }

    func floorplanViewControllerShouldFocusOnWorkOrder(workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) {
        if let pinView = pinViewForWorkOrder(workOrder) {
            dispatch_after_delay(0.0) {
                UIView.animateWithDuration(0.2, delay: 0.2, options: .CurveEaseOut,
                    animations: {
                        self.scrollView.zoomToRect(pinView.frame, animated: false)

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

    func pinViewForWorkOrder(workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) -> FloorplanPinView! {
        return pinViewForWorkOrder(workOrder)
    }

    func polygonViewForWorkOrder(workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) -> FloorplanPolygonView! {
        return nil
    }

    func floorplanViewControllerShouldDismissWorkOrderCreationAnnotationViewsForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) {
        self.dismissWorkOrderCreationPinView()
    }

    func previewImageForWorkOrder(workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) -> UIImage! {
        let pinView = pinViewForWorkOrder(workOrder)

        if workOrder.previewImage == nil { // FIXME!!! This has to get moved
            if let pinView = pinView {
                if let overlayViewBoundingBox = pinView.overlayViewBoundingBox {
                    if let floorplanImageView = imageView {
                        let previewImage = floorplanImageView.image!.crop(overlayViewBoundingBox)
                        let previewView = UIImageView(image: previewImage)
                        if let annotation = pinView.annotation {
                            let pin = FloorplanPinView(annotation: annotation)
                            pin.delegate = self
                            previewView.addSubview(pin)
                            previewView.bringSubviewToFront(pin)
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

        return nil
    }

    // MARK: UIPopoverPresentationControllerDelegate

    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        if let presentedViewController = (controller.presentedViewController as? UINavigationController)?.viewControllers.first {
            if presentedViewController.isKindOfClass(ProductPickerViewController) {
                return .None
            }
        }


        return .CurrentContext
    }

    func popoverPresentationControllerShouldDismissPopover(popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }

    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {

    }

    func popoverPresentationController(popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverToRect rect: UnsafeMutablePointer<CGRect>, inView view: AutoreleasingUnsafeMutablePointer<UIView?>) {

    }

    deinit {
        thumbnailView?.removeFromSuperview()

        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
