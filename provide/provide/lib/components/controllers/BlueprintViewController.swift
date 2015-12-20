//
//  BlueprintViewController.swift
//  provide
//
//  Created by Kyle Thomas on 10/23/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol BlueprintViewControllerDelegate: NSObjectProtocol {
    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job!
    func blueprintImageForBlueprintViewController(viewController: BlueprintViewController) -> UIImage!
    optional func scaleCanBeSetByBlueprintViewController(viewController: BlueprintViewController) -> Bool
    optional func newWorkOrderCanBeCreatedByBlueprintViewController(viewController: BlueprintViewController) -> Bool
    optional func navigationControllerForBlueprintViewController(viewController: BlueprintViewController) -> UINavigationController!
}

class BlueprintViewController: WorkOrderComponentViewController,
                               UIScrollViewDelegate,
                               BlueprintScaleViewDelegate,
                               BlueprintThumbnailViewDelegate,
                               BlueprintToolbarDelegate,
                               BlueprintPolygonViewDelegate,
                               WorkOrderCreationViewControllerDelegate,
                               UIPopoverPresentationControllerDelegate {

    weak var blueprintViewControllerDelegate: BlueprintViewControllerDelegate! {
        didSet {
            if let _ = blueprintViewControllerDelegate {
                if !loadedBlueprint && scrollView != nil {
                    loadBlueprint()
                }
            }
        }
    }

    private var thumbnailView: BlueprintThumbnailView!

    private var imageView: UIImageView!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

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

    private var polygonViews = [BlueprintPolygonView]()

    weak var job: Job! {
        if let job = blueprintViewControllerDelegate?.jobForBlueprintViewController(self) {
            return job
        }
        if let workOrder = workOrder {
            return workOrder.job
        }
        return nil
    }

    var workOrder: WorkOrder!

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
                activityIndicatorView.startAnimating()
            }
        }
    }

    private var loadingAnnotations = false {
        didSet {
            if !loadingBlueprint && !loadingAnnotations {
                activityIndicatorView.stopAnimating()
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

        imageView = UIImageView()
        imageView.alpha = 0.0
        imageView.userInteractionEnabled = true
        imageView.contentMode = .ScaleToFill

        scrollView.backgroundColor = UIColor(red: 0.11, green: 0.29, blue: 0.565, alpha: 0.45)
        scrollView.addSubview(imageView)
        scrollView.bringSubviewToFront(imageView)

        toolbar.alpha = 0.0
        toolbar.blueprintToolbarDelegate = self
        toolbar.barTintColor = UIColor.blackColor().colorWithAlphaComponent(0.5)

        hideToolbar()
        loadBlueprint()
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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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

        if let navigationController = navigationController {
            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
                animations: { [weak self] in
                    self!.view.alpha = 0.0
                    navigationController.view.alpha = 0.0
                    navigationController.view.frame = self!.hiddenNavigationControllerFrame
                },
                completion: nil
            )
        }
    }

    private func loadBlueprint() {
        if let job = job {
            if let image = blueprintViewControllerDelegate?.blueprintImageForBlueprintViewController(self) {
                setBlueprintImage(image)
                loadAnnotations()
            } else if let url = job.blueprintImageUrl {
                loadingBlueprint = true

                ApiService.sharedService().fetchImage(url,
                    onImageFetched: { statusCode, image in
                        dispatch_after_delay(0.0) { [weak self] in
                            self!.setBlueprintImage(image)
                        }
                    },
                    onError: { error, statusCode, responseString in

                    }
                )

                loadAnnotations()
            }
        }
    }

    private func setBlueprintImage(image: UIImage) {
        let size = CGSize(width: image.size.width, height: image.size.height)

        imageView!.image = image
        imageView!.frame = CGRect(origin: CGPointZero, size: size)

        thumbnailView?.blueprintImage = image

        scrollView.contentSize = size
        scrollView.scrollEnabled = false

        enableScrolling = true

        scrollView.minimumZoomScale = 0.2
        scrollView.maximumZoomScale = 1.0
        scrollView.zoomScale = 0.4

        imageView.alpha = 1.0

        loadingBlueprint = false
        toolbar.reload()

        showToolbar()
        loadedBlueprint = true
    }

    private func loadAnnotations() {
        if let job = job {
            if let blueprint = job.blueprint {
                loadingAnnotations = true
                let rpp = max(100, job.blueprintAnnotationsCount)
                let params = ["page": "1", "rpp": "\(rpp)"]
                blueprint.fetchAnnotations(params,
                    onSuccess: { [weak self] statusCode, mappingResult in
                        self!.refreshAnnotations()
                        self!.loadingAnnotations = false
                    },
                    onError: { [weak self] error, statusCode, responseString in
                        self!.loadingAnnotations = false
                    }
                )
            }
        }
    }

    private func polygonViewForWorkOrder(workOrder: WorkOrder) -> BlueprintPolygonView! {
        var polygonView: BlueprintPolygonView!
        for view in polygonViews {
            if let annotation = view.annotation {
                if let wo = annotation.workOrder {
                    if wo.id == workOrder.id {
                        polygonView = view
                        break
                    }
                } else if annotation.workOrderId == workOrder.id {
                    polygonView = view
                    break
                }
            }
        }
        if polygonView == nil {
            polygonView = self.polygonView
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
        for annotation in job.blueprint.annotations {
            if polygonView == polygonViewForWorkOrder(annotation.workOrder) {
                let polygonView = BlueprintPolygonView(delegate: self, annotation: annotation)
                imageView.addSubview(polygonView)
                polygonView.alpha = 1.0
                polygonView.attachGestureRecognizer()

                polygonViews.append(polygonView)
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
                self!.initialToolbarFrame = self!.toolbar.frame
            }
        }

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: { [weak self] in
                self!.toolbar.alpha = 0.0
                self!.toolbar.frame.origin.y += self!.toolbar.frame.size.height
            }, completion: { completed in

            }
        )
    }

    private func showToolbar() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: { [weak self] in
                self!.toolbar.alpha = 1.0
                if let initialToolbarFrame = self!.initialToolbarFrame {
                    self!.toolbar.frame = initialToolbarFrame
                } else {
                    self!.toolbar.frame.origin.y -= self!.toolbar.frame.size.height
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

        if let job = job {
            job.updateJobBlueprintScale(scale,
                onSuccess: { [weak self] statusCode, mappingResult in
                    self!.toolbar.reload()
                }, onError: { error, statusCode, responseString in

                }
            )
        }
    }

    func cancelCreateWorkOrder(sender: UIBarButtonItem) {
        newWorkOrderPending = false
        dismissWorkOrderCreationPolygonView()
        toolbar.reload()
    }

    func dismissWorkOrderCreationPolygonView() {
        polygonView.resignFirstResponder(false)
        restoreCachedNavigationItem()
    }

    func createWorkOrder(sender: UIBarButtonItem) {
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

        let cancelItem = UIBarButtonItem(title: "CANCEL", style: .Plain, target: self, action: "cancelSetScale:")
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Disabled)

        let setScaleItem = UIBarButtonItem(title: "SET SCALE", style: .Plain, target: self, action: "setScale:")
        setScaleItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        setScaleItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Disabled)
        setScaleItem.enabled = setScaleEnabled

        navigationItem.leftBarButtonItems = [cancelItem]
        navigationItem.rightBarButtonItems = [setScaleItem]
    }

    private func overrideNavigationItemForCreatingWorkOrder(setCreateEnabled: Bool = false) {
        cacheNavigationItem(navigationItem)

        let cancelItem = UIBarButtonItem(title: "CANCEL", style: .Plain, target: self, action: "cancelCreateWorkOrder:")
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Disabled)

        let createWorkOrderItem = UIBarButtonItem(title: "CREATE WORK ORDER", style: .Plain, target: self, action: "createWorkOrder:")
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
        if let job = job {
            return CGFloat(job.blueprintScale)
        }

        return 1.0
    }

    func blueprintScaleViewCanSetBlueprintScale(view: BlueprintScaleView) {
        overrideNavigationItemForSettingScale(true)
    }

    func blueprintScaleViewDidReset(view: BlueprintScaleView) {
        toolbar.toggleScaleVisibility()
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
        return 0.2
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
        if let blueprint = job?.blueprint {
            return blueprint
        }
        return Attachment()
    }

    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetNavigatorVisibility visible: Bool) {
        let alpha = CGFloat(visible ? 1.0 : 0.0)
        thumbnailView?.alpha = alpha
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
        if let canSetScale = blueprintViewControllerDelegate?.scaleCanBeSetByBlueprintViewController?(self) {
            return canSetScale
        }
        return true
    }

    func newWorkOrderItemIsShownByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool {
        if let canSetScale = blueprintViewControllerDelegate?.scaleCanBeSetByBlueprintViewController?(self) {
            return !canSetScale
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

        if let newWorkOrderCanBeCreated = blueprintViewControllerDelegate?.newWorkOrderCanBeCreatedByBlueprintViewController?(self) {
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

    func blueprintToolbar(toolbar: BlueprintToolbar, shouldPresentAlertController alertController: UIAlertController) {
        navigationController!.presentViewController(alertController, animated: true)
    }

    // MARK: BlueprintPolygonViewDelegate

    func blueprintPolygonViewCanBeResized(view: BlueprintPolygonView) -> Bool {
        if let annotation = view.annotation {
            if let workOrder = annotation.workOrder {
                return ["awaiting_schedule", "scheduled", "in_progress"].indexOfObject(workOrder.status) != nil
            }
        }
        return true
    }

    func blueprintScaleForBlueprintPolygonView(view: BlueprintPolygonView) -> CGFloat! {
        if let job = job {
            return CGFloat(job.blueprintScale)
        }
        return nil
    }

    func blueprintImageViewForBlueprintPolygonView(view: BlueprintPolygonView) -> UIImageView! {
        return imageView
    }

    func blueprintForBlueprintPolygonView(view: BlueprintPolygonView) -> Attachment! {
        if let job = job {
            return job.blueprint
        }
        return nil
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
    }

    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        let size = imageView.image!.size
        let width = size.width * scale
        let height = size.height * scale
        imageView.frame.size = CGSize(width: width, height: height)
        scrollView.contentSize = CGSize(width: width, height: height)

        showToolbar()
    }

    // MARK: WorkOrderCreationViewControllerDelegate

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, numberOfSectionsInTableView tableView: UITableView) -> Int {
        return 2
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.section == 0 ? 44.0 : 200.0
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 6 : 1
    }

    func workOrderCreationViewController(workOrderCreationViewController: WorkOrderCreationViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let navigationController = workOrderCreationViewController.navigationController {
            var viewController: UIViewController!

            switch indexPath.row {
            case 0:
                PDTSimpleCalendarViewCell.appearance().circleSelectedColor = Color.darkBlueBackground()
                PDTSimpleCalendarViewCell.appearance().textDisabledColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)

                let calendarViewController = PDTSimpleCalendarViewController()
                calendarViewController.delegate = workOrderCreationViewController
                calendarViewController.weekdayHeaderEnabled = true
                calendarViewController.firstDate = NSDate()

                viewController = calendarViewController
            case 1:
                viewController = UIStoryboard("WorkOrderCreation").instantiateViewControllerWithIdentifier("WorkOrderTeamViewController")
                (viewController as! WorkOrderTeamViewController).delegate = workOrderCreationViewController
            case 2:
                print("open up the sq footage cost details editor!!!")
            case 3:
                print("open up the master cost model editor!!!")
            case 4:
//                viewController = UIStoryboard("Manifest").instantiateViewControllerWithIdentifier("ManifestViewController")
//                (viewController as! ManifestViewController).delegate = workOrderCreationViewController

                viewController = UIStoryboard("WorkOrderCreation").instantiateViewControllerWithIdentifier("WorkOrderInventoryViewController")
                (viewController as! WorkOrderInventoryViewController).delegate = workOrderCreationViewController
            case 5:
                viewController = UIStoryboard("Expenses").instantiateViewControllerWithIdentifier("ExpensesViewController")
                (viewController as! ExpensesViewController).expenses = workOrderCreationViewController.workOrder.expenses
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
        if indexPath.section > 0 {
            return nil
        }

        let workOrder = viewController.workOrder

        let polygonView = polygonViewForWorkOrder(workOrder)

        let cell = tableView.dequeueReusableCellWithIdentifier("nameValueTableViewCellReuseIdentifier") as! NameValueTableViewCell
        cell.enableEdgeToEdgeDividers()

        switch indexPath.row {
        case 0:
            var scheduledStartTime = "--"
            if let humanReadableScheduledStartTime = workOrder.humanReadableScheduledStartAtTimestamp {
                scheduledStartTime = humanReadableScheduledStartTime
            }

            cell.setName("\(workOrder.status.uppercaseString)", value: scheduledStartTime)
            cell.backgroundView!.backgroundColor = workOrder.statusColor
            cell.accessoryType = .DisclosureIndicator
        case 1:
            var specificProviders = ""
            let detailDisplayCount = 3
            var i = 0
            for provider in workOrder.providers {
                if i == detailDisplayCount {
                    break
                }
                specificProviders += ", \(provider.contact.name)"
                i++
            }
            let matches = Regex.match("^, ", input: specificProviders)
            if matches.count > 0 {
                let match = matches[0]
                let range = Range<String.Index>(start: specificProviders.startIndex.advancedBy(match.range.length), end: specificProviders.endIndex)
                specificProviders = specificProviders.substringWithRange(range)
            }
            var providers = "\(specificProviders)"
            if workOrder.providers.count > detailDisplayCount {
                providers += " and \(workOrder.providers.count - detailDisplayCount) other"
                if workOrder.providers.count - detailDisplayCount > 1 {
                    providers += "s"
                }
            } else if workOrder.providers.count == 0 {
                providers += "No one"
            }
            providers += " assigned"
            if workOrder.providers.count >= detailDisplayCount {
                cell.setName("PROVIDERS", value: providers, valueFontSize: isIPad() ? 13.0 : 11.0)
            } else {
                cell.setName("PROVIDERS", value: providers)
            }
            cell.accessoryType = .DisclosureIndicator
        case 2:
            cell.setName("ESTIMATED SQ FT", value: "\(NSString(format: "%.03f", polygonView.area)) sq ft")
            cell.accessoryType = .DisclosureIndicator
        case 3:
            if let humanReadableEstimatedCost = workOrder.humanReadableEstimatedCost {
                cell.setName("ESTIMATED COST", value: humanReadableEstimatedCost, valueFontSize: isIPad() ? 13.0 : 11.0)
                cell.accessoryType = .DisclosureIndicator
            } else {
                cell.setName("ESTIMATED COST", value: "")
                cell.showActivity(false)
            }

        case 4:
            if let _ = workOrder.materials {
                let inventoryDisposition = workOrder.inventoryDisposition
                cell.setName("MATERIALS", value: inventoryDisposition, valueFontSize: isIPad() ? 13.0 : 11.0)
                cell.accessoryType = .DisclosureIndicator
            } else {
                cell.setName("MATERIALS", value: "")
                cell.showActivity(false)
            }
        case 5:
            if let expensesDisposition = workOrder.expensesDisposition {
                cell.setName("EXPENSES", value: expensesDisposition, valueFontSize: isIPad() ? 13.0 : 11.0)
                cell.accessoryType = .DisclosureIndicator
            } else {
                cell.setName("EXPENSES", value: "")
                cell.showActivity(false)
            }

        default:
            break
        }

        return cell
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCreateWorkOrder workOrder: WorkOrder) {
        if let job = job {
            if let blueprint = job.blueprint {
                let annotation = Annotation()
                annotation.polygon = polygonView.polygon
                annotation.workOrderId = workOrder.id
                annotation.workOrder = workOrder
                annotation.save(blueprint,
                    onSuccess: { [weak self] statusCode, mappingResult in
                        self!.refreshAnnotations()
                        self!.dismissWorkOrderCreationPolygonView()
                    },
                    onError: { error, statusCode, responseString in

                    }
                )
            }
        }
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
    }

    // MARK: UIPopoverPresentationControllerDelegate

//    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
//        return .None
//    }

    func popoverPresentationControllerShouldDismissPopover(popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }

    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {

    }

    func popoverPresentationController(popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverToRect rect: UnsafeMutablePointer<CGRect>, inView view: AutoreleasingUnsafeMutablePointer<UIView?>) {

    }

    deinit {
        thumbnailView?.removeFromSuperview()
    }
}
