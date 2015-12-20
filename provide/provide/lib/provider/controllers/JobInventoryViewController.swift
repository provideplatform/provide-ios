//
//  JobInventoryViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/11/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobInventoryViewControllerDelegate: NSObjectProtocol {
    func jobForJobInventoryViewController(viewController: JobInventoryViewContoller) -> Job!
}

class JobInventoryViewContoller: UITableViewController,
                                 UISearchBarDelegate,
                                 DraggableViewGestureRecognizerDelegate,
                                 ProductCreationViewControllerDelegate,
                                 ProductPickerViewControllerDelegate,
                                 JobProductCreationViewControllerDelegate,
                                 ManifestViewControllerDelegate {

    private let jobProductOperationQueue = dispatch_queue_create("api.jobProductOperationQueue", DISPATCH_QUEUE_SERIAL)

    let maximumSearchlessProductsCount = 25

    weak var delegate: JobInventoryViewControllerDelegate! {
        didSet {
            if let _ = delegate {
                if let jobProductsPickerViewController = jobProductsPickerViewController {
                    reloadJobProductsForPickerViewController(jobProductsPickerViewController)
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

    private var reloadingJobProducts = false
    private var reloadingProductsCount = false

    private var totalProductsCount = -1

    private var addingJobProduct = false
    private var removingJobProduct = false

    private var showsAllProducts: Bool {
        return totalProductsCount == -1 || totalProductsCount <= maximumSearchlessProductsCount
    }

    private var renderQueryResults: Bool {
        return queryString != nil || showsAllProducts
    }

    private var queryResultsPickerViewController: ProductPickerViewController!
    private var queryResultsPickerTableViewCell: UITableViewCell! {
        if let queryResultsPickerViewController = queryResultsPickerViewController {
            return resolveTableViewCellForEmbeddedViewController(queryResultsPickerViewController)
        }
        return nil
    }

    private var jobProductsPickerViewController: ProductPickerViewController!
    private var jobProductsTableViewCell: UITableViewCell! {
        if let jobProductsPickerViewController = jobProductsPickerViewController {
            return resolveTableViewCellForEmbeddedViewController(jobProductsPickerViewController)
        }
        return nil
    }

    @IBOutlet private weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Setup Inventory"

        searchBar?.placeholder = ""
    }

    func addJobProduct(product: Product) {
        if job == nil {
            return
        }

        var jobProduct = job.jobProductForProduct(product)
        if jobProduct == nil {
            jobProductsPickerViewController?.products.append(product)
            let indexPaths = [NSIndexPath(forRow: (jobProductsPickerViewController?.products.count)! - 1, inSection: 0)]
            jobProductsPickerViewController?.collectionView.reloadItemsAtIndexPaths(indexPaths)
            let cell = jobProductsPickerViewController?.collectionView.cellForItemAtIndexPath(indexPaths.first!) as! PickerCollectionViewCell
            cell.showActivityIndicator()

            let params: [String : AnyObject] = [:]

            dispatch_async(jobProductOperationQueue) { [weak self] in
                while self!.addingJobProduct { }

                self!.addingJobProduct = true

                self!.job?.addJobProductForProduct(product, params: params,
                    onSuccess: { [weak self] statusCode, mappingResult in
                        cell.hideActivityIndicator()

                        jobProduct = self!.job.jobProductForProduct(product)

                        let jobProductCreationViewController = UIStoryboard("ProductCreation").instantiateViewControllerWithIdentifier("JobProductCreationViewController") as! JobProductCreationViewController
                        jobProductCreationViewController.job = self!.job
                        jobProductCreationViewController.jobProduct = jobProduct
                        jobProductCreationViewController.jobProductCreationViewControllerDelegate = self!
                        jobProductCreationViewController.modalPresentationStyle = .Popover
                        jobProductCreationViewController.preferredContentSize = CGSizeMake(300, 250)
                        jobProductCreationViewController.popoverPresentationController!.sourceView = cell
                        jobProductCreationViewController.popoverPresentationController!.permittedArrowDirections = [.Left, .Right]
                        jobProductCreationViewController.popoverPresentationController!.canOverlapSourceViewRect = false
                        self!.presentViewController(jobProductCreationViewController, animated: true) {
                            self!.addingJobProduct = false
                        }
                    },
                    onError: { [weak self] error, statusCode, responseString in
                        self!.jobProductsPickerViewController?.products.removeObject(product)
                        self!.jobProductsPickerViewController?.reloadCollectionView()
                        self!.addingJobProduct = false
                    }
                )
            }


        }
    }

    func removeJobProduct(product: Product) {
        if job == nil {
            return
        }

        if let jobProduct = job.jobProductForProduct(product) {
            dispatch_async(jobProductOperationQueue) { [weak self] in
                while self!.removingJobProduct { }

                self!.removingJobProduct = true

                self!.job?.removeJobProduct(jobProduct,
                    onSuccess: { (statusCode, mappingResult) -> () in
                        self!.jobProductsPickerViewController?.products = self!.job.materials.map({ $0.product })
                        self!.jobProductsPickerViewController?.reloadCollectionView()
                        self!.removingJobProduct = false
                    },
                    onError: { (error, statusCode, responseString) -> () in
                        self!.jobProductsPickerViewController?.products.append(product)
                        self!.jobProductsPickerViewController?.reloadCollectionView()
                        self!.removingJobProduct = false
                    }
                )
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "ProductCreationViewControllerPopoverSegue" {
            segue.destinationViewController.preferredContentSize = CGSizeMake(400, 500)
            ((segue.destinationViewController as! UINavigationController).viewControllers.first! as! ProductCreationViewController).delegate = self
        } else if segue.identifier! == "QueryResultsProductPickerEmbedSegue" {
            queryResultsPickerViewController = segue.destinationViewController as! ProductPickerViewController
            queryResultsPickerViewController.delegate = self
        } else if segue.identifier! == "JobProductsProductPickerEmbedSegue" {
            jobProductsPickerViewController = segue.destinationViewController as! ProductPickerViewController
            jobProductsPickerViewController.delegate = self
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
        if jobProductsTableViewCell != nil && numberOfSectionsInTableView(tableView) == 1 {
            return jobProductsTableViewCell
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
            queryResultsPickerViewController?.products = [Product]()
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
        if gestureRecognizer.isKindOfClass(JobProductsPickerCollectionViewCellGestureRecognizer) {
            return (gestureRecognizer as! JobProductsPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        } else if gestureRecognizer.isKindOfClass(QueryResultsPickerCollectionViewCellGestureRecognizer) {
            return (gestureRecognizer as! QueryResultsPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        }
        return true
    }

    func queryResultsPickerCollectionViewCellGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    func jobProductsPickerCollectionViewCellGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    // MARK: ProductCreationViewControllerDelegate

    func productCreationViewController(viewController: ProductCreationViewController, didCreateProduct product: Product) {
        dismissViewController(animated: true)

        if totalProductsCount > -1 {
            totalProductsCount++

            if showsAllProducts {
                queryResultsPickerViewController?.products.append(product)
                queryResultsPickerViewController?.reloadCollectionView()

                searchBar.placeholder = "Showing all \(totalProductsCount) products"
            } else {
                searchBar.placeholder = "Search \(totalProductsCount) products"
            }
        }
    }

    // MARK: ProductPickerViewControllerDelegate

    func queryParamsForProductPickerViewController(viewController: ProductPickerViewController) -> [String : AnyObject]! {
        if let job = job {
            if viewController == jobProductsPickerViewController {
                return ["job_id": job.id, "company_id": job.companyId]
            } else if viewController == queryResultsPickerViewController {
                return ["company_id": job.companyId, "q": queryString != nil ? queryString : NSNull()]
            }
        }
        return nil
    }

    func productPickerViewController(viewController: ProductPickerViewController, didSelectProduct product: Product) {

    }

    func productPickerViewController(viewController: ProductPickerViewController, didDeselectProduct: Product) {

    }

    func productPickerViewControllerAllowsMultipleSelection(viewController: ProductPickerViewController) -> Bool {
        return false
    }

    func productsForPickerViewController(viewController: ProductPickerViewController) -> [Product] {
        return [Product]()
    }

    func selectedProductsForPickerViewController(viewController: ProductPickerViewController) -> [Product] {
        return [Product]()
    }

    func collectionViewScrollDirectionForPickerViewController(viewController: ProductPickerViewController) -> UICollectionViewScrollDirection {
        return .Horizontal
    }

    func productPickerViewControllerCanRenderResults(viewController: ProductPickerViewController) -> Bool {
        if jobProductsPickerViewController != nil && viewController == jobProductsPickerViewController {
            if let job = job {
                return job.materials != nil
            }
        } else if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
            return true
        }
        return false
    }

    func productPickerViewController(viewController: ProductPickerViewController, collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PickerCollectionViewCell", forIndexPath: indexPath) as! PickerCollectionViewCell
        let products = viewController.products

        if products.count > indexPath.row - 1 {
            let product = products[indexPath.row]

            cell.selected = viewController.isSelected(product)

            if cell.selected {
                collectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: .None)
            }

            cell.name = product.name

            if let profileImageUrl = product.barcodeDataURL {
                cell.rendersCircularImage = false
                cell.imageUrl = profileImageUrl
            }
        }

        if let gestureRecognizers = cell.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if gestureRecognizer.isKindOfClass(QueryResultsPickerCollectionViewCellGestureRecognizer)
                    || gestureRecognizer.isKindOfClass(JobProductsPickerCollectionViewCellGestureRecognizer) {
                    cell.removeGestureRecognizer(gestureRecognizer)
                }
            }
        }

        if viewController == jobProductsPickerViewController {
            let gestureRecognizer = JobProductsPickerCollectionViewCellGestureRecognizer(viewController: self)
            gestureRecognizer.draggableViewGestureRecognizerDelegate = self
            cell.addGestureRecognizer(gestureRecognizer)
        } else if viewController == queryResultsPickerViewController {
            let gestureRecognizer = QueryResultsPickerCollectionViewCellGestureRecognizer(viewController: self)
            gestureRecognizer.draggableViewGestureRecognizerDelegate = self
            cell.addGestureRecognizer(gestureRecognizer)
        }
        
        return cell
    }

    // MARK: JobProductCreationViewControllerDelegate

    func jobProductCreationViewController(viewController: JobProductCreationViewController, didUpdateJobProduct jobProduct: JobProduct) {
        viewController.presentingViewController?.dismissViewController(animated: true)

        print("created job product \(jobProduct)")
    }

    private func reloadJobProductsForPickerViewController(viewController: ProductPickerViewController) {
        if viewController == jobProductsPickerViewController {
            if !reloadingJobProducts {
                if let job = job {
                    dispatch_async_main_queue {
                        viewController.showActivityIndicator()
                    }

                    reloadingJobProducts = true

                    reloadProducts()

                    job.reloadMaterials(
                        { (statusCode, mappingResult) -> () in
                            viewController.products = self.job.materials.map({ $0.product })
                            viewController.reloadCollectionView()
                            self.reloadingJobProducts = false
                        },
                        onError: { (error, statusCode, responseString) -> () in
                            viewController.reloadCollectionView()
                            self.reloadingJobProducts = false
                        }
                    )
                }
            }
        }
    }

    private func reloadProducts() {
        reloadingProductsCount = true

        if let companyId = job?.companyId {
            queryResultsPickerViewController?.products = [Product]()
            queryResultsPickerViewController?.showActivityIndicator()
            tableView.reloadData()

            ApiService.sharedService().countProducts(["company_id": job.companyId],
                onTotalResultsCount: { totalResultsCount, error in
                    self.totalProductsCount = totalResultsCount
                    if totalResultsCount > -1 {
                        if totalResultsCount <= self.maximumSearchlessProductsCount {
                            ApiService.sharedService().fetchProducts(["company_id": companyId, "page": 1, "rpp": totalResultsCount],
                                onSuccess: { (statusCode, mappingResult) -> () in
                                    self.queryResultsPickerViewController?.products = mappingResult.array() as! [Product]
                                    self.tableView.reloadData()
                                    self.searchBar.placeholder = "Showing all \(totalResultsCount) products"
                                    self.reloadingProductsCount = false
                                },
                                onError: { (error, statusCode, responseString) -> () in
                                    self.queryResultsPickerViewController?.products = [Product]()
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

    private class QueryResultsPickerCollectionViewCellGestureRecognizer: DraggableViewGestureRecognizer {
        private var collectionView: UICollectionView!

        private var jobInventoryViewController: JobInventoryViewContoller!

        private var jobProductsPickerCollectionView: UICollectionView! {
            didSet {
                if let jobProductsPickerCollectionView = jobProductsPickerCollectionView {
                    initialJobProductsPickerCollectionViewBackgroundColor = jobProductsPickerCollectionView.backgroundColor
                }
            }
        }
        private var initialJobProductsPickerCollectionViewBackgroundColor: UIColor!

        private var shouldAddProduct = false

        private var window: UIWindow! {
            return UIApplication.sharedApplication().keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldAddProduct
        }

        init(viewController: JobInventoryViewContoller) {
            super.init(target: viewController, action: "queryResultsPickerCollectionViewCellGestureRecognized:")
            jobInventoryViewController = viewController
            jobProductsPickerCollectionView = viewController.jobProductsPickerViewController.collectionView
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
                    jobProductsPickerCollectionView.backgroundColor = initialJobProductsPickerCollectionViewBackgroundColor

                    if shouldAddProduct {
                        let indexPath = jobInventoryViewController.queryResultsPickerViewController.collectionView.indexPathForCell(initialView as! UICollectionViewCell)!
                        jobInventoryViewController?.addJobProduct(jobInventoryViewController.queryResultsPickerViewController.products[indexPath.row])
                    }

                    collectionView.scrollEnabled = true
                    collectionView = nil

                    shouldAddProduct = false
                }
            }
        }

        private override func drag(xOffset: CGFloat, yOffset: CGFloat) {
            super.drag(xOffset, yOffset: yOffset)

            if initialView == nil || collectionView == nil {
                return
            }

            if jobInventoryViewController.searchBar.isFirstResponder() {
                jobInventoryViewController.searchBar.resignFirstResponder()
            }

            let jobProductsPickerCollectionViewFrame = jobProductsPickerCollectionView.superview!.convertRect(jobProductsPickerCollectionView.frame, toView: nil)
            shouldAddProduct = !jobInventoryViewController.addingJobProduct && CGRectIntersectsRect(initialView.frame, jobProductsPickerCollectionViewFrame)

            if shouldAddProduct {
                jobProductsPickerCollectionView.backgroundColor = Color.completedStatusColor().colorWithAlphaComponent(0.8)
            } else {
                jobProductsPickerCollectionView.backgroundColor = initialJobProductsPickerCollectionViewBackgroundColor
            }
        }
    }

    private class JobProductsPickerCollectionViewCellGestureRecognizer: DraggableViewGestureRecognizer {
        private var collectionView: UICollectionView!

        private var jobInventoryViewController: JobInventoryViewContoller!

        private var jobProductsPickerCollectionView: UICollectionView! {
            didSet {
                if let jobProductsPickerCollectionView = jobProductsPickerCollectionView {
                    initialJobProductsPickerCollectionViewBackgroundColor = jobProductsPickerCollectionView.backgroundColor
                }
            }
        }
        private var initialJobProductsPickerCollectionViewBackgroundColor: UIColor!

        private var shouldRemoveJobProduct = false

        private var window: UIWindow! {
            return UIApplication.sharedApplication().keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldRemoveJobProduct
        }

        init(viewController: JobInventoryViewContoller) {
            super.init(target: viewController, action: "jobProductsPickerCollectionViewCellGestureRecognized:")
            jobInventoryViewController = viewController
            jobProductsPickerCollectionView = viewController.jobProductsPickerViewController.collectionView
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
                    jobProductsPickerCollectionView.backgroundColor = initialJobProductsPickerCollectionViewBackgroundColor

                    if shouldRemoveJobProduct {
                        let indexPath = jobProductsPickerCollectionView.indexPathForCell(initialView as! UICollectionViewCell)!
                        jobInventoryViewController?.removeJobProduct(jobInventoryViewController.jobProductsPickerViewController.products[indexPath.row])
                    }

                    collectionView.scrollEnabled = true
                    collectionView = nil

                    shouldRemoveJobProduct = false
                }
            }
        }

        private override func drag(xOffset: CGFloat, yOffset: CGFloat) {
            super.drag(xOffset, yOffset: yOffset)

            if initialView == nil || collectionView == nil {
                return
            }

            let jobProductsPickerCollectionViewFrame = jobProductsPickerCollectionView.superview!.convertRect(jobProductsPickerCollectionView.frame, toView: nil)
            shouldRemoveJobProduct = !jobInventoryViewController.removingJobProduct && !CGRectIntersectsRect(initialView.frame, jobProductsPickerCollectionViewFrame)

            if shouldRemoveJobProduct {
                let accessoryImage = FAKFontAwesome.removeIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
                (initialView as! PickerCollectionViewCell).setAccessoryImage(accessoryImage, tintColor: Color.abandonedStatusColor())
            } else {
                (initialView as! PickerCollectionViewCell).accessoryImage = nil
            }
        }
    }
}
