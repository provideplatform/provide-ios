//
//  CustomerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/12/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

class CustomerViewController: ViewController, MenuViewControllerDelegate {

    @IBOutlet fileprivate weak var mapView: CustomerMapView!

    fileprivate var destinationInputViewController: DestinationInputViewController!
    fileprivate var destinationResultsViewController: DestinationResultsViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true

        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.isTranslucent = true

        setupBarButtonItems()

        loadWorkOrderContext()

        LocationService.sharedService().resolveCurrentLocation { [weak self] (_) in
            logInfo("Current location resolved for customer view controller... refreshing context")
            self?.loadProviderContext()
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
            if let destinationInputViewController = destinationInputViewController {
                destinationInputViewController.destinationResultsViewController = destinationResultsViewController
            }
        default:
            break
        }
    }

    fileprivate func refreshContext() {
        loadWorkOrderContext()
        loadProviderContext()
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

        workOrderService.fetch(
            status: "scheduled,en_route,in_progress,rejected",
            today: true,
            onWorkOrdersFetched: { [weak self] workOrders in
                workOrderService.setWorkOrders(workOrders) // FIXME -- decide if this should live in the service instead

                if workOrders.count == 0 {
                    self?.presentDestinationInputViewController()
                    UIView.animate(withDuration: 0.25, animations: { [weak self] in
                        if let destinationInputView = self?.destinationInputViewController.view {
                            destinationInputView.frame.origin.y += self!.view.frame.height * 0.1
                            if let destinationInputTextField = destinationInputView.subviews.first as? UITextField {
                                destinationInputTextField.frame.origin.y = destinationInputTextField.frame.origin.y
                            }
                        }
                    })
                }

                // TODO: self!.nextWorkOrderContextShouldBeRewound()
                // TODO: self!.attemptSegueToValidWorkOrderContext()
                // TODO: self!.updatingWorkOrderContext = false
            }
        )
    }

    fileprivate func presentDestinationInputViewController() {
        if let destinationInputView = destinationInputViewController.view {
            destinationInputView.isHidden = true
            destinationInputView.removeFromSuperview()
            mapView.addSubview(destinationInputView)

            destinationInputView.frame.size.width = mapView.frame.width
//            destinationInputView.frame.origin.y -= destinationInputView.frame.size.height
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

    fileprivate func updateProviderLocation(_ provider: Provider) {
        logInfo("Update provider location: \(provider)")
        if !mapView.annotations.contains(where: { (annotation) -> Bool in
            if let _ = annotation as? Provider.Annotation {
                return true
            }
            return false
        }) {
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
}
