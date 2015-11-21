//
//  BlueprintViewController.swift
//  provide
//
//  Created by Kyle Thomas on 10/23/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintViewControllerDelegate {
    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job!
}

class BlueprintViewController: WorkOrderComponentViewController,
                               UIScrollViewDelegate,
                               BlueprintScaleViewDelegate,
                               BlueprintThumbnailViewDelegate,
                               BlueprintToolbarDelegate,
                               BlueprintPolygonViewDelegate,
                               WorkOrderCreationViewControllerDelegate,
                               UIPopoverPresentationControllerDelegate {

    var blueprintViewControllerDelegate: BlueprintViewControllerDelegate!

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

    @IBOutlet private weak var thumbnailView: BlueprintThumbnailView! {
        didSet {
            if let thumbnailView = thumbnailView {
                thumbnailView.delegate = self
                thumbnailView.backgroundColor = UIColor.whiteColor() //.colorWithAlphaComponent(0.85)
                thumbnailView.roundCorners(5.0)
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

    var job: Job! {
        if let job = blueprintViewControllerDelegate?.jobForBlueprintViewController(self) {
            return job
        }
        if let workOrder = workOrder {
            return workOrder.job
        }
        return nil
    }

    private var imageView: UIImageView!

    private var enableScrolling = false {
        didSet {
            if let scrollView = scrollView {
                scrollView.scrollEnabled = enableScrolling
            }
        }
    }

    private var workOrder: WorkOrder! {
        return WorkOrderService.sharedService().inProgressWorkOrder
    }

    private var hiddenNavigationControllerFrame: CGRect {
        return CGRect(
            x: 0.0,
            y: targetView.frame.height,
            width: targetView.frame.width,
            height: targetView.frame.height // / 1.333
        )
    }

    private var renderedNavigationControllerFrame: CGRect {
        return CGRect(
            x: 0.0,
            y: hiddenNavigationControllerFrame.origin.y - hiddenNavigationControllerFrame.height,
            width: hiddenNavigationControllerFrame.width,
            height: hiddenNavigationControllerFrame.height
        )
    }

    private var cachedNavigationItem: UINavigationItem!

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

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()

        imageView = UIImageView()
        imageView.alpha = 0.0
        imageView.userInteractionEnabled = true

        scrollView.backgroundColor = UIColor(red: 0.11, green: 0.29, blue: 0.565, alpha: 0.45)

        toolbar.alpha = 0.0
        toolbar.blueprintToolbarDelegate = self
        toolbar.backgroundColor = UIColor.blackColor()

        hideToolbar()
        loadBlueprint()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    func setupNavigationItem() {
        navigationItem.hidesBackButton = true

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
        }
    }

    override func unwind() {
        clearNavigationItem()

        if let navigationController = navigationController {
            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
                animations: {
                    self.view.alpha = 0.0
                    navigationController.view.alpha = 0.0
                    navigationController.view.frame = self.hiddenNavigationControllerFrame
                },
                completion: nil
            )
        }
    }

    private func loadBlueprint() {
        if let job = job {
            if let url = job.blueprintImageUrl {
                loadingBlueprint = true

                imageView.sd_setImageWithURL(url) { (image, error, cacheType, url) -> Void in
                    let size = CGSize(width: image.size.width, height: image.size.height)

                    self.thumbnailView.blueprintImage = image

                    self.imageView.frame = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
                    self.imageView.contentMode = .ScaleToFill

                    self.scrollView.contentSize = size
                    self.scrollView.scrollEnabled = false
                    self.scrollView.addSubview(self.imageView)
                    
                    self.enableScrolling = true

                    self.scrollView.minimumZoomScale = 0.25
                    self.scrollView.maximumZoomScale = 1.0
                    self.scrollView.zoomScale = 0.4

                    UIView.animateWithDuration(0.1, animations: { () -> Void in
                        self.scrollView.bringSubviewToFront(self.imageView)
                        self.imageView.alpha = 1.0

                        self.loadingBlueprint = false
                    })

                    self.showToolbar()
                }

                loadAnnotations()
            }
        }
    }

    private func loadAnnotations() {
        if let job = job {
            if let blueprint = job.blueprint {
                loadingAnnotations = true
                let rpp = max(100, job.blueprintAnnotationsCount)
                let params = ["page": "1", "rpp": "\(rpp)"]
                blueprint.fetchAnnotations(params,
                    onSuccess: { statusCode, mappingResult in
                        self.refreshAnnotations()
                        self.loadingAnnotations = false
                    },
                    onError: { error, statusCode, responseString in
                        self.loadingAnnotations = false
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
//            let annotation = Annotation()
//            annotation.workOrderId = workOrder.id
//            annotation.workOrder = workOrder
//
//            polygonView = BlueprintPolygonView(delegate: self, annotation: annotation)
//            imageView.addSubview(polygonView)
//            polygonView.alpha = 1.0
//            polygonView.attachGestureRecognizer()
//
//            polygonViews.append(polygonView)
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
            let polygonView = BlueprintPolygonView(delegate: self, annotation: annotation)
            imageView.addSubview(polygonView)
            polygonView.alpha = 1.0
            polygonView.attachGestureRecognizer()

            polygonViews.append(polygonView)
        }
    }

    private func hideToolbar() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.toolbar.alpha = 0.0
                self.toolbar.frame.origin.y += self.toolbar.frame.size.height
            }, completion: { completed in

            }
        )
    }

    private func showToolbar() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.toolbar.alpha = 1.0
                self.toolbar.frame.origin.y -= self.toolbar.frame.size.height
            }, completion: { completed in

            }
        )
    }

    func cancelSetScale(sender: UIBarButtonItem) {
        scaleView.resignFirstResponder(false)
        restoreCachedNavigationItem()
    }

    func setScale(sender: UIBarButtonItem) {
        let scale = scaleView.scale
        scaleView.resignFirstResponder(false)

        restoreCachedNavigationItem()

        if let job = job {
            job.updateJobBlueprintScale(scale,
                onSuccess: { statusCode, mappingResult in
                    print("set scale of \(scale) pixels per foot")
                }, onError: { error, statusCode, responseString in

                }
            )
        }
    }

    func cancelCreateWorkOrder(sender: UIBarButtonItem) {
        polygonView.resignFirstResponder(false)
        restoreCachedNavigationItem()
    }

    func createWorkOrder(sender: UIBarButtonItem) {
        let createWorkOrderViewController = UIStoryboard("Provider").instantiateViewControllerWithIdentifier("WorkOrderCreationViewController") as! WorkOrderCreationViewController

        let workOrder = WorkOrder()
        workOrder.company = job!.company
        workOrder.companyId = job!.companyId
        workOrder.customer = job!.customer
        workOrder.customerId = job!.customerId
        workOrder.job = job!
        workOrder.jobId = job!.id
        workOrder.status = "awaiting_schedule"
        workOrder.itemsDelivered = [Product]()
        workOrder.itemsOrdered = [Product]()
        workOrder.itemsRejected = [Product]()

        createWorkOrderViewController.workOrder = workOrder
        createWorkOrderViewController.delegate = self

        let navigationController = UINavigationController(rootViewController: createWorkOrderViewController)
        navigationController.modalPresentationStyle = .FormSheet

        presentViewController(navigationController, animated: true)
    }

    private func overrideNavigationItemForSettingScale(setScaleEnabled: Bool = false) {
        var navigationItem: UINavigationItem!
        if let navItem = workOrdersViewControllerDelegate?.navigationControllerNavigationItemForViewController?(self) {
            navigationItem = navItem
        } else {
            navigationItem = self.navigationItem
        }

        if let navigationItem = navigationItem {
            cacheNavigationItem(navigationItem)

            if let navigationController = workOrdersViewControllerDelegate?.navigationControllerForViewController?(self) {
                navigationController.setNavigationBarHidden(false, animated: true)
            }

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
    }

    private func overrideNavigationItemForCreatingWorkOrder(setCreateEnabled: Bool = false) {
        var navigationItem: UINavigationItem!
        if let navItem = workOrdersViewControllerDelegate?.navigationControllerNavigationItemForViewController?(self) {
            navigationItem = navItem
        } else {
            navigationItem = self.navigationItem
        }

        if let navigationItem = navigationItem {
            cacheNavigationItem(navigationItem)

            if let navigationController = workOrdersViewControllerDelegate?.navigationControllerForViewController?(self) {
                navigationController.setNavigationBarHidden(false, animated: true)
            }

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
        if let navigationItem = workOrdersViewControllerDelegate?.navigationControllerNavigationItemForViewController?(self) {
            if let cachedNavigationItem = cachedNavigationItem {
                navigationItem.leftBarButtonItems = cachedNavigationItem.leftBarButtonItems
                navigationItem.rightBarButtonItems = cachedNavigationItem.rightBarButtonItems
                navigationItem.title = cachedNavigationItem.title
                navigationItem.titleView = cachedNavigationItem.titleView
                navigationItem.prompt = cachedNavigationItem.prompt

                self.cachedNavigationItem = nil
            }
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

    // MARK: BlueprintThumbnailViewDelegate

    func blueprintThumbnailView(
        view: BlueprintThumbnailView, navigatedToFrame frame: CGRect) {
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
        return 0.4
    }

    func sizeForBlueprintThumbnailView(view: BlueprintThumbnailView) -> CGSize {
        let imageSize = imageView.image!.size
        let aspectRatio = CGFloat(imageSize.width / imageSize.height)
        let height = CGFloat(imageSize.width > imageSize.height ? 225.0 : 375.0)
        let width = aspectRatio * height
        return CGSize(width: width, height: height)
    }

    // MARK: BlueprintToolbarDelegate

    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetNavigatorVisibility visible: Bool) {
        let alpha = CGFloat(visible ? 1.0 : 0.0)
        thumbnailView.alpha = alpha
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

    func newWorkOrderShouldBeCreatedByBlueprintToolbar(toolbar: BlueprintToolbar) {
        polygonView.alpha = 1.0
        polygonView.attachGestureRecognizer()

        overrideNavigationItemForCreatingWorkOrder(false) // FIXME: pass true when polygonView has both line endpoints drawn...
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
        textLayer.string = "\(view.area) ft²"
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
                let createWorkOrderViewController = UIStoryboard("Provider").instantiateViewControllerWithIdentifier("WorkOrderCreationViewController") as! WorkOrderCreationViewController
                createWorkOrderViewController.workOrder = workOrder
                createWorkOrderViewController.delegate = self
                createWorkOrderViewController.preferredContentSize = CGSizeMake(500, 600)

                let navigationController = UINavigationController(rootViewController: createWorkOrderViewController)
                navigationController.modalPresentationStyle = .Popover

                let popover = navigationController.popoverPresentationController!
                popover.delegate = self
                popover.sourceView = imageView
                popover.sourceRect = CGPathGetBoundingBox(path)
                popover.passthroughViews = [view]
                
                presentViewController(navigationController, animated: true)
            }
        }
    }

    // MARK: UIScrollViewDelegate

    func scrollViewDidScroll(scrollView: UIScrollView) {
        if enableScrolling {
            thumbnailView.scrollViewDidScroll(scrollView)
        }
    }

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
        hideToolbar()
    }

    func scrollViewDidZoom(scrollView: UIScrollView) {
        thumbnailView.scrollViewDidZoom(scrollView)
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
            cell.setName("STATUS", value: workOrder.status)
            cell.backgroundView!.backgroundColor = workOrder.statusColor
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
            var scheduledStartTime = ""
            if let humanReadableScheduledStartTime = workOrder.humanReadableScheduledStartAtTimestamp {
                scheduledStartTime = humanReadableScheduledStartTime
            }

            cell.setName(isIPad() ? "SCHEDULED START TIME" : "STARTING AT", value: scheduledStartTime)
            cell.accessoryType = .DisclosureIndicator
        case 3:
            cell.setName("ESTIMATED FT²", value: "\(polygonView.area) ft²")
            cell.accessoryType = .DisclosureIndicator
        case 4:
            let cost = workOrder.estimatedDuration == nil ? "--" : (workOrder.humanReadableDuration == nil ? "--" : workOrder.humanReadableDuration!)
            cell.setName("ESTIMATED COST", value: cost)
            cell.accessoryType = .DisclosureIndicator
        case 5:
            let inventoryDisposition = workOrder.inventoryDisposition == nil ? "--" : workOrder.inventoryDisposition
            cell.setName("INVENTORY DISPOSITION", value: inventoryDisposition, valueFontSize: isIPad() ? 13.0 : 11.0)
            cell.accessoryType = .DisclosureIndicator
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
                    onSuccess: { statusCode, mappingResult in
                        self.polygonView.annotation = mappingResult.firstObject as! Annotation
                        print("FIXME!!!!!!!!!!!!!! Append the polygon view to the polygonViews array")
                        print("\(self.polygonView)")
                    },
                    onError: { error, statusCode, responseString in

                    }
                )
            }
        }
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, shouldBeDismissedWithWorkOrder workOrder: WorkOrder!) {
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
}
