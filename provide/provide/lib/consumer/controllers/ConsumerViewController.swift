//
//  ConsumerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/12/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ConsumerViewController: ViewController, MenuViewControllerDelegate, WorkOrderHistoryViewControllerDelegate {

    @IBOutlet private weak var mapView: ConsumerMapView!
    @IBOutlet private weak var destinationInputViewControllerTopConstraint: NSLayoutConstraint!
    @IBOutlet private var confirmWorkOrderViewControllerBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var providerEnRouteViewControllerBottomConstaint: NSLayoutConstraint!
    private var providerEnRouteTransitioningDelegate = CustomHeightModalTransitioningDelegate(height: 500) // swiftlint:disable:this weak_delegate (needs to be strong)

    private var destinationInputViewController: DestinationInputViewController!
    var destinationResultsViewController: DestinationResultsViewController!
    private var confirmWorkOrderViewController: ConfirmWorkOrderViewController!
    private var providerEnRouteViewController: ProviderEnRouteViewController!

    private var zeroStateViewController = UIStoryboard("ZeroState").instantiateInitialViewController() as! ZeroStateViewController

    private var updatingWorkOrderContext = false
    private var categories = [Category]() {
        didSet {
            confirmWorkOrderViewController?.configure(workOrder: confirmWorkOrderViewController?.workOrder, categories: categories) { _ in
                self.setupCancelWorkOrderBarButtonItem()
            }
        }
    }
    private var providers = [Provider]() {
        didSet {
            mapView.removeAnnotations()
            for provider in providers {
                updateProviderLocation(provider)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        destinationInputViewController.view.alpha = 0
        mapView.onMapRevealed = {
            self.destinationInputViewController.view.alpha = 1

            monkey("👨‍💼 Tap: SearchBar", after: 1.5) {
                _ = self.destinationInputViewController.textFieldShouldBeginEditing(UITextField())
            }
        }

        destinationInputViewControllerTopConstraint.constant = -destinationInputViewController.view.height
        confirmWorkOrderViewControllerBottomConstraint.constant = -confirmWorkOrderViewController.view.height
        providerEnRouteViewControllerBottomConstaint.constant = -providerEnRouteViewController.view.height

        destinationInputViewController.destinationTextField.addTarget(self, action: #selector(destinationTextFieldEditingDidBegin), for: .editingDidBegin)
        navigationItem.hidesBackButton = true

        setupMenuBarButtonItem()

        loadWorkOrderContext()

        LocationService.shared.resolveCurrentLocation { [weak self] (_) in
            logmoji("📍", "Current location resolved for consumer view controller... refreshing context")
            self?.loadCategoriesContext()
        }

        KTNotificationCenter.addObserver(forName: Notification.Name(rawValue: "SegueToWorkOrderHistoryStoryboard")) { [weak self] sender in
            if let strongSelf = self {
                if !strongSelf.navigationControllerContains(WorkOrderHistoryViewController.self) {
                    strongSelf.performSegue(withIdentifier: "WorkOrderHistoryViewControllerSegue", sender: strongSelf)
                }
            }
        }

        KTNotificationCenter.addObserver(forName: .CategorySelectionChanged, using: filterProvidersByCategoryFromNotification)

        KTNotificationCenter.addObserver(forName: .NewMessageReceivedNotification) { [weak self] notification in
            DispatchQueue.main.async { [weak self] in
                self?.setupMessagesBarButtonItem()
            }
        }

        KTNotificationCenter.addObserver(forName: .ProviderBecameAvailable, using: updateProviderLocationFromNotification)
        KTNotificationCenter.addObserver(forName: .ProviderBecameUnavailable, using: updateProviderLocationFromNotification)
        KTNotificationCenter.addObserver(forName: .ProviderLocationChanged, using: updateProviderLocationFromNotification)

        KTNotificationCenter.addObserver(forName: .WorkOrderContextShouldRefresh) { [weak self] notification in
            guard let strongSelf = self else { return }
            if !strongSelf.updatingWorkOrderContext && WorkOrderService.shared.inProgressWorkOrder == nil {
                strongSelf.loadWorkOrderContext(workOrder: notification.object as? WorkOrder)
            }
        }

        KTNotificationCenter.addObserver(forName: .WorkOrderOverviewShouldRender, queue: .main) { [weak self] notification in
            if let workOrder = notification.object as? WorkOrder {
                self?.mapView.renderOverviewPolylineForWorkOrder(workOrder)
            }
        }

        KTNotificationCenter.addObserver(forName: .WorkOrderStatusChanged, queue: .main) { [weak self] notification in
            if let workOrder = notification.object as? WorkOrder {
                if WorkOrderService.shared.inProgressWorkOrder?.id == workOrder.id {
                    self?.handleInProgressWorkOrderStateChange()
                } else if workOrder.status == "completed" {
                    NotificationService.shared.presentStatusBarNotificationWithTitle("You have arrived", style: .info)
                    self?.performTripCompletionViewControllerSegue(sender: workOrder)
                }
            }
        }
    }

    private func performTripCompletionViewControllerSegue(sender: WorkOrder) {
        DispatchQueue.main.async { [weak self] in
            if let vc = self?.presentedViewController {
                vc.dismiss(animated: true) {
                    self?.performSegue(withIdentifier: "TripCompletionViewControllerSegue", sender: sender)
                }
            } else {
                self?.performSegue(withIdentifier: "TripCompletionViewControllerSegue", sender: sender)
            }
        }
    }

    private func handleInProgressWorkOrderStateChange() {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder, workOrder.status == "en_route" {
            // ensure we weren't previously awaiting confirmation
            if confirmWorkOrderViewController?.workOrder != nil {
                confirmWorkOrderViewController?.prepareForReuse()
            }

            attemptSegueToValidWorkOrderContext()
        } else {
            if let status = WorkOrderService.shared.inProgressWorkOrder?.status {
                logmoji("📝", "status: \(status)")
            }
        }
    }

    private func navigationControllerContains(_ clazz: AnyClass) -> Bool {
        for viewController in navigationController?.viewControllers ?? [] {
            if viewController.isKind(of: clazz) {
                return true
            }
        }
        return false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "ProviderEnRouteViewControllerEmbedSegue":
            providerEnRouteViewController = segue.destination as? ProviderEnRouteViewController
        case "DestinationInputViewControllerEmbedSegue":
            destinationInputViewController = segue.destination as! DestinationInputViewController
        case "DestinationResultsViewControllerSegue":
            let extraSpace: CGFloat = 50 // visible map amount
            let destinationResultsViewControllerHeight = UIScreen.main.bounds.height - destinationInputViewController.view.height - extraSpace
            providerEnRouteTransitioningDelegate = CustomHeightModalTransitioningDelegate(height: destinationResultsViewControllerHeight)
            destinationResultsViewController = segue.destination as! DestinationResultsViewController
            destinationResultsViewController?.transitioningDelegate = providerEnRouteTransitioningDelegate
            destinationResultsViewController?.modalPresentationStyle = .custom
            destinationResultsViewController.configure(results: [], onResultSelected: onResultSelected)
        case "ConfirmWorkOrderViewControllerEmbedSegue":
            confirmWorkOrderViewController = segue.destination as! ConfirmWorkOrderViewController
            confirmWorkOrderViewController.configure(workOrder: nil, categories: categories) { _ in
                self.setupCancelWorkOrderBarButtonItem()
            }
        case "TripCompletionViewControllerSegue":
            let tripCompletionNVC = segue.destination as! UINavigationController
            let tripCompletionVC = tripCompletionNVC.topViewController as! TripCompletionViewController
            let workOrder = sender as! WorkOrder
            tripCompletionNVC.modalPresentationStyle = .overCurrentContext
            tripCompletionVC.configure(driver: workOrder.providers.last!) { tipAmount in
                logmoji("💰", "Tip amount is \(tipAmount). TODO: POST tip amount to server")
            }
        case "WorkOrderHistoryViewControllerSegue":
            let workOrderHistoryViewController = segue.destination as! WorkOrderHistoryViewController
            workOrderHistoryViewController.delegate = self
        default:
            break
        }
    }

    private func setupMenuBarButtonItem() {
        let menuIconImage = FAKFontAwesome.naviconIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
        navigationItem.leftBarButtonItem = NavigationBarButton.barButtonItemWithImage(menuIconImage, target: self, action: #selector(menuButtonTapped))
        navigationItem.rightBarButtonItem = nil
    }

    private func setupMessagesBarButtonItem() {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
            if ["en_route", "arriving", "in_progress"].contains(workOrder.status) {
                let messageIconImage = FAKFontAwesome.envelopeOIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0))!
                navigationItem.rightBarButtonItem = NavigationBarButton.barButtonItemWithImage(messageIconImage,
                                                                                               target: self,
                                                                                               action: #selector(messageButtonTapped),
                                                                                               badge: UIApplication.shared.applicationIconBadgeNumber)
            }
        }
    }

    private func setupCancelWorkOrderBarButtonItem() {
        let cancelBarButtonItem = UIBarButtonItem(title: "CANCEL", style: .plain, target: self, action: #selector(cancelButtonTapped))
        cancelBarButtonItem.setTitleTextAttributes(AppearenceProxy.clearBarButtonItemTitleTextAttributes(), for: .normal)
        navigationItem.leftBarButtonItem = cancelBarButtonItem
    }

    @objc private func menuButtonTapped(_ sender: UIBarButtonItem) {
        KTNotificationCenter.post(name: .MenuContainerShouldOpen)
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

    @objc private func cancelButtonTapped(_ sender: UIBarButtonItem) {
        LocationService.shared.background()

        logmoji("👱", "Tapped: CANCEL")

        if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
            workOrder.status = "canceled"  // HACK to allow immediate segue to empty work order context
            attemptSegueToValidWorkOrderContext()

            workOrder.updateWorkOrderWithStatus("canceled", onSuccess: { [weak self] statusCode, result in
                self?.attemptSegueToValidWorkOrderContext()
                self?.loadWorkOrderContext(workOrder: workOrder)
            }, onError: { [weak self] err, statusCode, response in
                logWarn("Failed to cancel work order; attempting to reload work order context")
                self?.loadWorkOrderContext(workOrder: workOrder)
            })
        }
    }

    private func presentServiceAvailabilityZeroState() {
        LocationService.shared.reverseGeocodeLocation(LocationService.shared.currentLocation) { [weak self] placemark in
            var msg = "No service available yet"
            if let locality = placemark.locality {
                msg = "\(msg) in \(locality)"
            }
            self?.zeroStateViewController.setMessage(msg)
            self?.zeroStateViewController.render(self!.view)
        }
    }

    private func loadCategoriesContext() {
        if let coordinate = LocationService.shared.currentLocation?.coordinate {
            CategoryService.shared.nearby(coordinate: coordinate, radius: 50.0, onSuccess: { [weak self] categories in
                logInfo("Found \(categories.count) categories: \(categories)")
                self?.categories = categories

                if categories.count == 0 {
                    self?.presentServiceAvailabilityZeroState()
                } else {
                    self?.zeroStateViewController.dismiss()
                    self?.loadProviderContext()
                }
            }, onError: { error, statusCode, response in
                logWarn("Failed to fetch categories near \(coordinate)")
            })
        } else {
            logWarn("No current location resolved for consumer view controller; nearby categories not fetched")
        }
    }

    private func loadProviderContext() {
        let providerService = ProviderService.shared
        if let coordinate = LocationService.shared.currentLocation?.coordinate {
            providerService.fetch(1, rpp: 100, available: true, active: true, nearbyCoordinate: coordinate) { [weak self] providers in
                logInfo("Found \(providers.count) provider(s): \(providers)")
                self?.providers = providers
                logWarn("Categories resolved but initial filtering by category not yet implemented")
            }
        } else {
            logWarn("No current location resolved for consumer view controller; nearby providers not fetched")
        }
    }

    private func loadWorkOrderContext(workOrder: WorkOrder? = nil) {
        let onWorkOrdersFetched: ([WorkOrder]) -> Void = { [weak self] workOrders in
            DispatchQueue.main.async {
                WorkOrderService.shared.setWorkOrders(workOrders) // FIXME -- decide if this should live in the service instead
                self?.attemptSegueToValidWorkOrderContext()
                self?.updatingWorkOrderContext = false
            }
        }

        if let workOrder = workOrder {
            if workOrder.status == "canceled" {
                onWorkOrdersFetched([])
            } else {
                onWorkOrdersFetched([workOrder])
            }
        } else {
            updatingWorkOrderContext = true
            WorkOrderService.shared.fetch(status: "awaiting_schedule,pending_acceptance,en_route,arriving,in_progress") { workOrders in
                onWorkOrdersFetched(workOrders)
            }
        }
    }

    private func attemptSegueToValidWorkOrderContext() {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
            if ["en_route", "arriving", "in_progress"].contains(workOrder.status) {
                setupCancelWorkOrderBarButtonItem()
                setupMessagesBarButtonItem()
                let workOrder = WorkOrderService.shared.inProgressWorkOrder!
                providerEnRouteViewController?.configure(workOrder: workOrder)
                animateProviderEnRouteViewController(toHidden: false)
            } else if ["awaiting_schedule", "pending_acceptance"].contains(workOrder.status) {
                setupCancelWorkOrderBarButtonItem()
                confirmWorkOrderViewController.configure(workOrder: workOrder, categories: categories) { _ in
                    self.setupCancelWorkOrderBarButtonItem()
                }
            }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0

            setupMenuBarButtonItem()

            mapView?.removeOverlays()
            animateProviderEnRouteViewController(toHidden: true)
            providerEnRouteViewController?.prepareForReuse()
            confirmWorkOrderViewController?.prepareForReuse()
            destinationResultsViewController?.prepareForReuse()
            animateDestinationInputView(toState: .normal)

            DispatchQueue.main.async { [weak self] in
                self?.mapView?.centerOnUserLocation()
            }
        }
    }

    private func filterProvidersByCategoryFromNotification(_ notification: Notification) {
        if let categoryId = notification.object as? Int {
            if let category = categories.first(where: { $0.id == categoryId }) {
                filterProvidersByCategory(category)
            }
        } else if let category = notification.object as? Category {
            filterProvidersByCategory(category)
        } else {
            logWarn("Filter providers notification received without category")
        }
    }

    private func filterProvidersByCategory(_ category: Category) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }

            let invalidAnnotations = strongSelf.providers.filter({ $0.categoryId != category.id }).map({ $0.annotation })
            strongSelf.mapView.removeAnnotations(invalidAnnotations)

            let annotations = strongSelf.providers.filter({ $0.categoryId == category.id }).map({ $0.annotation })
            for annotation in annotations {
                if !strongSelf.mapView.annotations.contains(where: { ($0 as? Provider.Annotation)?.matches(annotation.provider) == true }) {
                    strongSelf.mapView.addAnnotation(annotation)
                }
            }

            logWarn("Filtered provider annotations by category id: \(category.id)")
        }
    }

    private func updateProviderLocationFromNotification(_ notification: Notification) {
        if let provider = notification.object as? Provider {
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
                    UIView.animate(withDuration: 0.25) { [weak self] in
                        providerAnnotation.coordinate = provider.coordinate

                        if let annotationView = self?.mapView.view(for: providerAnnotation) {
                            let rotationAngle: CGFloat = CGFloat(provider.lastCheckinHeading) / 180.0 * .pi
                            annotationView.transform = CGAffineTransform(rotationAngle: rotationAngle)
                        }
                    }

                    return true
                } else {
                    logmoji("🗑", "Removing unavailable provider annotation from consumer map view")
                    mapView.removeAnnotation(annotation)
                    return true
                }
            }
            return false
        }) {
            logmoji("🚗", "Added provider annotation: \(provider)")
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
            return MenuItem(label: "History", action: "segueToWorkOrderHistory")
        case 1:
            return MenuItem(label: "Payment Methods", action: "paymentMethods")
        case 2:
            return MenuItem(label: "Driver Mode", action: #selector(provide))
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
        KTNotificationCenter.post(name: .ApplicationShouldReloadTopViewController)
    }

    @objc func segueToWorkOrderHistory() {
        KTNotificationCenter.post(name: .MenuContainerShouldReset)
        KTNotificationCenter.post(name: Notification.Name(rawValue: "SegueToWorkOrderHistoryStoryboard"), object: nil)
    }

    // MARK: DestinationInputViewControllerDelegate

    func selectDestination(destination: Contact, startingFrom origin: Contact) {
        setupCancelWorkOrderBarButtonItem()
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

    func animateConfirmWorkOrderView(toHidden hidden: Bool) {
        view.layoutIfNeeded()
        confirmWorkOrderViewControllerBottomConstraint.constant = hidden ? -confirmWorkOrderViewController.view.height : 0
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    func animateProviderEnRouteViewController(toHidden hidden: Bool) {
        view.layoutIfNeeded()
        providerEnRouteViewControllerBottomConstaint.constant = hidden ? -providerEnRouteViewController.view.height : 0
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    func animateDestinationInputView(toState state: DestinationInputViewState) {
        if state == .active {
            performSegue(withIdentifier: "DestinationResultsViewControllerSegue", sender: self)
        } else {
            destinationResultsViewController?.dismiss(animated: true)
        }

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

    // MARK: - WorkOrderHistoryViewControllerDelegate

    func paramsForWorkOrderHistoryViewController(viewController: WorkOrderHistoryViewController) -> [String: Any] {
        return  [
            "status": "completed",
            "sort_started_at_desc": "true",
            "user_id": currentUser.id,
        ]
    }
}
