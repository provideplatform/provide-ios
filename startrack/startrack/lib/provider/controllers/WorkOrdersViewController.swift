//
//  WorkOrdersViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol WorkOrdersViewControllerDelegate { // FIXME -- this is not named correctly. need an abstract WorkOrderComponent class and repurpose this hack as that delegate.
    // general UIKit callbacks
    optional func navigationControllerForViewController(viewController: UIViewController) -> UINavigationController!
    optional func navigationControllerNavigationItemForViewController(viewController: UIViewController) -> UINavigationItem!
    optional func navigationControllerNavBarButtonItemsShouldBeResetForViewController(viewController: UIViewController!)
    optional func targetViewForViewController(viewController: UIViewController) -> UIView!

    // mapping-related callbacks
    optional func annotationsForMapView(mapView: MKMapView, workOrder: WorkOrder) -> [MKAnnotation]
    optional func annotationViewForMapView(mapView: MKMapView, annotation: MKAnnotation) -> MKAnnotationView!
    optional func mapViewForViewController(viewController: UIViewController!) -> WorkOrderMapView!
    optional func mapViewShouldRefreshVisibleMapRect(mapView: MKMapView, animated: Bool)
    optional func shouldRemoveMapAnnotationsForWorkOrderViewController(viewController: UIViewController)

    // eta and driving directions callbacks
    optional func drivingEtaToNextWorkOrderChanged(minutesEta: NSNumber)
    optional func drivingEtaToNextWorkOrderForViewController(viewController: UIViewController) -> NSNumber
    optional func drivingEtaToInProgressWorkOrderChanged(minutesEta: NSNumber)
    optional func drivingDirectionsToNextWorkOrderForViewController(viewController: UIViewController) -> Directions!

    // next work order context and related segue callbacks
    optional func managedViewControllersForViewController(viewController: UIViewController!) -> [UIViewController]
    optional func nextWorkOrderContextShouldBeRewound()
    optional func nextWorkOrderContextShouldBeRewoundForViewController(viewController: UIViewController)
    optional func unwindManagedViewController(viewController: UIViewController)
    optional func confirmationRequiredForWorkOrderViewController(viewController: UIViewController)
    optional func confirmationCanceledForWorkOrderViewController(viewController: UIViewController)
    optional func confirmationReceivedForWorkOrderViewController(viewController: UIViewController)

    // in progress work order context and related segue callbacks
    // packing slip
    optional func workOrderAbandonedForViewController(viewController: ViewController)
    optional func workOrderDeliveryConfirmedForViewController(viewController: ViewController)
    optional func workOrderItemsOrderedForViewController(packingSlipViewController: PackingSlipViewController) -> [Product]
    optional func workOrderItemsOnTruckForViewController(packingSlipViewController: PackingSlipViewController) -> [Product]
    optional func workOrderItemsUnloadedForViewController(packingSlipViewController: PackingSlipViewController) -> [Product]
    optional func workOrderItemsRejectedForViewController(packingSlipViewController: PackingSlipViewController) -> [Product]

    // signature
    optional func summaryLabelTextForSignatureViewController(viewController: SignatureViewController) -> String
    optional func signatureReceived(signature: UIImage, forWorkOrderViewController: ViewController)

    // net promoter
    optional func netPromoterScoreReceived(netPromoterScore: NSNumber, forWorkOrderViewController: ViewController)
    optional func netPromoterScoreDeclinedForWorkOrderViewController(viewController: ViewController)

    // comments
    optional func commentsViewController(viewController: CommentsViewController, didSubmitComment comment: String)
    optional func commentsViewControllerShouldBeDismissed(viewController: CommentsViewController)
}

class WorkOrdersViewController: ViewController, WorkOrdersViewControllerDelegate,
                                                CommentsViewControllerDelegate,
                                                DirectionsViewControllerDelegate,
                                                WorkOrderComponentViewControllerDelegate,
                                                ManifestViewControllerDelegate {

    private let managedViewControllerSegues = [
        "DirectionsViewControllerSegue",
        "ProductionsViewControllerSegue",
        "WorkOrderAnnotationViewControllerSegue",
        "WorkOrderComponentViewControllerSegue",
        "WorkOrderDestinationHeaderViewControllerSegue",
        "WorkOrderDestinationConfirmationViewControllerSegue",
    ]

    private var managedViewControllers = [UIViewController]()
    private var updatingWorkOrderContext = false

    @IBOutlet private weak var mapView: WorkOrderMapView!

    private var zeroStateViewController: ZeroStateViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true

        loadWorkOrderContext()

        NSNotificationCenter.defaultCenter().addObserverForName("SegueToProductionsStoryboard") { sender in
            if self.navigationController?.viewControllers.last?.isKindOfClass(ProductionsViewController) == false {
                self.performSegueWithIdentifier("ProductionsViewControllerSegue", sender: self)
            }
        }

        NSNotificationCenter.defaultCenter().addObserverForName("WorkOrderContextShouldRefresh") { _ in
            if !self.updatingWorkOrderContext && (WorkOrderService.sharedService().inProgressWorkOrder == nil || self.canAttemptSegueToEnRouteWorkOrder) {
                if self.viewingDirections {
                    if !self.canAttemptSegueToUnloadInProgressRoute && !self.canAttemptSegueToUnloadingRoute {
                        WorkOrderService.sharedService().inProgressWorkOrder.reload(
                            onSuccess: { statusCode, mappingResult in
                                if let workOrder = mappingResult.firstObject as? WorkOrder {
                                    if workOrder.status != "en_route" {
                                        self.updatingWorkOrderContext = true
                                        self.loadWorkOrderContext()
                                    } else {
                                        log("not reloading context due to work order being routed to destination")
                                    }
                                }
                            },
                            onError: { error, statusCode, responseString in
                                self.updatingWorkOrderContext = true
                                self.loadWorkOrderContext()
                            }
                        )
                    }
                } else {
                    self.updatingWorkOrderContext = true
                    self.loadWorkOrderContext()
                }
            }
        }

        setupBarButtonItems()
        setupZeroStateView()
    }

    private func setupZeroStateView() {
        zeroStateViewController = UIStoryboard("Provider").instantiateViewControllerWithIdentifier("ZeroStateViewController") as! ZeroStateViewController
    }

    private func setupBarButtonItems() {
        setupTitleView()
        setupMenuBarButtonItem()
        setupMessagesBarButtonItem()
    }

    private func setupTitleView() {
        let starIconImage = FAKFontAwesome.spaceShuttleIconWithSize(40.0).imageWithSize(CGSize(width: 40.0, height: 40.0))
        let titleView = UIImageView(image: starIconImage.imageWithRenderingMode(.AlwaysTemplate))
        titleView.tintColor = Color.menuBackgroundColor()
        navigationItem.titleView = titleView
    }

    private func setupMenuBarButtonItem() {
        let menuIconImage = FAKFontAwesome.naviconIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0))
        let menuBarButtonItem = NavigationBarButton.barButtonItemWithImage(menuIconImage, target: self, action: "menuButtonTapped:")
        menuBarButtonItem.tintColor = Color.darkBlueBackground()
        navigationItem.leftBarButtonItem = menuBarButtonItem
    }

    private func setupMessagesBarButtonItem() {
        let messageIconImage = FAKFontAwesome.envelopeOIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0))
        let messagesBarButtonItem = NavigationBarButton.barButtonItemWithImage(messageIconImage, target: self, action: "messageButtonTapped:")
        messagesBarButtonItem.tintColor = Color.darkBlueBackground()
        navigationItem.rightBarButtonItem = messagesBarButtonItem
    }

    @objc private func menuButtonTapped(sender: UIBarButtonItem) {
        NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldOpen")
    }

    @objc private func messageButtonTapped(sender: UIBarButtonItem) {
        let messagesNavCon = UIStoryboard("Messages").instantiateInitialViewController() as? UINavigationController
        presentViewController(messagesNavCon!, animated: true)
    }

    // MARK: Route segue state interrogation

    private var canAttemptSegueToValidRouteContext: Bool {
        return canAttemptSegueToLoadingRoute || canAttemptSegueToInProgressRoute || canAttemptSegueToUnloadingRoute || canAttemptSegueToNextRoute
    }

    private var canAttemptSegueToLoadingRoute: Bool {
        return RouteService.sharedService().loadingRoute != nil
    }

    private var canAttemptSegueToUnloadingRoute: Bool {
        return RouteService.sharedService().unloadingRoute != nil
    }

    private var canAttemptSegueToNextRoute: Bool {
        return RouteService.sharedService().nextRoute != nil
    }

    private var canAttemptSegueToInProgressRoute: Bool {
        return RouteService.sharedService().inProgressRoute != nil
    }

    private var canAttemptSegueToUnloadInProgressRoute: Bool {
        if let route = RouteService.sharedService().inProgressRoute {
            return route.disposedOfAllWorkOrders
        }
        return false
    }

    // MARK: WorkOrder segue state interrogation

    private var canAttemptSegueToValidWorkOrderContext: Bool {
        if let _ = RouteService.sharedService().inProgressRoute {
            return false
        }

        return canAttemptSegueToInProgressWorkOrder || canAttemptSegueToEnRouteWorkOrder || canAttemptSegueToNextWorkOrder
    }

    private var canAttemptSegueToNextWorkOrder: Bool {
        return WorkOrderService.sharedService().nextWorkOrder != nil
    }

    private var canAttemptSegueToEnRouteWorkOrder: Bool {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            return workOrder.status == "en_route"
        }
        return false
    }

    private var canAttemptSegueToInProgressWorkOrder: Bool {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            return workOrder.status == "in_progress"
        }
        return false
    }

    private var inProgressWorkOrderHasComponents: Bool {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            return workOrder.status == "in_progress" && workOrder.components.count > 0
        }
        return false
    }

    private var viewingDirections: Bool {
        for vc in managedViewControllers {
            if vc is DirectionsViewController {
                return true
            }
        }
        return false
    }

    func loadWorkOrderContext() {
        let workOrderService = WorkOrderService.sharedService()

        workOrderService.fetch(
            status: "scheduled,en_route,in_progress",
            today: true,
            onWorkOrdersFetched: { workOrders in
                workOrderService.setWorkOrders(workOrders) // FIXME -- decide if this should live in the service instead

                if workOrders.count == 0 {
                    self.zeroStateViewController?.render(self.view)
                }

                self.nextWorkOrderContextShouldBeRewound()
                self.attemptSegueToValidWorkOrderContext()
                self.updatingWorkOrderContext = false
            }
        )
    }

    func loadRouteContext() {
        let workOrderService = WorkOrderService.sharedService()
        let routeService = RouteService.sharedService()

        routeService.fetch(
            status: "scheduled,loading,in_progress,unloading",
            today: true,
            nextRouteOnly: true,
            onRoutesFetched: { routes in
                if routes.count == 0 {
                    workOrderService.fetch(
                        status: "scheduled,en_route,in_progress",
                        today: true,
                        onWorkOrdersFetched: { workOrders in
                            workOrderService.setWorkOrders(workOrders) // FIXME -- decide if this should live in the service instead

                            if workOrders.count == 0 {
                                self.zeroStateViewController?.render(self.view)
                            }

                            self.nextWorkOrderContextShouldBeRewound()
                            self.attemptSegueToValidWorkOrderContext()
                            self.updatingWorkOrderContext = false
                        }
                    )
                } else if routes.count > 0 {
                    workOrderService.setWorkOrdersUsingRoute(routes[0])
                    self.attemptSegueToValidRouteContext()
                    self.updatingWorkOrderContext = false
                }
            }
        )
    }

    private func attemptSegueToCompleteRoute() {
        if let route = RouteService.sharedService().currentRoute {
            if route == RouteService.sharedService().inProgressRoute {
                if let providerOriginAssignment = route.providerOriginAssignment {
                    if let origin = providerOriginAssignment.origin {
                        RouteService.sharedService().setInProgressRouteOriginRegionMonitoringCallbacks(
                            {
                                route.arrive(
                                    onSuccess: { statusCode, responseString in
                                        self.nextWorkOrderContextShouldBeRewound()
                                        LocationService.sharedService().unregisterRegionMonitor(origin.regionIdentifier)
                                        self.attemptSegueToValidWorkOrderContext()
                                    },
                                    onError: { error, statusCode, responseString in
                                        route.reload(
                                            { statusCode, mappingResult in
                                                self.nextWorkOrderContextShouldBeRewound()
                                                LocationService.sharedService().unregisterRegionMonitor(origin.regionIdentifier)
                                                self.attemptSegueToValidWorkOrderContext()
                                            },
                                            onError: { error, statusCode, responseString in

                                            }
                                        )
                                    }
                                )
                            },
                            onDidExitRegion: {
                                
                            }
                        )
                    }
                }
            }
        }
    }

    func attemptSegueToValidRouteContext() {
        if canAttemptSegueToLoadingRoute {
            performSegueWithIdentifier("RouteManifestViewControllerSegue", sender: self)
        } else if canAttemptSegueToUnloadingRoute {
            performSegueWithIdentifier("RouteManifestViewControllerSegue", sender: self)
        } else if canAttemptSegueToUnloadInProgressRoute {
            performSegueWithIdentifier("DirectionsViewControllerSegue", sender: self)
        } else if canAttemptSegueToInProgressRoute {
            attemptSegueToValidWorkOrderContext()
        } else if canAttemptSegueToNextRoute {
            performSegueWithIdentifier("RouteManifestViewControllerSegue", sender: self)
        } else {
            dispatch_after_delay(0.0) {
                self.mapView.revealMap(true)

                self.zeroStateViewController?.render(self.view)
            }
        }
    }

    func attemptSegueToValidWorkOrderContext() {
        if canAttemptSegueToEnRouteWorkOrder {
            performSegueWithIdentifier("DirectionsViewControllerSegue", sender: self)
        } else if canAttemptSegueToInProgressWorkOrder {
            if !inProgressWorkOrderHasComponents {
                if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
                    workOrder.cancel(
                        onSuccess: { statusCode, mappingResult in
                            NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
                        }, onError: { error, statusCode, responseString in
                            NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
                        }
                    )
                }
            } else {
                performSegueWithIdentifier("WorkOrderComponentViewControllerSegue", sender: self)
            }
        } else if canAttemptSegueToNextWorkOrder {
            performSegueWithIdentifier("WorkOrderAnnotationViewControllerSegue", sender: self)
        } else {
            //attemptSegueToValidRouteContext()
        }
    }

    private func refreshAnnotations() {
        shouldRemoveMapAnnotationsForWorkOrderViewController(self)

        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            mapView.addAnnotation(workOrder)
        }
    }

    // MARK Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if managedViewControllerSegues.indexOfObject(segue.identifier!) != nil {
            managedViewControllers.append(segue.destinationViewController as! ViewController)
            zeroStateViewController?.dismiss()
        }

        switch segue.identifier! {
        case "DirectionsViewControllerSegue":
            assert(segue.destinationViewController is DirectionsViewController)

            refreshAnnotations()

            if canAttemptSegueToUnloadInProgressRoute {
                attemptSegueToCompleteRoute()
            } else {
                if let wo = WorkOrderService.sharedService().inProgressWorkOrder {
                    WorkOrderService.sharedService().setInProgressWorkOrderRegionMonitoringCallbacks(
                        {
                            wo.arrive(
                                onSuccess: { statusCode, responseString in
                                    self.nextWorkOrderContextShouldBeRewound()
                                    LocationService.sharedService().unregisterRegionMonitor(wo.regionIdentifier)
                                    self.attemptSegueToValidWorkOrderContext()
                                },
                                onError: { error, statusCode, responseString in

                                }
                            )
                        },
                        onDidExitRegion: {
                            
                        }
                    )
                }
            }

            CheckinService.sharedService().enableNavigationAccuracy()
            LocationService.sharedService().enableNavigationAccuracy()

            (segue.destinationViewController as! DirectionsViewController).directionsViewControllerDelegate = self
        case "WorkOrderAnnotationViewControllerSegue":
            assert(segue.destinationViewController is WorkOrderAnnotationViewController)
            (segue.destinationViewController as! WorkOrderAnnotationViewController).workOrdersViewControllerDelegate = self
        case "WorkOrderComponentViewControllerSegue":
            assert(segue.destinationViewController is WorkOrderComponentViewController)
            (segue.destinationViewController as! WorkOrderComponentViewController).delegate = self
            (segue.destinationViewController as! WorkOrderComponentViewController).workOrdersViewControllerDelegate = self

            refreshAnnotations()
        case "WorkOrderDestinationHeaderViewControllerSegue":
            assert(segue.destinationViewController is WorkOrderDestinationHeaderViewController)
            (segue.destinationViewController as! WorkOrderDestinationHeaderViewController).workOrdersViewControllerDelegate = self
        case "WorkOrderDestinationConfirmationViewControllerSegue":
            assert(segue.destinationViewController is WorkOrderDestinationConfirmationViewController)
            (segue.destinationViewController as! WorkOrderDestinationConfirmationViewController).workOrdersViewControllerDelegate = self
        default:
            break
        }
    }

    // MARK: WorkOrdersViewControllerDelegate

    func annotationsForMapView(mapView: MKMapView, workOrder: WorkOrder) -> [MKAnnotation] {
        var annotations = [MKAnnotation]()
        annotations.append(workOrder)
        return annotations
    }

    func annotationViewForMapView(mapView: MKMapView, annotation: MKAnnotation) -> MKAnnotationView! {
        var annotationView: MKAnnotationView!

        if annotation is WorkOrder {
            for vc in managedViewControllers {
                if vc is WorkOrderAnnotationViewController {
                    annotationView = (vc as! WorkOrderAnnotationViewController).view as! WorkOrderAnnotationView
                }
            }
        }

        return annotationView
    }

    func drivingEtaToNextWorkOrderForViewController(viewController: UIViewController) -> NSNumber {
        return WorkOrderService.sharedService().nextWorkOrderDrivingEtaMinutes
    }

    func drivingDirectionsToNextWorkOrderForViewController(viewController: UIViewController) -> Directions! {
        return nil
    }

    func managedViewControllersForViewController(viewController: UIViewController!) -> [UIViewController] {
        return managedViewControllers
    }

    func mapViewForViewController(viewController: UIViewController) -> WorkOrderMapView {
        return mapView
    }

    func mapViewUserTrackingMode(mapView: MKMapView) -> MKUserTrackingMode {
//        if viewingDirections {
//            return .FollowWithHeading
//        }
        return .None
    }

    func targetViewForViewController(viewController: UIViewController) -> UIView {
        return view
    }

    private func popManagedNavigationController() -> UINavigationController! {
        if let _ = managedViewControllers.last as? UINavigationController {
            return managedViewControllers.removeLast() as! UINavigationController
        }
        return nil
    }

    func nextWorkOrderContextShouldBeRewound() {
        while managedViewControllers.count > 0 {
            let managedNavigationController = popManagedNavigationController()
            let viewController = managedViewControllers.removeLast()
            unwindManagedViewController(viewController)
        }

        assert(managedViewControllers.count == 0)
    }

    func nextWorkOrderContextShouldBeRewoundForViewController(viewController: UIViewController) {
        if let i = managedViewControllers.indexOf(viewController) {
            if viewController is WorkOrderAnnotationViewController {
                shouldRemoveMapAnnotationsForWorkOrderViewController(viewController as! WorkOrderAnnotationViewController)
            } else {
                unwindManagedViewController(viewController)
            }

            managedViewControllers.removeAtIndex(i)
        }
    }

    func unwindManagedViewController(viewController: UIViewController) {
        let segueIdentifier = ("\(NSStringFromClass((viewController as AnyObject).dynamicType))UnwindSegue" as String).splitAtString(".").1
        viewController.performSegueWithIdentifier(segueIdentifier, sender: self)
    }

    func confirmationRequiredForWorkOrderViewController(viewController: UIViewController) {
        performSegueWithIdentifier("WorkOrderDestinationHeaderViewControllerSegue", sender: self)
        performSegueWithIdentifier("WorkOrderDestinationConfirmationViewControllerSegue", sender: self)
    }

    func confirmationCanceledForWorkOrderViewController(viewController: UIViewController) {
        nextWorkOrderContextShouldBeRewound()
        attemptSegueToValidWorkOrderContext()
    }

    func confirmationReceivedForWorkOrderViewController(viewController: UIViewController) {
        if viewController is WorkOrderDestinationConfirmationViewController {
            if let workOrder = WorkOrderService.sharedService().nextWorkOrder {
                workOrder.start(
                    { statusCode, responseString in
                        self.nextWorkOrderContextShouldBeRewound()
                        self.performSegueWithIdentifier("DirectionsViewControllerSegue", sender: self)
                    },
                    onError: { error, statusCode, responseString in

                    }
                )
            }
        }
    }

    func workOrderDeliveryConfirmedForViewController(viewController: ViewController) {
        nextWorkOrderContextShouldBeRewound()
        if let inProgressWorkOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            if inProgressWorkOrder.components.count > 0 {
                var components = inProgressWorkOrder.components
                components = NSMutableArray(array: components.subarrayWithRange(NSMakeRange(1, components.count - 2)))
                inProgressWorkOrder.components = components
            }
        }

        attemptSegueToValidWorkOrderContext()
    }

    func workOrderAbandonedForViewController(viewController: ViewController) {
        nextWorkOrderContextShouldBeRewound()
        WorkOrderService.sharedService().inProgressWorkOrder.abandon(
            onSuccess: { statusCode, responseString in
                self.attemptSegueToValidWorkOrderContext()
            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func workOrderItemsOrderedForViewController(packingSlipViewController: PackingSlipViewController) -> [Product] {
        return WorkOrderService.sharedService().inProgressWorkOrder.itemsOrdered
    }

    func workOrderItemsOnTruckForViewController(packingSlipViewController: PackingSlipViewController) -> [Product] {
        return WorkOrderService.sharedService().inProgressWorkOrder.itemsOnTruck
    }

    func workOrderItemsUnloadedForViewController(packingSlipViewController: PackingSlipViewController) -> [Product] {
        return WorkOrderService.sharedService().inProgressWorkOrder.itemsDelivered
    }

    func workOrderItemsRejectedForViewController(packingSlipViewController: PackingSlipViewController) -> [Product] {
        return WorkOrderService.sharedService().inProgressWorkOrder.itemsRejected
    }

    func summaryLabelTextForSignatureViewController(viewController: SignatureViewController) -> String {
        return "Received \(WorkOrderService.sharedService().inProgressWorkOrder.itemsDelivered.count) item(s) in good condition"
    }

    func signatureReceived(signature: UIImage, forWorkOrderViewController: ViewController) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            nextWorkOrderContextShouldBeRewound()
            workOrder.components.removeObject(WorkOrderService.sharedService().inProgressWorkOrder.components.firstObject!) // FIXME!!!!
            attemptSegueToValidWorkOrderContext()

            var params = [
                "tags": "signature, delivery",
                "public": false
            ]

            if let location = LocationService.sharedService().currentLocation {
                params["latitude"] = location.coordinate.latitude
                params["longitude"] = location.coordinate.longitude
            }

            workOrder.attach(signature, params: params,
                onSuccess: { statusCode, responseString in
                    self.attemptCompletionOfInProgressWorkOrder()
                },
                onError: { error, statusCode, responseString in
                    
                }
            )
        }
    }

    func netPromoterScoreReceived(netPromoterScore: NSNumber, forWorkOrderViewController: ViewController) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            nextWorkOrderContextShouldBeRewound()
            workOrder.components.removeObject(WorkOrderService.sharedService().inProgressWorkOrder.components.firstObject!) // FIXME!!!!
            attemptSegueToValidWorkOrderContext()

            workOrder.scoreProvider(netPromoterScore,
                onSuccess: { statusCode, responseString in
                    self.attemptCompletionOfInProgressWorkOrder()
                },
                onError: { error, statusCode, responseString in
                    
                }
            )
        }
    }

    func netPromoterScoreDeclinedForWorkOrderViewController(viewController: ViewController) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            nextWorkOrderContextShouldBeRewound()
            workOrder.components.removeObject(WorkOrderService.sharedService().inProgressWorkOrder.components.firstObject!) // FIXME!!!!
            attemptSegueToValidWorkOrderContext()

            attemptCompletionOfInProgressWorkOrder()
        }
    }

    func commentsViewController(viewController: CommentsViewController, didSubmitComment comment: String) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            nextWorkOrderContextShouldBeRewound()
            workOrder.components.removeObject(WorkOrderService.sharedService().inProgressWorkOrder.components.firstObject!) // FIXME!!!!
            attemptSegueToValidWorkOrderContext()

            workOrder.addComment(comment,
                onSuccess: { statusCode, responseString in
                    self.attemptCompletionOfInProgressWorkOrder()
                },
                onError: { error, statusCode, responseString in

                }
            )
        }
    }

    func commentsViewControllerShouldBeDismissed(viewController: CommentsViewController) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            nextWorkOrderContextShouldBeRewound()
            workOrder.components.removeObject(WorkOrderService.sharedService().inProgressWorkOrder.components.firstObject!) // FIXME!!!!
            attemptSegueToValidWorkOrderContext()

            attemptCompletionOfInProgressWorkOrder()
        }
    }

    func promptForCommentsViewController(viewController: CommentsViewController) -> String! {
        return "Anything worth mentioning?"
    }

    func titleForCommentsViewController(viewController: CommentsViewController) -> String! {
        return "COMMENTS"
    }

    func shouldRemoveMapAnnotationsForWorkOrderViewController(viewController: UIViewController) {
        mapView.removeAnnotations()
    }

    func navigationControllerForViewController(viewController: UIViewController) -> UINavigationController! {
        return navigationController!
    }

    func navigationControllerNavigationItemForViewController(viewController: UIViewController) -> UINavigationItem! {
        return navigationItem
    }

    func navigationControllerNavBarButtonItemsShouldBeResetForViewController(viewController: UIViewController) {
        setupBarButtonItems()
    }

    // MARK: DirectionsViewControllerDelegate

    func isPresentingDirections() -> Bool {
        return viewingDirections
    }

    func mapViewForDirectionsViewController(directionsViewController: DirectionsViewController) -> MKMapView! {
        return mapView
    }

    func finalDestinationForDirectionsViewController(directionsViewController: DirectionsViewController) -> CLLocationCoordinate2D {
        return WorkOrderService.sharedService().inProgressWorkOrder.coordinate
    }

    func navbarPromptForDirectionsViewController(viewController: UIViewController) -> String! {
        if canAttemptSegueToUnloadInProgressRoute {
            if let providerOriginAssignment = RouteService.sharedService().inProgressRoute.providerOriginAssignment {
                if let origin = providerOriginAssignment.origin {
                    if let name = origin.contact.name {
                        return "Return to \(name) to complete route"
                    } else {
                        return "Return to warehouse to complete route"
                    }
                }
            }
        }
        return nil
    }

    // MARK: RouteManifestViewControllerDelegate

    func routeForViewController(viewController: UIViewController) -> Route! {
        if let currentRoute = RouteService.sharedService().currentRoute {
            return currentRoute
        }
        return RouteService.sharedService().nextRoute
    }

    func routeUpdated(route: Route!, byViewController viewController: UIViewController) {
        dispatch_after_delay(0.0) {
            self.navigationController?.popViewControllerAnimated(true)
            self.attemptSegueToValidRouteContext()
        }
    }

    // MARK: WorkOrderComponentViewControllerDelegate

    func workOrderComponentViewControllerForParentViewController(viewController: WorkOrderComponentViewController) -> WorkOrderComponentViewController! {
        var vc: WorkOrderComponentViewController!
        if let componentIdentifier = WorkOrderService.sharedService().inProgressWorkOrder.currentComponentIdentifier {
            let initialViewController: UIViewController = UIStoryboard(componentIdentifier).instantiateInitialViewController()!
            if initialViewController.isKindOfClass(UINavigationController) {
                managedViewControllers.append(initialViewController)
                vc = (initialViewController as! UINavigationController).viewControllers.first as! WorkOrderComponentViewController

                if vc.isKindOfClass(CommentsViewController) {
                    (vc as! CommentsViewController).commentsViewControllerDelegate = self
                }
            } else {
                vc = initialViewController as! WorkOrderComponentViewController
            }
        }
        return vc
    }

    private func attemptCompletionOfInProgressWorkOrder() {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            if workOrder.components.count == 0 {
                workOrder.complete(
                    onSuccess: { statusCode, responseString in
                        self.nextWorkOrderContextShouldBeRewound()
                        self.attemptSegueToValidWorkOrderContext()
                    },
                    onError: { error, statusCode, responseString in

                    }
                )
            } else {
                // did not attempt to complete work order as there are outstanding components
            }
        }
    }
}