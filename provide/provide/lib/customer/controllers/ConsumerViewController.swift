//
//  ConsumerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/12/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ConsumerViewController: ViewController, MenuViewControllerDelegate, DestinationInputViewControllerDelegate {

    @IBOutlet private weak var mapView: ConsumerMapView!

    private var destinationInputViewController: DestinationInputViewController!
    private var destinationResultsViewController: DestinationResultsViewController!
    private var confirmWorkOrderViewController: ConfirmWorkOrderViewController!
    private var providerEnRouteViewController: ProviderEnRouteViewController!

    private var updatingWorkOrderContext = false

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
        return WorkOrderService.shared.inProgressWorkOrder?.status == "in_progress"
    }

    private var canAttemptSegueToAwaitingScheduleWorkOrder: Bool {
        return WorkOrderService.shared.inProgressWorkOrder?.status == "awaiting_schedule"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true

        setupMenuBarButtonItem()

        loadWorkOrderContext()

        LocationService.shared.resolveCurrentLocation { [weak self] (_) in
            logInfo("Current location resolved for consumer view controller... refreshing context")
            self?.loadProviderContext()
        }

        NotificationCenter.default.addObserverForName("WorkOrderContextShouldRefresh") { [weak self] _ in
            if let weakSelf = self {
                if !weakSelf.updatingWorkOrderContext && WorkOrderService.shared.inProgressWorkOrder == nil {
                    weakSelf.loadWorkOrderContext()
                }
            }
        }

        NotificationCenter.default.addObserverForName("ProviderContextShouldRefresh") { [weak self] _ in
            self?.loadProviderContext()
        }

        NotificationCenter.default.addObserverForName("ProviderBecameAvailable", usingBlock: updateProviderLocationFromNotification)
        NotificationCenter.default.addObserverForName("ProviderBecameUnavailable", usingBlock: updateProviderLocationFromNotification)
        NotificationCenter.default.addObserverForName("ProviderLocationChanged", usingBlock: updateProviderLocationFromNotification)

        NotificationCenter.default.addObserverForName("WorkOrderChanged") { [weak self] notification in
            if let workOrder = notification.object as? WorkOrder {
                DispatchQueue.main.async {
                    if WorkOrderService.shared.inProgressWorkOrder?.id == workOrder.id {
                        self?.handleInProgressWorkOrderStateChange()
                    }
                }
            }
        }
    }

    private func handleInProgressWorkOrderStateChange() {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder, workOrder.status == "en_route" {
            // ensure we weren't previously awaiting confirmation
            if confirmWorkOrderViewController?.inProgressWorkOrder != nil {
                confirmWorkOrderViewController?.prepareForReuse()
            }

            attemptSegueToValidWorkOrderContext()
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

    private func refreshContext() {
        loadWorkOrderContext()
        loadProviderContext()
    }

    private func setupMenuBarButtonItem() {
        let menuIconImage = FAKFontAwesome.naviconIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
        let menuBarButtonItem = NavigationBarButton.barButtonItemWithImage(menuIconImage, target: self, action: "menuButtonTapped:")
        navigationItem.leftBarButtonItem = menuBarButtonItem
        navigationItem.rightBarButtonItem = nil
    }

    private func setupMessagesBarButtonItem() {
        let messageIconImage = FAKFontAwesome.envelopeOIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0))!
        let messagesBarButtonItem = NavigationBarButton.barButtonItemWithImage(messageIconImage, target: self, action: "messageButtonTapped:")
        navigationItem.rightBarButtonItem = messagesBarButtonItem
    }

    private func setupCancelWorkOrderBarButtonItem() {
        let cancelBarButtonItem = UIBarButtonItem(title: "CANCEL", style: .plain, target: self, action: #selector(cancelButtonTapped(_:)))
        navigationItem.leftBarButtonItem = cancelBarButtonItem
    }

    @objc private func menuButtonTapped(_ sender: UIBarButtonItem) {
        NotificationCenter.default.postNotificationName("MenuContainerShouldOpen")
    }

    @objc private func messageButtonTapped(_ sender: UIBarButtonItem) {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
            let messagesNavCon = UIStoryboard("Messages").instantiateInitialViewController() as? UINavigationController
            if let messagesVC = messagesNavCon?.viewControllers.first as? MessagesViewController {
                if let provider = workOrder.provider {
                    let user = User()
                    user.id = provider.userId
                    user.name = provider.name
                    user.profileImageUrlString = provider.profileImageUrlString

                    messagesVC.recipient = user
                }
                let dismissItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissMessagesButtonTapped(_:)))
                dismissItem.tintColor = .white
                messagesVC.navigationItem.leftBarButtonItem = dismissItem
            }
            messagesNavCon?.modalPresentationStyle = .overCurrentContext
            present(messagesNavCon!, animated: true)
        }
    }

    @objc private func dismissMessagesButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    @objc private func cancelButtonTapped(_ sender: UIBarButtonItem) {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
            workOrder.status = "canceled"  // HACK to allow immediate segue to empty work order context
            attemptSegueToValidWorkOrderContext()

            workOrder.updateWorkOrderWithStatus("canceled", onSuccess: { [weak self] statusCode, result in
                self?.attemptSegueToValidWorkOrderContext()
                self?.loadWorkOrderContext()
            }, onError: { [weak self] err, statusCode, response in
                logWarn("Failed to cancel work order; attempting to reload work order context")
                self?.loadWorkOrderContext()
            })
        }
    }

    func loadProviderContext() {
        let providerService = ProviderService.shared
        if let coordinate = LocationService.shared.currentLocation?.coordinate {
            providerService.fetch(1, rpp: 100, available: true, active: true, nearbyCoordinate: coordinate) { [weak self] providers in
                logInfo("Found \(providers.count) provider(s): \(providers)")
                for provider in providers {
                    self?.updateProviderLocation(provider)
                }
            }
        } else {
            logWarn("No current location resolved for consumer view controller; nearby providers not fetched")
        }
    }

    func loadWorkOrderContext() {
        let workOrderService = WorkOrderService.shared

        updatingWorkOrderContext = true
        workOrderService.fetch(status: "awaiting_schedule,pending_acceptance,en_route,arriving,in_progress") { [weak self] workOrders in
            workOrderService.setWorkOrders(workOrders) // FIXME -- decide if this should live in the service instead
            self?.attemptSegueToValidWorkOrderContext()
            self?.updatingWorkOrderContext = false
        }
    }

    private func attemptSegueToValidWorkOrderContext() {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
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
            UIView.animate(withDuration: 0.25) {
                if let destinationInputView = self.destinationInputViewController.view, destinationInputView.frame.origin.y == 0 {
                    destinationInputView.frame.origin.y += self.view.height * 0.1
                    if let destinationInputTextField = destinationInputView.subviews.first as? UITextField {
                        destinationInputTextField.frame.origin.y = destinationInputTextField.frame.origin.y
                    }
                }
            }
        }
    }

    private func presentDestinationInputViewController() {
        if let destinationInputView = destinationInputViewController.view {
            destinationInputView.isHidden = true
            destinationInputView.removeFromSuperview()
            mapView.addSubview(destinationInputView)

            destinationInputView.frame.size.width = mapView.width
            destinationInputView.isHidden = false
            if let destinationInputTextField = destinationInputView.subviews.first as? UITextField {
                destinationInputTextField.frame.size.width = destinationInputView.width - (destinationInputTextField.frame.origin.x * 2.0)
            }
        }

        if let destinationResultsView = destinationResultsViewController.view {
            destinationResultsView.isHidden = true
            destinationResultsView.removeFromSuperview()
            mapView.addSubview(destinationResultsView)

            destinationResultsView.frame.origin.y = mapView.height
            destinationResultsView.frame.size.width = mapView.width
            if let destinationResultsTableView = destinationResultsView.subviews.first as? UITableView {
                destinationResultsTableView.frame.size.width = destinationResultsView.width
            }

            destinationResultsView.isHidden = false
        }
    }

    private func presentConfirmWorkOrderViewController() {
        if let confirmWorkOrderView = confirmWorkOrderViewController.view {
            confirmWorkOrderView.isHidden = true
            confirmWorkOrderView.removeFromSuperview()
            mapView.addSubview(confirmWorkOrderView)

            confirmWorkOrderView.frame.size.width = mapView.width
            confirmWorkOrderView.frame.origin.y = mapView.height
            confirmWorkOrderView.isHidden = false
        }
    }

    private func presentProviderEnRouteViewController() {
        if let providerEnRouteView = providerEnRouteViewController.view {
            providerEnRouteView.isHidden = true
            providerEnRouteView.removeFromSuperview()
            mapView.addSubview(providerEnRouteView)

            providerEnRouteView.frame.size.width = mapView.width
            providerEnRouteView.frame.origin.y = mapView.height
            providerEnRouteView.isHidden = false
        }
    }

    func updateProviderLocationFromNotification(_ notification: Notification?) {
        if let provider = notification?.object as? Provider {
            DispatchQueue.main.async {
                self.updateProviderLocation(provider)
            }
        }
    }

    private func updateProviderLocation(_ provider: Provider) {
        if provider.userId == currentUser.id {
            return  // HACK!!! API should not return this
        }

        if !mapView.annotations.contains(where: { annotation -> Bool in
            if let providerAnnotation = annotation as? Provider.Annotation, providerAnnotation.matches(provider) {
                if ProviderService.shared.containsProvider(provider) {
                    logWarn("Animated provider annotation movement not yet implemented")
                    mapView.removeAnnotation(annotation)
                    mapView.addAnnotation(provider.annotation)
                    return true
                } else {
                    logInfo("Removing unavailable provider annotation from consumer map view")
                    mapView.removeAnnotation(annotation)
                    return true
                }
            }
            return false
        }) {
            logInfo("Added provider annotation: \(provider)")
            mapView.addAnnotation(provider.annotation)
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
            return MenuItem(label: "Payment Methods", action: "paymentMethods")
        case 2:
            return MenuItem(label: "Driver Mode", action: "provide")
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

    @objc func provide() {
        KeyChainService.shared.mode = .provider
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
