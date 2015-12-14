//
//  JobTeamViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/11/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobTeamViewControllerDelegate {
    func jobForJobTeamViewController(viewController: JobTeamViewContoller) -> Job!
}

class JobTeamViewContoller: UITableViewController,
                            UIPopoverPresentationControllerDelegate,
                            UISearchBarDelegate,
                            ProviderPickerViewControllerDelegate {

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
        } else if segue.identifier! == "QueryResultsProviderPickerEmbedSegue" {
            queryResultsPickerViewController = segue.destinationViewController as! ProviderPickerViewController
            queryResultsPickerViewController.delegate = self
        } else if segue.identifier! == "SupervisorsProviderPickerEmbedSegue" {
            supervisorsPickerViewController = segue.destinationViewController as! ProviderPickerViewController
            supervisorsPickerViewController.delegate = self
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

    func collectionViewScrollDirectionForPickerViewController(viewController: ProviderPickerViewController) -> UICollectionViewScrollDirection {
        return .Horizontal
    }

    private func reloadJobForProviderPickerViewController(viewController: ProviderPickerViewController) {
        if viewController == supervisorsPickerViewController && job != nil {
            reloadingSupervisors = true

            reloadProviders()

            job?.reloadSupervisors(
                { (statusCode, mappingResult) -> () in
                    viewController.providers = self.job.supervisors
                    viewController.reloadCollectionView()
                    self.reloadingSupervisors = false
                },
                onError: { (error, statusCode, responseString) -> () in
                    viewController.reloadCollectionView()
                    self.reloadingSupervisors = false
                }
            )
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
                            })
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
}
