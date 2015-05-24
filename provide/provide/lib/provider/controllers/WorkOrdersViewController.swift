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
    optional func navigationControllerForViewController(viewController: ViewController!) -> UINavigationController!
    optional func navigationControllerNavigationItemForViewController(viewController: ViewController!) -> UINavigationItem!
    optional func targetViewForViewController(viewController: ViewController!) -> UIView!
    optional func slidingViewControllerForViewController(viewController: ViewController!) -> ECSlidingViewController!

    // mapping-related callbacks
    optional func annotationsForMapView(mapView: MKMapView!, workOrder: WorkOrder!) -> [MKAnnotation]!
    optional func annotationViewForMapView(mapView: MKMapView!, annotation: MKAnnotation!) -> MKAnnotationView!
    optional func mapViewForViewController(viewController: ViewController!) -> WorkOrderMapView!
    optional func mapViewShouldRefreshVisibleMapRect(mapView: MKMapView!, animated: Bool)
    optional func shouldRemoveMapAnnotationsForWorkOrderViewController(viewController: ViewController!)

//    // location service related callbacks
//    optional func locationServiceDidUpdateUserLocation(coordinate: CLLocationCoordinate2D)

    // eta and driving directions callbacks
    optional func drivingEtaToNextWorkOrderChanged(minutesEta: NSNumber!)
    optional func drivingEtaToNextWorkOrderForViewController(viewController: ViewController!) -> NSNumber!
    optional func drivingEtaToInProgressWorkOrderChanged(minutesEta: NSNumber!)
    optional func drivingDirectionsToNextWorkOrderForViewController(viewController: ViewController!) -> Directions!

    // next work order context and related segue callbacks
    optional func managedViewControllersForViewController(viewController: ViewController!) -> [ViewController]!
    optional func nextWorkOrderContextShouldBeRewound()
    optional func nextWorkOrderContextShouldBeRewoundForViewController(viewController: ViewController!)
    optional func unwindManagedViewController(viewController: ViewController!)
    optional func confirmationRequiredForWorkOrderViewController(viewController: ViewController!)
    optional func confirmationCanceledForWorkOrderViewController(viewController: ViewController!)
    optional func confirmationReceivedForWorkOrderViewController(viewController: ViewController!)

    // in progress work order context and related segue callbacks
    // packing slip
    optional func workOrderAbandonedForViewController(viewController: ViewController!)
    optional func workOrderDeliveryConfirmedForViewController(viewController: ViewController!)
    optional func workOrderItemsOrderedForViewController(packingSlipViewController: PackingSlipViewController!) -> [Product]!
    optional func workOrderItemsOnTruckForViewController(packingSlipViewController: PackingSlipViewController!) -> [Product]!
    optional func workOrderItemsUnloadedForViewController(packingSlipViewController: PackingSlipViewController!) -> [Product]!
    optional func workOrderItemsRejectedForViewController(packingSlipViewController: PackingSlipViewController!) -> [Product]!

    // signature
    optional func summaryLabelTextForSignatureViewController(viewController: SignatureViewController!) -> String!
    optional func signatureReceived(signature: UIImage!, forWorkOrderViewController: ViewController!)

    // net promoter
    optional func netPromoterScoreReceived(netPromoterScore: NSNumber!, forWorkOrderViewController: ViewController!)
    optional func netPromoterScoreDeclinedForWorkOrderViewController(viewController: ViewController!)
}

class WorkOrdersViewController: ViewController, UITableViewDelegate,
                                                UITableViewDataSource,
                                                WorkOrdersViewControllerDelegate,
                                                DirectionsViewControllerDelegate,
                                                WorkOrderComponentViewControllerDelegate,
                                                RouteManifestViewControllerDelegate {

    private var managedViewControllers = [ViewController]()
    private var updatingWorkOrderContext = false

    @IBOutlet private weak var mapView: WorkOrderMapView!
    @IBOutlet private weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.hidden = true

        navigationItem.hidesBackButton = true

        loadRouteContext()

        NSNotificationCenter.defaultCenter().addObserverForName("WorkOrderContextShouldRefresh") { _ in
            if self.updatingWorkOrderContext == false && (WorkOrderService.sharedService().inProgressWorkOrder == nil || self.canAttemptSegueToEnRouteWorkOrder == true) {
                if self.viewingDirections {
                    WorkOrderService.sharedService().inProgressWorkOrder.reload({ statusCode, mappingResult in
                        if let workOrder = mappingResult.firstObject as? WorkOrder {
                            if workOrder.status != "en_route" {
                                self.updatingWorkOrderContext = true
                                self.loadRouteContext()
                            } else {
                                log("not reloading context due to work order being routed to destination")
                            }
                        }
                    }, onError: { error, statusCode, responseString in
                        self.updatingWorkOrderContext = true
                        self.loadRouteContext()
                    })
                } else {
                    self.updatingWorkOrderContext = true
                    self.loadRouteContext()
                }
            }
        }
    }

    // MARK: Route segue state interrogation

    private var canAttemptSegueToValidRouteContext: Bool {
        return canAttemptSegueToLoadingRoute == true || canAttemptSegueToInProgressRoute == true || canAttemptSegueToNextRoute == true
    }

    private var canAttemptSegueToLoadingRoute: Bool {
        return RouteService.sharedService().loadingRoute != nil
    }

    private var canAttemptSegueToNextRoute: Bool {
        return RouteService.sharedService().nextRoute != nil
    }

    private var canAttemptSegueToInProgressRoute: Bool {
        if let route = RouteService.sharedService().inProgressRoute {
            return route.status == "in_progress"
        }
        return false
    }

    // MARK: WorkOrder segue state interrogation

    private var canAttemptSegueToValidWorkOrderContext: Bool {
        for route in [RouteService.sharedService().inProgressRoute, RouteService.sharedService().nextRoute] {
            if route != nil && route.canStart() == false {
                return false
            }
        }
        return canAttemptSegueToInProgressWorkOrder == true || canAttemptSegueToEnRouteWorkOrder == true || canAttemptSegueToNextWorkOrder == true
    }

    private var canAttemptSegueToNextWorkOrder: Bool {
        return WorkOrderService.sharedService().nextWorkOrder != nil //&& mapView.userLocation != nil //(mapView.userLocation != nil || LocationService.sharedService().currentLocation != nil)
    }

    private var canAttemptSegueToEnRouteWorkOrder: Bool {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            return workOrder.status == "en_route" //&& mapView.userLocation != nil
        }
        return false
    }

    private var canAttemptSegueToInProgressWorkOrder: Bool {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            return workOrder.status == "in_progress" //&& mapView.userLocation != nil
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
            status: "scheduled,loading,in_progress",
            today: true,
            nextRouteOnly: true,
            onRoutesFetched: { routes in
                if routes.count == 0 {
                    workOrderService.fetch(
                        status: "scheduled,en_route,in_progress",
                        today: true,
                        onWorkOrdersFetched: { workOrders in
                            workOrderService.setWorkOrders(workOrders) // FIXME -- decide if this should live in the service instead

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

    func attemptSegueToValidRouteContext() {
        if canAttemptSegueToLoadingRoute {
            performSegueWithIdentifier("RouteManifestViewControllerSegue", sender: self)
        } else if canAttemptSegueToInProgressRoute {
            attemptSegueToValidWorkOrderContext()
        } else if canAttemptSegueToNextRoute {
            performSegueWithIdentifier("RouteManifestViewControllerSegue", sender: self)
        } else {
            mapView.revealMap(force: true) // FIXME -- show zero state
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
            mapView.revealMap(force: true)

            // FIXME -- the following needs to be done differently as to allow the dispatcher to close out routes:
//            if canAttemptSegueToInProgressRoute == true {
//                RouteService.sharedService().inProgressRoute.complete({ statusCode, responseString in
//                    attemptSegueToValidRouteContext()
//                }, onError: { error, statusCode, responseString in
//
//                })
//            }
        }
    }

    // MARK Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        managedViewControllers.append(segue.destinationViewController as! ViewController)

        switch segue.identifier! {
        case "DirectionsViewControllerSegue":
            assert(segue.destinationViewController is DirectionsViewController)

            if let wo = WorkOrderService.sharedService().inProgressWorkOrder {
                WorkOrderService.sharedService().setInProgressWorkOrderRegionMonitoringCallbacks({
                    wo.arrive({ statusCode, responseString in
                        self.nextWorkOrderContextShouldBeRewound()
                        LocationService.sharedService().unregisterRegionMonitor(wo.regionIdentifier)
                        self.attemptSegueToValidWorkOrderContext()
                    }, onError: { error, statusCode, responseString in

                    })
                }, onDidExitRegion: {

                })
            }

            CheckinService.sharedService().enableNavigationAccuracy()
            LocationService.sharedService().enableNavigationAccuracy()

            (segue.destinationViewController as! DirectionsViewController).directionsViewControllerDelegate = self
            break

        case "RouteManifestViewControllerSegue":
            assert(segue.destinationViewController is RouteManifestViewController)
            (segue.destinationViewController as! RouteManifestViewController).delegate = self
            break

        case "WorkOrderAnnotationViewControllerSegue":
            assert(segue.destinationViewController is WorkOrderAnnotationViewController)
            (segue.destinationViewController as! WorkOrderAnnotationViewController).workOrdersViewControllerDelegate = self
            break
        case "WorkOrderComponentViewControllerSegue":
            assert(segue.destinationViewController is WorkOrderComponentViewController)
            (segue.destinationViewController as! WorkOrderComponentViewController).delegate = self
            (segue.destinationViewController as! WorkOrderComponentViewController).workOrdersViewControllerDelegate = self
            break
        case "WorkOrderDestinationHeaderViewControllerSegue":
            assert(segue.destinationViewController is WorkOrderDestinationHeaderViewController)
            (segue.destinationViewController as! WorkOrderDestinationHeaderViewController).workOrdersViewControllerDelegate = self
            break
        case "WorkOrderDestinationConfirmationViewControllerSegue":
            assert(segue.destinationViewController is WorkOrderDestinationConfirmationViewController)
            (segue.destinationViewController as! WorkOrderDestinationConfirmationViewController).workOrdersViewControllerDelegate = self
            break
        default:
            break
        }
    }

    // MARK UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!

        return cell
    }

    //optional func numberOfSectionsInTableView(tableView: UITableView) -> Int // Default is 1 if not implemented

    //optional func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? // fixed font style. use custom view (UILabel) if you want something different
    //optional func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String?

    // Editing

    // Individual rows can opt out of having the -editing property set for them. If not implemented, all rows are assumed to be editable.
    //optional func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool

    // Moving/reordering

    // Allows the reorder accessory view to optionally be shown for a particular row. By default, the reorder control will be shown only if the datasource implements -tableView:moveRowAtIndexPath:toIndexPath:
    //optional func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool

    // Index

    //optional func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! // return list of section titles to display in section index view (e.g. "ABCD...Z#")
    //optional func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int // tell table which section corresponds to section title/index (e.g. "B",1))

    // Data manipulation - insert and delete support

    // After a row has the minus or plus button invoked (based on the UITableViewCellEditingStyle for the cell), the dataSource must commit the change
    // Not called for edit actions using UITableViewRowAction - the action's handler will be invoked instead
    //optional func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)

    // Data manipulation - reorder / moving support

    //optional func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath)

    // MARK: WorkOrdersViewControllerDelegate

    func annotationsForMapView(mapView: MKMapView!, workOrder: WorkOrder!) -> [MKAnnotation]! {
        var annotations = [MKAnnotation]()

        return annotations
    }

    func annotationViewForMapView(mapView: MKMapView!, annotation: MKAnnotation!) -> MKAnnotationView! {
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

    func drivingEtaToNextWorkOrderForViewController(viewController: ViewController!) -> Int! {
        return WorkOrderService.sharedService().nextWorkOrderDrivingEtaMinutes
    }

    func drivingDirectionsToNextWorkOrderForViewController(viewController: ViewController!) -> Directions! {
        return nil
    }

    func managedViewControllersForViewController(viewController: ViewController!) -> [ViewController]! {
        return managedViewControllers
    }

    func mapViewForViewController(viewController: ViewController!) -> WorkOrderMapView! {
        return mapView
    }

    func mapViewUserTrackingMode(mapView: MKMapView!) -> MKUserTrackingMode {
//        if viewingDirections {
//            return .FollowWithHeading
//        }
        return .None
    }

    func targetViewForViewController(viewController: ViewController!) -> UIView! {
        return view
    }

    func slidingViewControllerForViewController(viewController: ViewController!) -> ECSlidingViewController! {
        return slidingViewController()
    }

    func nextWorkOrderContextShouldBeRewound() {
        while managedViewControllers.count > 0 {
            let viewController = managedViewControllers.removeLast()
            unwindManagedViewController(viewController)
        }

        assert(managedViewControllers.count == 0)
    }

    func nextWorkOrderContextShouldBeRewoundForViewController(viewController: ViewController!) {
        if let i = find(managedViewControllers, viewController) {
            if viewController is WorkOrderAnnotationViewController {
                shouldRemoveMapAnnotationsForWorkOrderViewController(viewController)
            } else {
                unwindManagedViewController(viewController)
            }

            managedViewControllers.removeAtIndex(i)
        }
    }

    func unwindManagedViewController(viewController: ViewController!) {
        let segueIdentifier = ("\(NSStringFromClass((viewController as AnyObject).dynamicType))UnwindSegue" as String).splitAtString(".").1
        viewController.performSegueWithIdentifier(segueIdentifier, sender: self)
    }

    func confirmationRequiredForWorkOrderViewController(viewController: ViewController!) {
        performSegueWithIdentifier("WorkOrderDestinationHeaderViewControllerSegue", sender: self)
        performSegueWithIdentifier("WorkOrderDestinationConfirmationViewControllerSegue", sender: self)
    }

    func confirmationCanceledForWorkOrderViewController(viewController: ViewController!) {
        nextWorkOrderContextShouldBeRewound()
        attemptSegueToValidWorkOrderContext()
    }

    func confirmationReceivedForWorkOrderViewController(viewController: ViewController!) {
        if viewController is WorkOrderDestinationConfirmationViewController {
            if let workOrder = WorkOrderService.sharedService().nextWorkOrder {
                workOrder.start({ statusCode, responseString in
                    self.nextWorkOrderContextShouldBeRewound()
                    self.performSegueWithIdentifier("DirectionsViewControllerSegue", sender: self)
                }, onError: { error, statusCode, responseString in

                })
            }
        }
    }

    func workOrderDeliveryConfirmedForViewController(viewController: ViewController!) {
        nextWorkOrderContextShouldBeRewound()
        WorkOrderService.sharedService().inProgressWorkOrder.components.removeObject(WorkOrderService.sharedService().inProgressWorkOrder.components.firstObject!) // FIXME!!!!
        attemptSegueToValidWorkOrderContext()
    }

    func workOrderAbandonedForViewController(viewController: ViewController!) {
        nextWorkOrderContextShouldBeRewound()
        WorkOrderService.sharedService().inProgressWorkOrder.abandon({ statusCode, responseString in
            self.attemptSegueToValidWorkOrderContext()
        }, onError: { error, statusCode, responseString in

        })
    }

    func workOrderItemsOrderedForViewController(packingSlipViewController: PackingSlipViewController!) -> [Product]! {
        var products = [Product]()
        if let itemsOrdered = WorkOrderService.sharedService().inProgressWorkOrder.itemsOrdered {
            for product in itemsOrdered.objectEnumerator().allObjects {
                products.append(product as! Product)
            }
        }
        return products
    }

    func workOrderItemsOnTruckForViewController(packingSlipViewController: PackingSlipViewController!) -> [Product]! {
        return WorkOrderService.sharedService().inProgressWorkOrder.itemsOnTruck
    }

    func workOrderItemsUnloadedForViewController(packingSlipViewController: PackingSlipViewController!) -> [Product]! {
        var products = [Product]()
        if let itemsUnloaded = WorkOrderService.sharedService().inProgressWorkOrder.itemsUnloaded {
            for product in itemsUnloaded.objectEnumerator().allObjects {
                products.append(product as! Product)
            }
        }
        return products
    }

    func workOrderItemsRejectedForViewController(packingSlipViewController: PackingSlipViewController!) -> [Product]! {
        var products = [Product]()
        if let itemsRejected = WorkOrderService.sharedService().inProgressWorkOrder.itemsRejected {
            for product in itemsRejected.objectEnumerator().allObjects {
                products.append(product as! Product)
            }
        }
        return products
    }

    func summaryLabelTextForSignatureViewController(viewController: SignatureViewController!) -> String! {
        return "Received \(WorkOrderService.sharedService().inProgressWorkOrder.itemsUnloaded.count) item(s) in good condition"
    }

    func signatureReceived(signature: UIImage!, forWorkOrderViewController: ViewController!) {
        nextWorkOrderContextShouldBeRewound()
        WorkOrderService.sharedService().inProgressWorkOrder.components.removeObject(WorkOrderService.sharedService().inProgressWorkOrder.components.firstObject!) // FIXME!!!!
        attemptSegueToValidWorkOrderContext()

        let params = [
            "latitude": LocationService.sharedService().currentLocation.coordinate.latitude,
            "longitude": LocationService.sharedService().currentLocation.coordinate.longitude,
            "tags": "signature, delivery",
            "public": false
        ]

        WorkOrderService.sharedService().inProgressWorkOrder.attach(signature, params: params, onSuccess: { statusCode, responseString in
            WorkOrderService.sharedService().inProgressWorkOrder.updateDeliveredItems({ statusCode, responseString in
                println("updated delivered items!")
            }) { error, statusCode, responseString in
                    
            }
        }) { error, statusCode, responseString in

        }
    }

    func netPromoterScoreReceived(netPromoterScore: NSNumber!, forWorkOrderViewController: ViewController!) {
        nextWorkOrderContextShouldBeRewound()
        WorkOrderService.sharedService().inProgressWorkOrder.components.removeObject(WorkOrderService.sharedService().inProgressWorkOrder.components.firstObject!) // FIXME!!!!
        attemptSegueToValidWorkOrderContext()

        WorkOrderService.sharedService().inProgressWorkOrder.scoreProvider(netPromoterScore, onSuccess: { statusCode, responseString in
            WorkOrderService.sharedService().inProgressWorkOrder.complete({ statusCode, responseString in
                println("net promoter score received")
                self.attemptSegueToValidWorkOrderContext()
            }, onError: { error, statusCode, responseString in

            })
        }) { error, statusCode, responseString in

        }
    }

    func netPromoterScoreDeclinedForWorkOrderViewController(viewController: ViewController!) {
        WorkOrderService.sharedService().inProgressWorkOrder.complete({ statusCode, responseString in
            self.attemptSegueToValidWorkOrderContext()
        }, onError: { error, statusCode, responseString in

        })
    }

    func shouldRemoveMapAnnotationsForWorkOrderViewController(viewController: ViewController!) {
        mapView.removeAnnotations()
    }

    func navigationControllerForViewController(viewController: ViewController!) -> UINavigationController! {
        return navigationController
    }

    func navigationControllerNavigationItemForViewController(viewController: ViewController!) -> UINavigationItem! {
        return navigationItem
    }

    // MARK: DirectionsViewControllerDelegate

    func isPresentingDirections() -> Bool {
        return viewingDirections == true
    }

    func mapViewForDirectionsViewController(directionsViewController: DirectionsViewController!) -> MKMapView! {
        return mapView
    }

    func finalDestinationForDirectionsViewController(directionsViewController: DirectionsViewController!) -> CLLocationCoordinate2D {
        return WorkOrderService.sharedService().inProgressWorkOrder.coordinate
    }

    // MARK: RouteManifestViewControllerDelegate

    func routeForViewController(viewController: ViewController!) -> Route! {
        let routeService = RouteService.sharedService()
        var route = routeService.inProgressRoute
        if route == nil {
            route = routeService.nextRoute
        }
        return route
    }

    func routeUpdated(route: Route!, byViewController viewController: ViewController!) {
        navigationController?.popViewControllerAnimated(true)
        attemptSegueToValidRouteContext()
    }

    // MARK: WorkOrderComponentViewControllerDelegate

    func workOrderComponentViewControllerForParentViewController(viewController: WorkOrderComponentViewController!) -> WorkOrderComponentViewController! {
        var vc: WorkOrderComponentViewController!
        if let componentIdentifier = WorkOrderService.sharedService().inProgressWorkOrder.currentComponentIdentifier {
            vc = UIStoryboard(name: componentIdentifier, bundle: nil).instantiateInitialViewController() as! WorkOrderComponentViewController
        }
        return vc
    }

}
