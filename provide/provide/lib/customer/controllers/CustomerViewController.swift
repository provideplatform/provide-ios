//
//  CustomerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/12/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

class CustomerViewController: ViewController, MenuViewControllerDelegate, DestinationInputViewControllerDelegate {

    @IBOutlet fileprivate weak var mapView: CustomerMapView!

    fileprivate var destinationInputViewController: DestinationInputViewController!
    fileprivate var destinationResultsViewController: DestinationResultsViewController!
    fileprivate var confirmWorkOrderViewController: ConfirmWorkOrderViewController!
    fileprivate var providerEnRouteViewController: ProviderEnRouteViewController!

    fileprivate var updatingWorkOrderContext = false

    fileprivate var canAttemptSegueToEnRouteWorkOrder: Bool {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            return workOrder.status == "en_route"
        }
        return false
    }

    fileprivate var canAttemptSegueToPendingAcceptanceWorkOrder: Bool {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            return workOrder.status == "pending_acceptance"
        }
        return false
    }

    fileprivate var canAttemptSegueToArrivingWorkOrder: Bool {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            return workOrder.status == "arriving"
        }
        return false
    }

    fileprivate var canAttemptSegueToInProgressWorkOrder: Bool {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            return workOrder.status == "in_progress"
        }
        return false
    }

    fileprivate var canAttemptSegueToAwaitingScheduleWorkOrder: Bool {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            return workOrder.status == "awaiting_schedule"
        }
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true

        setupMenuBarButtonItem()

        loadWorkOrderContext()

        LocationService.sharedService().resolveCurrentLocation { [weak self] (_) in
            logInfo("Current location resolved for customer view controller... refreshing context")
            self?.loadProviderContext()
        }

        NotificationCenter.default.addObserverForName("WorkOrderContextShouldRefresh") { [weak self] _ in
            if !self!.updatingWorkOrderContext && WorkOrderService.sharedService().inProgressWorkOrder == nil {
                self!.loadWorkOrderContext()
            }
        }

        NotificationCenter.default.addObserverForName("ProviderContextShouldRefresh") { [weak self] _ in
            self?.loadProviderContext()
        }

        NotificationCenter.default.addObserverForName("ProviderBecameAvailable") { [weak self] notification in
            if let provider = notification?.object as? Provider {
                dispatch_after_delay(0.0) {
                    self?.updateProviderLocation(provider)
                }
            }
        }

        NotificationCenter.default.addObserverForName("ProviderBecameUnavailable") { [weak self] notification in
            if let provider = notification?.object as? Provider {
                dispatch_after_delay(0.0) {
                    self?.updateProviderLocation(provider)
                }
            }
        }

        NotificationCenter.default.addObserverForName("ProviderLocationChanged") { [weak self] notification in
            if let provider = notification?.object as? Provider {
                dispatch_after_delay(0.0) {
                    self?.updateProviderLocation(provider)
                }
            }
        }

        NotificationCenter.default.addObserverForName("WorkOrderChanged") { [weak self] notification in
            if let workOrder = notification.object as? WorkOrder {
                dispatch_after_delay(0.0) {
                    if WorkOrderService.sharedService().inProgressWorkOrder?.id == workOrder.id {
                        self?.handleInProgressWorkOrderStateChange()
                    }
                }

            }
        }
    }

    fileprivate func handleInProgressWorkOrderStateChange() {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            if workOrder.status == "en_route" {
                // ensure we weren't previously awaiting confirmation
                if confirmWorkOrderViewController?.inProgressWorkOrder != nil {
                    confirmWorkOrderViewController?.prepareForReuse()
                }

                attemptSegueToValidWorkOrderContext()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "DestinationInputViewControllerEmbedSegue":
            assert(segue.destination is DestinationInputViewController)
            destinationInputViewController = segue.destination as! DestinationInputViewController
            destinationInputViewController.delegate = self
            if let destinationResultsViewController = destinationResultsViewController {
                destinationInputViewController.destinationResultsViewController = destinationResultsViewController
            }
        case "DestinationResultsViewControllerEmbedSegue":
            assert(segue.destination is DestinationResultsViewController)
            destinationResultsViewController = segue.destination as! DestinationResultsViewController
            if let destinationInputViewController = destinationInputViewController {
                destinationInputViewController.destinationResultsViewController = destinationResultsViewController
            }
        case "ConfirmWorkOrderViewControllerEmbedSegue":
            assert(segue.destination is ConfirmWorkOrderViewController)
            confirmWorkOrderViewController = segue.destination as! ConfirmWorkOrderViewController
        case "ProviderEnRouteViewControllerEmbedSegue":
            assert(segue.destination is ProviderEnRouteViewController)
            providerEnRouteViewController = segue.destination as! ProviderEnRouteViewController
        default:
            break
        }
    }

    fileprivate func refreshContext() {
        loadWorkOrderContext()
        loadProviderContext()
    }

    fileprivate func setupMenuBarButtonItem() {
        let menuIconImage = FAKFontAwesome.naviconIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
        let menuBarButtonItem = NavigationBarButton.barButtonItemWithImage(menuIconImage, target: self, action: "menuButtonTapped:")
        navigationItem.leftBarButtonItem = menuBarButtonItem
        navigationItem.rightBarButtonItem = nil
    }

    fileprivate func setupMessagesBarButtonItem() {
        let messageIconImage = FAKFontAwesome.envelopeOIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0))!
        let messagesBarButtonItem = NavigationBarButton.barButtonItemWithImage(messageIconImage, target: self, action: "messageButtonTapped:")
        navigationItem.rightBarButtonItem = messagesBarButtonItem
    }

    fileprivate func setupCancelWorkOrderBarButtonItem() {
        let cancelBarButtonItem = UIBarButtonItem(title: "CANCEL", style: .plain, target: self, action: #selector(CustomerViewController.cancelButtonTapped(_:)))
        navigationItem.leftBarButtonItem = cancelBarButtonItem
    }

    @objc fileprivate func menuButtonTapped(_ sender: UIBarButtonItem) {
        NotificationCenter.default.postNotificationName("MenuContainerShouldOpen")
    }

    @objc fileprivate func messageButtonTapped(_ sender: UIBarButtonItem) {
        let messagesNavCon = UIStoryboard("Messages").instantiateInitialViewController() as? UINavigationController
        presentViewController(messagesNavCon!, animated: true)
    }

    @objc fileprivate func cancelButtonTapped(_ sender: UIBarButtonItem) {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            workOrder.status = "canceled"  // HACK to allow immediate segue to empty work order context
            attemptSegueToValidWorkOrderContext()

            workOrder.updateWorkOrderWithStatus("canceled",
                onSuccess: { [weak self] statusCode, result in
                    self?.attemptSegueToValidWorkOrderContext()
                    self?.loadWorkOrderContext()
                },
                onError: { [weak self] err, statusCode, response in
                    logWarn("Failed to cancel work order; attempting to reload work order context")
                    self?.loadWorkOrderContext()
                }
            )
        }
    }

    func loadProviderContext() {
        let providerService = ProviderService.sharedService()
        if let coordinate = LocationService.sharedService().currentLocation?.coordinate {
            providerService.fetch(
                1,
                rpp: 100,
                available: true,
                active: true,
                nearbyCoordinate: coordinate)
            { [weak self] (providers) in
                logInfo("Found \(providers.count) provider(s): \(providers)")
                for provider in providers {
                    self!.updateProviderLocation(provider)
                }
            }
        } else {
            logWarn("No current location resolved for customer view controller; nearby providers not fetched")
        }
    }

    func loadWorkOrderContext() {
        let workOrderService = WorkOrderService.sharedService()

        updatingWorkOrderContext = true
        workOrderService.fetch(
            status: "awaiting_schedule,pending_acceptance,en_route,arriving,in_progress",
            onWorkOrdersFetched: { [weak self] workOrders in
                workOrderService.setWorkOrders(workOrders) // FIXME -- decide if this should live in the service instead
                self!.attemptSegueToValidWorkOrderContext()
                self!.updatingWorkOrderContext = false
            }
        )
    }

    fileprivate func attemptSegueToValidWorkOrderContext() {
        if let workOrder = WorkOrderService.sharedService().inProgressWorkOrder {
            if canAttemptSegueToEnRouteWorkOrder || canAttemptSegueToArrivingWorkOrder || canAttemptSegueToInProgressWorkOrder {
                setupCancelWorkOrderBarButtonItem()
                setupMessagesBarButtonItem()
                presentProviderEnRouteViewController()
                providerEnRouteViewController?.setWorkOrder(workOrder)
            } else if canAttemptSegueToAwaitingScheduleWorkOrder || canAttemptSegueToPendingAcceptanceWorkOrder {
                setupCancelWorkOrderBarButtonItem()
                presentConfirmWorkOrderViewController()
                confirmWorkOrderViewController?.setWorkOrder(workOrder)
            }
        } else {
            setupMenuBarButtonItem()

            providerEnRouteViewController?.prepareForReuse()
            confirmWorkOrderViewController?.prepareForReuse()
            destinationResultsViewController?.prepareForReuse()

            presentDestinationInputViewController()
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                if let destinationInputView = self?.destinationInputViewController.view {
                    if destinationInputView.frame.origin.y == 0.0 {
                        destinationInputView.frame.origin.y += self!.view.frame.height * 0.1
                        if let destinationInputTextField = destinationInputView.subviews.first as? UITextField {
                            destinationInputTextField.frame.origin.y = destinationInputTextField.frame.origin.y
                        }
                    }
                }
            })
        }
    }

    fileprivate func presentDestinationInputViewController() {
        if let destinationInputView = destinationInputViewController.view {
            destinationInputView.isHidden = true
            destinationInputView.removeFromSuperview()
            mapView.addSubview(destinationInputView)

            destinationInputView.frame.size.width = mapView.frame.width
            destinationInputView.isHidden = false
            if let destinationInputTextField = destinationInputView.subviews.first as? UITextField {
                destinationInputTextField.frame.size.width = destinationInputView.frame.width - (destinationInputTextField.frame.origin.x * 2.0)
            }
        }
        
        if let destinationResultsView = destinationResultsViewController.view {
            destinationResultsView.isHidden = true
            destinationResultsView.removeFromSuperview()
            mapView.addSubview(destinationResultsView)
            
            destinationResultsView.frame.origin.y = mapView.frame.height
            destinationResultsView.frame.size.width = mapView.frame.width
            if let destinationResultsTableView = destinationResultsView.subviews.first as? UITableView {
                destinationResultsTableView.frame.size.width = destinationResultsView.frame.width
            }

            destinationResultsView.isHidden = false
        }
    }
    
    fileprivate func presentConfirmWorkOrderViewController() {
        if let confirmWorkOrderView = confirmWorkOrderViewController.view {
            confirmWorkOrderView.isHidden = true
            confirmWorkOrderView.removeFromSuperview()
            mapView.addSubview(confirmWorkOrderView)
            
            confirmWorkOrderView.frame.size.width = mapView.frame.width
            confirmWorkOrderView.frame.origin.y = mapView.frame.size.height
            confirmWorkOrderView.isHidden = false
        }
    }

    fileprivate func presentProviderEnRouteViewController() {
        if let providerEnRouteView = providerEnRouteViewController.view {
            providerEnRouteView.isHidden = true
            providerEnRouteView.removeFromSuperview()
            mapView.addSubview(providerEnRouteView)

            providerEnRouteView.frame.size.width = mapView.frame.width
            providerEnRouteView.frame.origin.y = mapView.frame.size.height
            providerEnRouteView.isHidden = false
        }
    }

    fileprivate func updateProviderLocation(_ provider: Provider) {
        if provider.userId == currentUser.id {
            return  // HACK!!! API should not return this
        }

        if !mapView.annotations.contains(where: { annotation -> Bool in
            if let providerAnnotation = annotation as? Provider.Annotation {
                if providerAnnotation.matches(provider) {
                    if ProviderService.sharedService().containsProvider(provider) {
                        logWarn("Animated provider annotation movement not yet implemented")
                        return true
                    } else {
                        logInfo("Removing unavailable provider annotation from customer map view")
                        mapView.removeAnnotation(annotation)
                        return true
                    }
                }
            }
            return false
        }) {
            logInfo("Added provider annotation: \(provider)")
            mapView.addAnnotation(provider.annotation)
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
            return MenuItem(item: ["label": "Payment Methods", "action": "paymentMethods"])
        case 2:
            return MenuItem(item: ["label": "Driver Mode", "action": "provide"])
        default:
            break
        }
        return nil
    }

    func numberOfSectionsInMenuViewController(_ menuViewController: MenuViewController) -> Int {
        return 1
    }

    func menuViewController(_ menuViewController: MenuViewController, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func provide() {
        KeyChainService.sharedService().mode = .Provider
        NotificationCenter.default.postNotificationName("ApplicationShouldReloadTopViewController")
    }

    // MARK: ConfirmWorkOrderViewControllerDelegate

    func confirmWorkOrderViewController(_ viewController: ConfirmWorkOrderViewController, didConfirmWorkOrder workOrder: WorkOrder) {
        setupCancelWorkOrderBarButtonItem()
    }

    // MARK: DestinationInputViewControllerDelegate

    func destinationInputViewController(_ viewController: DestinationInputViewController,
                                        didSelectDestination destination: Contact,
                                        startingFrom origin: Contact) {
        setupCancelWorkOrderBarButtonItem()
        presentConfirmWorkOrderViewController()

        confirmWorkOrderViewController.confirmWorkOrderWithOrigin(origin, destination: destination)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
