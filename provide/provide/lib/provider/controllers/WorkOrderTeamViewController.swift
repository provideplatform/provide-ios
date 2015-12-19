//
//  WorkOrderTeamViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/18/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol WorkOrderTeamViewControllerDelegate {
    func workOrderForWorkOrderTeamViewController(viewController: WorkOrderTeamViewController) -> WorkOrder!
}

class WorkOrderTeamViewController: UITableViewController,
                                   UIPopoverPresentationControllerDelegate,
                                   UISearchBarDelegate,
                                   ProviderPickerViewControllerDelegate,
                                   ProviderCreationViewControllerDelegate,
                                   DraggableViewGestureRecognizerDelegate {

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

    private var workOrder: WorkOrder! {
        if let workOrder = delegate?.workOrderForWorkOrderTeamViewController(self) {
            return workOrder
        }
        return nil
    }

    private var queryString: String!

    private var reloadingProviders = false
    private var reloadingProvidersCount = false
    private var addingProvider = false
    private var removingProvider = false

    private var totalProvidersCount = -1

    private var popoverHeightOffset: CGFloat!

    private var showsAllProviders: Bool {
        return totalProvidersCount == -1 || totalProvidersCount <= maximumSearchlessProvidersCount
    }

    private var renderQueryResults: Bool {
        return queryString != nil || showsAllProviders
    }

    private var queryResultsPickerViewController: ProviderPickerViewController!
    private var queryResultsPickerTableViewCell: UITableViewCell! {
        if let queryResultsPickerViewController = queryResultsPickerViewController {
            return resolveTableViewCellForEmbeddedViewController(queryResultsPickerViewController)
        }
        return nil
    }

    private var providersPickerViewController: ProviderPickerViewController!
    private var providersPickerTableViewCell: UITableViewCell! {
        if let providersPickerViewController = providersPickerViewController {
            return resolveTableViewCellForEmbeddedViewController(providersPickerViewController)
        }
        return nil
    }

    @IBOutlet private weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Setup Team"

        searchBar?.placeholder = ""
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow", name: UIKeyboardWillShowNotification)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidShow", name: UIKeyboardDidShowNotification)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidHide", name: UIKeyboardDidHideNotification)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func reloadQueryResultsPickerViewController() {
        queryResultsPickerViewController?.reloadCollectionView()
    }

    func keyboardWillShow() {
        if let _ = popoverPresentationController {
            popoverHeightOffset = view.convertRect(view.frame, toView: nil).origin.y
        }
    }

    func keyboardDidShow() {
        if let _ = popoverPresentationController {
            if let popoverHeightOffset = popoverHeightOffset {
                self.popoverHeightOffset = popoverHeightOffset + view.convertRect(view.frame, toView: nil).origin.y
            }
        }
    }

    func keyboardDidHide() {

    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier == "ProviderCreationViewControllerPopoverSegue" {
            segue.destinationViewController.preferredContentSize = CGSizeMake(400, 500)
            segue.destinationViewController.popoverPresentationController!.delegate = self
            ((segue.destinationViewController as! UINavigationController).viewControllers.first! as! ProviderCreationViewController).delegate = self
        } else if segue.identifier! == "QueryResultsProviderPickerEmbedSegue" {
            queryResultsPickerViewController = segue.destinationViewController as! ProviderPickerViewController
            queryResultsPickerViewController.delegate = self

            if let _ = workOrder {
                reloadWorkOrderForProviderPickerViewController(queryResultsPickerViewController)
            }
        } else if segue.identifier! == "ProviderPickerEmbedSegue" {
            providersPickerViewController = segue.destinationViewController as! ProviderPickerViewController
            providersPickerViewController.delegate = self

            if let _ = workOrder {
                reloadWorkOrderForProviderPickerViewController(providersPickerViewController)
            }
        }
    }

    func addProvider(provider: Provider) {
        if workOrder == nil {
            return
        }

        if !workOrder.hasProvider(provider) {
            addingProvider = true

            providersPickerViewController?.providers.append(provider)
            let indexPaths = [NSIndexPath(forRow: (providersPickerViewController?.providers.count)! - 1, inSection: 0)]
            providersPickerViewController?.collectionView.reloadItemsAtIndexPaths(indexPaths)
            if let _ = providersPickerViewController?.collectionView {
                let cell = providersPickerViewController?.collectionView.cellForItemAtIndexPath(indexPaths.first!) as! PickerCollectionViewCell

                if workOrder.id > 0 {
                    cell.showActivityIndicator()
                } else {
                    addingProvider = false
                }

                workOrder?.addProvider(provider,
                    onSuccess: { (statusCode, mappingResult) -> () in
                        self.addingProvider = false
                        cell.hideActivityIndicator()
                    },
                    onError: { (error, statusCode, responseString) -> () in
                        self.providersPickerViewController?.providers.removeObject(provider)
                        self.providersPickerViewController?.reloadCollectionView()
                        self.addingProvider = false
                    }
                )
            }
        }
    }

    func removeProvider(provider: Provider) {
        if workOrder == nil {
            return
        }

        if workOrder.hasProvider(provider) {
            removingProvider = true

            let index = providersPickerViewController?.providers.indexOfObject(provider)!
            providersPickerViewController?.providers.removeAtIndex(index!)
            providersPickerViewController?.reloadCollectionView()

            if workOrder.id == 0 {
                removingProvider = false
            }

            workOrder?.removeProvider(provider,
                onSuccess: { (statusCode, mappingResult) -> () in
                    self.providersPickerViewController?.reloadCollectionView()
                    if self.workOrder.providers.count == 0 {
                        self.reloadWorkOrderProviders()
                    }
                    self.removingProvider = false
                },
                onError: { (error, statusCode, responseString) -> () in
                    self.providersPickerViewController?.providers.insert(provider, atIndex: index!)
                    self.providersPickerViewController?.reloadCollectionView()
                    self.removingProvider = false
                }
            )
        }
    }

    private func resolveTableViewCellForEmbeddedViewController(viewController: UIViewController) -> UITableViewCell! {
        var tableViewCell: UITableViewCell!
        var view = viewController.view
        while tableViewCell == nil {
            view = view.superview!
            if view.isKindOfClass(UITableViewCell) {
                tableViewCell = view as! UITableViewCell
            }
        }
        return tableViewCell
    }

    // MARK: UITableViewDelegate

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return renderQueryResults ? 2 : 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if providersPickerTableViewCell != nil && numberOfSectionsInTableView(tableView) == 1 {
            return providersPickerTableViewCell
        }
        return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if numberOfSectionsInTableView(tableView) == 1 {
            return "WORK ORDER CREW"
        } else {
            if numberOfSectionsInTableView(tableView) == 2 && showsAllProviders {
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

    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }

    // MARK: UISearchBarDelegate

    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        return !showsAllProviders
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
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

    // MARK: DraggableViewGestureRecognizerDelegate

    func draggableViewGestureRecognizer(gestureRecognizer: DraggableViewGestureRecognizer, shouldResetView view: UIView) -> Bool {
        if !draggableViewGestureRecognizer(gestureRecognizer, shouldAnimateResetView: view) {
            view.alpha = 0.0
        }
        return true
    }

    func draggableViewGestureRecognizer(gestureRecognizer: DraggableViewGestureRecognizer, shouldAnimateResetView view: UIView) -> Bool {
        if gestureRecognizer.isKindOfClass(ProviderPickerCollectionViewCellGestureRecognizer) {
            return (gestureRecognizer as! ProviderPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        } else if gestureRecognizer.isKindOfClass(QueryResultsPickerCollectionViewCellGestureRecognizer) {
            return (gestureRecognizer as! QueryResultsPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        }
        return true
    }

    func queryResultsPickerCollectionViewCellGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    func providersPickerCollectionViewCellGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    // MARK: ProviderPickerViewControllerDelegate

    func providersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider] {
        if providersPickerViewController != nil && viewController == providersPickerViewController {
            if let providers = workOrder?.providers {
                return providers
            } else {
                reloadWorkOrderForProviderPickerViewController(viewController)
            }
        } else if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {

        }

        return [Provider]()
    }

    func providerPickerViewController(viewController: ProviderPickerViewController, didSelectProvider provider: Provider) {

    }

    func providerPickerViewController(viewController: ProviderPickerViewController, didDeselectProvider provider: Provider) {

    }

    func providerPickerViewControllerAllowsMultipleSelection(viewController: ProviderPickerViewController) -> Bool {
        //        if viewController == providersPickerViewController {
        //            return false
        //        }
        return false
    }

    func providerPickerViewControllerCanRenderResults(viewController: ProviderPickerViewController) -> Bool {
        if providersPickerViewController != nil && viewController == providersPickerViewController {
            if let _ = workOrder {
                return true
            }
        } else if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
            return true
        }
        return false
    }

    func selectedProvidersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider] {
        return [Provider]()
    }

    func queryParamsForProviderPickerViewController(viewController: ProviderPickerViewController) -> [String : AnyObject]! {
        if let workOrder = workOrder {
            if let queryResultsPickerViewController = queryResultsPickerViewController {
                if viewController == queryResultsPickerViewController {
                    return ["company_id": workOrder.companyId, "q": queryString != nil ? queryString : NSNull()]
                }
            }
        }
        return nil
    }

    func providerPickerViewController(viewController: ProviderPickerViewController,
        collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PickerCollectionViewCell", forIndexPath: indexPath) as! PickerCollectionViewCell
            let providers = viewController.providers

            if providers.count > indexPath.row - 1 {
                let provider = providers[indexPath.row]

                cell.selected = viewController.isSelected(provider)

                if cell.selected {
                    collectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: .None)
                }

                cell.name = provider.contact.name

                if let profileImageUrl = provider.profileImageUrl {
                    cell.imageUrl = profileImageUrl
                } else {
                    cell.gravatarEmail = provider.contact.email
                }
            }

            if let gestureRecognizers = cell.gestureRecognizers {
                for gestureRecognizer in gestureRecognizers {
                    if gestureRecognizer.isKindOfClass(QueryResultsPickerCollectionViewCellGestureRecognizer)
                        || gestureRecognizer.isKindOfClass(ProviderPickerCollectionViewCellGestureRecognizer) {
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

    func collectionViewScrollDirectionForPickerViewController(viewController: ProviderPickerViewController) -> UICollectionViewScrollDirection {
        return .Horizontal
    }

    // MARK: ProviderCreationViewControllerDelegate

    func providerCreationViewController(viewController: ProviderCreationViewController, didCreateProvider provider: Provider) {
        viewController.presentingViewController?.dismissViewController(animated: true)

        if totalProvidersCount > -1 {
            totalProvidersCount++

            if showsAllProviders {
                queryResultsPickerViewController?.providers.append(provider)
                queryResultsPickerViewController?.reloadCollectionView()

                searchBar.placeholder = "Showing all \(totalProvidersCount) providers"
            } else {
                searchBar.placeholder = "Search \(totalProvidersCount) service providers"
            }
        }
    }

    private func reloadWorkOrderForProviderPickerViewController(viewController: ProviderPickerViewController) {
        if let providersPickerViewController = providersPickerViewController {
            if viewController == providersPickerViewController && workOrder != nil {
                reloadProviders()
                reloadWorkOrderProviders()
            }
        }
    }

    private func reloadProviders() {
        reloadingProvidersCount = true

        if let companyId = workOrder?.companyId {
            queryResultsPickerViewController?.providers = [Provider]()
            queryResultsPickerViewController?.showActivityIndicator()
            tableView.reloadData()

            ApiService.sharedService().countProviders(["company_id": workOrder.companyId],
                onTotalResultsCount: { totalResultsCount, error in
                    self.totalProvidersCount = totalResultsCount
                    if totalResultsCount > -1 {
                        if totalResultsCount <= self.maximumSearchlessProvidersCount {
                            ApiService.sharedService().fetchProviders(["company_id": companyId, "page": 1, "rpp": totalResultsCount],
                                onSuccess: { (statusCode, mappingResult) -> () in
                                    self.queryResultsPickerViewController?.providers = mappingResult.array() as! [Provider]
                                    self.tableView.reloadData()
                                    self.searchBar.placeholder = "Showing all \(totalResultsCount) service providers"
                                    self.reloadingProvidersCount = false
                                },
                                onError: { (error, statusCode, responseString) -> () in
                                    self.queryResultsPickerViewController?.providers = [Provider]()
                                    self.tableView.reloadData()
                                    self.reloadingProvidersCount = false
                                }
                            )
                        } else {
                            self.searchBar.placeholder = "Search \(totalResultsCount) service providers"
                            self.tableView.reloadData()
                            self.reloadingProvidersCount = false
                        }
                    }
                }
            )
        }
    }

    private func reloadWorkOrderProviders() {
        reloadingProviders = true

        workOrder?.reload(
            onSuccess: { (statusCode, mappingResult) -> () in
                let workOrder = mappingResult.firstObject as! WorkOrder
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

    // MARK: QueryResultsPickerCollectionViewCellGestureRecognizer

    private class QueryResultsPickerCollectionViewCellGestureRecognizer: DraggableViewGestureRecognizer {
        private var collectionView: UICollectionView!
        private var popoverHeightOffset:CGFloat = 0.0

        private var workOrderTeamViewController: WorkOrderTeamViewController!

        private var providersPickerCollectionView: UICollectionView! {
            didSet {
                if let providersPickerCollectionView = providersPickerCollectionView {
                    initialProvidersPickerCollectionViewBackgroundColor = providersPickerCollectionView.backgroundColor
                }
            }
        }
        private var initialProvidersPickerCollectionViewBackgroundColor: UIColor!

        private var shouldAddProvider = false

        private var window: UIWindow! {
            return UIApplication.sharedApplication().keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldAddProvider
        }

        init(viewController: WorkOrderTeamViewController) {
            super.init(target: viewController, action: "queryResultsPickerCollectionViewCellGestureRecognized:")
            workOrderTeamViewController = viewController
            providersPickerCollectionView = viewController.providersPickerViewController.collectionView
        }

        override private var initialView: UIView! {
            didSet {
                if let initialView = initialView {
                    if initialView.isKindOfClass(PickerCollectionViewCell) {
                        collectionView = initialView.superview! as! UICollectionView
                        collectionView.scrollEnabled = false

                        initialView.frame = collectionView.convertRect(initialView.frame, toView: nil)
                        popoverHeightOffset = collectionView.convertRect(collectionView.frame, toView: nil).origin.y

                        window.addSubview(initialView)
                        window.bringSubviewToFront(initialView)
                    }
                } else if let initialView = oldValue {
                    providersPickerCollectionView.backgroundColor = initialProvidersPickerCollectionViewBackgroundColor

                    if shouldAddProvider {
                        let indexPath = workOrderTeamViewController.queryResultsPickerViewController.collectionView.indexPathForCell(initialView as! UICollectionViewCell)!
                        workOrderTeamViewController?.addProvider(workOrderTeamViewController.queryResultsPickerViewController.providers[indexPath.row])
                    }

                    collectionView.scrollEnabled = true
                    collectionView = nil

                    shouldAddProvider = false
                }
            }
        }

        private override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
            initialFrame?.origin.y -= popoverHeightOffset - collectionView.convertRect(collectionView.frame, toView: nil).origin.y
            super.touchesEnded(touches, withEvent: event)
        }

        private override func drag(xOffset: CGFloat, yOffset: CGFloat) {
            super.drag(xOffset, yOffset: yOffset)

            if initialView == nil || collectionView == nil {
                return
            }

            if workOrderTeamViewController.searchBar.isFirstResponder() {
                workOrderTeamViewController.searchBar.resignFirstResponder()
            }

            let providersPickerCollectionViewFrame = providersPickerCollectionView.superview!.convertRect(providersPickerCollectionView.frame, toView: nil)
            shouldAddProvider = !workOrderTeamViewController.addingProvider && CGRectIntersectsRect(initialView.frame, providersPickerCollectionViewFrame)

            if shouldAddProvider {
                providersPickerCollectionView.backgroundColor = Color.completedStatusColor().colorWithAlphaComponent(0.8)
            } else {
                providersPickerCollectionView.backgroundColor = initialProvidersPickerCollectionViewBackgroundColor
            }
        }
    }

    // MARK: ProviderPickerCollectionViewCellGestureRecognizer

    private class ProviderPickerCollectionViewCellGestureRecognizer: DraggableViewGestureRecognizer {
        private var collectionView: UICollectionView!

        private var workOrderTeamViewController: WorkOrderTeamViewController!

        private var providersPickerCollectionView: UICollectionView! {
            didSet {
                if let providersPickerCollectionView = providersPickerCollectionView {
                    initialProvidersPickerCollectionViewBackgroundColor = providersPickerCollectionView.backgroundColor
                }
            }
        }
        private var initialProvidersPickerCollectionViewBackgroundColor: UIColor!

        private var shouldRemoveProvider = false

        private var window: UIWindow! {
            return UIApplication.sharedApplication().keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldRemoveProvider
        }

        init(viewController: WorkOrderTeamViewController) {
            super.init(target: viewController, action: "providersPickerCollectionViewCellGestureRecognized:")
            workOrderTeamViewController = viewController
            providersPickerCollectionView = viewController.providersPickerViewController.collectionView
        }

        override private var initialView: UIView! {
            didSet {
                if let initialView = initialView {
                    if initialView.isKindOfClass(PickerCollectionViewCell) {
                        collectionView = initialView.superview! as! UICollectionView
                        collectionView.scrollEnabled = false

                        initialView.frame = collectionView.convertRect(initialView.frame, toView: nil)

                        window.addSubview(initialView)
                        window.bringSubviewToFront(initialView)
                    }
                } else if let _ = oldValue {
                    providersPickerCollectionView.backgroundColor = initialProvidersPickerCollectionViewBackgroundColor

                    collectionView.scrollEnabled = true
                    collectionView = nil

                    shouldRemoveProvider = false
                }
            }
        }

        private override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
            if shouldRemoveProvider {
                let indexPath = providersPickerCollectionView.indexPathForCell(initialView as! UICollectionViewCell)!
                let supervisor = workOrderTeamViewController.providersPickerViewController.providers[indexPath.row]
                if currentUser().id == supervisor.userId {
                    workOrderTeamViewController.showToast("You can't remove yourself", dismissAfter: 2.0)
                } else {
                    workOrderTeamViewController?.removeProvider(supervisor)
                }
            }

            super.touchesEnded(touches, withEvent: event)
        }

        private override func drag(xOffset: CGFloat, yOffset: CGFloat) {
            super.drag(xOffset, yOffset: yOffset)
            
            if initialView == nil || collectionView == nil {
                return
            }
            
            let providersPickerCollectionViewFrame = providersPickerCollectionView.superview!.convertRect(providersPickerCollectionView.frame, toView: nil)
            shouldRemoveProvider = !workOrderTeamViewController.removingProvider && !CGRectIntersectsRect(initialView.frame, providersPickerCollectionViewFrame)
            
            if shouldRemoveProvider {
                let accessoryImage = FAKFontAwesome.removeIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
                (initialView as! PickerCollectionViewCell).setAccessoryImage(accessoryImage, tintColor: Color.abandonedStatusColor())
            } else {
                (initialView as! PickerCollectionViewCell).accessoryImage = nil
            }
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
