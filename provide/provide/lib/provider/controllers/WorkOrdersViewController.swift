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
    @objc optional func navigationControllerNavBarButtonItemsShouldBeResetForViewController(_ viewController: UIViewController!)

    // mapping-related callbacks
    @objc optional func annotationViewForMapView(_ mapView: MKMapView, annotation: MKAnnotation) -> MKAnnotationView!
    @objc optional func removeMapAnnotationsForWorkOrderViewController(_ viewController: UIViewController)

    // eta and driving directions callbacks
    @objc optional func drivingEtaToNextWorkOrderChanged(_ minutesEta: Int)

    // next work order context and related segue callbacks
    @objc optional func managedViewControllersForViewController(_ viewController: UIViewController!) -> [UIViewController]
    @objc optional func nextWorkOrderContextShouldBeRewoundForViewController(_ viewController: UIViewController)
    @objc optional func segueToWorkOrderDestinationConfirmationViewController(_ viewController: UIViewController)
    @objc optional func confirmationCanceledForWorkOrderViewController(_ viewController: UIViewController)
    @objc optional func confirmationReceivedForWorkOrderViewController(_ viewController: UIViewController)
}

class WorkOrdersViewController: ViewController, MenuViewControllerDelegate, WorkOrdersViewControllerDelegate, WorkOrderHistoryViewControllerDelegate, DirectionsViewControllerDelegate {

    private let managedViewControllerSegues = [
        "DirectionsViewControllerSegue",
        "WorkOrderAnnotationViewControllerSegue",
        "WorkOrderDestinationConfirmationViewControllerSegue",
    ]

    @IBOutlet private weak var headerViewControllerTopConstraint: NSLayoutConstraint!
    private var managedViewControllers = [UIViewController]()
    private var updatingWorkOrderContext = false

    @IBOutlet private weak var mapView: WorkOrderMapView!

    private var zeroStateViewController = UIStoryboard("ZeroState").instantiateInitialViewController() as! ZeroStateViewController

    private var availabilityBarButtonItem: UIBarButtonItem?

    private var headerView: UIView? {
        return (childViewControllers.first as? WorkOrderDestinationHeaderViewController)?.view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        headerView!.alpha = 0

        navigationItem.hidesBackButton = true
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "DISMISS", style: .plain, target: nil, action: nil)

        requireProviderContext()

        // FIXME-- how does this next line actually work? localLogout has been called at this point...
        KTNotificationCenter.addObserver(observer: self, selector: #selector(clearProviderContext), name: .ApplicationUserLoggedOut)

        KTNotificationCenter.addObserver(forName: Notification.Name(rawValue: "SegueToWorkOrderHistoryStoryboard")) { [weak self] sender in
            if let strongSelf = self {
                if !strongSelf.navigationControllerContains(WorkOrderHistoryViewController.self) {
                    strongSelf.performSegue(withIdentifier: "WorkOrderHistoryViewControllerSegue", sender: strongSelf)
                }
            }
        }

        KTNotificationCenter.addObserver(forName: .WorkOrderChanged) { [weak self] notification in
            if let workOrder = notification.object as? WorkOrder {
                if WorkOrderService.shared.inProgressWorkOrder?.id == workOrder.id, let pendingManualCompletion = self?.pendingManualCompletion, !pendingManualCompletion {
                    self?.registerRegionMonitoringCallbacks()
                } else if workOrder.status == "canceled" {
                    LocationService.shared.unregisterRegionMonitor(workOrder.regionIdentifier)
                }
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

        KTNotificationCenter.addObserver(forName: .NewMessageReceivedNotification) { [weak self] notification in
            DispatchQueue.main.async { [weak self] in
                self?.setupRightBarButtonItem()
            }
        }

        setupMenuBarButtonItem()
        setupRightBarButtonItem()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        hideHeaderView()
    }

    private func setupRightBarButtonItem() {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
            if ["en_route", "arriving", "in_progress"].contains(workOrder.status) {
                setupMessagesBarButtonItem()
            } else {
                setupAvailabilityBarButtonItem()
            }
        } else {
            setupAvailabilityBarButtonItem()
        }
    }

    private func setupMenuBarButtonItem() {
        let menuIconImage = FAKFontAwesome.naviconIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
        navigationItem.leftBarButtonItem = NavigationBarButton.barButtonItemWithImage(menuIconImage, target: self, action: #selector(menuButtonTapped))
    }

    private func setupMessagesBarButtonItem() {
        let messageIconImage = FAKFontAwesome.envelopeOIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0))!
        navigationItem.rightBarButtonItem = NavigationBarButton.barButtonItemWithImage(messageIconImage,
                                                                                       target: self,
                                                                                       action: #selector(messageButtonTapped),
                                                                                       badge: UIApplication.shared.applicationIconBadgeNumber)
    }

    @objc private func menuButtonTapped(_ sender: UIBarButtonItem) {
        KTNotificationCenter.post(name: .MenuContainerShouldOpen)
    }

    @objc private func messageButtonTapped(_ sender: UIBarButtonItem) {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
            let messagesNavCon = UIStoryboard("Messages").instantiateInitialViewController() as? UINavigationController
            if let messagesVC = messagesNavCon?.viewControllers.first as? MessagesViewController {
                if let user = workOrder.user {
                    messagesVC.recipient = user
                }
                let dismissItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissMessagesButtonTapped(_:)))
                dismissItem.tintColor = .white
                messagesVC.navigationItem.leftBarButtonItem = dismissItem
            }
            messagesNavCon?.modalPresentationStyle = .overCurrentContext
            present(messagesNavCon!, animated: true) {
                DispatchQueue.main.async { [weak self] in
                    self?.setupMessagesBarButtonItem()
                }
            }
        }
    }

    @objc private func dismissMessagesButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
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
            return workOrder.status == "in_progress"
        }
        return false
    }

    private var pendingManualCompletion: Bool {
        if let wo = WorkOrderService.shared.inProgressWorkOrder {
            return wo.status == "in_progress" && managedViewControllers.contains { $0 is WorkOrderDestinationConfirmationViewController }
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

                        self?.setupRightBarButtonItem()

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
                self?.zeroStateViewController.render(self!.view)
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
        } else if canAttemptSegueToArrivingWorkOrder {
            segueToWorkOrderDestinationConfirmationViewController(self)
            setupMessagesBarButtonItem()
        } else if canAttemptSegueToInProgressWorkOrder {
            let workOrder = WorkOrderService.shared.inProgressWorkOrder
            if workOrder?.user != nil {
                performSegue(withIdentifier: "DirectionsViewControllerSegue", sender: self)
            }
        } else if canAttemptSegueToNextWorkOrder {
            performSegue(withIdentifier: "WorkOrderAnnotationViewControllerSegue", sender: self)
            availabilityBarButtonItemEnabled = false
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
            setupRightBarButtonItem()
        }

        availabilityBarButtonItem?.isEnabled = availabilityBarButtonItemEnabled
    }

    private func refreshAnnotations() {
        DispatchQueue.main.async {
            self.removeMapAnnotationsForWorkOrderViewController(self)

            if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
                self.mapView.addAnnotation(workOrder.annotation)
            }
        }
    }

    private func registerRegionMonitoringCallbacks() {
        WorkOrderService.shared.setInProgressWorkOrderRegionMonitoringCallbacks({ [weak self] in
            logmoji("⭕️", "Entered monitored work order region")
            if let wo = WorkOrderService.shared.inProgressWorkOrder {
                if wo.canArrive {
                    wo.arrive(onSuccess: { [weak self] statusCode, responseString in
                        logmoji("⭕️", "Work order marked as arriving")
                        LocationService.shared.unregisterRegionMonitor(wo.regionIdentifier)
                        DirectionService.shared.resetLastDirectionsApiRequestCoordinateAndTimestamp()
                        dispatch_after_delay(2.5) {
                            self?.nextWorkOrderContextShouldBeRewound()
                            self?.attemptSegueToValidWorkOrderContext()
                        }
                    }, onError: { error, statusCode, responseString in
                        logWarn("⭕️ Failed to set work order status to in_progress upon arrival (\(statusCode)) ⭕️")
                        LocationService.shared.unregisterRegionMonitor(wo.regionIdentifier)
                    })
                } else if wo.status == "in_progress" {
                    LocationService.shared.unregisterRegionMonitor(wo.regionIdentifier)
                    DispatchQueue.main.async { [weak self] in
                        if let strongSelf = self {
                            strongSelf.nextWorkOrderContextShouldBeRewound()
                            strongSelf.segueToWorkOrderDestinationConfirmationViewController(strongSelf)
                        }
                    }
                }
            }
        }, onDidExitRegion: {
            logInfo("Exited monitored work order region")
        })
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if managedViewControllerSegues.contains(segue.identifier!) {
            managedViewControllers.append(segue.destination)
            zeroStateViewController.dismiss()
        }

        switch segue.identifier! {
        case "DirectionsViewControllerSegue":
            setupMessagesBarButtonItem()
            refreshAnnotations()
            registerRegionMonitoringCallbacks()

            CheckinService.shared.enableNavigationAccuracy()
            LocationService.shared.enableNavigationAccuracy()

            (segue.destination as! DirectionsViewController).configure(targetView: view, mapView: mapView, delegate: self)
        case "WorkOrderAnnotationViewControllerSegue":
            (segue.destination as! WorkOrderAnnotationViewController).configure(delegate: self, mapView: mapView, onConfirmationRequired: {
                segue.destination.performSegue(withIdentifier: "WorkOrderAnnotationViewTouchedUpInsideSegue", sender: self)
            })
        case "WorkOrderDestinationConfirmationViewControllerSegue":
            let destinationConfirmationViewController = segue.destination as! WorkOrderDestinationConfirmationViewController
            destinationConfirmationViewController.configure(delegate: self, targetView: view, sourceNavigationItem: navigationItem, onConfirm: {
                var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate?
                if let delegate = destinationConfirmationViewController.workOrdersViewControllerDelegate {
                    workOrdersViewControllerDelegate = delegate
                    for vc in delegate.managedViewControllersForViewController!(destinationConfirmationViewController) where vc != destinationConfirmationViewController {
                        delegate.nextWorkOrderContextShouldBeRewoundForViewController?(vc)
                    }
                }

                destinationConfirmationViewController.showProgressIndicator()
                workOrdersViewControllerDelegate?.confirmationReceivedForWorkOrderViewController?(destinationConfirmationViewController)
            })
        case "WorkOrderHistoryViewControllerSegue":
            let workOrderHistoryViewController = segue.destination as! WorkOrderHistoryViewController
            workOrderHistoryViewController.delegate = self
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
            return MenuItem(label: "History", action: "segueToWorkOrderHistory")
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

    @objc func segueToWorkOrderHistory() {
        KTNotificationCenter.post(name: .MenuContainerShouldReset)
        KTNotificationCenter.post(name: Notification.Name(rawValue: "SegueToWorkOrderHistoryStoryboard"), object: nil)
    }

    // MARK: WorkOrdersViewControllerDelegate

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

    func managedViewControllersForViewController(_ viewController: UIViewController!) -> [UIViewController] {
        return managedViewControllers
    }

    func mapViewUserTrackingMode(_ mapView: MKMapView) -> MKUserTrackingMode {
        if viewingDirections {
            return .followWithHeading
        }
        return .none
    }

    private func popManagedNavigationController() -> UINavigationController? {
        if managedViewControllers.last as? UINavigationController != nil {
            return managedViewControllers.removeLast() as? UINavigationController
        }
        return nil
    }

    private func navigationControllerContains(_ clazz: AnyClass) -> Bool {
        for viewController in navigationController?.viewControllers ?? [] {
            if viewController.isKind(of: clazz) {
                return true
            }
        }
        return false
    }

    func nextWorkOrderContextShouldBeRewound() {
        if presentedViewController != nil {
            dismiss(animated: true)
        }

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
                removeMapAnnotationsForWorkOrderViewController(viewController as! WorkOrderAnnotationViewController)
            } else {
                unwindManagedViewController(viewController)
            }

            managedViewControllers.remove(at: i)
        }
    }

    private func unwindManagedViewController(_ viewController: UIViewController) {
        let segueIdentifier = ("\(NSStringFromClass(type(of: viewController)))UnwindSegue" as String).components(separatedBy: ".").last!
        let managedSegues = [
            "DirectionsViewControllerUnwindSegue",
            "WorkOrderAnnotationViewControllerUnwindSegue",
            "WorkOrderDestinationConfirmationViewControllerUnwindSegue",
        ]

        if managedSegues.contains(segueIdentifier) {
            viewController.performSegue(withIdentifier: segueIdentifier, sender: self)
        }

        hideHeaderView()
    }

    private func showHeaderView() {
        let workOrder = WorkOrderService.shared.nextWorkOrder ?? WorkOrderService.shared.inProgressWorkOrder
        workOrder?.reload(onSuccess: { [weak self] statusCode, _ in
            let headerViewController = self?.childViewControllers.first as? WorkOrderDestinationHeaderViewController
            headerViewController?.configure(workOrder: workOrder)

            self?.view.layoutIfNeeded()
            self?.headerViewControllerTopConstraint.constant = 0
            UIView.animate(withDuration: 0.15) {
                self?.view.layoutIfNeeded()
                self?.headerView?.alpha = 1
            }
        }, onError: { err, statusCode, responseString in
            logWarn("Failed to reload work order")
        })
    }

    private func hideHeaderView() {
        view.layoutIfNeeded()
        headerViewControllerTopConstraint.constant = -(topLayoutGuide.length + (headerView?.height ?? 0))
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
            self.headerView?.alpha = 0
        }
    }

    func segueToWorkOrderDestinationConfirmationViewController(_ viewController: UIViewController) {
        var wo = WorkOrderService.shared.nextWorkOrder
        if wo == nil {
            wo = WorkOrderService.shared.inProgressWorkOrder
        }
        if let status = wo?.status, status == "in_progress" {
            DispatchQueue.main.async { [weak self] in
                self?.showHeaderView()
            }
        }

        performSegue(withIdentifier: "WorkOrderDestinationConfirmationViewControllerSegue", sender: self)
    }

    func confirmationCanceledForWorkOrderViewController(_ viewController: UIViewController) {
        if WorkOrderService.shared.nextWorkOrder != nil {
            nextWorkOrderContextShouldBeRewound()
            attemptSegueToValidWorkOrderContext()
        } else if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
            workOrder.status = "canceled"
            workOrder.save(onSuccess: { [weak self] statusCode, workOrder in
                logInfo("Work order canceled by provider")
                self?.nextWorkOrderContextShouldBeRewound()
                self?.attemptSegueToValidWorkOrderContext()
            }, onError: { err, status, responseString in
                logWarn("Provider attempt to cancel work order failed")
            })
        }
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
                switch workOrder.status {
                case "arriving":
                    workOrder.start(onSuccess: { [weak self] statusCode, responseString in
                        logInfo("Work order started")
                        LocationService.shared.unregisterRegionMonitor(workOrder.regionIdentifier)
                        self?.nextWorkOrderContextShouldBeRewound()
                        self?.performSegue(withIdentifier: "DirectionsViewControllerSegue", sender: self!)
                    }, onError: { error, statusCode, responseString in
                        logWarn("Failed to start work order (\(statusCode))")
                    })
                case "in_progress":
                    workOrder.complete(onSuccess: { [weak self] statusCode, responseString in
                        logmoji("⭕️", "Completed work order")
                        LocationService.shared.unregisterRegionMonitor(workOrder.regionIdentifier)
                        self?.nextWorkOrderContextShouldBeRewound()
                        self?.attemptSegueToValidWorkOrderContext()
                    }, onError: { error, statusCode, responseString in
                        logWarn("⭕️ Failed to set work order status to completed upon arrival (\(statusCode)) ⭕️")
                        LocationService.shared.unregisterRegionMonitor(workOrder.regionIdentifier)
                    })
                default:
                    logWarn("Failed to handle work order confirmation received due to unexpected work order status: \(workOrder.status)")
                }
            }
        }
    }

    func removeMapAnnotationsForWorkOrderViewController(_ viewController: UIViewController) {
        mapView.removeAnnotations()
        mapView.removeOverlays()
    }

    func navigationControllerNavBarButtonItemsShouldBeResetForViewController(_ viewController: UIViewController) {
        setupMenuBarButtonItem()
        setupRightBarButtonItem()
    }

    // MARK: DirectionsViewControllerDelegate

    func isPresentingDirections() -> Bool {
        return viewingDirections
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

    // MARK: WorkOrderHistoryViewControllerDelegate

    func paramsForWorkOrderHistoryViewController(viewController: WorkOrderHistoryViewController) -> [String: Any] {
        return  [
            "status": "completed",
            "sort_started_at_desc": "true",
            "provider_id": currentProvider.id,
        ]
    }
}
