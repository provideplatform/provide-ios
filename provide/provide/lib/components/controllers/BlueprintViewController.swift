//
//  BlueprintViewController.swift
//  provide
//
//  Created by Kyle Thomas on 10/23/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintViewControllerDelegate: NSObjectProtocol {
    func blueprintForBlueprintViewController(viewController: BlueprintViewController) -> Attachment!
    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job!
    func blueprintImageForBlueprintViewController(viewController: BlueprintViewController) -> UIImage!
    func modeForBlueprintViewController(viewController: BlueprintViewController) -> BlueprintViewController.Mode!
    func estimateForBlueprintViewController(viewController: BlueprintViewController) -> Estimate!
    func scaleCanBeSetByBlueprintViewController(viewController: BlueprintViewController) -> Bool
    func scaleWasSetForBlueprintViewController(viewController: BlueprintViewController)
    func newWorkOrderCanBeCreatedByBlueprintViewController(viewController: BlueprintViewController) -> Bool
    func areaSelectorIsAvailableForBlueprintViewController(viewController: BlueprintViewController) -> Bool
    func navigationControllerForBlueprintViewController(viewController: BlueprintViewController) -> UINavigationController!
    func blueprintViewControllerCanDropWorkOrderPin(viewController: BlueprintViewController) -> Bool
}

class BlueprintViewController: WorkOrderComponentViewController,
                               UIScrollViewDelegate,
                               BlueprintScaleViewDelegate,
                               BlueprintThumbnailViewDelegate,
                               BlueprintToolbarDelegate,
                               BlueprintPinViewDelegate,
                               BlueprintPolygonViewDelegate,
                               ExpensesViewControllerDelegate,
                               ProductPickerViewControllerDelegate,
                               WorkOrderCreationViewControllerDelegate,
                               UIPopoverPresentationControllerDelegate {

    enum Mode {
        case Setup, WorkOrders
        static let allValues = [Setup, WorkOrders]
    }

    weak var blueprintViewControllerDelegate: BlueprintViewControllerDelegate! {
        didSet {
            if let _ = blueprintViewControllerDelegate {
                if !loadedBlueprint && !loadingBlueprint && scrollView != nil {
                    loadBlueprint()
                } else if loadedBlueprint {
                    dispatch_after_delay(0.0) {
                        self.scrollViewDidScroll(self.scrollView)
                    }
                }
            }
        }
    }

    private var mode: Mode {
        if let blueprintViewControllerDelegate = blueprintViewControllerDelegate {
            if let mode = blueprintViewControllerDelegate.modeForBlueprintViewController(self) {
                return mode
            }
        }
        return .Setup
    }

    private var thumbnailView: BlueprintThumbnailView!
    private var thumbnailTintView: UIView!

    private var imageView: UIImageView!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var progressView: UIProgressView! {
        didSet {
            if let progressView = progressView {
                progressView.setProgress(0.0, animated: false)
            }
        }
    }

    @IBOutlet private weak var scrollView: BlueprintScrollView!

    @IBOutlet private weak var toolbar: BlueprintToolbar!

    @IBOutlet private weak var scaleView: BlueprintScaleView! {
        didSet {
            if let scaleView = scaleView {
                scaleView.delegate = self
                scaleView.backgroundColor = UIColor.whiteColor() //.colorWithAlphaComponent(0.85)
                scaleView.clipsToBounds = true
                scaleView.roundCorners(5.0)
            }
        }
    }

    @IBOutlet private weak var polygonView: BlueprintPolygonView! {
        didSet {
            if let polygonView = polygonView {
                polygonView.delegate = self
            }
        }
    }

    private var pinViews = [BlueprintPinView]()
    private var polygonViews = [BlueprintPolygonView]()

    private var selectedPinView: BlueprintPinView!
    private var selectedPolygonView: BlueprintPolygonView!

    var blueprint: Attachment! {
        if let blueprint = blueprintViewControllerDelegate?.blueprintForBlueprintViewController(self) {
            return blueprint
        } else if let job = job {
            return job.blueprint
        } else if let estimate = estimate {
            return estimate.blueprint
        }
        return nil
    }

    var blueprintImageUrl: NSURL! {
        if let blueprint = blueprint {
            return blueprint.url
        }
        return nil
    }

    var blueprintAnnotationsCount: Int {
        if let blueprint = blueprint {
            return blueprint.annotations.count
        }
        return 0
    }

    var blueprintScale: Float! {
        if let metadata = blueprint?.metadata {
            if let scale = metadata["scale"] as? Double {
                return Float(scale)
            }
        }
        return nil
    }

    weak var job: Job! {
        if let job = blueprintViewControllerDelegate?.jobForBlueprintViewController(self) {
            return job
        }
        if let workOrder = workOrder {
            return workOrder.job
        }
        return nil
    }

    weak var estimate: Estimate! {
        if let estimate = blueprintViewControllerDelegate?.estimateForBlueprintViewController(self) {
            return estimate
        }
        return nil
    }

    var workOrder: WorkOrder!

    private var backsplashProductPickerViewController: ProductPickerViewController!

    private var initialToolbarFrame: CGRect!

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

    private var loadedBlueprint = false

    private var loadingBlueprint = false {
        didSet {
            if !loadingBlueprint && !loadingAnnotations {
                activityIndicatorView.stopAnimating()
            } else if !activityIndicatorView.isAnimating() {
                if loadingBlueprint == true && oldValue == false {
                    progressView?.setProgress(0.0, animated: false)
                }
                activityIndicatorView.startAnimating()
            }
        }
    }

    private var loadingAnnotations = false {
        didSet {
            if !loadingBlueprint && !loadingAnnotations {
                activityIndicatorView.stopAnimating()
                progressView?.hidden = true
            } else if !activityIndicatorView.isAnimating() {
                activityIndicatorView.startAnimating()
            }
        }
    }

    private var loadingMaterials = false {
        didSet {
            if !loadingBlueprint && !loadingAnnotations && !loadingMaterials {
                activityIndicatorView.stopAnimating()
                progressView?.hidden = true
            } else if !activityIndicatorView.isAnimating() {
                activityIndicatorView.startAnimating()
            }
        }
    }

    private var newWorkOrderPending = false

    override var navigationController: UINavigationController! {
        if let navigationController = super.navigationController {
            if let parentNavigationController = navigationController.navigationController {
                return parentNavigationController
            }
        }
        return super.navigationController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()

        let blueprintThumbnailViewController = UIStoryboard("Blueprint").instantiateViewControllerWithIdentifier("BlueprintThumbnailViewController") as! BlueprintThumbnailViewController
        thumbnailView = blueprintThumbnailViewController.thumbnailView
        thumbnailView.delegate = self
        view.addSubview(thumbnailView)

        thumbnailTintView = UIView(frame: view.bounds)
        thumbnailTintView.backgroundColor = UIColor.blackColor()
        thumbnailTintView.alpha = 0.0
        view.addSubview(thumbnailTintView)
        view.sendSubviewToBack(thumbnailTintView)
        thumbnailTintView?.userInteractionEnabled = false

        imageView = UIImageView()
        imageView.alpha = 0.0
        imageView.userInteractionEnabled = true
        imageView.contentMode = .ScaleToFill

        scrollView?.backgroundColor = UIColor.whiteColor() //UIColor(red: 0.11, green: 0.29, blue: 0.565, alpha: 0.45)
        scrollView?.addSubview(imageView)
        scrollView?.bringSubviewToFront(imageView)

        toolbar?.alpha = 0.0
        toolbar?.blueprintToolbarDelegate = self
        toolbar?.barTintColor = Color.darkBlueBackground()

        hideToolbar()

        activityIndicatorView?.startAnimating()

        if blueprintViewControllerDelegate != nil && !loadedBlueprint && !loadingBlueprint && scrollView != nil {
            loadBlueprint()
        }

        NSNotificationCenter.defaultCenter().addObserverForName("WorkOrderChanged") { notification in
            if let workOrder = notification.object as? WorkOrder {
                if let blueprint = self.blueprint {
                    for annotation in blueprint.annotations {
                        if workOrder.id == annotation.workOrderId {
                            if let wo = annotation.workOrder {
                                if let pinView = self.pinViewForWorkOrder(wo) {
                                    pinView.annotation = annotation
                                    pinView.redraw()
                                } else if let polygonView = self.polygonViewForWorkOrder(wo) {
                                    polygonView.annotation = annotation
                                    polygonView.redraw()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func teardown() -> UIImage? {
        let image = imageView?.image
        imageView?.image = nil
        thumbnailView?.blueprintImage = nil
        loadedBlueprint = false
        return image
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        dispatch_after_delay(0.0) { [weak self] in
            self!.thumbnailView?.blueprintImage = self!.imageView.image
        }
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

    private var floorplanSupportsBacksplash: Bool {
        if let floorplan = job?.floorplans.first {
            return floorplan.backsplashProductOptions?.count > 0
        }
        return false
    }

    private func loadBlueprint() {
        if let url = blueprintImageUrl {
            loadingBlueprint = true

            ImageService.sharedService().fetchImage(url, cacheOnDisk: true,
                onDownloadSuccess: { [weak self] image in
                    dispatch_async_main_queue {
                        self!.progressView?.setProgress(1.0, animated: false)
                        self!.setBlueprintImage(image)
                    }

                    self!.loadAnnotations()
                },
                onDownloadFailure: { error in
                    logWarn("Blueprint image download failed; \(error)")
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

    private func setBlueprintImage(image: UIImage) {
        let size = CGSize(width: image.size.width, height: image.size.height)

        imageView!.image = image
        imageView!.frame = CGRect(origin: CGPointZero, size: size)

        thumbnailView?.blueprintImage = image

        scrollView.scrollEnabled = false
        scrollView.contentSize = size

        enableScrolling = true

        loadingBlueprint = false
        loadedBlueprint = true

        if let canDropWorkOrderPin = blueprintViewControllerDelegate?.blueprintViewControllerCanDropWorkOrderPin(self) {
            if canDropWorkOrderPin {
                let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(BlueprintViewController.dropPin(_:)))
                imageView.addGestureRecognizer(gestureRecognizer)
            }
        }

        self.progressView?.hidden = true

        if let _ = presentedViewController {
            dismissViewController(animated: true)
        }

        if let inProgressWorkOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            openWorkOrder(inProgressWorkOrder)
        }

        dispatch_after_delay(0.0) {
            self.setZoomLevel()
            self.imageView.alpha = 1.0

            self.toolbar?.reload()

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
            selectedPinView = BlueprintPinView(delegate: self, annotation: annotation)

            imageView.addSubview(selectedPinView)
            imageView.bringSubviewToFront(selectedPinView)
            selectedPinView.frame = CGRect(x: point.x, y: point.y, width: selectedPinView.bounds.width, height: selectedPinView.bounds.height)
            selectedPinView.frame.origin = CGPoint(x: selectedPinView.frame.origin.x - (selectedPinView.frame.size.width / 2.0),
                                                   y: selectedPinView.frame.origin.y - selectedPinView.frame.size.height)
            selectedPinView.alpha = 1.0
            selectedPinView.attachGestureRecognizer()
            pinViews.append(selectedPinView)

            createWorkOrder(nil)
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

    private func loadAnnotations() {
        if let blueprint = blueprint {
            loadingAnnotations = true
            blueprint.annotations = [Annotation]()
            let rpp = max(100, blueprintAnnotationsCount)
            let params = ["page": "1", "rpp": "\(rpp)"]
            blueprint.fetchAnnotations(params,
                onSuccess: { statusCode, mappingResult in
                    self.loadingAnnotations = false
                    self.refreshAnnotations()
                    self.presentFloorplanProductViewControllers()
                },
                onError: { error, statusCode, responseString in
                    self.loadingAnnotations = false
                }
            )
        }
    }

    private func presentFloorplanProductViewControllers() {
        if floorplanSupportsBacksplash {
            if let floorplanJob = job?.floorplanJobs.first {
                if floorplanJob.backsplashSqFt != -1 {
                    loadingMaterials = true
                    job.reloadMaterials(
                        { statusCode, mappingResult in
                            var shouldPresentBacksplashProductPickerViewController = true
                            for jobProduct in self.job.materials {
                                let product = jobProduct.product
                                for backsplashProductOption in floorplanJob.floorplan.backsplashProductOptions {
                                    if product.id == backsplashProductOption.id {
                                        shouldPresentBacksplashProductPickerViewController = false
                                        break
                                    }
                                }
                            }
                            if shouldPresentBacksplashProductPickerViewController {
                                self.presentBacksplashProductPickerViewController()
                            }
                            self.loadingMaterials = false
                        },
                        onError: { error, statusCode, responseString in
                            self.loadingMaterials = false
                        }
                    )
                }
            }
        }
    }

    private func pinViewForWorkOrder(workOrder: WorkOrder!) -> BlueprintPinView! {
        var pinView: BlueprintPinView!
        for view in pinViews {
            if let annotation = view.annotation {
                if annotation.point != nil {
                    if let wo = annotation.workOrder {
                        if wo.id == workOrder?.id {
                            pinView = view
                            break
                        }
                    } else if annotation.workOrderId == workOrder?.id {
                        pinView = view
                        break
                    }
                }
            }
        }
        if pinView == nil {
//            pinView = self.pinView
            if let annotations = workOrder.annotations {
                if annotations.count > 0 {
                    if let annotation = annotations.first {
                        if annotation.point != nil {
                            pinView = BlueprintPinView(delegate: self, annotation: annotation)
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

        pinViews = [BlueprintPinView]()
    }

    private func polygonViewForWorkOrder(workOrder: WorkOrder!) -> BlueprintPolygonView! {
        var polygonView: BlueprintPolygonView!
        for view in polygonViews {
            if let annotation = view.annotation {
                if annotation.polygon != nil {
                    if let wo = annotation.workOrder {
                        if wo.id == workOrder?.id {
                            polygonView = view
                            break
                        }
                    } else if annotation.workOrderId == workOrder?.id {
                        polygonView = view
                        break
                    }
                }
            }
        }
        if polygonView == nil {
            if let workOrder = workOrder {
                if let annotations = workOrder.annotations {
                    if annotations.count > 0 {
                        if let annotation = annotations.first {
                            if annotation.polygon != nil {
                                polygonView = BlueprintPolygonView(delegate: self, annotation: annotation)
                            }
                        }
                    }
                }
            }
        }
        return polygonView
    }

    private func removePolygonViews() {
        for view in polygonViews {
            view.removeFromSuperview()
        }

        polygonViews = [BlueprintPolygonView]()
    }

    private func refreshAnnotations() {
        if let blueprint = blueprint {
            for annotation in blueprint.annotations {
                let annotationWorkOrder = annotation.workOrderId > 0 ? annotation.workOrder : nil
                if annotation.point != nil {
                    let pinView = BlueprintPinView(delegate: self, annotation: annotation)
                    pinView.category = annotation.workOrder?.category
                    pinView.frame = CGRect(x: annotation.point[0],
                                           y: annotation.point[1],
                                           width: pinView.bounds.width,
                                           height: pinView.bounds.height)
                    pinView.frame.origin = CGPoint(x: pinView.frame.origin.x - (pinView.frame.size.width / 2.0),
                                                   y: pinView.frame.origin.y - pinView.frame.size.height)
                    pinView.alpha = 1.0

                    imageView.addSubview(pinView)
                    imageView.bringSubviewToFront(pinView)
                    
                    pinView.attachGestureRecognizer()

                    pinViews.append(pinView)
                } else if let polygonView = polygonViewForWorkOrder(annotationWorkOrder) {
                    imageView.addSubview(polygonView)
                    polygonView.alpha = 1.0
                    polygonView.attachGestureRecognizer()

                    polygonViews.append(polygonView)
                }
            }
        }
    }

    private func refreshWorkOrderCreationView() {
        if let presentedViewController = presentedViewController {
            if presentedViewController is UINavigationController {
                let viewController = (presentedViewController as! UINavigationController).viewControllers.first!
                if viewController is WorkOrderCreationViewController {
                    (viewController as! WorkOrderCreationViewController).reloadTableView()
                }
            }
        }
    }

    private func hideToolbar() {
        if initialToolbarFrame == nil {
            dispatch_after_delay(0.0) { [weak self] in
                self!.initialToolbarFrame = self!.toolbar?.frame
            }
        }

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: { [weak self] in
                self!.toolbar?.alpha = 0.0
                self!.toolbar?.frame.origin.y += (self!.toolbar?.frame.size.height)!
            }, completion: { completed in

                
            }
        )
    }

    private func showToolbar() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.toolbar?.alpha = 1.0
                if let initialToolbarFrame = self.initialToolbarFrame {
                    self.toolbar?.frame = initialToolbarFrame
                } else {
                    self.toolbar?.frame.origin.y -= (self.toolbar?.frame.size.height)!
                }
            }, completion: { completed in

            }
        )
    }

    func cancelSetScale(sender: UIBarButtonItem) {
        scaleView.resignFirstResponder(false)
        restoreCachedNavigationItem()
    }

    func setScale(sender: UIBarButtonItem!) {
        let scale = scaleView.scale
        scaleView.resignFirstResponder(false)

        restoreCachedNavigationItem()

        if let blueprint = blueprint {
            var metadata = blueprint.metadata.mutableCopy() as! [String : AnyObject]
            metadata["scale"] = scale
            blueprint.updateAttachment(["metadata": metadata],
                onSuccess: { statusCode, mappingResult in
                    self.toolbar.reload()
                    self.blueprintViewControllerDelegate?.scaleWasSetForBlueprintViewController(self)
                }, onError: { error, statusCode, responseString in

                }
            )
        }
    }

    func cancelCreateWorkOrder(sender: UIBarButtonItem) {
        newWorkOrderPending = false
        dismissWorkOrderCreationPinView()
        dismissWorkOrderCreationPolygonView()
        toolbar.reload()
    }

    func dismissWorkOrderCreationPinView() {
        selectedPinView?.resignFirstResponder(false)
    }

    func dismissWorkOrderCreationPolygonView() {
        polygonView?.resignFirstResponder(false)
        restoreCachedNavigationItem()
    }

    func createWorkOrder(sender: UIBarButtonItem!) {
        let createWorkOrderViewController = UIStoryboard("WorkOrderCreation").instantiateInitialViewController() as! WorkOrderCreationViewController

        let workOrder = WorkOrder()
        workOrder.company = job!.company
        workOrder.companyId = job!.companyId
        workOrder.customer = job!.customer
        workOrder.customerId = job!.customerId
        workOrder.job = job!
        workOrder.jobId = job!.id
        workOrder.status = "awaiting_schedule"
        workOrder.expenses = [Expense]()
        workOrder.itemsDelivered = [Product]()
        workOrder.itemsOrdered = [Product]()
        workOrder.itemsRejected = [Product]()
        workOrder.materials = [WorkOrderProduct]()

        createWorkOrderViewController.workOrder = workOrder
        createWorkOrderViewController.delegate = self

        let navigationController = UINavigationController(rootViewController: createWorkOrderViewController)
        navigationController.modalPresentationStyle = .FormSheet

        presentViewController(navigationController, animated: true)
    }

    private func overrideNavigationItemForSettingScale(setScaleEnabled: Bool = false) {
        cacheNavigationItem(navigationItem)

        let cancelItem = UIBarButtonItem(title: "CANCEL", style: .Plain, target: self, action: #selector(BlueprintViewController.cancelSetScale(_:)))
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Disabled)

        let setScaleItem = UIBarButtonItem(title: "SET SCALE", style: .Plain, target: self, action: #selector(BlueprintViewController.setScale(_:)))
        setScaleItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        setScaleItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Disabled)
        setScaleItem.enabled = setScaleEnabled

        navigationItem.leftBarButtonItems = [cancelItem]
        navigationItem.rightBarButtonItems = [setScaleItem]
    }

    private func overrideNavigationItemForCreatingWorkOrder(setCreateEnabled: Bool = false) {
        cacheNavigationItem(navigationItem)

        let cancelItem = UIBarButtonItem(title: "CANCEL", style: .Plain, target: self, action: #selector(BlueprintViewController.cancelCreateWorkOrder(_:)))
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Disabled)

        let createWorkOrderItem = UIBarButtonItem(title: "CREATE WORK ORDER", style: .Plain, target: self, action: #selector(BlueprintViewController.createWorkOrder(_:)))
        createWorkOrderItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        createWorkOrderItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Disabled)
        createWorkOrderItem.enabled = setCreateEnabled

        navigationItem.leftBarButtonItems = [cancelItem]
        navigationItem.rightBarButtonItems = [createWorkOrderItem]
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

    // MARK: BlueprintScaleViewDelegate

    func blueprintImageViewForBlueprintScaleView(view: BlueprintScaleView) -> UIImageView! {
        return imageView
    }

    func blueprintScaleForBlueprintScaleView(view: BlueprintScaleView) -> CGFloat {
        if let blueprintScale = blueprintScale {
            return CGFloat(blueprintScale)
        }

        return 1.0
    }

    func blueprintScaleViewCanSetBlueprintScale(view: BlueprintScaleView) {
        overrideNavigationItemForSettingScale(true)
    }

    func blueprintScaleViewDidReset(view: BlueprintScaleView) {
        toolbar?.toggleScaleVisibility()
    }

    func blueprintScaleView(view: BlueprintScaleView, didSetScale scale: CGFloat) {
        setScale(nil)
    }

    // MARK: BlueprintThumbnailViewControllerDelegate

    func blueprintThumbnailView(view: BlueprintThumbnailView, navigatedToFrame frame: CGRect) {
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

    func blueprintThumbnailViewNavigationBegan(view: BlueprintThumbnailView) {
        hideToolbar()
    }

    func blueprintThumbnailViewNavigationEnded(view: BlueprintThumbnailView) {
        showToolbar()
    }

    func initialScaleForBlueprintThumbnailView(view: BlueprintThumbnailView) -> CGFloat {
        return scrollView.minimumZoomScale
    }

    func sizeForBlueprintThumbnailView(view: BlueprintThumbnailView) -> CGSize {
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

    // MARK: BlueprintToolbarDelegate

    func blueprintForBlueprintToolbar(toolbar: BlueprintToolbar) -> Attachment {
        if let blueprint = blueprint {
            return blueprint
        }
        return Attachment()
    }

    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetNavigatorVisibility visible: Bool) {
        let alpha = CGFloat(visible ? 1.0 : 0.0)
        thumbnailView?.alpha = alpha
        if visible {
            thumbnailTintView?.alpha = 0.3
            view.bringSubviewToFront(thumbnailTintView)
            view.bringSubviewToFront(thumbnailView)
            view.bringSubviewToFront(toolbar)
        } else {
            thumbnailTintView?.alpha = 0.0
            view.sendSubviewToBack(thumbnailTintView)
        }
    }

    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetScaleVisibility visible: Bool) {
        let alpha = CGFloat(visible ? 1.0 : 0.0)
        scaleView.alpha = alpha

        if visible {
            if scrollView.zoomScale < 0.9 {
                scrollView.setZoomScale(0.9, animated: true)
            }

            overrideNavigationItemForSettingScale(false) // FIXME: pass true when scaleView has both line endpoints drawn...
            scaleView.attachGestureRecognizer()
        } else {
            restoreCachedNavigationItem()
            scaleView.resignFirstResponder(true)
        }
    }

    func scaleCanBeSetByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool {
        if let canSetScale = blueprintViewControllerDelegate?.scaleCanBeSetByBlueprintViewController(self) {
            return canSetScale
        }
        return false
    }

    func newWorkOrderItemIsShownByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool {
        if let canSetScale = blueprintViewControllerDelegate?.scaleCanBeSetByBlueprintViewController(self) {
            return !canSetScale && job != nil && !job.isPunchlist
        }
        return true
    }

    func newWorkOrderCanBeCreatedByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool {
        if newWorkOrderPending {
            return false
        }

        if let presentedViewController = presentedViewController {
            return !(presentedViewController is WorkOrderCreationViewController)
        }

        if let newWorkOrderCanBeCreated = blueprintViewControllerDelegate?.newWorkOrderCanBeCreatedByBlueprintViewController(self) {
            return newWorkOrderCanBeCreated
        }

        return true
    }

    func newWorkOrderShouldBeCreatedByBlueprintToolbar(toolbar: BlueprintToolbar) {
        polygonView.alpha = 1.0
        polygonView.attachGestureRecognizer()

        newWorkOrderPending = true

        overrideNavigationItemForCreatingWorkOrder(false) // FIXME: pass true when polygonView has both line endpoints drawn...
    }

    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetFloorplanOptionsVisibility visible: Bool) {
        if visible {
            if presentedViewController == nil {
                presentFloorplanProductViewControllers()
            }
        } else if let presentedViewController = presentedViewController {
            if presentedViewController.isKindOfClass(ProductPickerViewController) {
                dismissViewController(animated: true)
            }
        }
    }

    func floorplanOptionsItemIsShownByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool {
        if let job = job {
            return job.isResidential
        }
        return false
    }

    func blueprintToolbar(toolbar: BlueprintToolbar, shouldPresentAlertController alertController: UIAlertController) {
        navigationController!.presentViewController(alertController, animated: true)
    }

    // MARK: BlueprintPinViewDelegate

    func tintColorForBlueprintPinView(view: BlueprintPinView) -> UIColor {
        if let annotation = view.annotation {
            if let workOrder = annotation.workOrder {
                return workOrder.statusColor
            }
        }
        return UIColor.blueColor()
    }

    func categoryForBlueprintPinView(view: BlueprintPinView) -> Category! {
        if let annotation = view.annotation {
            if let workOrder = annotation.workOrder {
                return workOrder.category
            }
        }
        return nil
    }

    func blueprintImageViewForBlueprintPinView(view: BlueprintPinView) -> UIImageView! {
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

    func blueprintPinViewWasSelected(view: BlueprintPinView) {
        selectedPinView = view

        if let annotation = view.annotation {
            if let workOrder = annotation.workOrder {
                openWorkOrder(workOrder, fromPinView: view)
            }
        }
    }

    private func openWorkOrder(workOrder: WorkOrder, fromPinView pinView: BlueprintPinView! = nil) {
        setPreviewImageForWorkOrder(workOrder)

        let createWorkOrderViewController = UIStoryboard("WorkOrderCreation").instantiateInitialViewController() as! WorkOrderCreationViewController
        createWorkOrderViewController.workOrder = workOrder
        createWorkOrderViewController.delegate = self
        createWorkOrderViewController.preferredContentSize = CGSizeMake(500, 600)

        let navigationController = UINavigationController(rootViewController: createWorkOrderViewController)
        navigationController.modalPresentationStyle = .Popover

        let popover = navigationController.popoverPresentationController!
        popover.delegate = self
        popover.sourceView = imageView
        if let pinView = pinView {
            popover.sourceRect = pinView.frame
        }
        popover.canOverlapSourceViewRect = true
        popover.permittedArrowDirections = [.Left, .Right]
        popover.passthroughViews = [view]

        presentViewController(navigationController, animated: true)
    }

    private func setPreviewImageForWorkOrder(workOrder: WorkOrder) {
        let polygonView = polygonViewForWorkOrder(workOrder)
        let pinView = pinViewForWorkOrder(workOrder)

        if workOrder.previewImage == nil { // FIXME!!! This has to get moved
            if let blueprintPolygonView = polygonView {
                if let overlayViewBoundingBox = blueprintPolygonView.overlayViewBoundingBox {
                    if let blueprintImageView = imageView {
                        let previewImage = blueprintImageView.image!.crop(overlayViewBoundingBox)
                        let previewView = UIImageView(image: previewImage)
                        if let annotation = blueprintPolygonView.annotation {
                            let polygonView = BlueprintPolygonView(annotation: annotation)
                            previewView.addSubview(polygonView)
                            previewView.bringSubviewToFront(polygonView)
                            polygonView.alpha = 1.0
                            if let sublayers = polygonView.layer.sublayers {
                                for sublayer in sublayers {
                                    sublayer.position.x -= overlayViewBoundingBox.origin.x
                                    sublayer.position.y -= overlayViewBoundingBox.origin.y
                                }
                            }

                            workOrder.previewImage = previewView.toImage()
                        }
                    }
                }
            } else if let pinView = pinView {
                if let overlayViewBoundingBox = pinView.overlayViewBoundingBox {
                    if let blueprintImageView = imageView {
                        let previewImage = blueprintImageView.image!.crop(overlayViewBoundingBox)
                        let previewView = UIImageView(image: previewImage)
                        if let annotation = pinView.annotation {
                            let pin = BlueprintPinView(annotation: annotation)
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
    }

    // MARK: BlueprintPolygonViewDelegate

    func blueprintPolygonViewCanBeResized(view: BlueprintPolygonView) -> Bool {
        if let job = job {
            if job.isResidential {
                return false
            }
        }

        if let annotation = view.annotation {
            if let workOrder = annotation.workOrder {
                return ["awaiting_schedule", "scheduled"].indexOfObject(workOrder.status) != nil
            }
        }
        return false
    }

    func blueprintScaleForBlueprintPolygonView(view: BlueprintPolygonView) -> CGFloat! {
        if let blueprintScale = blueprintScale {
            return CGFloat(blueprintScale)
        }
        return nil
    }

    func blueprintImageViewForBlueprintPolygonView(view: BlueprintPolygonView) -> UIImageView! {
        if let index = polygonViews.indexOfObject(view) {
            if let _ = polygonViews[index].delegate {
                return imageView
            } else {
                return nil
            }
        } else {
            return imageView
        }
    }

    func blueprintForBlueprintPolygonView(view: BlueprintPolygonView) -> Attachment! {
        return blueprint
    }

    func blueprintPolygonViewDidClose(view: BlueprintPolygonView) {
        if view == polygonView {
            overrideNavigationItemForCreatingWorkOrder(true)

            if view.annotation == nil {

            }
        }
    }

    func blueprintPolygonView(view: BlueprintPolygonView, colorForOverlayView overlayView: UIView) -> UIColor {
        if let annotation = view.annotation {
            if let workOrder = annotation.workOrder {
                return workOrder.statusColor
            }
        }
        return UIColor.clearColor()
    }

    func blueprintPolygonView(view: BlueprintPolygonView, opacityForOverlayView overlayView: UIView) -> CGFloat {
        return 0.75
    }

    func blueprintPolygonView(view: BlueprintPolygonView, layerForOverlayView overlayView: UIView, inBoundingBox boundingBox: CGRect) -> CALayer! {
        let textLayer = CATextLayer()
        textLayer.string = "\(NSString(format: "%.03f", view.area)) sq ft"
        textLayer.font = UIFont(name: "Exo2-Regular", size: 16.0)
        textLayer.foregroundColor = UIColor.blackColor().CGColor
        textLayer.alignmentMode = "center"
        textLayer.frame = CGRect(x: boundingBox.origin.x,
                                 y: boundingBox.origin.y + (boundingBox.height / 2.0),
                                 width: boundingBox.width,
                                 height: boundingBox.height)

        return textLayer
    }

    func blueprintPolygonView(view: BlueprintPolygonView, didSelectOverlayView overlayView: UIView, atPoint point: CGPoint, inPath path: CGPath) {
        selectedPolygonView = view

        if let annotation = view.annotation {
            if let workOrder = annotation.workOrder {
                let createWorkOrderViewController = UIStoryboard("WorkOrderCreation").instantiateInitialViewController() as! WorkOrderCreationViewController
                createWorkOrderViewController.workOrder = workOrder
                createWorkOrderViewController.delegate = self
                createWorkOrderViewController.preferredContentSize = CGSizeMake(500, 600)

                let navigationController = UINavigationController(rootViewController: createWorkOrderViewController)
                navigationController.modalPresentationStyle = .Popover

                let popover = navigationController.popoverPresentationController!
                popover.delegate = self
                popover.sourceView = imageView
                popover.sourceRect = CGPathGetBoundingBox(path)
                popover.canOverlapSourceViewRect = true
                popover.permittedArrowDirections = [.Left, .Right]
                popover.passthroughViews = [view]
                
                presentViewController(navigationController, animated: true)
            } else {
                if job.isResidential {
                    let productPickerViewController = UIStoryboard("ProductPicker").instantiateInitialViewController() as! ProductPickerViewController
                    productPickerViewController.title = "SELECT PRODUCT"
                    if let roomName = annotation.metadata["name"] as? String {
                        productPickerViewController.title = "\(productPickerViewController.title) FOR \(roomName)"
                    }
                    productPickerViewController.delegate = self
                    productPickerViewController.preferredContentSize = CGSizeMake(500, 200)

                    let navigationController = UINavigationController(rootViewController: productPickerViewController)
                    navigationController.modalPresentationStyle = .Popover

                    let popover = navigationController.popoverPresentationController!
                    popover.delegate = self
                    popover.sourceView = imageView
                    popover.sourceRect = CGPathGetBoundingBox(path)
                    popover.canOverlapSourceViewRect = true
                    popover.permittedArrowDirections = [.Left, .Right]
                    popover.passthroughViews = [view]

                    presentViewController(navigationController, animated: true)
                }
            }
        }
    }

    func blueprintPolygonView(view: BlueprintPolygonView, didUpdateAnnotation annotation: Annotation) {
        refreshWorkOrderCreationView()
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

    private func presentBacksplashProductPickerViewController() {
        if job.isResidential && floorplanSupportsBacksplash {
            backsplashProductPickerViewController = UIStoryboard("ProductPicker").instantiateInitialViewController() as! ProductPickerViewController
            backsplashProductPickerViewController.title = "SELECT BACKSPLASH"
            backsplashProductPickerViewController.delegate = self
            backsplashProductPickerViewController.preferredContentSize = CGSizeMake(500, 200)

            let navigationController = UINavigationController(rootViewController: backsplashProductPickerViewController)
            navigationController.modalPresentationStyle = .Popover

            let popover = navigationController.popoverPresentationController!
            popover.delegate = self
            popover.sourceView = imageView
            popover.canOverlapSourceViewRect = true
            popover.permittedArrowDirections = [.Up]
            popover.passthroughViews = [view]

            presentViewController(navigationController, animated: true)
        }
    }

    // MARK: ExpensesViewControllerDelegate

    func expenseCaptureViewControllerDelegateForExpensesViewController(viewController: ExpensesViewController) -> AnyObject! {
        if let presentedViewController = presentedViewController {
            if presentedViewController is UINavigationController {
                let viewController = (presentedViewController as! UINavigationController).viewControllers.first!
                if viewController is WorkOrderCreationViewController {
                    return viewController
                }
            }
        }
        return nil
    }

    // MARK: ProductPickerViewControllerDelegate

    func productsForPickerViewController(viewController: ProductPickerViewController) -> [Product] {
        if let job = job {
            if job.isResidential {
                if let floorplan = job.floorplans.first {
                    if let backsplashProductPickerViewController = backsplashProductPickerViewController {
                        if viewController == backsplashProductPickerViewController {
                            return floorplan.backsplashProductOptions
                        } else {
                            return floorplan.flooringProductOptions
                        }
                    } else {
                        return floorplan.flooringProductOptions
                    }
                }
            }
        }

        return [Product]()
    }

    func productPickerViewControllerCanRenderResults(viewController: ProductPickerViewController) -> Bool {
        return true
    }

    func queryParamsForProductPickerViewController(viewController: ProductPickerViewController) -> [String : AnyObject]! {
        return nil
    }

    func productPickerViewController(viewController: ProductPickerViewController, didSelectProduct product: Product) {
        if let presentingViewController = viewController.presentingViewController {
            presentingViewController.dismissViewController(animated: true)

            let workOrder = WorkOrder()
            workOrder.companyId = job.companyId
            workOrder.customer = job.customer
            workOrder.customerId = job.customerId
            workOrder.jobId = job.id
            workOrder.status = "awaiting_schedule"
            workOrder.materials = [WorkOrderProduct]()
            workOrder.expenses = [Expense]()
            workOrder.itemsDelivered = [Product]()
            workOrder.itemsOrdered = [Product]()
            workOrder.itemsRejected = [Product]()

            let floorplanJob = job.floorplanJobs.first

            job.reloadMaterials(
                { statusCode, mappingResult in
                    workOrder.save(
                        onSuccess: { statusCode, mappingResult in
                            if let annotation = self.selectedPolygonView?.annotation {
                                annotation.workOrder = workOrder
                                annotation.workOrderId = workOrder.id
                                annotation.save(self.blueprint,
                                    onSuccess: { statusCode, mappingResult in
                                        var jobProduct = self.job.jobProductForProduct(product)
                                        if jobProduct != nil && floorplanJob != nil {
                                            CompanyService.sharedService().fetch(companyId: self.job.companyId,
                                                onCompaniesFetched: { companies in
                                                    if let company = companies.first {
                                                        var price: Double?
                                                        if product.isTierOne && floorplanJob != nil && floorplanJob!.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                            price = floorplanJob!.flooringMaterialTier1CostPerSqFt
                                                        } else if product.isTierOne && company.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                            price = company.flooringMaterialTier1CostPerSqFt
                                                        } else if product.isTierTwo && floorplanJob != nil && floorplanJob!.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                            price = floorplanJob!.flooringMaterialTier2CostPerSqFt
                                                        } else if product.isTierTwo && company.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                            price = company.flooringMaterialTier2CostPerSqFt
                                                        } else if product.isTierThree && floorplanJob != nil && floorplanJob!.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                            price = floorplanJob!.flooringMaterialTier3CostPerSqFt
                                                        } else if product.isTierThree && company.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                            price = company.flooringMaterialTier3CostPerSqFt
                                                        }

                                                        jobProduct.initialQuantity += Double(self.selectedPolygonView.area)
                                                        if let price = price {
                                                            jobProduct.price = price
                                                        }

                                                        self.job.save(
                                                            onSuccess: { statusCode, mappingResult in
                                                                jobProduct = self.job.materials.last!

                                                                var price: Double?
                                                                if product.isTierOne && floorplanJob != nil && floorplanJob!.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                                    price = floorplanJob!.flooringMaterialTier1CostPerSqFt
                                                                } else if product.isTierOne && company.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                                    price = company.flooringMaterialTier1CostPerSqFt
                                                                } else if product.isTierTwo && floorplanJob != nil && floorplanJob!.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                                    price = floorplanJob!.flooringMaterialTier2CostPerSqFt
                                                                } else if product.isTierTwo && company.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                                    price = company.flooringMaterialTier2CostPerSqFt
                                                                } else if product.isTierThree && floorplanJob != nil && floorplanJob!.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                                    price = floorplanJob!.flooringMaterialTier3CostPerSqFt
                                                                } else if product.isTierThree && company.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                                    price = company.flooringMaterialTier3CostPerSqFt
                                                                }

                                                                var workOrderProductParams: [String : AnyObject] = ["quantity": self.selectedPolygonView.area]
                                                                if let price = price {
                                                                    workOrderProductParams["price"] = CGFloat(price)
                                                                }

                                                                workOrder.addWorkOrderProductForJobProduct(jobProduct, params: workOrderProductParams,
                                                                    onSuccess: { statusCode, mappingResult in
                                                                        self.selectedPolygonView.redraw()
                                                                        self.selectedPolygonView = nil

                                                                        // TODO: show work order popover?
                                                                    },
                                                                    onError: { error, statusCode, responseString in
                                                                        print(responseString)
                                                                    }
                                                                )
                                                            },
                                                            onError: { error, statusCode, responseString -> () in
                                                                print(responseString)
                                                            }
                                                        )
                                                    }
                                                }
                                            )
                                        } else {
                                            CompanyService.sharedService().fetch(companyId: self.job.companyId,
                                                onCompaniesFetched: { companies in
                                                    if let company = companies.first {
                                                        var price: Double?
                                                        if product.isTierOne && floorplanJob != nil && floorplanJob!.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                            price = floorplanJob!.flooringMaterialTier1CostPerSqFt
                                                        } else if product.isTierOne && company.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                            price = company.flooringMaterialTier1CostPerSqFt
                                                        } else if product.isTierTwo && floorplanJob != nil && floorplanJob!.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                            price = floorplanJob!.flooringMaterialTier2CostPerSqFt
                                                        } else if product.isTierTwo && company.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                            price = company.flooringMaterialTier2CostPerSqFt
                                                        } else if product.isTierThree && floorplanJob != nil && floorplanJob!.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                            price = floorplanJob!.flooringMaterialTier3CostPerSqFt
                                                        } else if product.isTierThree && company.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                            price = company.flooringMaterialTier3CostPerSqFt
                                                        }

                                                        var jobProductParams: [String : AnyObject] = ["initial_quantity": Double(self.selectedPolygonView.area)]
                                                        if let price = price {
                                                            jobProductParams["price"] = price
                                                        }

                                                        self.job.addJobProductForProduct(product, params: jobProductParams,
                                                            onSuccess: { statusCode, mappingResult in
                                                                jobProduct = self.job.materials.last!

                                                                var price: Double?
                                                                if product.isTierOne && floorplanJob != nil && floorplanJob!.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                                    price = floorplanJob!.flooringMaterialTier1CostPerSqFt
                                                                } else if product.isTierOne && company.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                                    price = company.flooringMaterialTier1CostPerSqFt
                                                                } else if product.isTierTwo && floorplanJob != nil && floorplanJob!.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                                    price = floorplanJob!.flooringMaterialTier2CostPerSqFt
                                                                } else if product.isTierTwo && company.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                                    price = company.flooringMaterialTier2CostPerSqFt
                                                                } else if product.isTierThree && floorplanJob != nil && floorplanJob!.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                                    price = floorplanJob!.flooringMaterialTier3CostPerSqFt
                                                                } else if product.isTierThree && company.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                                    price = company.flooringMaterialTier3CostPerSqFt
                                                                }

                                                                var workOrderProductParams = ["quantity": self.selectedPolygonView.area]
                                                                if let price = price {
                                                                    workOrderProductParams["price"] = CGFloat(price)
                                                                }

                                                                workOrder.addWorkOrderProductForJobProduct(jobProduct, params: workOrderProductParams,
                                                                    onSuccess: { statusCode, mappingResult in
                                                                        self.selectedPolygonView.redraw()
                                                                        self.selectedPolygonView = nil

                                                                        // TODO: show work order popover?
                                                                    },
                                                                    onError: { error, statusCode, responseString in
                                                                        print(responseString)
                                                                    }
                                                                )
                                                            },
                                                            onError: { error, statusCode, responseString -> () in
                                                                print(responseString)
                                                            }
                                                        )
                                                    }
                                                }
                                            )
                                        }
                                    },
                                    onError: { error, statusCode, responseString in
                                        print(responseString)
                                    }
                                )
                            } else {
                                var jobProduct = self.job.jobProductForProduct(product)
                                if jobProduct != nil {
                                    let backsplashSqFt = self.job.floorplans.first!.backsplashSqFt
                                    if backsplashSqFt != -1 {
                                        CompanyService.sharedService().fetch(companyId: self.job.companyId,
                                            onCompaniesFetched: { companies in
                                                if let company = companies.first {
                                                    var price: Double?
                                                    if product.isTierOne && floorplanJob != nil && floorplanJob!.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                        price = floorplanJob!.flooringMaterialTier1CostPerSqFt
                                                    } else if product.isTierOne && company.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                        price = company.flooringMaterialTier1CostPerSqFt
                                                    } else if product.isTierTwo && floorplanJob != nil && floorplanJob!.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                        price = floorplanJob!.flooringMaterialTier2CostPerSqFt
                                                    } else if product.isTierTwo && company.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                        price = company.flooringMaterialTier2CostPerSqFt
                                                    } else if product.isTierThree && floorplanJob != nil && floorplanJob!.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                        price = floorplanJob!.flooringMaterialTier3CostPerSqFt
                                                    } else if product.isTierThree && company.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                        price = company.flooringMaterialTier3CostPerSqFt
                                                    }

                                                    jobProduct.initialQuantity += backsplashSqFt
                                                    if let price = price {
                                                        jobProduct.price = price
                                                    }
                                                    self.job.save(
                                                        onSuccess: { statusCode, mappingResult in
                                                            jobProduct = self.job.materials.last!

                                                            var price: Double?
                                                            if product.isTierOne && floorplanJob != nil && floorplanJob!.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                                price = floorplanJob!.flooringMaterialTier1CostPerSqFt
                                                            } else if product.isTierOne && company.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                                price = company.flooringMaterialTier1CostPerSqFt
                                                            } else if product.isTierTwo && floorplanJob != nil && floorplanJob!.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                                price = floorplanJob!.flooringMaterialTier2CostPerSqFt
                                                            } else if product.isTierTwo && company.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                                price = company.flooringMaterialTier2CostPerSqFt
                                                            } else if product.isTierThree && floorplanJob != nil && floorplanJob!.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                                price = floorplanJob!.flooringMaterialTier3CostPerSqFt
                                                            } else if product.isTierThree && company.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                                price = company.flooringMaterialTier3CostPerSqFt
                                                            }

                                                            var workOrderProductParams: [String : AnyObject] = ["quantity": backsplashSqFt]
                                                            if let price = price {
                                                                workOrderProductParams["price"] = price
                                                            }

                                                            workOrder.addWorkOrderProductForJobProduct(jobProduct, params: workOrderProductParams,
                                                                onSuccess: { statusCode, mappingResult in
                                                                    self.selectedPolygonView?.redraw()
                                                                    self.selectedPolygonView = nil

                                                                    // TODO: show work order popover?
                                                                },
                                                                onError: { error, statusCode, responseString in
                                                                    print(responseString)
                                                                }
                                                            )
                                                        },
                                                        onError: { error, statusCode, responseString -> () in
                                                            print(responseString)
                                                        }
                                                    )
                                                }
                                            }
                                        )
                                    }
                                } else {
                                    let backsplashSqFt = self.job.floorplans.first!.backsplashSqFt
                                    if backsplashSqFt != -1 {
                                        CompanyService.sharedService().fetch(companyId: self.job.companyId,
                                            onCompaniesFetched: { companies in
                                                if let company = companies.first {
                                                    var price: Double?
                                                    if product.isTierOne && floorplanJob != nil && floorplanJob!.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                        price = floorplanJob!.flooringMaterialTier1CostPerSqFt
                                                    } else if product.isTierOne && company.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                        price = company.flooringMaterialTier1CostPerSqFt
                                                    } else if product.isTierTwo && floorplanJob != nil && floorplanJob!.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                        price = floorplanJob!.flooringMaterialTier2CostPerSqFt
                                                    } else if product.isTierTwo && company.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                        price = company.flooringMaterialTier2CostPerSqFt
                                                    } else if product.isTierThree && floorplanJob != nil && floorplanJob!.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                        price = floorplanJob!.flooringMaterialTier3CostPerSqFt
                                                    } else if product.isTierThree && company.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                        price = company.flooringMaterialTier3CostPerSqFt
                                                    }

                                                    var jobProductParams: [String : AnyObject] = ["initial_quantity": backsplashSqFt]
                                                    if let price = price {
                                                        jobProductParams["price"] = price
                                                    }
                                                    self.job.addJobProductForProduct(product, params: jobProductParams,
                                                        onSuccess: { statusCode, mappingResult in
                                                            jobProduct = self.job.materials.last!

                                                            var price: Double?
                                                            if product.isTierOne && floorplanJob != nil && floorplanJob!.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                                price = floorplanJob!.flooringMaterialTier1CostPerSqFt
                                                            } else if product.isTierOne && company.flooringMaterialTier1CostPerSqFt != -1.0 {
                                                                price = company.flooringMaterialTier1CostPerSqFt
                                                            } else if product.isTierTwo && floorplanJob != nil && floorplanJob!.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                                price = floorplanJob!.flooringMaterialTier2CostPerSqFt
                                                            } else if product.isTierTwo && company.flooringMaterialTier2CostPerSqFt != -1.0 {
                                                                price = company.flooringMaterialTier2CostPerSqFt
                                                            } else if product.isTierThree && floorplanJob != nil && floorplanJob!.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                                price = floorplanJob!.flooringMaterialTier3CostPerSqFt
                                                            } else if product.isTierThree && company.flooringMaterialTier3CostPerSqFt != -1.0 {
                                                                price = company.flooringMaterialTier3CostPerSqFt
                                                            }

                                                            var workOrderProductParams = ["quantity": backsplashSqFt]
                                                            if let price = price {
                                                                workOrderProductParams["price"] = price
                                                            }

                                                            workOrder.addWorkOrderProductForJobProduct(jobProduct, params: workOrderProductParams,
                                                                onSuccess: { statusCode, mappingResult in
                                                                    self.selectedPolygonView?.redraw()
                                                                    self.selectedPolygonView = nil

                                                                    // TODO: show work order popover?
                                                                },
                                                                onError: { error, statusCode, responseString in
                                                                    print(responseString)
                                                                }
                                                            )
                                                        },
                                                        onError: { error, statusCode, responseString -> () in
                                                            print(responseString)
                                                        }
                                                    )
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        },
                        onError: { error, statusCode, responseString -> () in
                            print(responseString)
                        }
                    )
                },
                onError: { error, statusCode, responseString in
                    print(responseString)
                }
            )
        } else {
            selectedPolygonView = nil
        }
    }

    func productPickerViewController(viewController: ProductPickerViewController, didDeselectProduct: Product) {

    }

    func productPickerViewControllerAllowsMultipleSelection(viewController: ProductPickerViewController) -> Bool {
        return false
    }

    func selectedProductsForPickerViewController(viewController: ProductPickerViewController) -> [Product] {
        return [Product]()
    }

    func collectionViewScrollDirectionForPickerViewController(viewController: ProductPickerViewController) -> UICollectionViewScrollDirection {
        return .Horizontal
    }

    // MARK: WorkOrderCreationViewControllerDelegate

    func blueprintPinViewForWorkOrderCreationViewController(viewController: WorkOrderCreationViewController) -> BlueprintPinView! {
        if let workOrder = viewController.workOrder {
            return pinViewForWorkOrder(workOrder)
        }
        return nil
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, numberOfSectionsInTableView tableView: UITableView) -> Int {
        return 1
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.section == 0 ? 75.0 : 44.0
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let isNewRecord = viewController.workOrder == nil || viewController.workOrder.id == 0
//        let isPunchlist = job.isPunchlist
        return 1 //section == 0 ? (isNewRecord ? 2 : (isPunchlist ? 2 : 4)) : 1
    }

    func workOrderCreationViewController(workOrderCreationViewController: WorkOrderCreationViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let navigationController = workOrderCreationViewController.navigationController {
            var viewController: UIViewController!

            switch indexPath.row {
            case 0:
                PDTSimpleCalendarViewCell.appearance().circleSelectedColor = Color.darkBlueBackground()
                PDTSimpleCalendarViewCell.appearance().textDisabledColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)

                let calendarViewController = CalendarViewController()
                calendarViewController.delegate = workOrderCreationViewController
                calendarViewController.weekdayHeaderEnabled = true
                calendarViewController.firstDate = NSDate()

                viewController = calendarViewController
            case 1:
                viewController = UIStoryboard("CategoryPicker").instantiateViewControllerWithIdentifier("CategoryPickerViewController")
                (viewController as! CategoryPickerViewController).delegate = workOrderCreationViewController
                CategoryService.sharedService().fetch(companyId: workOrderCreationViewController.workOrder.companyId,
                    onCategoriesFetched: { categories in
                        (viewController as! CategoryPickerViewController).categories = categories

                        if let selectedCategory = workOrderCreationViewController.workOrder.category {
                            (viewController as! CategoryPickerViewController).selectedCategories = [selectedCategory]
                        }
                    }
                )
            case 2:
                viewController = UIStoryboard("WorkOrderCreation").instantiateViewControllerWithIdentifier("WorkOrderTeamViewController")
                (viewController as! WorkOrderTeamViewController).delegate = workOrderCreationViewController
//            case 3:
//                viewController = UIStoryboard("WorkOrderCreation").instantiateViewControllerWithIdentifier("WorkOrderInventoryViewController")
//                (viewController as! WorkOrderInventoryViewController).delegate = workOrderCreationViewController
//            case 4:
//                viewController = UIStoryboard("Expenses").instantiateViewControllerWithIdentifier("ExpensesViewController")
//                (viewController as! ExpensesViewController).expenses = workOrderCreationViewController.workOrder.expenses
//                (viewController as! ExpensesViewController).delegate = self
            default:
                break
            }

            if let vc = viewController {
                navigationController.pushViewController(vc, animated: true)
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, cellForTableView tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell! {
        return nil
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCreateWorkOrder workOrder: WorkOrder) {
        if let blueprint = blueprint {
            let annotation = Annotation()
            if let pinView = selectedPinView {
                annotation.point = [pinView.point.x, pinView.point.y]
            } else if let polygonView = polygonView {
                annotation.polygon = polygonView.polygon
            }
            annotation.workOrderId = workOrder.id
            annotation.workOrder = workOrder
            annotation.save(blueprint,
                onSuccess: { [weak self] statusCode, mappingResult in
                    self!.refreshAnnotations()
                    self!.dismissWorkOrderCreationPinView()
                    self!.dismissWorkOrderCreationPolygonView()
                    viewController.reloadTableView()
                },
                onError: { error, statusCode, responseString in

                }
            )
        }
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didSubmitForApprovalWorkOrder workOrder: WorkOrder) {
        if let presentedViewController = presentedViewController {
            if presentedViewController is UINavigationController {
                let viewController = (presentedViewController as! UINavigationController).viewControllers.first!
                if viewController is WorkOrderCreationViewController {
                    presentedViewController.dismissViewController(animated: true) {
                        NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
                    }
                }
            }
        }
    }

    private func refreshPinViewForWorkOrder(workOrder: WorkOrder) {
        if let pinView = pinViewForWorkOrder(workOrder) {
            pinView.redraw()
        }
    }

    private func refreshPolygonViewForWorkOrder(workOrder: WorkOrder) {
        if let polygonView = polygonViewForWorkOrder(workOrder) {
            polygonView.redraw()
        }
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didStartWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCancelWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCompleteWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didApproveWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didRejectWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didRestartWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCreateExpense expense: Expense) {
        if let presentedViewController = presentedViewController {
            if presentedViewController is UINavigationController {
                let viewController = (presentedViewController as! UINavigationController).viewControllers.first!
                if viewController is WorkOrderCreationViewController {
                    (viewController as! WorkOrderCreationViewController).workOrder.prependExpense(expense)
                    (viewController as! WorkOrderCreationViewController).reloadTableView()
                }
            }
        }

        refreshWorkOrderCreationView()
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, shouldBeDismissedWithWorkOrder workOrder: WorkOrder!) {
        newWorkOrderPending = false
        toolbar.reload()
        dismissViewController(animated: true)
        if workOrder == nil {
            if let selectedPinView = selectedPinView {
                if let index = pinViews.indexOfObject(selectedPinView) {
                    pinViews.removeAtIndex(index)
                    selectedPinView.removeFromSuperview()
                }
            }
        }
        selectedPolygonView = nil
        selectedPinView = nil
    }

    func flatFeeForNewProvider(provider: Provider, forWorkOrderCreationViewController viewController: WorkOrderCreationViewController) -> Double! {
        let workOrder = viewController.workOrder
        if let job = job {
            if let floorplanJob = job.floorplanJobs.first {
                let floorplan = floorplanJob.floorplan
                if floorplanJob.supportsBacksplash {
                    for backsplashProductOptions in floorplan.backsplashProductOptions {
                        for workOrderProduct in workOrder.materials {
                            if workOrderProduct.jobProduct.productId == backsplashProductOptions.id {
                                let backsplashLaborPricePerLfFt = 11.0 // FIXME-- determine if straight/diag/running bong
                                return (floorplanJob.backsplashFullLf * backsplashLaborPricePerLfFt) + (floorplanJob.backsplashPartialLf * backsplashLaborPricePerLfFt * 0.5)
                            }
                        }
                    }
                }

                for flooringProductOption in floorplan.flooringProductOptions {
                    for workOrderProduct in workOrder.materials {
                        let product = workOrderProduct.jobProduct.product
                        if product.id == flooringProductOption.id {
                            var flooringLaborPricePerSqFt: Double?
                            if product.isTierOne && floorplanJob.flooringLaborTier1RevenuePerSqFt != -1.0 {
                                flooringLaborPricePerSqFt = floorplanJob.flooringLaborTier1RevenuePerSqFt
                            } else if product.isTierTwo && floorplanJob.flooringLaborTier2RevenuePerSqFt != -1.0 {
                                flooringLaborPricePerSqFt = floorplanJob.flooringLaborTier2RevenuePerSqFt
                            } else if product.isTierThree && floorplanJob.flooringLaborTier3RevenuePerSqFt != -1.0 {
                                flooringLaborPricePerSqFt = floorplanJob.flooringLaborTier3RevenuePerSqFt
                            }

                            if let flooringLaborPricePerSqFt = flooringLaborPricePerSqFt {
                                return flooringLaborPricePerSqFt * workOrderProduct.quantity
                            }
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
