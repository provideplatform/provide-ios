//
//  JobTeamViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/11/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import FontAwesomeKit
import KTSwiftExtensions

protocol JobTeamViewControllerDelegate: NSObjectProtocol {
    func jobForJobTeamViewController(_ viewController: JobTeamViewController) -> Job!
}

class JobTeamViewController: UITableViewController,
                             UIPopoverPresentationControllerDelegate,
                             UISearchBarDelegate,
                             ProviderPickerViewControllerDelegate,
                             ProviderCreationViewControllerDelegate,
                             KTDraggableViewGestureRecognizerDelegate {

    fileprivate let jobSupervisorOperationQueue = DispatchQueue(label: "api.jobSupervisorOperationQueue", attributes: [])

    let maximumSearchlessProvidersCount = 20

    weak var delegate: JobTeamViewControllerDelegate! {
        didSet {
            if let _ = delegate {
                if let supervisorsPickerViewController = supervisorsPickerViewController {
                    reloadJobForProviderPickerViewController(supervisorsPickerViewController)
                }
            }
        }
    }

    fileprivate var job: Job! {
        if let job = delegate?.jobForJobTeamViewController(self) {
            return job
        }
        return nil
    }

    fileprivate var queryString: String!

    fileprivate var reloadingSupervisors = false
    fileprivate var reloadingProvidersCount = false
    fileprivate var addingSupervisor = false
    fileprivate var removingSupervisor = false

    fileprivate var totalProvidersCount = -1

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
    
    fileprivate var supervisorsPickerViewController: ProviderPickerViewController!
    fileprivate var supervisorsPickerTableViewCell: UITableViewCell! {
        if let supervisorsPickerViewController = supervisorsPickerViewController {
            return resolveTableViewCellForEmbeddedViewController(supervisorsPickerViewController)
        }
        return nil
    }

    @IBOutlet fileprivate weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Setup Team"

        searchBar?.placeholder = ""
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier == "ProviderCreationViewControllerPopoverSegue" {
            if !isIPad() {
                segue.destination.preferredContentSize = CGSize(width: 400, height: 500)
                segue.destination.popoverPresentationController!.delegate = self
            }
            ((segue.destination as! UINavigationController).viewControllers.first! as! ProviderCreationViewController).delegate = self
        } else if segue.identifier! == "QueryResultsProviderPickerEmbedSegue" {
            queryResultsPickerViewController = segue.destination as! ProviderPickerViewController
            queryResultsPickerViewController.delegate = self
        } else if segue.identifier! == "SupervisorsProviderPickerEmbedSegue" {
            supervisorsPickerViewController = segue.destination as! ProviderPickerViewController
            supervisorsPickerViewController.delegate = self
        }
    }

    func addSupervisor(_ supervisor: Provider) {
        if job == nil {
            return
        }

        if !job.hasSupervisor(supervisor) {
            supervisorsPickerViewController?.providers.append(supervisor)
            let indexPaths = [IndexPath(row: (supervisorsPickerViewController?.providers.count)! - 1, section: 0)]
            supervisorsPickerViewController?.collectionView.reloadItems(at: indexPaths)
            let cell = supervisorsPickerViewController?.collectionView.cellForItem(at: indexPaths.first!) as! PickerCollectionViewCell
            cell.showActivityIndicator()

            jobSupervisorOperationQueue.async {
                while self.addingSupervisor { }

                self.addingSupervisor = true

                self.job?.addSupervisor(supervisor,
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
    }

    func removeSupervisor(_ supervisor: Provider) {
        if job == nil {
            return
        }

        if job.hasSupervisor(supervisor) {
            let index = supervisorsPickerViewController?.providers.indexOfObject(supervisor)!
            supervisorsPickerViewController?.providers.remove(at: index!)
            supervisorsPickerViewController?.reloadCollectionView()

            jobSupervisorOperationQueue.async {
                while self.removingSupervisor { }

                self.removingSupervisor = true

                self.job?.removeSupervisor(supervisor,
                    onSuccess: { (statusCode, mappingResult) -> () in
                        self.supervisorsPickerViewController?.reloadCollectionView()
                        if self.job.supervisors.count == 0 {
                            self.reloadSupervisors()
                        }
                        self.removingSupervisor = false
                    },
                    onError: { (error, statusCode, responseString) -> () in
                        self.supervisorsPickerViewController?.providers.insert(supervisor, at: index!)
                        self.supervisorsPickerViewController?.reloadCollectionView()
                        self.removingSupervisor = false
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
        if supervisorsPickerTableViewCell != nil && numberOfSections(in: tableView) == 1 {
            return supervisorsPickerTableViewCell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if numberOfSections(in: tableView) == 1 {
            return "SUPERVISORS"
        } else {
            if numberOfSections(in: tableView) == 2 && showsAllProviders {
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
        if gestureRecognizer.isKind(of: SupervisorPickerCollectionViewCellGestureRecognizer.self) {
            return (gestureRecognizer as! SupervisorPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        } else if gestureRecognizer.isKind(of: QueryResultsPickerCollectionViewCellGestureRecognizer.self) {
            return (gestureRecognizer as! QueryResultsPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        }
        return true
    }

    func queryResultsPickerCollectionViewCellGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    func supervisorsPickerCollectionViewCellGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    // MARK: ProviderPickerViewControllerDelegate

    func providersForPickerViewController(_ viewController: ProviderPickerViewController) -> [Provider] {
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

    func providerPickerViewController(_ viewController: ProviderPickerViewController, didSelectProvider provider: Provider) {

    }

    func providerPickerViewController(_ viewController: ProviderPickerViewController, didDeselectProvider provider: Provider) {

    }

    func providerPickerViewControllerAllowsMultipleSelection(_ viewController: ProviderPickerViewController) -> Bool {
//        if viewController == supervisorsPickerViewController {
//            return false
//        }
        return false
    }

    func providerPickerViewControllerCanRenderResults(_ viewController: ProviderPickerViewController) -> Bool {
        if supervisorsPickerViewController != nil && viewController == supervisorsPickerViewController {
            if let job = job {
                return job.supervisors != nil
            }
        } else if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
            return true
        }
        return false
    }

    func selectedProvidersForPickerViewController(_ viewController: ProviderPickerViewController) -> [Provider] {
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

    func queryParamsForProviderPickerViewController(_ viewController: ProviderPickerViewController) -> [String : AnyObject]! {
        if let job = job {
            if viewController == supervisorsPickerViewController {
                return ["company_id": job.companyId as AnyObject]
            } else if viewController == queryResultsPickerViewController {
                return ["company_id": job.companyId as AnyObject, "q": queryString != nil ? queryString as AnyObject : NSNull() as AnyObject]
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
                cell.gravatarEmail = provider.contact.email
            }
        }

        if let gestureRecognizers = cell.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if gestureRecognizer.isKind(of: QueryResultsPickerCollectionViewCellGestureRecognizer.self)
                    || gestureRecognizer.isKind(of: SupervisorPickerCollectionViewCellGestureRecognizer.self) {
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

    fileprivate func reloadJobForProviderPickerViewController(_ viewController: ProviderPickerViewController) {
        if let supervisorsPickerViewController = supervisorsPickerViewController {
            if viewController == supervisorsPickerViewController && job != nil {
                reloadProviders()
                reloadSupervisors()
            }
        }
    }

    fileprivate func reloadProviders() {
        reloadingProvidersCount = true

        if let companyId = job?.companyId {
            queryResultsPickerViewController?.providers = [Provider]()
            queryResultsPickerViewController?.showActivityIndicator()
            tableView.reloadData()

            ApiService.sharedService().countProviders(["company_id": job.companyId as AnyObject],
                onTotalResultsCount: { totalResultsCount, error in
                    self.totalProvidersCount = totalResultsCount
                    if totalResultsCount > -1 {
                        if totalResultsCount <= self.maximumSearchlessProvidersCount {
                            ApiService.sharedService().fetchProviders(["company_id": companyId as AnyObject, "page": 1 as AnyObject, "rpp": totalResultsCount as AnyObject],
                                onSuccess: { (statusCode, mappingResult) -> () in
                                    self.queryResultsPickerViewController?.providers = mappingResult?.array() as! [Provider]
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

    fileprivate func reloadSupervisors() {
        jobSupervisorOperationQueue.async {
            while self.reloadingSupervisors { }

            self.reloadingSupervisors = true

            self.job?.reloadSupervisors(
                { statusCode, mappingResult in
                    self.supervisorsPickerViewController?.providers = self.job.supervisors
                    self.supervisorsPickerViewController?.reloadCollectionView()
                    self.reloadingSupervisors = false
                },
                onError: { error, statusCode, responseString in
                    self.supervisorsPickerViewController?.reloadCollectionView()
                    self.reloadingSupervisors = false
                }
            )
        }
    }

    // MARK: QueryResultsPickerCollectionViewCellGestureRecognizer

    fileprivate class QueryResultsPickerCollectionViewCellGestureRecognizer: KTDraggableViewGestureRecognizer {
        fileprivate var collectionView: UICollectionView!

        fileprivate var jobTeamViewController: JobTeamViewController!

        fileprivate var supervisorsPickerCollectionView: UICollectionView! {
            didSet {
                if let supervisorsPickerCollectionView = supervisorsPickerCollectionView {
                    initialSupervisorsPickerCollectionViewBackgroundColor = supervisorsPickerCollectionView.backgroundColor
                }
            }
        }
        fileprivate var initialSupervisorsPickerCollectionViewBackgroundColor: UIColor!

        fileprivate var shouldAddSupervisor = false

        fileprivate var window: UIWindow! {
            return UIApplication.shared.keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldAddSupervisor
        }

        init(viewController: JobTeamViewController) {
            super.init(target: viewController, action: #selector(JobTeamViewController.queryResultsPickerCollectionViewCellGestureRecognized(_:)))
            jobTeamViewController = viewController
            supervisorsPickerCollectionView = viewController.supervisorsPickerViewController.collectionView
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
                } else if let initialView = oldValue {
                    supervisorsPickerCollectionView.backgroundColor = initialSupervisorsPickerCollectionViewBackgroundColor

                    if shouldAddSupervisor {
                        let indexPath = jobTeamViewController.queryResultsPickerViewController.collectionView.indexPath(for: initialView as! UICollectionViewCell)!
                        jobTeamViewController?.addSupervisor(jobTeamViewController.queryResultsPickerViewController.providers[(indexPath as NSIndexPath).row])
                    }

                    collectionView.isScrollEnabled = true
                    collectionView = nil

                    shouldAddSupervisor = false
                }
            }
        }

        override func drag(_ xOffset: CGFloat, yOffset: CGFloat) {
            super.drag(xOffset, yOffset: yOffset)

            if initialView == nil || collectionView == nil {
                return
            }

            if jobTeamViewController.searchBar.isFirstResponder {
                jobTeamViewController.searchBar.resignFirstResponder()
            }

            let supervisorsPickerCollectionViewFrame = supervisorsPickerCollectionView.superview!.convert(supervisorsPickerCollectionView.frame, to: nil)
            shouldAddSupervisor = initialView.frame.intersects(supervisorsPickerCollectionViewFrame)

            if shouldAddSupervisor {
                supervisorsPickerCollectionView.backgroundColor = Color.completedStatusColor().withAlphaComponent(0.8)
            } else {
                supervisorsPickerCollectionView.backgroundColor = initialSupervisorsPickerCollectionViewBackgroundColor
            }
        }
    }

    // MARK: SupervisorPickerCollectionViewCellGestureRecognizer

    fileprivate class SupervisorPickerCollectionViewCellGestureRecognizer: KTDraggableViewGestureRecognizer {
        fileprivate var collectionView: UICollectionView!

        fileprivate var jobTeamViewController: JobTeamViewController!

        fileprivate var supervisorsPickerCollectionView: UICollectionView! {
            didSet {
                if let supervisorsPickerCollectionView = supervisorsPickerCollectionView {
                    initialSupervisorsPickerCollectionViewBackgroundColor = supervisorsPickerCollectionView.backgroundColor
                }
            }
        }
        fileprivate var initialSupervisorsPickerCollectionViewBackgroundColor: UIColor!

        fileprivate var shouldRemoveSupervisor = false

        fileprivate var window: UIWindow! {
            return UIApplication.shared.keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldRemoveSupervisor
        }

        init(viewController: JobTeamViewController) {
            super.init(target: viewController, action: #selector(JobTeamViewController.supervisorsPickerCollectionViewCellGestureRecognized(_:)))
            jobTeamViewController = viewController
            supervisorsPickerCollectionView = viewController.supervisorsPickerViewController.collectionView
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
                    supervisorsPickerCollectionView.backgroundColor = initialSupervisorsPickerCollectionViewBackgroundColor

                    collectionView.isScrollEnabled = true
                    collectionView = nil

                    shouldRemoveSupervisor = false
                }
            }
        }

        fileprivate override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            if shouldRemoveSupervisor {
                let indexPath = supervisorsPickerCollectionView.indexPath(for: initialView as! UICollectionViewCell)!
                let supervisor = jobTeamViewController.supervisorsPickerViewController.providers[(indexPath as NSIndexPath).row]
                if currentUser().id == supervisor.userId {
                    jobTeamViewController.showToast("You can't remove yourself", dismissAfter: 2.0)
                } else {
                    jobTeamViewController?.removeSupervisor(supervisor)
                }
            }

            super.touchesEnded(touches, with: event)
        }

        fileprivate override func drag(_ xOffset: CGFloat, yOffset: CGFloat) {
            super.drag(xOffset, yOffset: yOffset)

            if initialView == nil || collectionView == nil {
                return
            }

            let supervisorsPickerCollectionViewFrame = supervisorsPickerCollectionView.superview!.convert(supervisorsPickerCollectionView.frame, to: nil)
            shouldRemoveSupervisor = !initialView.frame.intersects(supervisorsPickerCollectionViewFrame)

            if shouldRemoveSupervisor {
                let accessoryImage = FAKFontAwesome.removeIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
                (initialView as! PickerCollectionViewCell).setAccessoryImage(accessoryImage, tintColor: Color.abandonedStatusColor())
            } else {
                (initialView as! PickerCollectionViewCell).accessoryImage = nil
            }
        }
    }
}
