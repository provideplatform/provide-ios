//
//  WorkOrdersViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import FontAwesomeKit

@objc
protocol WorkOrdersViewControllerDelegate: NSObjectProtocol { // FIXME -- this is not named correctly. need an abstract WorkOrderComponent class and repurpose this hack as that delegate.
    // general UIKit callbacks
    @objc optional func navigationControllerForViewController(_ viewController: UIViewController) -> UINavigationController?
    @objc optional func navigationControllerNavigationItemForViewController(_ viewController: UIViewController) -> UINavigationItem?
    @objc optional func navigationControllerNavBarButtonItemsShouldBeResetForViewController(_ viewController: UIViewController!)
    @objc optional func targetViewForViewController(_ viewController: UIViewController) -> UIView!

    // mapping-related callbacks
    @objc optional func annotationsForMapView(_ mapView: MKMapView, workOrder: WorkOrder) -> [MKAnnotation]
    @objc optional func annotationViewForMapView(_ mapView: MKMapView, annotation: MKAnnotation) -> MKAnnotationView!
    @objc optional func mapViewForViewController(_ viewController: UIViewController!) -> WorkOrderMapView!
    @objc optional func mapViewShouldRefreshVisibleMapRect(_ mapView: MKMapView, animated: Bool)
    @objc optional func shouldRemoveMapAnnotationsForWorkOrderViewController(_ viewController: UIViewController)

    // eta and driving directions callbacks
    @objc optional func drivingEtaToNextWorkOrderChanged(_ minutesEta: Int)
    @objc optional func drivingEtaToNextWorkOrderForViewController(_ viewController: UIViewController) -> Int
    @objc optional func drivingEtaToInProgressWorkOrderChanged(_ minutesEta: Int)
    @objc optional func drivingDirectionsToNextWorkOrderForViewController(_ viewController: UIViewController) -> Directions!

    // next work order context and related segue callbacks
    @objc optional func managedViewControllersForViewController(_ viewController: UIViewController!) -> [UIViewController]
    @objc optional func nextWorkOrderContextShouldBeRewound()
    @objc optional func nextWorkOrderContextShouldBeRewoundForViewController(_ viewController: UIViewController)
    @objc optional func confirmationRequiredForWorkOrderViewController(_ viewController: UIViewController)
    @objc optional func confirmationCanceledForWorkOrderViewController(_ viewController: UIViewController)
    @objc optional func confirmationReceivedForWorkOrderViewController(_ viewController: UIViewController)

    // net promoter
    @objc optional func netPromoterScoreReceived(_ netPromoterScore: Double, forWorkOrderViewController: ViewController)
    @objc optional func netPromoterScoreDeclinedForWorkOrderViewController(_ viewController: ViewController)
}

class WorkOrdersViewController: ViewController, MenuViewControllerDelegate, WorkOrdersViewControllerDelegate, DirectionsViewControllerDelegate, WorkOrderComponentViewControllerDelegate {

    private let managedViewControllerSegues = [
        "DirectionsViewControllerSegue",
        "WorkOrderAnnotationViewControllerSegue",
        "WorkOrderComponentViewControllerSegue",
        "WorkOrderDestinationHeaderViewControllerSegue",
        "WorkOrderDestinationConfirmationViewControllerSegue",
    ]

    private var managedViewControllers = [UIViewController]()
    private var updatingWorkOrderContext = false

    @IBOutlet private weak var mapView: WorkOrderMapView!

    private var zeroStateViewController: ZeroStateViewController!

    private var availabilityBarButtonItem: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "DISMISS", style: .plain, target: nil, action: nil)

        requireProviderContext()

        // FIXME-- how does this next line actually work? localLogout has been called at this point...
        KTNotificationCenter.addObserver(observer: self, selector: #selector(clearProviderContext), name: .ApplicationUserLoggedOut)

        KTNotificationCenter.addObserver(forName: Notification.Name(rawValue: "SegueToWorkOrderHistoryStoryboard")) { [weak self] sender in
            if !self!.navigationControllerContains(WorkOrderHistoryViewController.self) {
                self!.performSegue(withIdentifier: "WorkOrderHistoryViewControllerSegue", sender: self!)
            }
        }

        KTNotificationCenter.addObserver(forName: .WorkOrderContextShouldRefresh) { _ in
            if !self.updatingWorkOrderContext && (WorkOrderService.shared.inProgressWorkOrder == nil || self.canAttemptSegueToEnRouteWorkOrder || self.canAttemptSegueToPendingAcceptanceWorkOrder) {
                if self.viewingDirections && WorkOrderService.shared.inProgressWorkOrder != nil {
                    self.updatingWorkOrderContext = true
                    WorkOrderService.shared.inProgressWorkOrder?.reload(onSuccess: { statusCode, mappingResult in
                        if let workOrder = mappingResult?.firstObject as? WorkOrder, workOrder.status != "en_route" {
                            self.refreshAnnotations()
                            self.loadWorkOrderContext()
                        } else {
                            log("not reloading context due to work order being routed to destination")
                            self.updatingWorkOrderContext = false
                        }
                    }, onError: { error, statusCode, responseString in
                        self.refreshAnnotations()
                        self.updatingWorkOrderContext = true
                        self.loadWorkOrderContext()
                    })
                } else {
                    DirectionService.shared.resetLastDirectionsApiRequestCoordinateAndTimestamp()

                    self.refreshAnnotations()
                    self.updatingWorkOrderContext = true
                    self.loadWorkOrderContext()
                }
            }
        }

        setupMenuBarButtonItem()
        setupAvailabilityBarButtonItem()

        setupZeroStateView()
    }

    private func setupZeroStateView() {
        zeroStateViewController = UIStoryboard("ZeroState").instantiateInitialViewController() as! ZeroStateViewController
    }

    private func setupMenuBarButtonItem() {
        let menuIconImage = FAKFontAwesome.naviconIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
        navigationItem.leftBarButtonItem = NavigationBarButton.barButtonItemWithImage(menuIconImage, target: self, action: #selector(menuButtonTapped))
    }

    private func setupMessagesBarButtonItem() {
        let messageIconImage = FAKFontAwesome.envelopeOIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0))!
        navigationItem.rightBarButtonItem = NavigationBarButton.barButtonItemWithImage(messageIconImage, target: self, action: #selector(messageButtonTapped))
    }

    @objc private func menuButtonTapped(_ sender: UIBarButtonItem) {
        KTNotificationCenter.post(name: .MenuContainerShouldOpen)
    }

    @objc private func messageButtonTapped(_ sender: UIBarButtonItem) {
        let messagesNavCon = UIStoryboard("Messages").instantiateInitialViewController() as? UINavigationController
        present(messagesNavCon!, animated: true)
    }

    @IBAction private func toggleAvailability(_ sender: UISwitch) {
        if let currentProvider = currentProvider {
            availabilityBarButtonItem?.isEnabled = false
            currentProvider.toggleAvailability(onSuccess: { [weak self] statusCode, mappingResult in
                logInfo("Current provider context marked \(sender.isOn ? "available" : "unavailable") for hire")
                self?.availabilityBarButtonItem?.isEnabled = true

                if currentProvider.isAvailable {
                    CheckinService.shared.start()
                    LocationService.shared.start()
                } else {
                    CheckinService.shared.stop()
                    LocationService.shared.stop()
                }
            }, onError: { [weak self] error, statusCode, responseString in
                logWarn("Failed to update current provider availability")
                sender.isOn = !sender.isOn
                self?.availabilityBarButtonItem?.isEnabled = true
            })
        }
    }

    // MARK: WorkOrder segue state interrogation

    private var canAttemptSegueToValidWorkOrderContext: Bool {
        return canAttemptSegueToInProgressWorkOrder || canAttemptSegueToEnRouteWorkOrder || canAttemptSegueToNextWorkOrder
    }

    private var canAttemptSegueToNextWorkOrder: Bool {
        return WorkOrderService.shared.nextWorkOrder != nil
    }

    private var canAttemptSegueToEnRouteWorkOrder: Bool {
        return WorkOrderService.shared.inProgressWorkOrder?.status == "en_route"
    }

    private var canAttemptSegueToPendingAcceptanceWorkOrder: Bool {
        return WorkOrderService.shared.inProgressWorkOrder?.status == "pending_acceptance"
    }

    private var canAttemptSegueToArrivingWorkOrder: Bool {
        return WorkOrderService.shared.inProgressWorkOrder?.status == "arriving"
    }

    private var canAttemptSegueToInProgressWorkOrder: Bool {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
            return workOrder.status == "in_progress" || workOrder.status == "rejected"
        }
        return false
    }

    private var viewingDirections: Bool {
        return managedViewControllers.contains { $0 is DirectionsViewController }
    }

    private func setupAvailabilityBarButtonItem() {
        if availabilityBarButtonItem != nil {
            navigationItem.rightBarButtonItem = nil
            availabilityBarButtonItem = nil
        }

        if currentProvider == nil {
            return
        }

        let availabilitySwitch = UISwitch()
        availabilitySwitch.addTarget(self, action: #selector(toggleAvailability), for: .valueChanged)
        availabilitySwitch.isHidden = false
        availabilitySwitch.isEnabled = true
        availabilitySwitch.isOn = currentProvider.isAvailable

        availabilityBarButtonItem = UIBarButtonItem(customView: availabilitySwitch)
        navigationItem.rightBarButtonItem = availabilityBarButtonItem
    }

    private func requireProviderContext() {
        if let currentProvider = currentProvider {
            logInfo("Current provider context has already been established: \(currentProvider)")
            if currentProvider.isAvailable {
                CheckinService.shared.start()
                LocationService.shared.start()
            }
            loadWorkOrderContext()
            return
        }

        if let user = currentUser {
            if user.providerIds.count == 0 {
                ApiService.shared.createProvider(["user_id": String(user.id)], onSuccess: { [weak self] statusCode, mappingResult in
                    if let provider = mappingResult!.firstObject as? Provider {
                        logInfo("Created new provider context for user: \(user)")
                        user.providerIds.append(provider.id)
                        self?.requireProviderContext()
                    }
                    }, onError: { err, statusCode, response in
                        logWarn("Failed to create new provider for user (\(statusCode))")
                })
            } else if user.providerIds.count == 1 {
                ApiService.shared.fetchProviderWithId(String(user.providerIds.first!), onSuccess: { [weak self] statusCode, mappingResult in
                    if let provider = mappingResult!.firstObject as? Provider {
                        logInfo("Fetched provider context for user: \(provider)")
                        currentProvider = provider

                        self?.setupAvailabilityBarButtonItem()

                        if currentProvider.isAvailable {
                            CheckinService.shared.start()
                            LocationService.shared.start()
                        }

                        self?.loadWorkOrderContext()
                    }
                }, onError: { err, statusCode, response in
                    logWarn("Failed to fetch provider (id: \(user.providerIds.first!)) for user (\(statusCode))")
                })
            }
        } else {
            logWarn("No user for which provider context can be loaded")
        }
    }

    private func loadWorkOrderContext() {
        let workOrderService = WorkOrderService.shared

        workOrderService.fetch(status: "pending_acceptance,en_route,arriving,in_progress") { [weak self] workOrders in
            workOrderService.setWorkOrders(workOrders) // FIXME -- decide if this should live in the service instead

            if workOrders.count == 0 || WorkOrderService.shared.inProgressWorkOrder == nil {
                if let zeroStateViewController = self?.zeroStateViewController {
                    zeroStateViewController.render(self!.view)
                }
            }

            self?.nextWorkOrderContextShouldBeRewound()
            self?.attemptSegueToValidWorkOrderContext()
            self?.updatingWorkOrderContext = false
        }
    }

    private func attemptSegueToValidWorkOrderContext() {
        var availabilityBarButtonItemEnabled = true

        if canAttemptSegueToEnRouteWorkOrder {
            performSegue(withIdentifier: "DirectionsViewControllerSegue", sender: self)
            availabilityBarButtonItemEnabled = false
        } else if canAttemptSegueToArrivingWorkOrder {
            confirmationRequiredForWorkOrderViewController(self)
        } else if canAttemptSegueToInProgressWorkOrder {
            let workOrder = WorkOrderService.shared.inProgressWorkOrder
            if workOrder?.user != nil {
                performSegue(withIdentifier: "DirectionsViewControllerSegue", sender: self)
            } else {
                performSegue(withIdentifier: "WorkOrderComponentViewControllerSegue", sender: self)
            }

            availabilityBarButtonItemEnabled = false
        } else if canAttemptSegueToNextWorkOrder {
            performSegue(withIdentifier: "WorkOrderAnnotationViewControllerSegue", sender: self)
            availabilityBarButtonItemEnabled = false
        } else {
            setupAvailabilityBarButtonItem()
        }

        availabilityBarButtonItem?.isEnabled = availabilityBarButtonItemEnabled
    }

    private func refreshAnnotations() {
        DispatchQueue.main.async {
            self.shouldRemoveMapAnnotationsForWorkOrderViewController(self)

            if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
                self.mapView.addAnnotation(workOrder.annotation)
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if managedViewControllerSegues.index(of: segue.identifier!) != nil {
            managedViewControllers.append(segue.destination as! ViewController)
            zeroStateViewController?.dismiss()
        }

        switch segue.identifier! {
        case "DirectionsViewControllerSegue":
            assert(segue.destination is DirectionsViewController)

            refreshAnnotations()

            WorkOrderService.shared.setInProgressWorkOrderRegionMonitoringCallbacks({
                logInfo("Entered monitored work order region")
                if let wo = WorkOrderService.shared.inProgressWorkOrder {
                    if wo.canArrive {
                        wo.arrive(onSuccess: { [weak self] statusCode, responseString in
                            logInfo("Work order marked as arriving")
                            LocationService.shared.unregisterRegionMonitor(wo.regionIdentifier)
                            DirectionService.shared.resetLastDirectionsApiRequestCoordinateAndTimestamp()
                            dispatch_after_delay(2.5) {
                                self?.nextWorkOrderContextShouldBeRewound()
                                self?.attemptSegueToValidWorkOrderContext()
                            }
                        }, onError: { error, statusCode, responseString in
                            logWarn("Failed to set work order status to in_progress upon arrival (\(statusCode))")
                            LocationService.shared.unregisterRegionMonitor(wo.regionIdentifier)
                        })
                    } else if wo.status == "in_progress" {
                        wo.complete(onSuccess: { [weak self] statusCode, responseString in
                            logInfo("Completed work order")
                            self?.nextWorkOrderContextShouldBeRewound()
                            self?.attemptSegueToValidWorkOrderContext()
                            LocationService.shared.unregisterRegionMonitor(wo.regionIdentifier)
                        }, onError: { error, statusCode, responseString in
                            logWarn("Failed to set work order status to completed upon arrival (\(statusCode))")
                            LocationService.shared.unregisterRegionMonitor(wo.regionIdentifier)
                        })
                    }
                }
            }, onDidExitRegion: {
                logInfo("Exited monitored work order region")
            })

            CheckinService.shared.enableNavigationAccuracy()
            LocationService.shared.enableNavigationAccuracy()

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

    func navigationControllerForMenuViewController(_ menuViewController: MenuViewController) -> UINavigationController? {
        return navigationController
    }

    func menuItemForMenuViewController(_ menuViewController: MenuViewController, at indexPath: IndexPath) -> MenuItem? {
        switch indexPath.row {
        case 0:
            return MenuItem(label: "History", action: "history")
        case 1:
            return MenuItem(label: "Ride Mode", action: #selector(switchToConsumerMode))
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

    @objc private func clearProviderContext() {
        if currentProvider != nil {
            if currentProvider.available {
                currentProvider.toggleAvailability(onSuccess: { statusCode, mappingResult in
                    logInfo("Current provider context marked unavailable for hire")
                    currentProvider = nil
                }, onError: { error, statusCode, responseString in
                    logWarn("Failed to update current provider availability; current provider context cleared anyway")
                    currentProvider = nil
                })
            }
        }
    }

    @objc func switchToConsumerMode() {
        // TODO: ensure there is not an active work order that should prevent this from happening...
        clearProviderContext()

        KeyChainService.shared.mode = .consumer
        KTNotificationCenter.post(name: .ApplicationShouldReloadTopViewController)
    }

    // MARK: WorkOrdersViewControllerDelegate

    func annotationsForMapView(_ mapView: MKMapView, workOrder: WorkOrder) -> [MKAnnotation] {
        var annotations = [MKAnnotation]()
        if let user = workOrder.user {
            annotations.append(user.annotation)
        } else {
            annotations.append(workOrder.annotation)
        }

        return annotations
    }

    func annotationViewForMapView(_ mapView: MKMapView, annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView: MKAnnotationView!

        if annotation is WorkOrder.Annotation {
            for vc in managedViewControllers where vc is WorkOrderAnnotationViewController {
                annotationView = (vc as! WorkOrderAnnotationViewController).view as! WorkOrderAnnotationView
            }
        } else if annotation is User.Annotation {

        }

        return annotationView
    }

    func drivingEtaToNextWorkOrderForViewController(_ viewController: UIViewController) -> Int {
        return WorkOrderService.shared.nextWorkOrderDrivingEtaMinutes
    }

    func drivingDirectionsToNextWorkOrderForViewController(_ viewController: UIViewController) -> Directions? {
        return nil
    }

    func managedViewControllersForViewController(_ viewController: UIViewController!) -> [UIViewController] {
        return managedViewControllers
    }

    func mapViewForViewController(_ viewController: UIViewController) -> WorkOrderMapView {
        return mapView
    }

    func mapViewUserTrackingMode(_ mapView: MKMapView) -> MKUserTrackingMode {
        if viewingDirections {
            return .followWithHeading
        }
        return .none
    }

    func targetViewForViewController(_ viewController: UIViewController) -> UIView {
        return view
    }

    private func popManagedNavigationController() -> UINavigationController? {
        if managedViewControllers.last as? UINavigationController != nil {
            return managedViewControllers.removeLast() as? UINavigationController
        }
        return nil
    }

    private func navigationControllerContains(_ clazz: AnyClass) -> Bool {
        for viewController in (navigationController?.viewControllers)! {
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

    private func unwindManagedViewController(_ viewController: UIViewController) {
        let segueIdentifier = ("\(NSStringFromClass(type(of: (viewController as AnyObject))))UnwindSegue" as String).components(separatedBy: ".").last!
        let index = [
            "DirectionsViewControllerUnwindSegue",
            "WorkOrderAnnotationViewControllerUnwindSegue",
            "WorkOrderDestinationHeaderViewControllerUnwindSegue",
            "WorkOrderDestinationConfirmationViewControllerUnwindSegue",
            "WorkOrderComponentViewControllerUnwindSegue",
        ].index(of: segueIdentifier)

        if index != nil {
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
            if let workOrder = WorkOrderService.shared.nextWorkOrder {
                workOrder.route(onSuccess: { [weak self] statusCode, responseString in
                    logInfo("Work order en route")
                    self?.nextWorkOrderContextShouldBeRewound()
                    self?.performSegue(withIdentifier: "DirectionsViewControllerSegue", sender: self!)
                }, onError: { error, statusCode, responseString in
                    logWarn("Failed to start work order (\(statusCode))")
                })
            } else if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
                workOrder.start(onSuccess: { [weak self] statusCode, responseString in
                    logInfo("Work order started")
                    self?.nextWorkOrderContextShouldBeRewound()
                    self?.performSegue(withIdentifier: "DirectionsViewControllerSegue", sender: self!)
                }, onError: { error, statusCode, responseString in
                    logWarn("Failed to start work order (\(statusCode))")
                })
            }
        }
    }

    private func workOrderAbandonedForViewController(_ viewController: ViewController) {
        nextWorkOrderContextShouldBeRewound()
        WorkOrderService.shared.inProgressWorkOrder.abandon(onSuccess: { [weak self] statusCode, responseString in
            self?.attemptSegueToValidWorkOrderContext()
        }, onError: { error, statusCode, responseString in
            logWarn("Failed to abandon work order (\(statusCode))")
        })
    }

    func netPromoterScoreReceived(_ netPromoterScore: Double, forWorkOrderViewController: ViewController) {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
            nextWorkOrderContextShouldBeRewound()
            if workOrder.components.count > 0 {
                var components = workOrder.components
                components = components.count == 1 ? [] : NSMutableArray(array: components.subarray(with: NSRange(location: 1, length: components.count - 1)))
                workOrder.setComponents(components)
            }
            attemptSegueToValidWorkOrderContext()

            workOrder.scoreProvider(netPromoterScore, onSuccess: { [weak self] statusCode, responseString in
                self?.attemptCompletionOfInProgressWorkOrder()
            }, onError: { error, statusCode, responseString in
                logError(error)
            })
        }
    }

    func netPromoterScoreDeclinedForWorkOrderViewController(_ viewController: ViewController) {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
            nextWorkOrderContextShouldBeRewound()
            if workOrder.components.count > 0 {
                var components = workOrder.components
                components = components.count == 1 ? [] : NSMutableArray(array: components.subarray(with: NSRange(location: 1, length: components.count - 1)))
                workOrder.setComponents(components)
            }
            attemptSegueToValidWorkOrderContext()

            attemptCompletionOfInProgressWorkOrder()
        }
    }

    func shouldRemoveMapAnnotationsForWorkOrderViewController(_ viewController: UIViewController) {
        mapView.removeAnnotations()
    }

    func navigationControllerForViewController(_ viewController: UIViewController) -> UINavigationController? {
        return navigationController
    }

    func navigationControllerNavigationItemForViewController(_ viewController: UIViewController) -> UINavigationItem? {
        return navigationItem
    }

    func navigationControllerNavBarButtonItemsShouldBeResetForViewController(_ viewController: UIViewController) {
        setupMenuBarButtonItem()
        setupAvailabilityBarButtonItem()
    }

    // MARK: DirectionsViewControllerDelegate

    func isPresentingDirections() -> Bool {
        return viewingDirections
    }

    @nonobjc func mapViewForDirectionsViewController(_ directionsViewController: DirectionsViewController) -> MKMapView {
        return mapView
    }

    func finalDestinationForDirectionsViewController(_ directionsViewController: DirectionsViewController) -> CLLocationCoordinate2D {
        return WorkOrderService.shared.inProgressWorkOrder.coordinate
    }

    func navbarPromptForDirectionsViewController(_ viewController: UIViewController) -> String? {
        return nil
    }

    // MARK: WorkOrderComponentViewControllerDelegate

    func workOrderComponentViewControllerForParentViewController(_ viewController: WorkOrderComponentViewController) -> WorkOrderComponentViewController {
        var vc: WorkOrderComponentViewController!
        if let componentIdentifier = WorkOrderService.shared.inProgressWorkOrder.currentComponentIdentifier {
            let initialViewController: UIViewController = UIStoryboard(componentIdentifier).instantiateInitialViewController()!
            if initialViewController is UINavigationController {
                managedViewControllers.append(initialViewController)
                vc = (initialViewController as! UINavigationController).viewControllers.first as! WorkOrderComponentViewController
            } else {
                vc = initialViewController as! WorkOrderComponentViewController
            }
        }
        return vc
    }

    private func attemptCompletionOfInProgressWorkOrder() {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder, workOrder.components.count == 0 {
            workOrder.complete(onSuccess: { [weak self] statusCode, responseString in
                self?.nextWorkOrderContextShouldBeRewound()
                self?.attemptSegueToValidWorkOrderContext()
            }, onError: { error, statusCode, responseString in
                logError(error)
            })
        } else {
            // did not attempt to complete work order as there are outstanding components
        }
    }
}
