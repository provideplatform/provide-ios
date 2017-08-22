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

    // net promoter
    @objc optional func netPromoterScoreReceived(_ netPromoterScore: NSNumber, forWorkOrderViewController: ViewController)
    @objc optional func netPromoterScoreDeclinedForWorkOrderViewController(_ viewController: ViewController)

    // comments
    @objc optional func commentsViewController(_ viewController: CommentsViewController, didSubmitComment comment: String)
    @objc optional func commentsViewControllerShouldBeDismissed(_ viewController: CommentsViewController)
}

class WorkOrdersViewController: ViewController, MenuViewControllerDelegate,
                                                WorkOrdersViewControllerDelegate,
                                                CommentCreationViewControllerDelegate,
                                                DirectionsViewControllerDelegate,
                                                WorkOrderComponentViewControllerDelegate {

    fileprivate let managedViewControllerSegues = [
        "DirectionsViewControllerSegue",
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

        loadWorkOrderContext()

        NotificationCenter.default.addObserverForName("SegueToWorkOrderHistoryStoryboard") { [weak self] sender in
            if !self!.navigationControllerContains(WorkOrderHistoryViewController.self) {
                self!.performSegue(withIdentifier: "WorkOrderHistoryViewControllerSegue", sender: self!)
            }
        }

        NotificationCenter.default.addObserverForName("WorkOrderContextShouldRefresh") { _ in
            if !self.updatingWorkOrderContext && (WorkOrderService.sharedService().inProgressWorkOrder == nil || self.canAttemptSegueToEnRouteWorkOrder) {
                if self.viewingDirections {
                    self.updatingWorkOrderContext = true
                    WorkOrderService.sharedService().inProgressWorkOrder?.reload(
                        { statusCode, mappingResult in
                            if let workOrder = mappingResult?.firstObject as? WorkOrder {
                                if workOrder.status != "en_route" {
                                    self.refreshAnnotations()
                                    self.loadWorkOrderContext()
                                } else {
                                    log("not reloading context due to work order being routed to destination")
                                    self.updatingWorkOrderContext = false
                                }
                            }
                    },
                        onError: { error, statusCode, responseString in
                            self.refreshAnnotations()
                            self.updatingWorkOrderContext = true
                            self.loadWorkOrderContext()
                    }
                    )
                } else {
                    self.refreshAnnotations()
                    self.updatingWorkOrderContext = true
                    self.loadWorkOrderContext()
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

    // MARK: WorkOrder segue state interrogation

    fileprivate var canAttemptSegueToValidWorkOrderContext: Bool {
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
        currentUser?.reloadCompanies(
            { statusCode, mappingResult in
                var company: Company!
                let companies = mappingResult?.array() as! [Company]
                if companies.count == 1 {
                    company = companies.first!
                    logInfo("Loaded company: \(company!)")
                } else {
                    for c in companies {
                        if currentUser.defaultCompanyId > 0 && c.id == currentUser.defaultCompanyId {
                            company = c
                            break
                        }
                    }
                }
            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func loadWorkOrderContext() {
        let workOrderService = WorkOrderService.sharedService()

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
    }

    func attemptSegueToValidWorkOrderContext() {
        if canAttemptSegueToEnRouteWorkOrder {
            performSegue(withIdentifier: "DirectionsViewControllerSegue", sender: self)
        } else if canAttemptSegueToInProgressWorkOrder {
            performSegue(withIdentifier: "WorkOrderComponentViewControllerSegue", sender: self)
        } else if canAttemptSegueToNextWorkOrder {
            performSegue(withIdentifier: "WorkOrderAnnotationViewControllerSegue", sender: self)
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

            CheckinService.sharedService().enableNavigationAccuracy()
            LocationService.sharedService().enableNavigationAccuracy()

            (segue.destination as! DirectionsViewController).directionsViewControllerDelegate = self
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

    // MARK: MenuViewControllerDelegate

    func navigationControllerForMenuViewController(_ menuViewController: MenuViewController) -> UINavigationController! {
        return navigationController
    }

    func menuItemForMenuViewController(_ menuViewController: MenuViewController, at indexPath: IndexPath) -> MenuItem! {
        switch (indexPath as NSIndexPath).row {
        case 0:
            return MenuItem(item: ["label": "History", "action": "history"])
        case 1:
            return MenuItem(item: ["label": "Ride Mode", "action": "switchToCustomerMode"])
        default:
            break
        }
        return nil
    }

    func numberOfSectionsInMenuViewController(_ menuViewController: MenuViewController) -> Int {
        return 1
    }

    func menuViewController(_ menuViewController: MenuViewController, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func switchToCustomerMode() {
        KeyChainService.sharedService().mode = .Customer
        NotificationCenter.default.postNotificationName("ApplicationShouldReloadTopViewController")
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

    // MARK: DirectionsViewControllerDelegate

    func isPresentingDirections() -> Bool {
        return viewingDirections
    }

    @nonobjc func mapViewForDirectionsViewController(_ directionsViewController: DirectionsViewController) -> MKMapView! {
        return mapView
    }

    func finalDestinationForDirectionsViewController(_ directionsViewController: DirectionsViewController) -> CLLocationCoordinate2D {
        return WorkOrderService.sharedService().inProgressWorkOrder.coordinate
    }

    func navbarPromptForDirectionsViewController(_ viewController: UIViewController) -> String! {
        return nil
    }

    // MARK: WorkOrderComponentViewControllerDelegate

    func workOrderComponentViewControllerForParentViewController(_ viewController: WorkOrderComponentViewController) -> WorkOrderComponentViewController! {
        var vc: WorkOrderComponentViewController!
        if let componentIdentifier = WorkOrderService.sharedService().inProgressWorkOrder.currentComponentIdentifier {
            let initialViewController: UIViewController = UIStoryboard(componentIdentifier).instantiateInitialViewController()!
            if initialViewController is UINavigationController {
                managedViewControllers.append(initialViewController)
                vc = (initialViewController as! UINavigationController).viewControllers.first as! WorkOrderComponentViewController

                if vc is CommentsViewController {
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
