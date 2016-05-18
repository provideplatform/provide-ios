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
                               BlueprintScaleViewDelegate,
                               FloorplanSelectorViewDelegate,
                               BlueprintThumbnailViewDelegate,
                               BlueprintPinViewDelegate,
                               BlueprintWorkOrdersViewControllerDelegate,
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

    @IBOutlet private weak var scaleView: BlueprintScaleView! {
        didSet {
            if let scaleView = scaleView {
                scaleView.delegate = self
                scaleView.backgroundColor = UIColor.whiteColor()
                scaleView.clipsToBounds = true
                scaleView.roundCorners(5.0)
            }
        }
    }

    private var pinViews = [BlueprintPinView]()

    private var selectedPinView: BlueprintPinView! {
        didSet {
            if selectedPinView == nil {
                showPinViews()
            } else if selectedPinView != nil {
                hidePinViews(selectedPinView)
            }
        }
    }
    private var selectedPolygonView: BlueprintPolygonView!

    @IBOutlet private weak var blueprintWorkOrdersViewControllerContainer: UIView!
    private var blueprintWorkOrdersViewController: FloorplanWorkOrdersViewController!

    var floorplan: Floorplan!

    var floorplanImageUrl: NSURL! {
        if let floorplan = floorplan {
            return floorplan.imageUrl
        }
        return nil
    }

    var blueprintScale: Float! {
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

        let blueprintThumbnailViewController = UIStoryboard("Floorplan").instantiateViewControllerWithIdentifier("FloorplanThumbnailViewController") as! FloorplanThumbnailViewController
        thumbnailView = blueprintThumbnailViewController.thumbnailView
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

        scrollView?.backgroundColor = UIColor.whiteColor()
        scrollView?.addSubview(imageView)
        scrollView?.bringSubviewToFront(imageView)

        activityIndicatorView?.startAnimating()

        if floorplanViewControllerDelegate != nil && !loadedFloorplan && !loadingFloorplan && scrollView != nil {
            loadFloorplan()
        }

        NSNotificationCenter.defaultCenter().addObserverForName("WorkOrderChanged") { notification in
            if let workOrder = notification.object as? WorkOrder {
                if let floorplan = self.floorplan {
                    for wo in floorplan.workOrders {
                        if workOrder.id == wo.id {
                            dispatch_after_delay(0.0) {
                                // FIXME!!!!!!!!!!!! replace floorplans work order with this one... annotation.workOrder = workOrder

                                if let pinView = self.pinViewForWorkOrder(workOrder) {
                                    pinView.workOrder = workOrder
                                    pinView.redraw()
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

        if segue.identifier! == "BlueprintWorkOrdersViewControllerSegue" {
            let navigationController = segue.destinationViewController as! UINavigationController
            blueprintWorkOrdersViewController = navigationController.viewControllers.first! as! FloorplanWorkOrdersViewController
            blueprintWorkOrdersViewController.delegate = self
        }
    }

    func teardown() -> UIImage? {
        let image = imageView?.image
        imageView?.image = nil
        thumbnailView?.blueprintImage = nil
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
                self.thumbnailView?.blueprintImage = self.imageView.image
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
        if let url = floorplanImageUrl {
            loadingFloorplan = true

            ImageService.sharedService().fetchImage(url, cacheOnDisk: true,
                onDownloadSuccess: { [weak self] image in
                    dispatch_async_main_queue {
                        self!.activityIndicatorView?.stopAnimating()
                        self!.progressView?.setProgress(1.0, animated: false)
                        self!.setFloorplanImage(image)
                    }

                    if let blueprintWorkOrdersViewController = self!.blueprintWorkOrdersViewController {
                        blueprintWorkOrdersViewController.loadAnnotations()
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

    private func setFloorplanImage(image: UIImage) {
        let size = CGSize(width: image.size.width, height: image.size.height)

        imageView!.image = image
        imageView!.frame = CGRect(origin: CGPointZero, size: size)

        thumbnailView?.blueprintImage = image

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

            let workOrder = WorkOrder()
            //annotation.point = [point.x, point.y]

            newWorkOrderPending = true
            selectedPinView = BlueprintPinView(delegate: self, workOrder: workOrder)

            imageView.addSubview(selectedPinView)
            imageView.bringSubviewToFront(selectedPinView)
            selectedPinView.frame = CGRect(x: point.x, y: point.y, width: selectedPinView.bounds.width, height: selectedPinView.bounds.height)
            selectedPinView.frame.origin = CGPoint(x: selectedPinView.frame.origin.x - (selectedPinView.frame.size.width / 2.0),
                                                   y: selectedPinView.frame.origin.y - selectedPinView.frame.size.height)
            selectedPinView.alpha = 1.0
            selectedPinView.attachGestureRecognizer()
            pinViews.append(selectedPinView)

            blueprintWorkOrdersViewController?.createWorkOrder(gestureRecognizer)
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

    private func pinViewForWorkOrder(workOrder: WorkOrder!) -> BlueprintPinView! {
        var pinView: BlueprintPinView!
        for view in pinViews {
            if let wo = view.workOrder {
                if wo.id == workOrder?.id {
                    pinView = view
                    break
                }
            }
        }
        if pinView == nil {
            pinView = BlueprintPinView(delegate: self, workOrder: workOrder)
        }
        return pinView
    }

    private func removePinViews() {
        for view in pinViews {
            view.removeFromSuperview()
        }

        pinViews = [BlueprintPinView]()
    }

    private func refreshAnnotations() {
        if let floorplan = floorplan {
            for workOrder in floorplan.workOrders {
//                if annotation.point != nil {
//                    let pinView = BlueprintPinView(delegate: self, annotation: annotation)
//                    pinView.category = annotation.workOrder?.category
//                    pinView.frame = CGRect(x: annotation.point[0],
//                                           y: annotation.point[1],
//                                           width: pinView.bounds.width,
//                                           height: pinView.bounds.height)
//                    pinView.frame.origin = CGPoint(x: pinView.frame.origin.x - (pinView.frame.size.width / 2.0),
//                                                   y: pinView.frame.origin.y - pinView.frame.size.height)
//                    pinView.alpha = 1.0
//
//                    imageView.addSubview(pinView)
//                    imageView.bringSubviewToFront(pinView)
//
//                    pinView.attachGestureRecognizer()
//
//                    pinViews.append(pinView)
//                } else if let polygonView = polygonViewForWorkOrder(annotationWorkOrder) {
//                    imageView.addSubview(polygonView)
//                    polygonView.alpha = 1.0
//                    polygonView.attachGestureRecognizer()
//
//                    polygonViews.append(polygonView)
//                }
            }

//            for annotation in blueprint.annotations {
//                let annotationWorkOrder = annotation.workOrderId > 0 ? annotation.workOrder : nil
//                if annotation.point != nil {
//                    let pinView = BlueprintPinView(delegate: self, annotation: annotation)
//                    pinView.category = annotation.workOrder?.category
//                    pinView.frame = CGRect(x: annotation.point[0],
//                                           y: annotation.point[1],
//                                           width: pinView.bounds.width,
//                                           height: pinView.bounds.height)
//                    pinView.frame.origin = CGPoint(x: pinView.frame.origin.x - (pinView.frame.size.width / 2.0),
//                                                   y: pinView.frame.origin.y - pinView.frame.size.height)
//                    pinView.alpha = 1.0
//
//                    imageView.addSubview(pinView)
//                    imageView.bringSubviewToFront(pinView)
//                    
//                    pinView.attachGestureRecognizer()
//
//                    pinViews.append(pinView)
//                } else if let polygonView = polygonViewForWorkOrder(annotationWorkOrder) {
//                    imageView.addSubview(polygonView)
//                    polygonView.alpha = 1.0
//                    polygonView.attachGestureRecognizer()
//
//                    polygonViews.append(polygonView)
//                }
//            }

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
//        if let blueprint = blueprint {
//            var metadata = blueprint.metadata.mutableCopy() as! [String : AnyObject]
//            metadata["scale"] = scale
//            blueprint.updateAttachment(["metadata": metadata],
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
        //toolbar?.toggleScaleVisibility()
    }

    func blueprintScaleView(view: BlueprintScaleView, didSetScale scale: CGFloat) {
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
                toolbar.presentBlueprintAtIndexPath(indexPath)
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

    // MARK: BlueprintThumbnailViewDelegate

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
        let x = visible ? (view.frame.width - blueprintWorkOrdersViewControllerContainer.frame.size.width) : view.frame.width

        if visible {
            setFloorplanSelectorVisibility(false)
            setNavigatorVisibility(false)

            thumbnailTintView?.alpha = 0.2
            view.bringSubviewToFront(thumbnailTintView)
            view.bringSubviewToFront(blueprintWorkOrdersViewControllerContainer)
            insetScrollViewContentForBlueprintWorkOrdersPresentation()
        } else {
            thumbnailTintView?.alpha = 0.0
            scrollView.contentInset = UIEdgeInsetsZero
        }

        UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.blueprintWorkOrdersViewControllerContainer?.alpha = alpha != nil ? alpha : (visible ? 1.0 : 0.0)
                self.blueprintWorkOrdersViewControllerContainer?.frame.origin.x = x
            },
            completion:  { (completed) in

            }
        )
    }

    private func insetScrollViewContentForBlueprintWorkOrdersPresentation() {
        if scrollView.contentInset != UIEdgeInsetsZero {
            return
        }

        let widthInset = blueprintWorkOrdersViewControllerContainer.frame.width * 1.25
        let heightInset = widthInset

        scrollView.contentInset = UIEdgeInsets(top: heightInset,
                                               left: widthInset,
                                               bottom: heightInset,
                                               right: widthInset)
    }

    // MARK: BlueprintPinViewDelegate

    func tintColorForBlueprintPinView(view: BlueprintPinView) -> UIColor {
        if let workOrder = view.workOrder {
            return workOrder.statusColor
        }
        return UIColor.blueColor()
    }

    func categoryForBlueprintPinView(view: BlueprintPinView) -> Category! {
        if let workOrder = view.workOrder {
            return workOrder.category
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
        var delay = 0.0

        if selectedPinView != nil && selectedPinView == view {
            if let toolbar = floorplanViewControllerDelegate?.toolbarForFloorplanViewController(self) {
                toolbar.setWorkOrdersVisibility(false, alpha: 0.0)
            }

            if let workOrder = view.workOrder {
                floorplanViewControllerShouldFocusOnWorkOrder(workOrder, forFloorplanWorkOrdersViewController: blueprintWorkOrdersViewController)
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

    private func openWorkOrder(workOrder: WorkOrder, fromPinView pinView: BlueprintPinView! = nil, delay: Double = 0.0) {
        blueprintWorkOrdersViewController?.openWorkOrder(workOrder)
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

    private func hidePinViews(excludedPin: BlueprintPinView! = nil) {
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

    // MARK: BlueprintWorkOrdersViewControllerDelegate

    func floorplanForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) -> Floorplan! {
        return floorplan
    }

    func floorplanWorkOrdersViewControllerDismissedPendingWorkOrder(viewController: FloorplanWorkOrdersViewController) {
        newWorkOrderPending = false
    }

    func floorplanViewControllerShouldRedrawAnnotationPinsForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) {
        if !initializedAnnotations {
            initializedAnnotations = true
            if let blueprintWorkOrdersViewControllerContainer = blueprintWorkOrdersViewControllerContainer {
                if blueprintWorkOrdersViewControllerContainer.alpha == 0.0 {
                    dispatch_after_delay(0.0) {
                        blueprintWorkOrdersViewControllerContainer.frame.origin.x = self.view.frame.width
                        //blueprintWorkOrdersViewControllerContainer.alpha = 1.0
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

    func selectedPinViewForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) -> BlueprintPinView! {
        return selectedPinView
    }

    func selectedPolygonViewForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) -> BlueprintPolygonView! {
        return selectedPolygonView
    }

    func floorplanViewControllerShouldRemovePinView(pinView: BlueprintPinView, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) {
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

                        let offsetX = (self.blueprintWorkOrdersViewControllerContainer.frame.width / 2.0) - (pinView.frame.width / 2.0)
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

    func pinViewForWorkOrder(workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) -> BlueprintPinView! {
        return pinViewForWorkOrder(workOrder)
    }

    func polygonViewForWorkOrder(workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) -> BlueprintPolygonView! {
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
                    if let blueprintImageView = imageView {
                        let previewImage = blueprintImageView.image!.crop(overlayViewBoundingBox)
                        let previewView = UIImageView(image: previewImage)
//                        if let annotation = pinView.annotation {
//                            let pin = BlueprintPinView(annotation: annotation)
//                            pin.delegate = self
//                            previewView.addSubview(pin)
//                            previewView.bringSubviewToFront(pin)
//                            pin.alpha = 1.0
//                            if let sublayers = pin.layer.sublayers {
//                                for sublayer in sublayers {
//                                    sublayer.position.x -= overlayViewBoundingBox.origin.x
//                                    sublayer.position.y -= overlayViewBoundingBox.origin.y
//                                }
//                            }
//
//                            workOrder.previewImage = previewView.toImage()
//                        }
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
