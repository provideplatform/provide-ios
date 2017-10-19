//
//  ConsumerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/12/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ConsumerViewController: ViewController, MenuViewControllerDelegate {

    @IBOutlet private weak var mapView: ConsumerMapView!
    @IBOutlet private weak var destinationInputViewControllerTopConstraint: NSLayoutConstraint!

    private var destinationInputViewController: DestinationInputViewController!
    private var destinationResultsViewController: DestinationResultsViewController!
    private var confirmWorkOrderViewController: ConfirmWorkOrderViewController!
    private var providerEnRouteViewController: ProviderEnRouteViewController!

    private var updatingWorkOrderContext = false

    override func viewDidLoad() {
        super.viewDidLoad()

        destinationInputViewController.view.alpha = 0
        mapView.onMapRevealed = {
            self.destinationInputViewController.view.alpha = 1
        }

        destinationInputViewControllerTopConstraint.constant = -destinationInputViewController.view.height
        destinationInputViewController.destinationTextField.addTarget(self, action: #selector(destinationTextFieldEditingDidBegin), for: .editingDidBegin)
        navigationItem.hidesBackButton = true

        setupMenuBarButtonItem()

        loadWorkOrderContext()

        LocationService.shared.resolveCurrentLocation { [weak self] (_) in
            logInfo("Current location resolved for consumer view controller... refreshing context")
            self?.loadProviderContext()
        }

        NotificationCenter.addObserver(forName: .WorkOrderContextShouldRefresh) { [weak self] _ in
            if let strongSelf = self {
                if !strongSelf.updatingWorkOrderContext && WorkOrderService.shared.inProgressWorkOrder == nil {
                    strongSelf.loadWorkOrderContext()
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
            if let destinationResultsViewController = destinationResultsViewController {
                destinationInputViewController.destinationResultsViewController = destinationResultsViewController
            }
        case "DestinationResultsViewControllerEmbedSegue":
            assert(segue.destination is DestinationResultsViewController)
            destinationResultsViewController = segue.destination as! DestinationResultsViewController
            destinationResultsViewController.configure(results: [], onResultSelected: onResultSelected)
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
        let menuBarButtonItem = NavigationBarButton.barButtonItemWithImage(menuIconImage, target: self, action: #selector(menuButtonTapped))
        navigationItem.leftBarButtonItem = menuBarButtonItem
        navigationItem.rightBarButtonItem = nil
    }

    private func setupMessagesBarButtonItem() {
        let messageIconImage = FAKFontAwesome.envelopeOIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0))!
        let messagesBarButtonItem = NavigationBarButton.barButtonItemWithImage(messageIconImage, target: self, action: #selector(messageButtonTapped))
        navigationItem.rightBarButtonItem = messagesBarButtonItem
    }

    private func setupCancelWorkOrderBarButtonItem() {
        let cancelBarButtonItem = UIBarButtonItem(title: "CANCEL", style: .plain, target: self, action: #selector(cancelButtonTapped))
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

    private func loadProviderContext() {
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

    private func loadWorkOrderContext() {
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
            if ["en_route", "arriving", "in_progress"].contains(workOrder.status) {
                setupCancelWorkOrderBarButtonItem()
                setupMessagesBarButtonItem()
                presentProviderEnRouteViewController()
                providerEnRouteViewController?.configure(workOrder: workOrder)
            } else if ["awaiting_schedule", "pending_acceptance"].contains(workOrder.status) {
                setupCancelWorkOrderBarButtonItem()
                presentConfirmWorkOrderViewController()
                confirmWorkOrderViewController.configure(workOrder: workOrder) { _ in
                    self.setupCancelWorkOrderBarButtonItem()
                }
            }
        } else {
            setupMenuBarButtonItem()

            providerEnRouteViewController?.prepareForReuse()
            confirmWorkOrderViewController?.prepareForReuse()
            destinationResultsViewController?.prepareForReuse()

            presentDestinationInputViewController()

            animateDestinationInputView(toState: .normal)
        }
    }

    private func presentDestinationInputViewController() {

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

    private func updateProviderLocationFromNotification(_ notification: Notification?) {
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
            return nil
        }
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

    // MARK: DestinationInputViewControllerDelegate

    func selectDestination(destination: Contact, startingFrom origin: Contact) {
        setupCancelWorkOrderBarButtonItem()
        presentConfirmWorkOrderViewController()

        confirmWorkOrderViewController.confirmWorkOrderWithOrigin(origin, destination: destination)
    }

    func onResultSelected(result: Contact?) {
        destinationInputViewController.collapseAndHide()

        guard let result = result else {
            animateDestinationInputView(toState: .normal)
            return
        }

        animateDestinationInputView(toState: .hidden)

        // TODO: switch on result contact type when additional sections are added to DestinationResultsViewController

        LocationService.shared.resolveCurrentLocation { currentLocation in
            let origin = Contact()
            origin.latitude = currentLocation.coordinate.latitude
            origin.longitude = currentLocation.coordinate.longitude
            if let placemark = self.destinationInputViewController?.placemark {
                origin.merge(placemark: placemark)
                self.destinationInputViewController?.placemark = nil
            }
            self.selectDestination(destination: result, startingFrom: origin)
        }
    }

    // MARK: - DestinationInputViewController

    @objc func destinationTextFieldEditingDidBegin(_ sender: UITextField) {
        animateDestinationInputView(toState: .active)
    }

    func animateDestinationInputView(toState state: DestinationInputViewState) {
        view.layoutIfNeeded()
        destinationInputViewControllerTopConstraint.constant = state.config.topConstraint
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
            self.destinationInputViewController.view.backgroundColor = state.config.backgroundColor
            self.destinationInputViewController.destinationTextFieldTopConstraint.constant = state.config.textFieldTopConstraintConstant
        }
    }

    enum DestinationInputViewState {
        case hidden
        case active
        case normal

        var config: (backgroundColor: UIColor, textFieldTopConstraintConstant: CGFloat, topConstraint: CGFloat) {
            switch self {
            case .hidden: return (.clear, 22, -100)
            case .active: return (.white, 42, 0)
            case .normal: return (.clear, 22, 80)
            }
        }
    }
}
