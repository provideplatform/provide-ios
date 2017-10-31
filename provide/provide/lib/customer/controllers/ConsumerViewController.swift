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
    @IBOutlet var confirmWorkOrderViewControllerBottomConstraint: NSLayoutConstraint!

    private var destinationInputViewController: DestinationInputViewController!
    private var destinationResultsViewController: DestinationResultsViewController!
    private var confirmWorkOrderViewController: ConfirmWorkOrderViewController!
    private var providerEnRouteViewController: ProviderEnRouteViewController?
    private let providerEnRouteTransitioningDelegate = CustomHeightModalTransitioningDelegate(height: 150) // swiftlint:disable:this weak_delegate (needs to be strong)

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

        destinationInputViewController.destinationTextField.addTarget(self, action: #selector(destinationTextFieldEditingDidBegin), for: .editingDidBegin)
        navigationItem.hidesBackButton = true

        setupMenuBarButtonItem()

        loadWorkOrderContext()

        LocationService.shared.resolveCurrentLocation { [weak self] (_) in
            logmoji("📍", "Current location resolved for consumer view controller... refreshing context")
            self?.loadCategoriesContext()
        }

        KTNotificationCenter.addObserver(forName: .WorkOrderContextShouldRefresh) { [weak self] notification in
            guard let strongSelf = self else { return }
            if !strongSelf.updatingWorkOrderContext && WorkOrderService.shared.inProgressWorkOrder == nil {
                strongSelf.loadWorkOrderContext(workOrder: notification.object as? WorkOrder)
            }
        }

        KTNotificationCenter.addObserver(forName: .ProviderBecameAvailable, using: updateProviderLocationFromNotification)
        KTNotificationCenter.addObserver(forName: .ProviderBecameUnavailable, using: updateProviderLocationFromNotification)
        KTNotificationCenter.addObserver(forName: .ProviderLocationChanged, using: updateProviderLocationFromNotification)

        KTNotificationCenter.addObserver(forName: .CategorySelectionChanged, using: filterProvidersByCategoryFromNotification)

        KTNotificationCenter.addObserver(forName: .WorkOrderStatusChanged, queue: .main) { [weak self] notification in
            if let workOrder = notification.object as? WorkOrder {
                if WorkOrderService.shared.inProgressWorkOrder?.id == workOrder.id {
                    self?.handleInProgressWorkOrderStateChange()
                }
            }
        }

        KTNotificationCenter.addObserver(forName: .WorkOrderChanged, queue: .main) { [weak self] notification in
            if let workOrder = notification.object as? WorkOrder, workOrder.status == "completed" {
                self?.performSegue(withIdentifier: "TripCompletionViewControllerSegue", sender: workOrder)
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "ProviderEnRouteViewControllerSegue":
            providerEnRouteViewController = segue.destination as? ProviderEnRouteViewController
            providerEnRouteViewController?.transitioningDelegate = providerEnRouteTransitioningDelegate
            providerEnRouteViewController?.modalPresentationStyle = .custom
            let workOrder = WorkOrderService.shared.inProgressWorkOrder!
            providerEnRouteViewController?.configure(workOrder: workOrder)
        case "DestinationInputViewControllerEmbedSegue":
            destinationInputViewController = segue.destination as! DestinationInputViewController
            if let destinationResultsViewController = destinationResultsViewController {
                destinationInputViewController.destinationResultsViewController = destinationResultsViewController
            }
        case "DestinationResultsViewControllerEmbedSegue":
            destinationResultsViewController = segue.destination as! DestinationResultsViewController
            destinationResultsViewController.configure(results: [], onResultSelected: onResultSelected)
            destinationInputViewController?.destinationResultsViewController = destinationResultsViewController
        case "ConfirmWorkOrderViewControllerEmbedSegue":
            confirmWorkOrderViewController = segue.destination as! ConfirmWorkOrderViewController
            confirmWorkOrderViewController.configure(workOrder: nil, categories: categories) { _ in
                self.setupCancelWorkOrderBarButtonItem()
            }
        case "TripCompletionViewControllerSegue":
            let tripCompletionVC = (segue.destination as! UINavigationController).topViewController as! TripCompletionViewController
            let workOrder = sender as! WorkOrder
            tripCompletionVC.configure(driver: workOrder.providers.last!) { tipAmount in
                logmoji("💰", "Tip amount is \(tipAmount). TODO: POST tip amount to server")
            }
        default:
            break
        }
    }

    private func refreshContext() {
        loadWorkOrderContext()
        loadCategoriesContext()
    }

    private func setupMenuBarButtonItem() {
        let menuIconImage = FAKFontAwesome.naviconIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
        navigationItem.leftBarButtonItem = NavigationBarButton.barButtonItemWithImage(menuIconImage, target: self, action: #selector(menuButtonTapped))
        navigationItem.rightBarButtonItem = nil
    }

    private func setupMessagesBarButtonItem() {
        let messageIconImage = FAKFontAwesome.envelopeOIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0))!
        navigationItem.rightBarButtonItem = NavigationBarButton.barButtonItemWithImage(messageIconImage, target: self, action: #selector(messageButtonTapped))
    }

    private func setupCancelWorkOrderBarButtonItem() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "CANCEL", style: .plain, target: self, action: #selector(cancelButtonTapped))
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
            present(messagesNavCon!, animated: true)
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
            Category.nearby(coordinate: coordinate, radius: 50.0, onSuccess: { [weak self] categories in
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
                performSegue(withIdentifier: "ProviderEnRouteViewControllerSegue", sender: self)
            } else if ["awaiting_schedule", "pending_acceptance"].contains(workOrder.status) {
                setupCancelWorkOrderBarButtonItem()
                confirmWorkOrderViewController.configure(workOrder: workOrder, categories: categories) { _ in
                    self.setupCancelWorkOrderBarButtonItem()
                }
            }
        } else {
            setupMenuBarButtonItem()

            providerEnRouteViewController?.dismiss(animated: true)
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
                    logWarn("Animated provider annotation movement not yet implemented")
                    mapView.removeAnnotation(annotation)
                    mapView.addAnnotation(provider.annotation)
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
            return MenuItem(label: "History", action: "history")
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
