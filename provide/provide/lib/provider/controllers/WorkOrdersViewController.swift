//
//  WorkOrdersViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import FontAwesomeKit
import KTSwiftExtensions

@objc
protocol WorkOrdersViewControllerDelegate: NSObjectProtocol { // FIXME -- this is not named correctly. need an abstract WorkOrderComponent class and repurpose this hack as that delegate.
    // general UIKit callbacks
    @objc optional func navigationControllerForViewController(_ viewController: UIViewController) -> UINavigationController!
    @objc optional func navigationControllerNavigationItemForViewController(_ viewController: UIViewController) -> UINavigationItem!
    @objc optional func navigationControllerNavBarButtonItemsShouldBeResetForViewController(_ viewController: UIViewController!)
    @objc optional func targetViewForViewController(_ viewController: UIViewController) -> UIView!

    // mapping-related callbacks
    @objc optional func annotationsForMapView(_ mapView: MKMapView, workOrder: WorkOrder) -> [MKAnnotation]
    @objc optional func annotationViewForMapView(_ mapView: MKMapView, annotation: MKAnnotation) -> MKAnnotationView!
    @objc optional func mapViewForViewController(_ viewController: UIViewController!) -> WorkOrderMapView!
    @objc optional func mapViewShouldRefreshVisibleMapRect(_ mapView: MKMapView, animated: Bool)
    @objc optional func shouldRemoveMapAnnotationsForWorkOrderViewController(_ viewController: UIViewController)

    // eta and driving directions callbacks
    @objc optional func drivingEtaToNextWorkOrderChanged(_ minutesEta: NSNumber)
    @objc optional func drivingEtaToNextWorkOrderForViewController(_ viewController: UIViewController) -> NSNumber
    @objc optional func drivingEtaToInProgressWorkOrderChanged(_ minutesEta: NSNumber)
    @objc optional func drivingDirectionsToNextWorkOrderForViewController(_ viewController: UIViewController) -> Directions!

    // next work order context and related segue callbacks
    @objc optional func managedViewControllersForViewController(_ viewController: UIViewController!) -> [UIViewController]
    @objc optional func nextWorkOrderContextShouldBeRewound()
    @objc optional func nextWorkOrderContextShouldBeRewoundForViewController(_ viewController: UIViewController)
    @objc optional func confirmationRequiredForWorkOrderViewController(_ viewController: UIViewController)
    @objc optional func confirmationCanceledForWorkOrderViewController(_ viewController: UIViewController)
    @objc optional func confirmationReceivedForWorkOrderViewController(_ viewController: UIViewController)

    // in progress work order context and related segue callbacks
    // packing slip
    @objc optional func workOrderAbandonedForViewController(_ viewController: ViewController)
    @objc optional func workOrderDeliveryConfirmedForViewController(_ viewController: ViewController)
    @objc optional func workOrderItemsOrderedForViewController(_ packingSlipViewController: PackingSlipViewController) -> [Product]
    @objc optional func workOrderItemsOnTruckForViewController(_ packingSlipViewController: PackingSlipViewController) -> [Product]
    @objc optional func workOrderItemsUnloadedForViewController(_ packingSlipViewController: PackingSlipViewController) -> [Product]
    @objc optional func workOrderItemsRejectedForViewController(_ packingSlipViewController: PackingSlipViewController) -> [Product]

    // signature
    @objc optional func summaryLabelTextForSignatureViewController(_ viewController: SignatureViewController) -> String
    @objc optional func signatureReceived(_ signature: UIImage, forWorkOrderViewController: ViewController)

    // net promoter
    @objc optional func netPromoterScoreReceived(_ netPromoterScore: NSNumber, forWorkOrderViewController: ViewController)
    @objc optional func netPromoterScoreDeclinedForWorkOrderViewController(_ viewController: ViewController)

    // comments
    @objc optional func commentsViewController(_ viewController: CommentsViewController, didSubmitComment comment: String)
    @objc optional func commentsViewControllerShouldBeDismissed(_ viewController: CommentsViewController)
}

class WorkOrdersViewController: ViewController, WorkOrdersViewControllerDelegate,
                                                CommentCreationViewControllerDelegate,
                                                DirectionsViewControllerDelegate,
                                                WorkOrderComponentViewControllerDelegate,
                                                RouteManifestViewControllerDelegate,
                                                ManifestViewControllerDelegate,
                                                FloorplanViewControllerDelegate {

    fileprivate let managedViewControllerSegues = [
        "DirectionsViewControllerSegue",
        "RouteManifestViewControllerSegue",
        "WorkOrderAnnotationViewControllerSegue",
        "WorkOrderComponentViewControllerSegue",
        "WorkOrderDestinationHeaderViewControllerSegue",
        "WorkOrderDestinationConfirmationViewControllerSegue",
    ]

    fileprivate var managedViewControllers = [UIViewController]()
    fileprivate var updatingWorkOrderContext = false

    @IBOutlet fileprivate weak var mapView: WorkOrderMapView!

    fileprivate var zeroStateViewController: ZeroStateViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        CheckinService.sharedService().start()
        LocationService.sharedService().start()

        navigationItem.hidesBackButton = true
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "DISMISS", style: .plain, target: nil, action: nil)

        loadCompaniesContext()

        loadRouteContext()

        NotificationCenter.default.addObserverForName("SegueToRouteStoryboard") { [weak self] sender in
            if !self!.navigationControllerContains(RouteViewController.self) {
                self!.performSegue(withIdentifier: "RouteViewControllerSegue", sender: self!)
            }
        }

        NotificationCenter.default.addObserverForName("SegueToRouteHistoryStoryboard") { [weak self] sender in
            if !self!.navigationControllerContains(RouteHistoryViewController.self) {
                self!.performSegue(withIdentifier: "RouteHistoryViewControllerSegue", sender: self!)
            }
        }

        NotificationCenter.default.addObserverForName("SegueToWorkOrderHistoryStoryboard") { [weak self] sender in
            if !self!.navigationControllerContains(WorkOrderHistoryViewController.self) {
                self!.performSegue(withIdentifier: "WorkOrderHistoryViewControllerSegue", sender: self!)
            }
        }

        NotificationCenter.default.addObserverForName("SegueToJobsStoryboard") { [weak self] sender in
            if !self!.navigationControllerContains(JobsViewController.self) {
                self!.performSegue(withIdentifier: "JobsViewControllerSegue", sender: self!)
            }
        }

        NotificationCenter.default.addObserverForName("SegueToManifestStoryboard") { [weak self] sender in
            if !self!.navigationControllerContains(ManifestViewController.self) {
                self!.performSegue(withIdentifier: "ManifestViewControllerSegue", sender: self!)
            }
        }

        NotificationCenter.default.addObserverForName("WorkOrderContextShouldRefresh") { _ in
            if !self.updatingWorkOrderContext && (WorkOrderService.sharedService().inProgressWorkOrder == nil || self.canAttemptSegueToEnRouteWorkOrder) {
                if self.viewingDirections {
                    if !self.canAttemptSegueToUnloadInProgressRoute && !self.canAttemptSegueToUnloadingRoute {
                        self.updatingWorkOrderContext = true
                        WorkOrderService.sharedService().inProgressWorkOrder?.reload(
                            { statusCode, mappingResult in
                                if let workOrder = mappingResult?.firstObject as? WorkOrder {
                                    if workOrder.status != "en_route" {
                                        self.refreshAnnotations()
                                        self.loadRouteContext()
                                    } else {
                                        log("not reloading context due to work order being routed to destination")
                                        self.updatingWorkOrderContext = false
                                    }
                                }
                            },
                            onError: { error, statusCode, responseString in
                                self.refreshAnnotations()
                                self.updatingWorkOrderContext = true
                                self.loadRouteContext()
                            }
                        )
                    }
                } else {
                    self.refreshAnnotations()
                    self.updatingWorkOrderContext = true
                    self.loadRouteContext()
                }
            }
        }

        setupBarButtonItems()
        setupZeroStateView()
    }

    fileprivate func setupZeroStateView() {
        zeroStateViewController = UIStoryboard("ZeroState").instantiateInitialViewController() as! ZeroStateViewController
    }

    fileprivate func setupBarButtonItems() {
        setupMenuBarButtonItem()
        setupMessagesBarButtonItem()
    }

    fileprivate func setupMenuBarButtonItem() {
        let menuIconImage = FAKFontAwesome.naviconIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
        let menuBarButtonItem = NavigationBarButton.barButtonItemWithImage(menuIconImage, target: self, action: "menuButtonTapped:")
        navigationItem.leftBarButtonItem = menuBarButtonItem
    }

    fileprivate func setupMessagesBarButtonItem() {
//        let messageIconImage = FAKFontAwesome.envelopeOIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0))
//        let messagesBarButtonItem = NavigationBarButton.barButtonItemWithImage(messageIconImage, target: self, action: "messageButtonTapped:")
//        navigationItem.rightBarButtonItem = messagesBarButtonItem
    }

    @objc fileprivate func menuButtonTapped(_ sender: UIBarButtonItem) {
        NotificationCenter.default.postNotificationName("MenuContainerShouldOpen")
    }

    @objc fileprivate func messageButtonTapped(_ sender: UIBarButtonItem) {
        let messagesNavCon = UIStoryboard("Messages").instantiateInitialViewController() as? UINavigationController
        presentViewController(messagesNavCon!, animated: true)
    }

    // MARK: Route segue state interrogation

    fileprivate var canAttemptSegueToValidRouteContext: Bool {
        return canAttemptSegueToLoadingRoute || canAttemptSegueToInProgressRoute || canAttemptSegueToUnloadingRoute || canAttemptSegueToNextRoute
    }

    fileprivate var canAttemptSegueToLoadingRoute: Bool {
        return RouteService.sharedService().loadingRoute != nil
    }

    fileprivate var canAttemptSegueToUnloadingRoute: Bool {
        return RouteService.sharedService().unloadingRoute != nil
    }

    fileprivate var canAttemptSegueToNextRoute: Bool {
        return RouteService.sharedService().nextRoute != nil
    }

    fileprivate var canAttemptSegueToInProgressRoute: Bool {
        return RouteService.sharedService().inProgressRoute != nil
    }

    fileprivate var canAttemptSegueToUnloadInProgressRoute: Bool {
        if let route = RouteService.sharedService().inProgressRoute {
            return route.disposedOfAllWorkOrders
        }
        return false
    }

    // MARK: WorkOrder segue state interrogation

    fileprivate var canAttemptSegueToValidWorkOrderContext: Bool {
        if let _ = RouteService.sharedService().inProgressRoute {
            return false
        }

        return canAttemptSegueToInProgressWorkOrder || canAttemptSegueToEnRouteWorkOrder || canAttemptSegueToNextWorkOrder
    }

    fileprivate var canAttemptSegueToNextWorkOrder: Bool {
        return WorkOrderService.sharedService().nextWorkOrder != nil
    }

    fileprivate var canAttemptSegueToEnRouteWorkOrder: Bool {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            return workOrder.status == "en_route"
        }
        return false
    }

    fileprivate var canAttemptSegueToInProgressWorkOrder: Bool {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            return workOrder.status == "in_progress" || workOrder.status == "rejected"
        }
        return false
    }

    fileprivate var viewingDirections: Bool {
        for vc in managedViewControllers {
            if vc is DirectionsViewController {
                return true
            }
        }
        return false
    }

    func loadCompaniesContext() {
        let user = currentUser()
        user.reloadCompanies(
            { statusCode, mappingResult in
                var company: Company!
                let companies = mappingResult?.array() as! [Company]
                if companies.count == 1 {
                    company = companies.first!
                } else {
                    for c in companies {
                        if user.defaultCompanyId > 0 && c.id == user.defaultCompanyId {
                            company = c
                            break
                        }
                    }
                }

                if let company = company {
                    if !company.isIntegratedWithQuickbooks && !user.hasBeenPromptedToIntegrateQuickbooks {
                        self.performSegue(withIdentifier: "QuickbooksViewControllerSegue", sender: company)
                    }
                }
            },
            onError: { error, statusCode, responseString in

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
            onRoutesFetched: { [weak self] routes in
                if routes.count == 0 {
                    workOrderService.fetch(
                        status: "scheduled,en_route,in_progress,rejected",
                        today: true,
                        onWorkOrdersFetched: { [weak self] workOrders in
                            workOrderService.setWorkOrders(workOrders) // FIXME -- decide if this should live in the service instead

                            if workOrders.count == 0 {
                                self!.zeroStateViewController?.render(self!.view)
                            }

                            self!.nextWorkOrderContextShouldBeRewound()
                            self!.attemptSegueToValidWorkOrderContext()
                            self!.updatingWorkOrderContext = false
                        }
                    )
                } else if routes.count > 0 {
                    workOrderService.setWorkOrdersUsingRoute(routes[0])
                    self!.attemptSegueToValidRouteContext()
                    self!.updatingWorkOrderContext = false
                }
            }
        )
    }

    fileprivate func attemptSegueToCompleteRoute() {
        if let route = RouteService.sharedService().currentRoute {
            if route == RouteService.sharedService().inProgressRoute {
                if let providerOriginAssignment = route.providerOriginAssignment {
                    if let origin = providerOriginAssignment.origin {
                        RouteService.sharedService().setInProgressRouteOriginRegionMonitoringCallbacks(
                            {
                                route.arrive(
                                    { [weak self] statusCode, responseString in
                                        self!.nextWorkOrderContextShouldBeRewound()
                                        LocationService.sharedService().unregisterRegionMonitor(origin.regionIdentifier)
                                        self!.attemptSegueToValidWorkOrderContext()
                                    },
                                    onError: { [weak self] error, statusCode, responseString in
                                        route.reload(
                                            { statusCode, mappingResult in
                                                self!.nextWorkOrderContextShouldBeRewound()
                                                LocationService.sharedService().unregisterRegionMonitor(origin.regionIdentifier)
                                                self!.attemptSegueToValidWorkOrderContext()
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
            performSegue(withIdentifier: "RouteManifestViewControllerSegue", sender: self)
        } else if canAttemptSegueToUnloadingRoute {
            performSegue(withIdentifier: "RouteManifestViewControllerSegue", sender: self)
        } else if canAttemptSegueToUnloadInProgressRoute {
            performSegue(withIdentifier: "DirectionsViewControllerSegue", sender: self)
        } else if canAttemptSegueToInProgressRoute {
            attemptSegueToValidWorkOrderContext()
        } else if canAttemptSegueToNextRoute {
            performSegue(withIdentifier: "RouteManifestViewControllerSegue", sender: self)
        } else {
            dispatch_after_delay(0.0) { [weak self] in
                self!.mapView.revealMap(true)

                self!.zeroStateViewController?.render(self!.view)
            }
        }
    }

    func attemptSegueToValidWorkOrderContext() {
        if canAttemptSegueToEnRouteWorkOrder {
            performSegue(withIdentifier: "DirectionsViewControllerSegue", sender: self)
        } else if canAttemptSegueToInProgressWorkOrder {
            performSegue(withIdentifier: "WorkOrderComponentViewControllerSegue", sender: self)
        } else if canAttemptSegueToNextWorkOrder {
            performSegue(withIdentifier: "WorkOrderAnnotationViewControllerSegue", sender: self)
        } else {
            attemptSegueToValidRouteContext()
        }
    }

    fileprivate func refreshAnnotations() {
        dispatch_after_delay(0.0) {
            self.shouldRemoveMapAnnotationsForWorkOrderViewController(self)

            if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
                self.mapView.addAnnotation(workOrder.annotation)
            }
        }
    }

    // MARK Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if managedViewControllerSegues.indexOfObject(segue.identifier!) != nil {
            managedViewControllers.append(segue.destination as! ViewController)
            zeroStateViewController?.dismiss()
        }

        switch segue.identifier! {
        case "DirectionsViewControllerSegue":
            assert(segue.destination is DirectionsViewController)

            refreshAnnotations()

            if canAttemptSegueToUnloadInProgressRoute {
                attemptSegueToCompleteRoute()
            } else {
                if let wo = WorkOrderService.sharedService().inProgressWorkOrder {
                    WorkOrderService.sharedService().setInProgressWorkOrderRegionMonitoringCallbacks(
                        {
                            if wo.canArrive {
                                wo.arrive(
                                    { [weak self] statusCode, responseString in
                                        self!.nextWorkOrderContextShouldBeRewound()
                                        LocationService.sharedService().unregisterRegionMonitor(wo.regionIdentifier)
                                        self!.attemptSegueToValidWorkOrderContext()
                                    },
                                    onError: { error, statusCode, responseString in

                                    }
                                )
                            }

                        },
                        onDidExitRegion: {
                            
                        }
                    )
                }
            }

            CheckinService.sharedService().enableNavigationAccuracy()
            LocationService.sharedService().enableNavigationAccuracy()

            (segue.destination as! DirectionsViewController).directionsViewControllerDelegate = self
        case "RouteViewControllerSegue":
            assert(segue.destination is RouteViewController)
            //(segue.destinationViewController as! RouteViewController).delegate = self
        case "ManifestViewControllerSegue":
            assert(segue.destination is ManifestViewController)
            (segue.destination as! ManifestViewController).delegate = self
        case "QuickbooksViewControllerSegue":
            assert(segue.destination is UINavigationController)
            let quickbooksViewController = (segue.destination as! UINavigationController).viewControllers.first! as! QuickbooksViewController
            if let sender = sender {
                if sender is Company {
                    quickbooksViewController.company = sender as! Company
                }
            }
        case "RouteManifestViewControllerSegue":
            assert(segue.destination is RouteManifestViewController)
            (segue.destination as! RouteManifestViewController).delegate = self
        case "WorkOrderAnnotationViewControllerSegue":
            assert(segue.destination is WorkOrderAnnotationViewController)
            (segue.destination as! WorkOrderAnnotationViewController).workOrdersViewControllerDelegate = self
        case "WorkOrderComponentViewControllerSegue":
            assert(segue.destination is WorkOrderComponentViewController)
            (segue.destination as! WorkOrderComponentViewController).delegate = self
            (segue.destination as! WorkOrderComponentViewController).workOrdersViewControllerDelegate = self

            refreshAnnotations()
        case "WorkOrderDestinationHeaderViewControllerSegue":
            assert(segue.destination is WorkOrderDestinationHeaderViewController)
            (segue.destination as! WorkOrderDestinationHeaderViewController).workOrdersViewControllerDelegate = self
        case "WorkOrderDestinationConfirmationViewControllerSegue":
            assert(segue.destination is WorkOrderDestinationConfirmationViewController)
            (segue.destination as! WorkOrderDestinationConfirmationViewController).workOrdersViewControllerDelegate = self
        default:
            break
        }
    }

    // MARK: WorkOrdersViewControllerDelegate

    func annotationsForMapView(_ mapView: MKMapView, workOrder: WorkOrder) -> [MKAnnotation] {
        var annotations = [MKAnnotation]()
        annotations.append(workOrder.annotation)
        return annotations
    }

    func annotationViewForMapView(_ mapView: MKMapView, annotation: MKAnnotation) -> MKAnnotationView! {
        var annotationView: MKAnnotationView!

        if annotation is WorkOrder.Annotation {
            for vc in managedViewControllers {
                if vc is WorkOrderAnnotationViewController {
                    annotationView = (vc as! WorkOrderAnnotationViewController).view as! WorkOrderAnnotationView
                }
            }
        }

        return annotationView
    }

    func drivingEtaToNextWorkOrderForViewController(_ viewController: UIViewController) -> NSNumber {
        return WorkOrderService.sharedService().nextWorkOrderDrivingEtaMinutes as NSNumber
    }

    func drivingDirectionsToNextWorkOrderForViewController(_ viewController: UIViewController) -> Directions! {
        return nil
    }

    func managedViewControllersForViewController(_ viewController: UIViewController!) -> [UIViewController] {
        return managedViewControllers
    }

    func mapViewForViewController(_ viewController: UIViewController) -> WorkOrderMapView {
        return mapView
    }

    func mapViewUserTrackingMode(_ mapView: MKMapView) -> MKUserTrackingMode {
//        if viewingDirections {
//            return .FollowWithHeading
//        }
        return .none
    }

    func targetViewForViewController(_ viewController: UIViewController) -> UIView {
        return view
    }

    fileprivate func popManagedNavigationController() -> UINavigationController! {
        if let _ = managedViewControllers.last as? UINavigationController {
            return managedViewControllers.removeLast() as! UINavigationController
        }
        return nil
    }

    fileprivate func navigationControllerContains(_ clazz: AnyClass) -> Bool {
        for viewController in (self.navigationController?.viewControllers)! {
            if viewController.isKind(of: clazz) {
                return true
            }
        }
        return false
    }

    func nextWorkOrderContextShouldBeRewound() {
        while managedViewControllers.count > 0 {
            _ = popManagedNavigationController()
            let viewController = managedViewControllers.removeLast()
            unwindManagedViewController(viewController)
        }

        assert(managedViewControllers.count == 0)
    }

    func nextWorkOrderContextShouldBeRewoundForViewController(_ viewController: UIViewController) {
        if let i = managedViewControllers.index(of: viewController) {
            if viewController is WorkOrderAnnotationViewController {
                shouldRemoveMapAnnotationsForWorkOrderViewController(viewController as! WorkOrderAnnotationViewController)
            } else {
                unwindManagedViewController(viewController)
            }

            managedViewControllers.remove(at: i)
        }
    }

    fileprivate func unwindManagedViewController(_ viewController: UIViewController) {
        let segueIdentifier = ("\(NSStringFromClass(type(of: (viewController as AnyObject))))UnwindSegue" as String).components(separatedBy: ".").last!
        let index = [
            "DirectionsViewControllerUnwindSegue",
            "WorkOrderAnnotationViewControllerUnwindSegue",
            "WorkOrderDestinationHeaderViewControllerUnwindSegue",
            "WorkOrderDestinationConfirmationViewControllerUnwindSegue",
            "WorkOrderComponentViewControllerUnwindSegue"
            ].index(of: segueIdentifier)
        if let _ = index {
            viewController.performSegue(withIdentifier: segueIdentifier, sender: self)
        }
    }

    func confirmationRequiredForWorkOrderViewController(_ viewController: UIViewController) {
        performSegue(withIdentifier: "WorkOrderDestinationHeaderViewControllerSegue", sender: self)
        performSegue(withIdentifier: "WorkOrderDestinationConfirmationViewControllerSegue", sender: self)
    }

    func confirmationCanceledForWorkOrderViewController(_ viewController: UIViewController) {
        nextWorkOrderContextShouldBeRewound()
        attemptSegueToValidWorkOrderContext()
    }

    func confirmationReceivedForWorkOrderViewController(_ viewController: UIViewController) {
        if viewController is WorkOrderDestinationConfirmationViewController {
            if let workOrder = WorkOrderService.sharedService().nextWorkOrder {
                workOrder.start(
                    { [weak self] statusCode, responseString in
                        self!.nextWorkOrderContextShouldBeRewound()
                        self!.performSegue(withIdentifier: "DirectionsViewControllerSegue", sender: self!)
                    },
                    onError: { error, statusCode, responseString in

                    }
                )
            }
        }
    }

    func workOrderDeliveryConfirmedForViewController(_ viewController: ViewController) {
        nextWorkOrderContextShouldBeRewound()
        if let inProgressWorkOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            if inProgressWorkOrder.components.count > 0 {
                var components = inProgressWorkOrder.components
                components = components.count == 1 ? [] : NSMutableArray(array: components.subarray(with: NSMakeRange(1, components.count - 1)))
                inProgressWorkOrder.setComponents(components)
            }
        }

        attemptSegueToValidWorkOrderContext()
    }

    func workOrderAbandonedForViewController(_ viewController: ViewController) {
        nextWorkOrderContextShouldBeRewound()
        WorkOrderService.sharedService().inProgressWorkOrder.abandon(
            { [weak self] statusCode, responseString in
                self!.attemptSegueToValidWorkOrderContext()
            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func workOrderItemsOrderedForViewController(_ packingSlipViewController: PackingSlipViewController) -> [Product] {
        return WorkOrderService.sharedService().inProgressWorkOrder.itemsOrdered
    }

    func workOrderItemsOnTruckForViewController(_ packingSlipViewController: PackingSlipViewController) -> [Product] {
        return WorkOrderService.sharedService().inProgressWorkOrder.itemsOnTruck
    }

    func workOrderItemsUnloadedForViewController(_ packingSlipViewController: PackingSlipViewController) -> [Product] {
        return WorkOrderService.sharedService().inProgressWorkOrder.itemsDelivered
    }

    func workOrderItemsRejectedForViewController(_ packingSlipViewController: PackingSlipViewController) -> [Product] {
        return WorkOrderService.sharedService().inProgressWorkOrder.itemsRejected
    }

    func summaryLabelTextForSignatureViewController(_ viewController: SignatureViewController) -> String {
        return "Received \(WorkOrderService.sharedService().inProgressWorkOrder.itemsDelivered.count) item(s) in good condition"
    }

    func signatureReceived(_ signature: UIImage, forWorkOrderViewController: ViewController) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            nextWorkOrderContextShouldBeRewound()
            if workOrder.components.count > 0 {
                var components = workOrder.components
                components = components.count == 1 ? [] : NSMutableArray(array: components.subarray(with: NSMakeRange(1, components.count - 1)))
                workOrder.setComponents(components)
            }
            attemptSegueToValidWorkOrderContext()

            var params = [
                "tags": ["signature", "delivery"],
                "public": false
            ] as [String : Any]

            if let location = LocationService.sharedService().currentLocation {
                params["latitude"] = location.coordinate.latitude
                params["longitude"] = location.coordinate.longitude
            }

            workOrder.attach(signature, params: params as [String : AnyObject],
                onSuccess: { [weak self] statusCode, responseString in
                    self!.attemptCompletionOfInProgressWorkOrder()
                },
                onError: { error, statusCode, responseString in
                    
                }
            )
        }
    }

    func netPromoterScoreReceived(_ netPromoterScore: NSNumber, forWorkOrderViewController: ViewController) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            nextWorkOrderContextShouldBeRewound()
            if workOrder.components.count > 0 {
                var components = workOrder.components
                components = components.count == 1 ? [] : NSMutableArray(array: components.subarray(with: NSMakeRange(1, components.count - 1)))
                workOrder.setComponents(components)
            }
            attemptSegueToValidWorkOrderContext()

            workOrder.scoreProvider(netPromoterScore,
                onSuccess: { [weak self] statusCode, responseString in
                    self!.attemptCompletionOfInProgressWorkOrder()
                },
                onError: { error, statusCode, responseString in
                    
                }
            )
        }
    }

    func netPromoterScoreDeclinedForWorkOrderViewController(_ viewController: ViewController) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            nextWorkOrderContextShouldBeRewound()
            if workOrder.components.count > 0 {
                var components = workOrder.components
                components = components.count == 1 ? [] : NSMutableArray(array: components.subarray(with: NSMakeRange(1, components.count - 1)))
                workOrder.setComponents(components)
            }
            attemptSegueToValidWorkOrderContext()

            attemptCompletionOfInProgressWorkOrder()
        }
    }

    // MARK: CommentsCreationViewControllerDelegate

    func commentCreationViewController(_ viewController: CommentCreationViewController, didSubmitComment comment: String) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            nextWorkOrderContextShouldBeRewound()
            if workOrder.components.count > 0 {
                var components = workOrder.components
                components = components.count == 1 ? [] : NSMutableArray(array: components.subarray(with: NSMakeRange(1, components.count - 1)))
                workOrder.setComponents(components)
            }
            attemptSegueToValidWorkOrderContext()

            workOrder.addComment(comment,
                onSuccess: { [weak self] statusCode, responseString in
                    self!.attemptCompletionOfInProgressWorkOrder()
                },
                onError: { error, statusCode, responseString in

                }
            )
        }
    }

    func commentCreationViewControllerShouldBeDismissed(_ viewController: CommentCreationViewController) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            nextWorkOrderContextShouldBeRewound()
            if workOrder.components.count > 0 {
                var components = workOrder.components
                components = components.count == 1 ? [] : NSMutableArray(array: components.subarray(with: NSMakeRange(1, components.count - 1)))
                workOrder.setComponents(components)
            }
            attemptSegueToValidWorkOrderContext()

            attemptCompletionOfInProgressWorkOrder()
        }
    }

    func promptForCommentCreationViewController(_ viewController: CommentCreationViewController) -> String! {
        return "Anything worth mentioning?"
    }

    func titleForCommentCreationViewController(_ viewController: CommentCreationViewController) -> String! {
        return "COMMENTS"
    }

    func shouldRemoveMapAnnotationsForWorkOrderViewController(_ viewController: UIViewController) {
        mapView.removeAnnotations()
    }

    func navigationControllerForViewController(_ viewController: UIViewController) -> UINavigationController! {
        return navigationController!
    }

    func navigationControllerNavigationItemForViewController(_ viewController: UIViewController) -> UINavigationItem! {
        return navigationItem
    }

    func navigationControllerNavBarButtonItemsShouldBeResetForViewController(_ viewController: UIViewController) {
        setupBarButtonItems()
    }

    // MARK: FloorplanViewControllerDelegate

    func floorplanForFloorplanViewController(_ viewController: FloorplanViewController) -> Floorplan! {
        if let floorplans = jobForFloorplanViewController(viewController)?.floorplans {
            if floorplans.count > 0 {
                return Array(floorplans).sorted(by: { $0.id < $1.id }).first! // HACK
            }
        }
        return nil
    }

    func jobForFloorplanViewController(_ viewController: FloorplanViewController) -> Job! {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            if let job = workOrder.job {
                if job.company == nil {
                    job.company = workOrder.company
                    job.companyId = workOrder.companyId
                }

                if job.customer == nil {
                    job.customer = workOrder.customer
                    job.customerId = workOrder.customerId
                }
                return job
            }
        }
        return nil
    }

    func floorplanImageForFloorplanViewController(_ viewController: FloorplanViewController) -> UIImage! {
        return nil
    }

    func modeForFloorplanViewController(_ viewController: FloorplanViewController) -> FloorplanViewController.Mode! {
        return .workOrders
    }

    func newWorkOrderCanBeCreatedByFloorplanViewController(_ viewController: FloorplanViewController) -> Bool {
        return false
    }

    func areaSelectorIsAvailableForFloorplanViewController(_ viewController: FloorplanViewController) -> Bool {
        return false
    }

    func scaleCanBeSetByFloorplanViewController(_ viewController: FloorplanViewController) -> Bool {
        return false
    }

    func scaleWasSetForFloorplanViewController(_ viewController: FloorplanViewController) {

    }

    func navigationControllerForFloorplanViewController(_ viewController: FloorplanViewController) -> UINavigationController! {
        return navigationController
    }

    func floorplanViewControllerCanDropWorkOrderPin(_ viewController: FloorplanViewController) -> Bool {
        return false
    }

    func toolbarForFloorplanViewController(_ viewController: FloorplanViewController) -> FloorplanToolbar! {
        return nil
    }

    func showToolbarForFloorplanViewController(_ viewController: FloorplanViewController) {

    }

    func hideToolbarForFloorplanViewController(_ viewController: FloorplanViewController) {

    }

    // MARK: DirectionsViewControllerDelegate

    func isPresentingDirections() -> Bool {
        return viewingDirections
    }

    func mapViewForDirectionsViewController(_ directionsViewController: DirectionsViewController) -> MKMapView! {
        return mapView
    }

    func finalDestinationForDirectionsViewController(_ directionsViewController: DirectionsViewController) -> CLLocationCoordinate2D {
        return WorkOrderService.sharedService().inProgressWorkOrder.coordinate
    }

    func navbarPromptForDirectionsViewController(_ viewController: UIViewController) -> String! {
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

    func routeForViewController(_ viewController: UIViewController) -> Route! {
        if let currentRoute = RouteService.sharedService().currentRoute {
            return currentRoute
        }
        return RouteService.sharedService().nextRoute
    }

    func routeUpdated(_ route: Route!, byViewController viewController: UIViewController) {
        dispatch_after_delay(0.0) { [weak self] in
            let _ = self!.navigationController?.popViewController(animated: true)
            self!.attemptSegueToValidRouteContext()
        }
    }

    // MARK: WorkOrderComponentViewControllerDelegate

    func workOrderComponentViewControllerForParentViewController(_ viewController: WorkOrderComponentViewController) -> WorkOrderComponentViewController! {
        var vc: WorkOrderComponentViewController!
        if let componentIdentifier = WorkOrderService.sharedService().inProgressWorkOrder.currentComponentIdentifier {
            let initialViewController: UIViewController = UIStoryboard(componentIdentifier).instantiateInitialViewController()!
            if initialViewController is UINavigationController {
                managedViewControllers.append(initialViewController)
                vc = (initialViewController as! UINavigationController).viewControllers.first as! WorkOrderComponentViewController

                if vc is FloorplanViewController {
                    (vc as! FloorplanViewController).floorplanViewControllerDelegate = self
                } else if vc is CommentsViewController {
                    (vc as! CommentCreationViewController).commentCreationViewControllerDelegate = self
                }
            } else {
                vc = initialViewController as! WorkOrderComponentViewController
            }
        }
        return vc
    }

    fileprivate func attemptCompletionOfInProgressWorkOrder() {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            if workOrder.components.count == 0 {
                workOrder.complete(
                    { [weak self] statusCode, responseString in
                        self!.nextWorkOrderContextShouldBeRewound()
                        self!.attemptSegueToValidWorkOrderContext()
                    },
                    onError: { error, statusCode, responseString in

                    }
                )
            } else {
                // did not attempt to complete work order as there are outstanding components
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
