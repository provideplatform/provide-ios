//
//  ConsumerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/12/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ConsumerViewController: ViewController, MenuViewControllerDelegate, WorkOrderHistoryViewControllerDelegate {

    @IBOutlet private weak var mapView: ConsumerMapView!
    @IBOutlet private weak var destinationInputViewControllerTopConstraint: NSLayoutConstraint!
//    @IBOutlet private var confirmWorkOrderViewControllerBottomConstraint: NSLayoutConstraint!
//    @IBOutlet private weak var providerEnRouteViewControllerBottomConstaint: NSLayoutConstraint!
    private var destinationResultsTransitioningDelegate = CustomHeightModalTransitioningDelegate(height: 500) // swiftlint:disable:this weak_delegate (needs to be strong)
    private var confirmWorkOrderTransitioningDelegate = CustomHeightModalTransitioningDelegate(height: 220) // swiftlint:disable:this weak_delegate (needs to be strong)
    private var providerEnRouteTransitioningDelegate = CustomHeightModalTransitioningDelegate(height: 150) // swiftlint:disable:this weak_delegate (needs to be strong)

    private var destinationInputViewController: DestinationInputViewController!
    var destinationResultsViewController: DestinationResultsViewController!
    private var confirmWorkOrderViewController: ConfirmWorkOrderViewController!
    private var providerEnRouteViewController: ProviderEnRouteViewController!

    private var registeredConsumerContextObservers = false
    private var zeroStateViewController = UIStoryboard("ZeroState").instantiateInitialViewController() as! ZeroStateViewController

    private var updatingWorkOrderContext = false
    private var categories = [Category]() {
        didSet {
            confirmWorkOrderViewController?.configure(workOrder: confirmWorkOrderViewController?.workOrder, categories: categories, paymentMethod: currentUser.defaultPaymentMethod) { _ in
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
        destinationInputViewController.destinationTextField.addTarget(self, action: #selector(destinationTextFieldEditingDidBegin), for: .editingDidBegin)
        navigationItem.hidesBackButton = true

        setupMenuBarButtonItem()
        registerRequiredObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.backgroundColor = Color.applicationDefaultNavigationBarBackgroundColor()
        navigationController?.navigationBar.barTintColor = nil
        navigationController?.navigationBar.tintColor = nil
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        dispatch_after_delay(0.25) {
            LocationService.shared.resolveCurrentLocation(allowCachedLocation: true) { [weak self] (_) in
                logmoji("📍", "Current location resolved for consumer view controller... refreshing context")
                self?.requireConsumerContext()
            }
        }
    }

    private func registerRequiredObservers() {
        KTNotificationCenter.addObserver(forName: Notification.Name(rawValue: "SegueToPaymentsStoryboard")) { [weak self] sender in
            if KeyChainService.shared.mode! == .provider {
                return
            }

            if let _ = WorkOrderService.shared.inProgressWorkOrder {
                return
            }

            if let strongSelf = self {
                if !strongSelf.navigationControllerContains(PaymentMethodsViewController.self) {
                    strongSelf.performSegue(withIdentifier: "PaymentsViewControllerSegue", sender: strongSelf)
                }
            }
        }

        KTNotificationCenter.addObserver(forName: Notification.Name(rawValue: "SegueToWorkOrderHistoryStoryboard")) { [weak self] sender in
            if let strongSelf = self {
                if !strongSelf.navigationControllerContains(WorkOrderHistoryViewController.self) {
                    strongSelf.performSegue(withIdentifier: "WorkOrderHistoryViewControllerSegue", sender: strongSelf)
                }
            }
        }

        KTNotificationCenter.addObserver(forName: .ProviderBecameAvailable, using: updateProviderLocationFromNotification)
        KTNotificationCenter.addObserver(forName: .ProviderBecameUnavailable, using: updateProviderLocationFromNotification)
        KTNotificationCenter.addObserver(forName: .ProviderLocationChanged, using: updateProviderLocationFromNotification)
    }

    private func registerConsumerContextObservers() {
        if registeredConsumerContextObservers {
            return
        }
        registeredConsumerContextObservers = true

        // TODO: deregister these when it applies
        KTNotificationCenter.addObserver(forName: .CategorySelectionChanged, using: filterProvidersByCategoryFromNotification)

        KTNotificationCenter.addObserver(forName: .NewMessageReceivedNotification) { [weak self] notification in
            DispatchQueue.main.async { [weak self] in
                self?.setupMessagesBarButtonItem()
            }
        }

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
            if confirmWorkOrderViewController != nil {
                animateConfirmWorkOrderView(toHidden: true)
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
        case "ConfirmWorkOrderViewControllerSegue":
            confirmWorkOrderViewController = segue.destination as? ConfirmWorkOrderViewController
            confirmWorkOrderViewController?.transitioningDelegate = confirmWorkOrderTransitioningDelegate
            confirmWorkOrderViewController?.modalPresentationStyle = .custom
            confirmWorkOrderViewController?.configure(workOrder: sender as? WorkOrder, categories: categories, paymentMethod: currentUser.defaultPaymentMethod) { _ in
                self.setupCancelWorkOrderBarButtonItem()
            }
        case "DestinationInputViewControllerEmbedSegue":
            destinationInputViewController = segue.destination as? DestinationInputViewController
        case "DestinationResultsViewControllerSegue":
            let extraSpace: CGFloat = 50 // visible map amount
            let destinationResultsViewControllerHeight = UIScreen.main.bounds.height - destinationInputViewController.view.height - extraSpace
            destinationResultsTransitioningDelegate = CustomHeightModalTransitioningDelegate(height: destinationResultsViewControllerHeight)
            destinationResultsViewController = segue.destination as? DestinationResultsViewController
            destinationResultsViewController?.transitioningDelegate = destinationResultsTransitioningDelegate
            destinationResultsViewController?.modalPresentationStyle = .custom
            destinationResultsViewController.configure(results: [], onResultSelected: onResultSelected)
        case "ProviderEnRouteViewControllerSegue":
            providerEnRouteViewController = segue.destination as? ProviderEnRouteViewController
            providerEnRouteViewController?.transitioningDelegate = providerEnRouteTransitioningDelegate
            providerEnRouteViewController?.modalPresentationStyle = .custom
            providerEnRouteViewController?.configure(workOrder: sender as? WorkOrder)
        case "TripCompletionViewControllerSegue":
            let tripCompletionNVC = segue.destination as! UINavigationController
            let tripCompletionVC = tripCompletionNVC.topViewController as! TripCompletionViewController
            let workOrder = sender as! WorkOrder
            tripCompletionNVC.modalPresentationStyle = .overCurrentContext
            tripCompletionVC.configure(driver: workOrder.providers.last!) { tipAmount in
                logmoji("💰", "Tip amount is \(tipAmount). TODO: POST tip amount to server")
            }
        case "PaymentsViewControllerSegue":
            prepareForMenuItemSegue()
        case "WorkOrderHistoryViewControllerSegue":
            prepareForMenuItemSegue()
            let workOrderHistoryViewController = segue.destination as! WorkOrderHistoryViewController
            workOrderHistoryViewController.delegate = self
        default:
            break
        }
    }

    private func prepareForMenuItemSegue() {
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.navigationBar.backgroundColor = .black
            self?.navigationController?.navigationBar.barTintColor = .black
            self?.navigationController?.navigationBar.tintColor = .white
            if #available(iOS 11.0, *) {
                self?.navigationController?.navigationBar.prefersLargeTitles = true
                self?.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
            }
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

    private func presentPaymentMethodRequiredZeroState() {
        zeroStateViewController.setMessage("Please setup a valid payment method.")
        zeroStateViewController.render(view)
    }

    private func presentServiceProviderAccountActiveZeroState() {
        zeroStateViewController.setMessage("Your service provider account is currently active.")
        zeroStateViewController.render(view)
    }

    private func presentServiceAvailabilityZeroState() {
        LocationService.shared.reverseGeocodeLocation(LocationService.shared.currentLocation) { [weak self] placemark in
            var msg = "No service available yet"
            if let locality = placemark.locality {
                msg = "\(msg) in \(locality)."
            }
            self?.zeroStateViewController.setMessage(msg)
            self?.zeroStateViewController.render(self!.view)
        }
    }

    private func requireConsumerContext() {
        if let user = currentUser {
            if user.providerIds.count == 1 {
                ApiService.shared.fetchProviderWithId(String(user.providerIds.first!), onSuccess: { [weak self] statusCode, mappingResult in
                    if let provider = mappingResult!.firstObject as? Provider {
                        logInfo("Fetched provider context for user: \(provider)")
                        if provider.available {
                            logWarn("User has an active provider context; consuming services will be disabled while still active")
                            currentProvider = provider
                            self?.presentServiceProviderAccountActiveZeroState()
                            return
                        }

                        self?.loadMarketContext()
                    }
                    }, onError: { err, statusCode, response in
                        logWarn("Failed to fetch provider (id: \(user.providerIds.first!)) for user (\(statusCode))")
                })
            } else {
                loadMarketContext()
            }
        } else {
            logWarn("No user for which provider context can be loaded")
        }
    }

    private func loadMarketContext() {
        if let coordinate = LocationService.shared.currentLocation?.coordinate {
            CategoryService.shared.nearby(coordinate: coordinate, radius: 50.0, onSuccess: { [weak self] categories in
                logInfo("Found \(categories.count) categories: \(categories)")
                self?.categories = categories

                if categories.count == 0 {
                    self?.presentServiceAvailabilityZeroState()
                } else {
                    self?.loadProviderContext()
                    self?.loadWorkOrderContext()
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
                logWarn("Categories resolved but no default category selected")
            }
        } else {
            logWarn("No current location resolved for consumer view controller; nearby providers not fetched")
        }
    }

    private func loadWorkOrderContext(workOrder: WorkOrder? = nil) {
        let onWorkOrdersFetched: ([WorkOrder]) -> Void = { [weak self] workOrders in
            self?.registerConsumerContextObservers()
            if currentUser.defaultPaymentMethod == nil {
                self?.presentPaymentMethodRequiredZeroState()
                return
            }

            self?.zeroStateViewController.dismiss()

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
                if let providerEnRouteViewController = providerEnRouteViewController {
                    providerEnRouteViewController.configure(workOrder: workOrder)
                } else {
                    performSegue(withIdentifier: "ProviderEnRouteViewControllerSegue", sender: workOrder)
                }
            } else if ["awaiting_schedule", "pending_acceptance"].contains(workOrder.status) {
                setupCancelWorkOrderBarButtonItem()
                if let confirmWorkOrderViewController = confirmWorkOrderViewController {
                    confirmWorkOrderViewController.configure(workOrder: workOrder, categories: categories, paymentMethod: currentUser.defaultPaymentMethod) { _ in
                        self.setupCancelWorkOrderBarButtonItem()
                    }
                } else {
                    performSegue(withIdentifier: "ConfirmWorkOrderViewControllerSegue", sender: workOrder)
                }
            }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0

            setupMenuBarButtonItem()
            mapView?.removeOverlays()

            animateConfirmWorkOrderView(toHidden: true)
            animateProviderEnRouteView(toHidden: true)

            if let hasFirstResponder = destinationInputViewController?.hasFirstResponder, !hasFirstResponder {
                destinationResultsViewController?.prepareForReuse()
                animateDestinationInputView(toState: .normal)
            }

            DispatchQueue.main.async { [weak self] in
                self?.mapView?.centerOnUserLocation()
                self?.confirmWorkOrderViewController?.prepareForReuse()
                self?.providerEnRouteViewController?.prepareForReuse()
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

            var invalidAnnotations = [Provider.Annotation]()
            for annotation in strongSelf.mapView.annotations {
                if let providerAnnotation = annotation as? Provider.Annotation {
                    if providerAnnotation.provider.categoryId != category.id {
                        invalidAnnotations.append(providerAnnotation)
                    }
                }
            }
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
            // HACK!!! API should not return this
            if currentProvider == nil {
                currentProvider = provider
            }

            if currentProvider.id == provider.id {
                currentProvider = nil
                requireConsumerContext()
            }
            return
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
            return MenuItem(label: "Payments", action: "segueToPayments")
        case 2:
            return MenuItem(label: "Switch to Driver", action: "enterProviderApplication")
        default:
            return nil
        }
    }

    func numberOfSectionsInMenuViewController(_ menuViewController: MenuViewController) -> Int {
        return 1
    }

    func menuViewController(_ menuViewController: MenuViewController, numberOfRowsInSection section: Int) -> Int {
        return UserMode.mode != nil ? 2 : 3
    }

    @objc func enterProviderApplication() {
        KeyChainService.shared.mode = .provider
        KTNotificationCenter.post(name: .ApplicationShouldReloadTopViewController)
    }

    @objc func segueToWorkOrderHistory() {
        KTNotificationCenter.post(name: .MenuContainerShouldReset)
        KTNotificationCenter.post(name: Notification.Name(rawValue: "SegueToWorkOrderHistoryStoryboard"), object: nil)
    }

    @objc func segueToPayments() {
        KTNotificationCenter.post(name: .MenuContainerShouldReset)
        KTNotificationCenter.post(name: Notification.Name(rawValue: "SegueToPaymentsStoryboard"), object: nil)
    }

    // MARK: DestinationInputViewControllerDelegate

    func selectDestination(destination: Contact, startingFrom origin: Contact) {
        setupCancelWorkOrderBarButtonItem()
        confirmWorkOrderWithOrigin(origin, destination: destination)
    }

    func confirmWorkOrderWithOrigin(_ origin: Contact, destination: Contact) {
        let latitude = origin.latitude
        let longitude = origin.longitude

        logInfo("Creating work order from \(latitude),\(longitude) -> \(destination.desc!)")

        let pendingWorkOrder = WorkOrder()
        pendingWorkOrder.desc = destination.desc
        if let cfg = destination.data {
            pendingWorkOrder.config = [
                "origin": origin.toDictionary(),
                "destination": cfg,
            ]
        }

        pendingWorkOrder.save(onSuccess: { [weak self] statusCode, mappingResult in
            if let workOrder = mappingResult?.firstObject as? WorkOrder {
                logInfo("Created work order for hire: \(workOrder)")
                WorkOrderService.shared.setWorkOrders([workOrder])
                self?.performSegue(withIdentifier: "ConfirmWorkOrderViewControllerSegue", sender: workOrder)
            }
        }, onError: { err, statusCode, responseString in
                logWarn("Failed to create work order for hire (\(statusCode))")
        })
    }

    func onResultSelected(result: Contact?) {
        destinationInputViewController.collapseAndHide()

        guard let result = result else {
            animateDestinationInputView(toState: .normal)
            return
        }

        animateDestinationInputView(toState: .hidden)

        // TODO: switch on result contact type when additional sections are added to DestinationResultsViewController

        LocationService.shared.resolveCurrentLocation(allowCachedLocation: true) { currentLocation in
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
        if let confirmWorkOrderViewController = confirmWorkOrderViewController {
            view.layoutIfNeeded()
            UIView.animate(withDuration: 0.25) {
                confirmWorkOrderViewController.view.frame.origin.y += hidden ? confirmWorkOrderViewController.view.height : -confirmWorkOrderViewController.view.height
                self.view.layoutIfNeeded()
                if hidden {
                    confirmWorkOrderViewController.dismiss(animated: true, completion: {
                        log("Dismissed work order confirmation")
                        self.confirmWorkOrderViewController = nil
                    })
                }
            }
        }
    }

    func animateProviderEnRouteView(toHidden hidden: Bool) {
        if let providerEnRouteViewController = providerEnRouteViewController {
            view.layoutIfNeeded()
            UIView.animate(withDuration: 0.25) {
                providerEnRouteViewController.view.frame.origin.y += hidden ? providerEnRouteViewController.view.height : -providerEnRouteViewController.view.height
                self.view.layoutIfNeeded()
                if hidden {
                    providerEnRouteViewController.dismiss(animated: true, completion: {
                        log("Dismissed provider en route")
                        self.providerEnRouteViewController = nil
                    })
                }
            }
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
