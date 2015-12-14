//
//  JobInventoryViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/11/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobInventoryViewControllerDelegate {
    func jobForJobInventoryViewController(viewController: JobInventoryViewContoller) -> Job!
}

class JobInventoryViewContoller: UITableViewController, UISearchBarDelegate, ManifestViewControllerDelegate {

    let maximumSearchlessProductsCount = 25

    var delegate: JobInventoryViewControllerDelegate! {
        didSet {
            if let _ = delegate {
                if let jobManifestViewController = jobManifestViewController {
                    reloadJobForManifestViewController(jobManifestViewController)
                }
            }
        }
    }

    private var job: Job! {
        if let job = delegate?.jobForJobInventoryViewController(self) {
            return job
        }
        return nil
    }

    private var queryString: String!

    private var reloadingJobManifest = false
    private var reloadingProductsCount = false

    private var totalProductsCount = -1

    private var showsAllProducts: Bool {
        return totalProductsCount == -1 || totalProductsCount <= maximumSearchlessProductsCount
    }

    private var renderQueryResults: Bool {
        return queryString != nil || showsAllProducts
    }

    private var queryResultsManifestViewController: ManifestViewController!
    private var queryResultsManifestTableViewCell: UITableViewCell! {
        if let queryResultsManifestViewController = queryResultsManifestViewController {
            return resolveTableViewCellForEmbeddedViewController(queryResultsManifestViewController)
        }
        return nil
    }

    private var jobManifestViewController: ManifestViewController!
    private var jobManifestTableViewCell: UITableViewCell! {
        if let jobManifestViewController = jobManifestViewController {
            return resolveTableViewCellForEmbeddedViewController(jobManifestViewController)
        }
        return nil
    }

    @IBOutlet private weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Setup Inventory"

        searchBar?.placeholder = ""
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "QueryResultsManifestEmbedSegue" {
            queryResultsManifestViewController = segue.destinationViewController as! ManifestViewController
            queryResultsManifestViewController.delegate = self
        } else if segue.identifier! == "JobManifestEmbedSegue" {
            jobManifestViewController = segue.destinationViewController as! ManifestViewController
            jobManifestViewController.delegate = self
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
        if numberOfSectionsInTableView(tableView) == 1 {
            return jobManifestTableViewCell
        }
        return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if numberOfSectionsInTableView(tableView) == 1 {
            return "JOB MANIFEST"
        } else {
            if numberOfSectionsInTableView(tableView) == 2 && showsAllProducts {
                if section == 0 {
                    return "PRODUCTS"
                } else if section == 1 {
                    return "JOB MANIFEST"
                }
            }
        }
        return super.tableView(tableView, titleForHeaderInSection: section)
    }

    // MARK: UISearchBarDelegate

    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        return !showsAllProducts
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        queryString = searchText
        if queryString.replaceString(" ", withString: "").length == 0 {
            queryString = nil
//            queryResultsPickerViewController? = [Provider]()
            tableView.reloadData()
        } else {
            tableView.reloadData()
            queryResultsManifestViewController?.reset()
        }
    }

    // MARK: ManifestViewControllerDelegate

    func workOrderForManifestViewController(viewController: UIViewController) -> WorkOrder! {
        return nil
    }

    func segmentsForManifestViewController(viewController: UIViewController) -> [String]! {
        return ["JOB MANIFEST"]
    }

    func jobForManifestViewController(viewController: UIViewController) -> Job! {
        return job
    }

    func itemsForManifestViewController(viewController: UIViewController, forSegmentIndex segmentIndex: Int) -> [Product]! {
        let manifestViewController = viewController as! ManifestViewController
        return jobProductsForManifestViewController(manifestViewController, forSegmentIndex: segmentIndex).map({ $0.product })
    }

    func manifestViewController(viewController: UIViewController, tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier("jobProductTableViewCell") as! JobProductTableViewCell
        let manifestViewController = viewController as! ManifestViewController
        cell.jobProduct = jobProductsForManifestViewController(manifestViewController, forSegmentIndex: manifestViewController.selectedSegmentIndex)[indexPath.row]
        return cell
    }

    func manifestViewController(viewController: UIViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let manifestViewController = viewController as! ManifestViewController
        let jobProduct = jobProductsForManifestViewController(manifestViewController, forSegmentIndex: manifestViewController.selectedSegmentIndex)[indexPath.row]
        print("selected job product \(jobProduct)")
    }

    func queryParamsForManifestViewController(viewController: UIViewController) -> [String : AnyObject]! {
        if viewController == queryResultsManifestViewController {
            return ["company_id": job.companyId, "q": queryString != nil ? queryString : NSNull()]
        }
        return nil
    }

    private func jobProductsForManifestViewController(viewController: ManifestViewController, forSegmentIndex segmentIndex: Int) -> [JobProduct] {
        if segmentIndex > -1 {
            // job manifest
            if segmentIndex == 0 {
                if let job = job {
                    if let _ = job.materials {
                        return job.materials
                    } else {
                        reloadJobForManifestViewController(viewController)
                    }
                } else {
                    reloadJobForManifestViewController(viewController)
                }
            } else if segmentIndex == 1 {
                // no-op
            }
        }

        return [JobProduct]()
    }

    private func reloadJobForManifestViewController(viewController: ManifestViewController) {
        if !reloadingJobManifest {
            if let job = job {
                dispatch_async_main_queue {
                    viewController.showActivityIndicator()
                }

                reloadingJobManifest = true

                reloadProducts()

                job.reloadMaterials(
                    { (statusCode, mappingResult) -> () in
                        viewController.reloadTableView()
                        self.reloadingJobManifest = false
                    },
                    onError: { (error, statusCode, responseString) -> () in
                        viewController.reloadTableView()
                        self.reloadingJobManifest = false
                    }
                )
            }
        }
    }

    private func reloadProducts() {
        reloadingProductsCount = true

        if let companyId = job?.companyId {
            queryResultsManifestViewController?.products = [Product]()
            queryResultsManifestViewController?.showActivityIndicator()
            tableView.reloadData()

            ApiService.sharedService().countProducts(["company_id": job.companyId],
                onTotalResultsCount: { totalResultsCount, error in
                    self.totalProductsCount = totalResultsCount
                    if totalResultsCount > -1 {
                        if totalResultsCount <= self.maximumSearchlessProductsCount {
                            ApiService.sharedService().fetchProducts(["company_id": companyId, "page": 1, "rpp": totalResultsCount],
                                onSuccess: { (statusCode, mappingResult) -> () in
                                    self.queryResultsManifestViewController?.products = mappingResult.array() as! [Product]
                                    self.tableView.reloadData()
                                    self.searchBar.placeholder = "Showing all \(totalResultsCount) products"
                                    self.reloadingProductsCount = false
                                },
                                onError: { (error, statusCode, responseString) -> () in
                                    self.queryResultsManifestViewController?.products = [Product]()
                                    self.tableView.reloadData()
                                    self.reloadingProductsCount = false
                            })
                        } else {
                            self.searchBar.placeholder = "Search \(totalResultsCount) products"
                            self.tableView.reloadData()
                            self.reloadingProductsCount = false
                        }
                    }
                }
            )
        }
    }
}
