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
    optional func navigationControllerForViewController(viewController: ViewController) -> UINavigationController
    optional func navigationControllerNavigationItemForViewController(viewController: ViewController) -> UINavigationItem
    optional func navigationControllerNavBarButtonItemsShouldBeResetForViewController(viewController: ViewController!)
    optional func targetViewForViewController(viewController: ViewController) -> UIView!

    // mapping-related callbacks
    optional func annotationsForMapView(mapView: MKMapView, workOrder: WorkOrder) -> [MKAnnotation]
    optional func annotationViewForMapView(mapView: MKMapView, annotation: MKAnnotation) -> MKAnnotationView!
    optional func mapViewForViewController(viewController: ViewController!) -> WorkOrderMapView!
    optional func mapViewShouldRefreshVisibleMapRect(mapView: MKMapView, animated: Bool)
    optional func shouldRemoveMapAnnotationsForWorkOrderViewController(viewController: ViewController)

    // eta and driving directions callbacks
    optional func drivingEtaToNextWorkOrderChanged(minutesEta: NSNumber)
    optional func drivingEtaToNextWorkOrderForViewController(viewController: ViewController) -> NSNumber
    optional func drivingEtaToInProgressWorkOrderChanged(minutesEta: NSNumber)
    optional func drivingDirectionsToNextWorkOrderForViewController(viewController: ViewController) -> Directions!

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
                                                DirectionsViewControllerDelegate,
                                                WorkOrderComponentViewControllerDelegate,
                                                RouteViewControllerDelegate,
                                                RouteManifestViewControllerDelegate,
                                                ManifestViewControllerDelegate {

    private let managedViewControllerSegues = [
        "DirectionsViewControllerSegue",
        "RouteManifestViewControllerSegue",
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

        loadRouteContext()

        NSNotificationCenter.defaultCenter().addObserverForName("SegueToRouteStoryboard") { sender in
            if self.navigationController?.viewControllers.last?.isKindOfClass(RouteViewController) == false {
                self.performSegueWithIdentifier("RouteViewControllerSegue", sender: self)
            }
        }

        NSNotificationCenter.defaultCenter().addObserverForName("SegueToHistoryStoryboard") { sender in
            if self.navigationController?.viewControllers.last?.isKindOfClass(RouteHistoryViewController) == false {
                self.performSegueWithIdentifier("RouteHistoryViewControllerSegue", sender: self)
            }
        }

        NSNotificationCenter.defaultCenter().addObserverForName("SegueToManifestStoryboard") { sender in
            if self.navigationController?.viewControllers.last?.isKindOfClass(ManifestViewController) == false {
                self.performSegueWithIdentifier("ManifestViewControllerSegue", sender: self)
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
                                        self.loadRouteContext()
                                    } else {
                                        log("not reloading context due to work order being routed to destination")
                                    }
                                }
                            },
                            onError: { error, statusCode, responseString in
                                self.updatingWorkOrderContext = true
                                self.loadRouteContext()
                            }
                        )
                    }
                } else {
                    self.updatingWorkOrderContext = true
                    self.loadRouteContext()
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
        setupMenuBarButtonItem()
        setupMessagesBarButtonItem()
    }

    private func setupMenuBarButtonItem() {
        let menuIconImage = FAKFontAwesome.naviconIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0))
        let menuBarButtonItem = UIBarButtonItem(image: menuIconImage, style: .Plain, target: self, action: "menuButtonTapped:")
        menuBarButtonItem.tintColor = UIColor.whiteColor()

        navigationItem.leftBarButtonItem = menuBarButtonItem
    }

    private func setupMessagesBarButtonItem() {
        let messageIconImage = FAKFontAwesome.envelopeOIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0))
        let messagesBarButtonItem = UIBarButtonItem(image: messageIconImage, style: .Plain, target: self, action: "messageButtonTapped:")
        messagesBarButtonItem.tintColor = UIColor.whiteColor()

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
        if let loadingRoute = RouteService.sharedService().inProgressRoute {
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

    private var viewingDirections: Bool {
        for vc in managedViewControllers {
            if vc is DirectionsViewController {
                return true
            }
        }
        return false
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
                                            onSuccess: { statusCode, mappingResult in
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
                self.mapView.revealMap(force: true)

                self.zeroStateViewController?.render(self.view)
            }
        }
    }

    func attemptSegueToValidWorkOrderContext() {
        if canAttemptSegueToEnRouteWorkOrder {
            performSegueWithIdentifier("DirectionsViewControllerSegue", sender: self)
        } else if canAttemptSegueToInProgressWorkOrder {
            performSegueWithIdentifier("WorkOrderComponentViewControllerSegue", sender: self)
        } else if canAttemptSegueToNextWorkOrder {
            performSegueWithIdentifier("WorkOrderAnnotationViewControllerSegue", sender: self)
        } else {
            attemptSegueToValidRouteContext()
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
        case "RouteViewControllerSegue":
            assert(segue.destinationViewController is RouteViewController)
            (segue.destinationViewController as! RouteViewController).delegate = self
        case "ManifestViewControllerSegue":
            assert(segue.destinationViewController is ManifestViewController)
            (segue.destinationViewController as! ManifestViewController).delegate = self
        case "RouteManifestViewControllerSegue":
            assert(segue.destinationViewController is RouteManifestViewController)
            (segue.destinationViewController as! RouteManifestViewController).delegate = self
        case "WorkOrderAnnotationViewControllerSegue":
            assert(segue.destinationViewController is WorkOrderAnnotationViewController)
            (segue.destinationViewController as! WorkOrderAnnotationViewController).workOrdersViewControllerDelegate = self
        case "WorkOrderComponentViewControllerSegue":
            assert(segue.destinationViewController is WorkOrderComponentViewController)
            (segue.destinationViewController as! WorkOrderComponentViewController).delegate = self
            (segue.destinationViewController as! WorkOrderComponentViewController).workOrdersViewControllerDelegate = self
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
        let annotations = [MKAnnotation]()

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

    func drivingEtaToNextWorkOrderForViewController(viewController: ViewController) -> NSNumber {
        return WorkOrderService.sharedService().nextWorkOrderDrivingEtaMinutes
    }

    func drivingDirectionsToNextWorkOrderForViewController(viewController: ViewController) -> Directions! {
        return nil
    }

    func managedViewControllersForViewController(viewController: ViewController) -> [ViewController] {
        return managedViewControllers
    }

    func mapViewForViewController(viewController: ViewController) -> WorkOrderMapView {
        return mapView
    }

    func mapViewUserTrackingMode(mapView: MKMapView) -> MKUserTrackingMode {
//        if viewingDirections {
//            return .FollowWithHeading
//        }
        return .None
    }

    func targetViewForViewController(viewController: ViewController) -> UIView {
        return view
    }

    private func popManagedNavigationController() -> UINavigationController! {
        if let viewController = managedViewControllers.last as? UINavigationController {
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

    func nextWorkOrderContextShouldBeRewoundForViewController(viewController: ViewController) {
        if let i = find(managedViewControllers, viewController) {
            if viewController is WorkOrderAnnotationViewController {
                shouldRemoveMapAnnotationsForWorkOrderViewController(viewController as! WorkOrderAnnotationViewController)
            } else {
                unwindManagedViewController(viewController)
            }

            managedViewControllers.removeAtIndex(i)
        }
    }

    func unwindManagedViewController(viewController: ViewController) {
        let segueIdentifier = ("\(NSStringFromClass((viewController as AnyObject).dynamicType))UnwindSegue" as String).splitAtString(".").1
        viewController.performSegueWithIdentifier(segueIdentifier, sender: self)
    }

    func confirmationRequiredForWorkOrderViewController(viewController: ViewController) {
        performSegueWithIdentifier("WorkOrderDestinationHeaderViewControllerSegue", sender: self)
        performSegueWithIdentifier("WorkOrderDestinationConfirmationViewControllerSegue", sender: self)
    }

    func confirmationCanceledForWorkOrderViewController(viewController: ViewController) {
        nextWorkOrderContextShouldBeRewound()
        attemptSegueToValidWorkOrderContext()
    }

    func confirmationReceivedForWorkOrderViewController(viewController: ViewController) {
        if viewController is WorkOrderDestinationConfirmationViewController {
            if let workOrder = WorkOrderService.sharedService().nextWorkOrder {
                workOrder.start(
                    onSuccess: { statusCode, responseString in
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
                inProgressWorkOrder.components.removeAtIndex(0)
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
        var products = [Product]()
        if let itemsOrdered = WorkOrderService.sharedService().inProgressWorkOrder.itemsOrdered {
            for product in itemsOrdered {
                products.append(product)
            }
        }
        return products
    }

    func workOrderItemsOnTruckForViewController(packingSlipViewController: PackingSlipViewController) -> [Product] {
        return WorkOrderService.sharedService().inProgressWorkOrder.itemsOnTruck
    }

    func workOrderItemsUnloadedForViewController(packingSlipViewController: PackingSlipViewController) -> [Product] {
        var products = [Product]()
        if let itemsDelivered = WorkOrderService.sharedService().inProgressWorkOrder.itemsDelivered {
            for product in itemsDelivered {
                products.append(product)
            }
        }
        return products
    }

    func workOrderItemsRejectedForViewController(packingSlipViewController: PackingSlipViewController) -> [Product] {
        var products = [Product]()
        if let itemsRejected = WorkOrderService.sharedService().inProgressWorkOrder.itemsRejected {
            for product in itemsRejected {
                products.append(product)
            }
        }
        return products
    }

    func summaryLabelTextForSignatureViewController(viewController: SignatureViewController) -> String! {
        return "Received \(WorkOrderService.sharedService().inProgressWorkOrder.itemsDelivered.count) item(s) in good condition"
    }

    func signatureReceived(signature: UIImage, forWorkOrderViewController: ViewController) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            nextWorkOrderContextShouldBeRewound()
            WorkOrderService.sharedService().inProgressWorkOrder.components.removeAtIndex(0)
            attemptSegueToValidWorkOrderContext()

            let location = LocationService.sharedService().currentLocation

            let params = [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude,
                "tags": "signature, delivery",
                "public": false
            ]

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

    func shouldRemoveMapAnnotationsForWorkOrderViewController(viewController: ViewController!) {
        mapView.removeAnnotations()
    }

    func navigationControllerForViewController(viewController: ViewController) -> UINavigationController {
        return navigationController!
    }

    func navigationControllerNavigationItemForViewController(viewController: ViewController) -> UINavigationItem {
        return navigationItem
    }

    func navigationControllerNavBarButtonItemsShouldBeResetForViewController(viewController: ViewController!) {
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

    func navbarPromptForDirectionsViewController(viewController: ViewController!) -> String! {
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

    func routeForViewController(viewController: ViewController) -> Route! {
        if let currentRoute = RouteService.sharedService().currentRoute {
            return currentRoute
        }
        return RouteService.sharedService().nextRoute
    }

    func routeUpdated(route: Route, byViewController viewController: ViewController) {
        dispatch_after_delay(0.0) {
            self.navigationController?.popViewControllerAnimated(true)
            self.attemptSegueToValidRouteContext()
        }
    }

    // MARK: WorkOrderComponentViewControllerDelegate

    func workOrderComponentViewControllerForParentViewController(viewController: WorkOrderComponentViewController) -> WorkOrderComponentViewController {
        var vc: WorkOrderComponentViewController!
        if let componentIdentifier = WorkOrderService.sharedService().inProgressWorkOrder.currentComponentIdentifier {
            let initialViewController: UIViewController = UIStoryboard(componentIdentifier).instantiateInitialViewController() as! UIViewController
            if initialViewController.isKindOfClass(UINavigationController) {
                managedViewControllers.append(initialViewController)
                vc = (initialViewController as! UINavigationController).viewControllers.first as! WorkOrderComponentViewController
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
