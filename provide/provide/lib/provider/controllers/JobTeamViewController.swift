//
//  JobTeamViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/11/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobTeamViewControllerDelegate {
    func jobForJobTeamViewController(viewController: JobTeamViewController) -> Job!
}

class JobTeamViewController: UITableViewController,
                             UIPopoverPresentationControllerDelegate,
                             UISearchBarDelegate,
                             ProviderPickerViewControllerDelegate,
                             ProviderCreationViewControllerDelegate,
                             DraggableViewGestureRecognizerDelegate {

    let maximumSearchlessProvidersCount = 20

    var delegate: JobTeamViewControllerDelegate! {
        didSet {
            if let _ = delegate {
                if let supervisorsPickerViewController = supervisorsPickerViewController {
                    reloadJobForProviderPickerViewController(supervisorsPickerViewController)
                }
            }
        }
    }

    private var job: Job! {
        if let job = delegate?.jobForJobTeamViewController(self) {
            return job
        }
        return nil
    }

    private var queryString: String!

    private var reloadingSupervisors = false
    private var reloadingProvidersCount = false
    private var addingSupervisor = false
    private var removingSupervisor = false

    private var totalProvidersCount = -1

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
    
    private var supervisorsPickerViewController: ProviderPickerViewController!
    private var supervisorsPickerTableViewCell: UITableViewCell! {
        if let supervisorsPickerViewController = supervisorsPickerViewController {
            return resolveTableViewCellForEmbeddedViewController(supervisorsPickerViewController)
        }
        return nil
    }

    @IBOutlet private weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Setup Team"

        searchBar?.placeholder = ""
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
        } else if segue.identifier! == "SupervisorsProviderPickerEmbedSegue" {
            supervisorsPickerViewController = segue.destinationViewController as! ProviderPickerViewController
            supervisorsPickerViewController.delegate = self
        }
    }

    func addSupervisor(supervisor: Provider) {
        if job == nil {
            return
        }

        if !job.hasSupervisor(supervisor) {
            addingSupervisor = true

            supervisorsPickerViewController?.providers.append(supervisor)
            let indexPaths = [NSIndexPath(forRow: (supervisorsPickerViewController?.providers.count)! - 1, inSection: 0)]
            supervisorsPickerViewController?.collectionView.reloadItemsAtIndexPaths(indexPaths)
            let cell = supervisorsPickerViewController?.collectionView.cellForItemAtIndexPath(indexPaths.first!) as! PickerCollectionViewCell
            cell.showActivityIndicator()

            job?.addSupervisor(supervisor,
                onSuccess: { (statusCode, mappingResult) -> () in
                    self.addingSupervisor = false
                    cell.hideActivityIndicator()
                },
                onError: { (error, statusCode, responseString) -> () in
                    self.supervisorsPickerViewController?.providers.removeObject(supervisor)
                    self.supervisorsPickerViewController?.reloadCollectionView()
                    self.addingSupervisor = false
                }
            )
        }
    }

    func removeSupervisor(supervisor: Provider) {
        if job == nil {
            return
        }

        if job.hasSupervisor(supervisor) {
            removingSupervisor = true

            let index = supervisorsPickerViewController?.providers.indexOfObject(supervisor)!
            supervisorsPickerViewController?.providers.removeAtIndex(index!)
            supervisorsPickerViewController?.reloadCollectionView()

            job?.removeSupervisor(supervisor,
                onSuccess: { (statusCode, mappingResult) -> () in
                    self.supervisorsPickerViewController?.reloadCollectionView()
                    if self.job.supervisors.count == 0 {
                        self.reloadSupervisors()
                    }
                    self.removingSupervisor = false
                },
                onError: { (error, statusCode, responseString) -> () in
                    self.supervisorsPickerViewController?.providers.insert(supervisor, atIndex: index!)
                    self.supervisorsPickerViewController?.reloadCollectionView()
                    self.removingSupervisor = false
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
        if supervisorsPickerTableViewCell != nil && numberOfSectionsInTableView(tableView) == 1 {
            return supervisorsPickerTableViewCell
        }
        return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if numberOfSectionsInTableView(tableView) == 1 {
            return "SUPERVISORS"
        } else {
            if numberOfSectionsInTableView(tableView) == 2 && showsAllProviders {
                if section == 0 {
                    return "SERVICE PROVIDERS"
                } else if section == 1 {
                    return "SUPERVISORS"
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
        if gestureRecognizer.isKindOfClass(SupervisorPickerCollectionViewCellGestureRecognizer) {
            return (gestureRecognizer as! SupervisorPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        } else if gestureRecognizer.isKindOfClass(QueryResultsPickerCollectionViewCellGestureRecognizer) {
            return (gestureRecognizer as! QueryResultsPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        }
        return true
    }

    func queryResultsPickerCollectionViewCellGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    func supervisorsPickerCollectionViewCellGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    // MARK: ProviderPickerViewControllerDelegate

    func providersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider] {
        if supervisorsPickerViewController != nil && viewController == supervisorsPickerViewController {
            if let supervisors = job?.supervisors {
                return supervisors
            } else {
                reloadJobForProviderPickerViewController(viewController)
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
//        if viewController == supervisorsPickerViewController {
//            return false
//        }
        return false
    }

    func providerPickerViewControllerCanRenderResults(viewController: ProviderPickerViewController) -> Bool {
        if supervisorsPickerViewController != nil && viewController == supervisorsPickerViewController {
            if let job = job {
                return job.supervisors != nil
            }
        } else if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
            return true
        }
        return false
    }

    func selectedProvidersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider] {
//        if supervisorsPickerViewController != nil && viewController == supervisorsPickerViewController {
//            if let supervisors = job?.supervisors {
//                return supervisors
//            } else {
//                reloadJobForProviderPickerViewController(viewController)
//            }
//        } else if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
//
//        }

        return [Provider]()
    }

    func queryParamsForProviderPickerViewController(viewController: ProviderPickerViewController) -> [String : AnyObject]! {
        if let job = job {
            if viewController == supervisorsPickerViewController {
                return ["company_id": job.companyId]
            } else if viewController == queryResultsPickerViewController {
                return ["company_id": job.companyId, "q": queryString != nil ? queryString : NSNull()]
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
                    || gestureRecognizer.isKindOfClass(SupervisorPickerCollectionViewCellGestureRecognizer) {
                    cell.removeGestureRecognizer(gestureRecognizer)
                }
            }
        }

        if viewController == supervisorsPickerViewController {
            let gestureRecognizer = SupervisorPickerCollectionViewCellGestureRecognizer(viewController: self)
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

    private func reloadJobForProviderPickerViewController(viewController: ProviderPickerViewController) {
        if viewController == supervisorsPickerViewController && job != nil {
            reloadProviders()
            reloadSupervisors()
        }
    }

    private func reloadProviders() {
        reloadingProvidersCount = true

        if let companyId = job?.companyId {
            queryResultsPickerViewController?.providers = [Provider]()
            queryResultsPickerViewController?.showActivityIndicator()
            tableView.reloadData()

            ApiService.sharedService().countProviders(["company_id": job.companyId],
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

    private func reloadSupervisors() {
        reloadingSupervisors = true

        job?.reloadSupervisors(
            { (statusCode, mappingResult) -> () in
                self.supervisorsPickerViewController.providers = self.job.supervisors
                self.supervisorsPickerViewController.reloadCollectionView()
                self.reloadingSupervisors = false
            },
            onError: { (error, statusCode, responseString) -> () in
                self.supervisorsPickerViewController.reloadCollectionView()
                self.reloadingSupervisors = false
            }
        )
    }

    private class QueryResultsPickerCollectionViewCellGestureRecognizer: DraggableViewGestureRecognizer {
        private var collectionView: UICollectionView!

        private var jobTeamViewController: JobTeamViewController!

        private var supervisorsPickerCollectionView: UICollectionView! {
            didSet {
                if let supervisorsPickerCollectionView = supervisorsPickerCollectionView {
                    initialSupervisorsPickerCollectionViewBackgroundColor = supervisorsPickerCollectionView.backgroundColor
                }
            }
        }
        private var initialSupervisorsPickerCollectionViewBackgroundColor: UIColor!

        private var shouldAddSupervisor = false

        private var window: UIWindow! {
            return UIApplication.sharedApplication().keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldAddSupervisor
        }

        init(viewController: JobTeamViewController) {
            super.init(target: viewController, action: "queryResultsPickerCollectionViewCellGestureRecognized:")
            jobTeamViewController = viewController
            supervisorsPickerCollectionView = viewController.supervisorsPickerViewController.collectionView
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
                } else if let initialView = oldValue {
                    supervisorsPickerCollectionView.backgroundColor = initialSupervisorsPickerCollectionViewBackgroundColor

                    if shouldAddSupervisor {
                        let indexPath = jobTeamViewController.queryResultsPickerViewController.collectionView.indexPathForCell(initialView as! UICollectionViewCell)!
                        jobTeamViewController?.addSupervisor(jobTeamViewController.queryResultsPickerViewController.providers[indexPath.row])
                    }

                    collectionView.scrollEnabled = true
                    collectionView = nil

                    shouldAddSupervisor = false
                }
            }
        }

        private override func drag(xOffset: CGFloat, yOffset: CGFloat) {
            super.drag(xOffset, yOffset: yOffset)

            if initialView == nil || collectionView == nil {
                return
            }

            if jobTeamViewController.searchBar.isFirstResponder() {
                jobTeamViewController.searchBar.resignFirstResponder()
            }

            let supervisorsPickerCollectionViewFrame = supervisorsPickerCollectionView.superview!.convertRect(supervisorsPickerCollectionView.frame, toView: nil)
            shouldAddSupervisor = !jobTeamViewController.addingSupervisor && CGRectIntersectsRect(initialView.frame, supervisorsPickerCollectionViewFrame)

            if shouldAddSupervisor {
                supervisorsPickerCollectionView.backgroundColor = Color.completedStatusColor().colorWithAlphaComponent(0.8)
            } else {
                supervisorsPickerCollectionView.backgroundColor = initialSupervisorsPickerCollectionViewBackgroundColor
            }
        }
    }

    private class SupervisorPickerCollectionViewCellGestureRecognizer: DraggableViewGestureRecognizer {
        private var collectionView: UICollectionView!

        private var jobTeamViewController: JobTeamViewController!

        private var supervisorsPickerCollectionView: UICollectionView! {
            didSet {
                if let supervisorsPickerCollectionView = supervisorsPickerCollectionView {
                    initialSupervisorsPickerCollectionViewBackgroundColor = supervisorsPickerCollectionView.backgroundColor
                }
            }
        }
        private var initialSupervisorsPickerCollectionViewBackgroundColor: UIColor!

        private var shouldRemoveSupervisor = false

        private var window: UIWindow! {
            return UIApplication.sharedApplication().keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldRemoveSupervisor
        }

        init(viewController: JobTeamViewController) {
            super.init(target: viewController, action: "supervisorsPickerCollectionViewCellGestureRecognized:")
            jobTeamViewController = viewController
            supervisorsPickerCollectionView = viewController.supervisorsPickerViewController.collectionView
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
                    supervisorsPickerCollectionView.backgroundColor = initialSupervisorsPickerCollectionViewBackgroundColor

                    collectionView.scrollEnabled = true
                    collectionView = nil

                    shouldRemoveSupervisor = false
                }
            }
        }

        private override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
            if shouldRemoveSupervisor {
                let indexPath = supervisorsPickerCollectionView.indexPathForCell(initialView as! UICollectionViewCell)!
                let supervisor = jobTeamViewController.supervisorsPickerViewController.providers[indexPath.row]
                if currentUser().id == supervisor.userId {
                    jobTeamViewController.showToast("You can't remove yourself", dismissAfter: 2.0)
                } else {
                    jobTeamViewController?.removeSupervisor(supervisor)
                }
            }

            super.touchesEnded(touches, withEvent: event)
        }

        private override func drag(xOffset: CGFloat, yOffset: CGFloat) {
            super.drag(xOffset, yOffset: yOffset)

            if initialView == nil || collectionView == nil {
                return
            }

            let supervisorsPickerCollectionViewFrame = supervisorsPickerCollectionView.superview!.convertRect(supervisorsPickerCollectionView.frame, toView: nil)
            shouldRemoveSupervisor = !jobTeamViewController.removingSupervisor && !CGRectIntersectsRect(initialView.frame, supervisorsPickerCollectionViewFrame)

            if shouldRemoveSupervisor {
                let accessoryImage = FAKFontAwesome.removeIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
                (initialView as! PickerCollectionViewCell).setAccessoryImage(accessoryImage, tintColor: Color.abandonedStatusColor())
            } else {
                (initialView as! PickerCollectionViewCell).accessoryImage = nil
            }
        }
    }
}
