//
//  WorkOrderTeamViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/18/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import FontAwesomeKit
import KTSwiftExtensions

protocol WorkOrderTeamViewControllerDelegate {
    func workOrderForWorkOrderTeamViewController(_ viewController: WorkOrderTeamViewController) -> WorkOrder!
    func workOrderTeamViewController(_ viewController: WorkOrderTeamViewController, didUpdateWorkOrderProvider workOrderProvider: WorkOrderProvider)
    func workOrderTeamViewController(_ viewController: WorkOrderTeamViewController, didRemoveProvider provider: Provider)
    func flatFeeForNewProvider(_ provider: Provider, forWorkOrderTeamViewControllerViewController workOrderTeamViewControllerViewController: WorkOrderTeamViewController) -> Double!
}

class WorkOrderTeamViewController: UITableViewController,
                                   UIPopoverPresentationControllerDelegate,
                                   UISearchBarDelegate,
                                   ProviderPickerViewControllerDelegate,
                                   ProviderCreationViewControllerDelegate,
                                   KTDraggableViewGestureRecognizerDelegate,
                                   WorkOrderProviderCreationViewControllerDelegate {

    fileprivate let workOrderProviderOperationQueue = DispatchQueue(label: "api.workOrderProviderOperationQueue", attributes: [])

    let maximumSearchlessProvidersCount = 20

    var delegate: WorkOrderTeamViewControllerDelegate! {
        didSet {
            if let _ = delegate {
                if let providersPickerViewController = providersPickerViewController {
                    reloadWorkOrderForProviderPickerViewController(providersPickerViewController)
                }
            }
        }
    }

    fileprivate var workOrder: WorkOrder! {
        if let workOrder = delegate?.workOrderForWorkOrderTeamViewController(self) {
            return workOrder
        }
        return nil
    }

    fileprivate var queryString: String!

    fileprivate var reloadingProviders = false
    fileprivate var reloadingProvidersCount = false
    fileprivate var addingProvider = false
    fileprivate var removingProvider = false

    fileprivate var totalProvidersCount = -1

    fileprivate var popoverHeightOffset: CGFloat!

    fileprivate var showsAllProviders: Bool {
        return totalProvidersCount == -1 || totalProvidersCount <= maximumSearchlessProvidersCount
    }

    fileprivate var renderQueryResults: Bool {
        return queryString != nil || showsAllProviders
    }

    fileprivate var queryResultsPickerViewController: ProviderPickerViewController!
    fileprivate var queryResultsPickerTableViewCell: UITableViewCell! {
        if let queryResultsPickerViewController = queryResultsPickerViewController {
            return resolveTableViewCellForEmbeddedViewController(queryResultsPickerViewController)
        }
        return nil
    }

    fileprivate var providersPickerViewController: ProviderPickerViewController!
    fileprivate var providersPickerTableViewCell: UITableViewCell! {
        if let providersPickerViewController = providersPickerViewController {
            return resolveTableViewCellForEmbeddedViewController(providersPickerViewController)
        }
        return nil
    }

    @IBOutlet fileprivate weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Setup Team"

        searchBar?.placeholder = ""
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(WorkOrderTeamViewController.keyboardWillShow), name: Notification.Name.UIKeyboardWillShow.rawValue)
        NotificationCenter.default.addObserver(self, selector: #selector(WorkOrderTeamViewController.keyboardDidShow), name: Notification.Name.UIKeyboardDidShow.rawValue)
        NotificationCenter.default.addObserver(self, selector: #selector(WorkOrderTeamViewController.keyboardDidHide), name: Notification.Name.UIKeyboardDidHide.rawValue)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self)
    }

    func reloadQueryResultsPickerViewController() {
        queryResultsPickerViewController?.reloadCollectionView()
    }

    func keyboardWillShow() {
        if let _ = popoverPresentationController {
            popoverHeightOffset = view.convert(view.frame, to: nil).origin.y
        }
    }

    func keyboardDidShow() {
        if let _ = popoverPresentationController {
            if let popoverHeightOffset = popoverHeightOffset {
                self.popoverHeightOffset = popoverHeightOffset + view.convert(view.frame, to: nil).origin.y
            }
        }
    }

    func keyboardDidHide() {

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier == "ProviderCreationViewControllerPopoverSegue" {
            segue.destination.preferredContentSize = CGSize(width: 400, height: 500)
            segue.destination.popoverPresentationController!.delegate = self
            ((segue.destination as! UINavigationController).viewControllers.first! as! ProviderCreationViewController).delegate = self
        } else if segue.identifier! == "QueryResultsProviderPickerEmbedSegue" {
            queryResultsPickerViewController = segue.destination as! ProviderPickerViewController
            queryResultsPickerViewController.delegate = self

            if let _ = workOrder {
                reloadWorkOrderForProviderPickerViewController(queryResultsPickerViewController)
            }
        } else if segue.identifier! == "ProviderPickerEmbedSegue" {
            providersPickerViewController = segue.destination as! ProviderPickerViewController
            providersPickerViewController.delegate = self

            if let _ = workOrder {
                reloadWorkOrderForProviderPickerViewController(providersPickerViewController)
            }
        }
    }

    func addProvider(_ provider: Provider) {
        if workOrder == nil || workOrder.workOrderProviders == nil {
            return
        }

        if !workOrder.hasProvider(provider) {
            if let providersPickerViewController = providersPickerViewController {
                providersPickerViewController.providers.append(provider)
                let indexPaths = [IndexPath(row: providersPickerViewController.providers.count - 1, section: 0)]
                providersPickerViewController.collectionView.reloadItems(at: indexPaths)
                if let _ = providersPickerViewController.collectionView {
                    let cell = providersPickerViewController.collectionView.cellForItem(at: indexPaths.first!) as? PickerCollectionViewCell

                    if workOrder.id > 0 {
                        cell?.showActivityIndicator()
                    } else {
                        addingProvider = false
                    }

                    workOrderProviderOperationQueue.async { [weak self] in
                        while self!.addingProvider { }

                        self!.addingProvider = true

                        var flatFee = -1.0
                        if let fee = self!.delegate?.flatFeeForNewProvider(provider, forWorkOrderTeamViewControllerViewController: self!) {
                            flatFee = fee
                        }
                        self!.workOrder?.addProvider(provider, flatFee: flatFee,
                                                     onSuccess: { (statusCode, mappingResult) -> () in
                                                        cell?.hideActivityIndicator()
                            },
                                                     onError: { (error, statusCode, responseString) -> () in
                                                        self!.providersPickerViewController?.providers.removeObject(provider)
                                                        self!.providersPickerViewController?.reloadCollectionView()
                                                        self!.addingProvider = false
                            }
                        )
                    }
                }
            }
        }
    }

    func removeProvider(_ provider: Provider) {
        if workOrder == nil {
            return
        }

        if workOrder.hasProvider(provider) {
            let index = providersPickerViewController?.providers.indexOfObject(provider)!
            providersPickerViewController?.providers.remove(at: index!)
            providersPickerViewController?.reloadCollectionView()

            if workOrder.id == 0 {
                removingProvider = false
            }

            workOrderProviderOperationQueue.async { [weak self] in
                while self!.addingProvider { }

                self!.removingProvider = true

                self!.workOrder?.removeProvider(provider,
                    onSuccess: { (statusCode, mappingResult) -> () in
                        self!.providersPickerViewController?.reloadCollectionView()
                        if self!.workOrder.providers.count == 0 {
                            self!.reloadWorkOrderProviders()
                        }
                        self!.removingProvider = false
                        self!.delegate?.workOrderTeamViewController(self!, didRemoveProvider: provider)
                    },
                    onError: { (error, statusCode, responseString) -> () in
                        self!.providersPickerViewController?.providers.insert(provider, at: index!)
                        self!.providersPickerViewController?.reloadCollectionView()
                        self!.removingProvider = false
                    }
                )
            }


        }
    }

    fileprivate func resolveTableViewCellForEmbeddedViewController(_ viewController: UIViewController) -> UITableViewCell! {
        var tableViewCell: UITableViewCell!
        var view = viewController.view
        while tableViewCell == nil {
            if let v = view?.superview {
                view = v
                if v is UITableViewCell {
                    tableViewCell = v as! UITableViewCell
                }
            }

        }
        return tableViewCell
    }

    // MARK: UITableViewDelegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return renderQueryResults ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if providersPickerTableViewCell != nil && numberOfSections(in: tableView) == 1 {
            return providersPickerTableViewCell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if numberOfSections(in: tableView) == 1 {
            return "WORK ORDER CREW"
        } else {
            if numberOfSections(in: tableView) == 2 && showsAllProviders {
                if section == 0 {
                    return "SERVICE PROVIDERS"
                } else if section == 1 {
                    return "WORK ORDER CREW"
                }
            }
        }
        return super.tableView(tableView, titleForHeaderInSection: section)
    }

    // MARK: UIPopoverPresentationControllerDelegate

//    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
//        return .None
//    }

    // MARK: UISearchBarDelegate

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return !showsAllProviders
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        queryString = searchText
        if queryString.replaceString(" ", withString: "").length == 0 {
            queryString = nil
            queryResultsPickerViewController?.providers = [Provider]()
            tableView.reloadData()
        } else {
            tableView.reloadData()
            queryResultsPickerViewController?.reset()
        }
    }

    // MARK: KTDraggableViewGestureRecognizerDelegate

    func draggableViewGestureRecognizer(_ gestureRecognizer: KTDraggableViewGestureRecognizer, shouldResetView view: UIView) -> Bool {
        if !draggableViewGestureRecognizer(gestureRecognizer, shouldAnimateResetView: view) {
            view.alpha = 0.0
        }
        return true
    }

    func draggableViewGestureRecognizer(_ gestureRecognizer: KTDraggableViewGestureRecognizer, shouldAnimateResetView view: UIView) -> Bool {
        if gestureRecognizer.isKind(of: ProviderPickerCollectionViewCellGestureRecognizer.self) {
            return (gestureRecognizer as! ProviderPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        } else if gestureRecognizer.isKind(of: QueryResultsPickerCollectionViewCellGestureRecognizer.self) {
            return (gestureRecognizer as! QueryResultsPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        }
        return true
    }

    func queryResultsPickerCollectionViewCellGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    func providersPickerCollectionViewCellGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    // MARK: ProviderPickerViewControllerDelegate

    func providersForPickerViewController(_ viewController: ProviderPickerViewController) -> [Provider] {
        if providersPickerViewController != nil && viewController == providersPickerViewController {
            if let workOrder = workOrder {
                return workOrder.providers
            } else {
                reloadWorkOrderForProviderPickerViewController(viewController)
            }
        } else if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {

        }

        return [Provider]()
    }

    func providerPickerViewController(_ viewController: ProviderPickerViewController, didSelectProvider provider: Provider) {

    }

    func providerPickerViewController(_ viewController: ProviderPickerViewController, didDeselectProvider provider: Provider) {

    }

    func providerPickerViewControllerAllowsMultipleSelection(_ viewController: ProviderPickerViewController) -> Bool {
        //        if viewController == providersPickerViewController {
        //            return false
        //        }
        return false
    }

    func providerPickerViewControllerCanRenderResults(_ viewController: ProviderPickerViewController) -> Bool {
        if providersPickerViewController != nil && viewController == providersPickerViewController {
            if let _ = workOrder {
                return true
            }
        } else if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
            return true
        }
        return false
    }

    func selectedProvidersForPickerViewController(_ viewController: ProviderPickerViewController) -> [Provider] {
        return [Provider]()
    }

    func queryParamsForProviderPickerViewController(_ viewController: ProviderPickerViewController) -> [String : AnyObject]! {
        if let workOrder = workOrder {
            if let queryResultsPickerViewController = queryResultsPickerViewController {
                if viewController == queryResultsPickerViewController {
                    var params: [String : AnyObject] = [
                        "company_id": workOrder.companyId as AnyObject,
                    ]

                    if workOrder.categoryId != 0 {
                        params["category_id"] = workOrder.categoryId as AnyObject
                    }

                    if let queryString = queryString {
                        params["q"] = queryString as AnyObject
                    }
                    return params
                }
            }
        }
        return nil
    }

    func providerPickerViewController(_ viewController: ProviderPickerViewController,
        collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickerCollectionViewCell", for: indexPath) as! PickerCollectionViewCell
            let providers = viewController.providers

            if providers.count > (indexPath as NSIndexPath).row - 1 {
                let provider = providers[(indexPath as NSIndexPath).row]

                cell.isSelected = viewController.isSelected(provider)

                if cell.isSelected {
                    collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition())
                }

                cell.name = provider.contact.name

                if let profileImageUrl = provider.profileImageUrl {
                    cell.imageUrl = profileImageUrl
                } else {
                    cell.renderInitials()
                }
            }

            if let gestureRecognizers = cell.gestureRecognizers {
                for gestureRecognizer in gestureRecognizers {
                    if gestureRecognizer.isKind(of: QueryResultsPickerCollectionViewCellGestureRecognizer.self)
                        || gestureRecognizer.isKind(of: ProviderPickerCollectionViewCellGestureRecognizer.self) {
                            cell.removeGestureRecognizer(gestureRecognizer)
                    }
                }
            }

            if viewController == providersPickerViewController {
                let gestureRecognizer = ProviderPickerCollectionViewCellGestureRecognizer(viewController: self)
                gestureRecognizer.draggableViewGestureRecognizerDelegate = self
                cell.addGestureRecognizer(gestureRecognizer)
            } else if viewController == queryResultsPickerViewController {
                let gestureRecognizer = QueryResultsPickerCollectionViewCellGestureRecognizer(viewController: self)
                gestureRecognizer.draggableViewGestureRecognizerDelegate = self
                cell.addGestureRecognizer(gestureRecognizer)
            }

            return cell
    }

    func collectionViewScrollDirectionForPickerViewController(_ viewController: ProviderPickerViewController) -> UICollectionViewScrollDirection {
        return .horizontal
    }

    // MARK: ProviderCreationViewControllerDelegate

    func providerCreationViewController(_ viewController: ProviderCreationViewController, didCreateProvider provider: Provider) {
        viewController.presentingViewController?.dismissViewController(true)

        if totalProvidersCount > -1 {
            totalProvidersCount += 1

            if showsAllProviders {
                queryResultsPickerViewController?.providers.append(provider)
                queryResultsPickerViewController?.reloadCollectionView()

                searchBar.placeholder = "Showing all \(totalProvidersCount) providers"
            } else {
                searchBar.placeholder = "Search \(totalProvidersCount) service providers"
            }
        }
    }

    fileprivate func reloadWorkOrderForProviderPickerViewController(_ viewController: ProviderPickerViewController) {
        if let providersPickerViewController = providersPickerViewController {
            if viewController == providersPickerViewController && workOrder != nil {
                reloadProviders()
                reloadWorkOrderProviders()
            }
        }
    }

    fileprivate func reloadProviders() {
        reloadingProvidersCount = true

        if let companyId = workOrder?.companyId {
            queryResultsPickerViewController?.providers = [Provider]()
            queryResultsPickerViewController?.showActivityIndicator()
            tableView.reloadData()

            var params: [String : AnyObject] = ["company_id": companyId as AnyObject]
            if workOrder.categoryId > 0 {
                params["category_id"] = workOrder.categoryId as AnyObject
            }

            ApiService.sharedService().countProviders(params,
                onTotalResultsCount: { totalResultsCount, error in
                    self.totalProvidersCount = totalResultsCount
                    if totalResultsCount > -1 {
                        if totalResultsCount <= self.maximumSearchlessProvidersCount {
                            params["page"] = 1 as AnyObject
                            params["rpp"] = totalResultsCount as AnyObject

                            ApiService.sharedService().fetchProviders(params,
                                onSuccess: { (statusCode, mappingResult) -> () in
                                    self.queryResultsPickerViewController?.providers = mappingResult?.array() as! [Provider]
                                    self.tableView.reloadData()
                                    if totalResultsCount == 0 {
                                        if let category = self.workOrder.category {
                                            self.searchBar.placeholder = "No \(category.name.lowercased()) service providers have been added... yet."
                                        } else {
                                            self.searchBar.placeholder = "No service providers have been added... yet."
                                        }
                                    } else if let category = self.workOrder.category {
                                        self.searchBar.placeholder = "Showing all \(totalResultsCount) \(category.name.lowercased()) service providers"
                                    } else {
                                        self.searchBar.placeholder = "Showing all \(totalResultsCount) service providers"
                                    }
                                    self.reloadingProvidersCount = false
                                },
                                onError: { (error, statusCode, responseString) -> () in
                                    self.queryResultsPickerViewController?.providers = [Provider]()
                                    self.tableView.reloadData()
                                    self.reloadingProvidersCount = false
                                }
                            )
                        } else {
                            var placeholder =  "Search \(totalResultsCount) service providers"
                            if let category = self.workOrder.category {
                                placeholder = "Search \(totalResultsCount) \(category.name.lowercased()) service providers"
                            }
                            self.searchBar.placeholder = placeholder
                            self.tableView.reloadData()
                            self.reloadingProvidersCount = false
                        }
                    }
                }
            )
        }
    }

    fileprivate func reloadWorkOrderProviders() {
        if let workOrder = workOrder {
            if workOrder.id == 0 {
                return
            }

            reloadingProviders = true

            workOrder.reload(
                { (statusCode, mappingResult) -> () in
                    let workOrder = mappingResult?.firstObject as! WorkOrder
                    self.providersPickerViewController.providers = workOrder.providers
                    self.providersPickerViewController.reloadCollectionView()
                    self.reloadingProviders = false
                },
                onError: { (error, statusCode, responseString) -> () in
                    self.providersPickerViewController.reloadCollectionView()
                    self.reloadingProviders = false
                }
            )
        }
    }

    // MARK: QueryResultsPickerCollectionViewCellGestureRecognizer

    fileprivate class QueryResultsPickerCollectionViewCellGestureRecognizer: KTDraggableViewGestureRecognizer {
        fileprivate var collectionView: UICollectionView!
        fileprivate var popoverHeightOffset:CGFloat = 0.0

        fileprivate var workOrderTeamViewController: WorkOrderTeamViewController!

        fileprivate var providersPickerCollectionView: UICollectionView! {
            didSet {
                if let providersPickerCollectionView = providersPickerCollectionView {
                    initialProvidersPickerCollectionViewBackgroundColor = providersPickerCollectionView.backgroundColor
                }
            }
        }
        fileprivate var initialProvidersPickerCollectionViewBackgroundColor: UIColor!

        fileprivate var shouldAddProvider = false

        fileprivate var window: UIWindow! {
            return UIApplication.shared.keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldAddProvider
        }

        init(viewController: WorkOrderTeamViewController) {
            super.init(target: viewController, action: #selector(WorkOrderTeamViewController.queryResultsPickerCollectionViewCellGestureRecognized(_:)))
            workOrderTeamViewController = viewController
            providersPickerCollectionView = viewController.providersPickerViewController.collectionView
        }

        override open var initialView: UIView! {
            didSet {
                if let initialView = self.initialView {
                    if initialView.isKind(of: PickerCollectionViewCell.self) {
                        collectionView = initialView.superview! as! UICollectionView
                        collectionView.isScrollEnabled = false

                        initialView.frame = collectionView.convert(initialView.frame, to: nil)
                        popoverHeightOffset = collectionView.convert(collectionView.frame, to: nil).origin.y

                        window.addSubview(initialView)
                        window.bringSubview(toFront: initialView)
                    }
                } else if let initialView = oldValue {
                    providersPickerCollectionView.backgroundColor = initialProvidersPickerCollectionViewBackgroundColor

                    if shouldAddProvider {
                        let indexPath = workOrderTeamViewController.queryResultsPickerViewController.collectionView.indexPath(for: initialView as! UICollectionViewCell)!
                        let provider = workOrderTeamViewController.queryResultsPickerViewController.providers[(indexPath as NSIndexPath).row]
                        workOrderTeamViewController?.addProvider(provider)
                    }

                    collectionView.isScrollEnabled = true
                    collectionView = nil

                    shouldAddProvider = false
                }
            }
        }

        fileprivate override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            initialFrame?.origin.y -= popoverHeightOffset - collectionView.convert(collectionView.frame, to: nil).origin.y
            super.touchesEnded(touches, with: event)
        }

        fileprivate override func drag(_ xOffset: CGFloat, yOffset: CGFloat) {
            super.drag(xOffset, yOffset: yOffset)

            if initialView == nil || collectionView == nil {
                return
            }

            if workOrderTeamViewController.searchBar.isFirstResponder {
                workOrderTeamViewController.searchBar.resignFirstResponder()
            }

            let providersPickerCollectionViewFrame = providersPickerCollectionView.superview!.convert(providersPickerCollectionView.frame, to: nil)
            shouldAddProvider = initialView.frame.intersects(providersPickerCollectionViewFrame)

            if shouldAddProvider {
                providersPickerCollectionView.backgroundColor = Color.completedStatusColor().withAlphaComponent(0.8)
            } else {
                providersPickerCollectionView.backgroundColor = initialProvidersPickerCollectionViewBackgroundColor
            }
        }
    }

    // MARK: ProviderPickerCollectionViewCellGestureRecognizer

    fileprivate class ProviderPickerCollectionViewCellGestureRecognizer: KTDraggableViewGestureRecognizer {
        fileprivate var collectionView: UICollectionView!

        fileprivate var workOrderTeamViewController: WorkOrderTeamViewController!

        fileprivate var providersPickerCollectionView: UICollectionView! {
            didSet {
                if let providersPickerCollectionView = providersPickerCollectionView {
                    initialProvidersPickerCollectionViewBackgroundColor = providersPickerCollectionView.backgroundColor
                }
            }
        }
        fileprivate var initialProvidersPickerCollectionViewBackgroundColor: UIColor!

        fileprivate var shouldRemoveProvider = false

        fileprivate var window: UIWindow! {
            return UIApplication.shared.keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldRemoveProvider
        }

        init(viewController: WorkOrderTeamViewController) {
            super.init(target: viewController, action: #selector(WorkOrderTeamViewController.providersPickerCollectionViewCellGestureRecognized(_:)))
            workOrderTeamViewController = viewController
            providersPickerCollectionView = viewController.providersPickerViewController.collectionView
        }

        override open var initialView: UIView! {
            didSet {
                if let initialView = self.initialView {
                    if initialView.isKind(of: PickerCollectionViewCell.self) {
                        collectionView = initialView.superview! as! UICollectionView
                        collectionView.isScrollEnabled = false

                        initialView.frame = collectionView.convert(initialView.frame, to: nil)

                        window.addSubview(initialView)
                        window.bringSubview(toFront: initialView)
                    }
                } else if let _ = oldValue {
                    providersPickerCollectionView.backgroundColor = initialProvidersPickerCollectionViewBackgroundColor

                    collectionView.isScrollEnabled = true
                    collectionView = nil

                    shouldRemoveProvider = false
                }
            }
        }

        fileprivate override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            if shouldRemoveProvider {
                let indexPath = providersPickerCollectionView.indexPath(for: initialView as! UICollectionViewCell)!
                let supervisor = workOrderTeamViewController.providersPickerViewController.providers[(indexPath as NSIndexPath).row]
                if currentUser().id == supervisor.userId {
                    workOrderTeamViewController.showToast("You can't remove yourself", dismissAfter: 2.0)
                } else {
                    workOrderTeamViewController?.removeProvider(supervisor)
                }
            }

            super.touchesEnded(touches, with: event)
        }

        fileprivate override func drag(_ xOffset: CGFloat, yOffset: CGFloat) {
            super.drag(xOffset, yOffset: yOffset)
            
            if initialView == nil || collectionView == nil {
                return
            }
            
            let providersPickerCollectionViewFrame = providersPickerCollectionView.superview!.convert(providersPickerCollectionView.frame, to: nil)
            shouldRemoveProvider = !initialView.frame.intersects(providersPickerCollectionViewFrame)
            
            if shouldRemoveProvider {
                let accessoryImage = FAKFontAwesome.removeIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
                (initialView as! PickerCollectionViewCell).setAccessoryImage(accessoryImage, tintColor: Color.abandonedStatusColor())
            } else {
                (initialView as! PickerCollectionViewCell).accessoryImage = nil
            }
        }
    }

    // MARK: WorkOrderProviderCreationViewControllerDelegate

    func workOrderProviderCreationViewController(_ viewController: WorkOrderProviderCreationViewController, didUpdateWorkOrderProvider workOrderProvider: WorkOrderProvider) {
        viewController.presentingViewController?.dismissViewController(true)
        delegate?.workOrderTeamViewController(self, didUpdateWorkOrderProvider: workOrderProvider)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
