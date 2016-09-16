//
//  JobInventoryViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/11/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import FontAwesomeKit
import KTSwiftExtensions

protocol JobInventoryViewControllerDelegate: NSObjectProtocol {
    func jobForJobInventoryViewController(_ viewController: JobInventoryViewContoller) -> Job!
}

class JobInventoryViewContoller: UITableViewController,
                                 UISearchBarDelegate,
                                 KTDraggableViewGestureRecognizerDelegate,
                                 ProductCreationViewControllerDelegate,
                                 ProductPickerViewControllerDelegate,
                                 JobProductCreationViewControllerDelegate,
                                 ManifestViewControllerDelegate {

    fileprivate let jobProductOperationQueue = DispatchQueue(label: "api.jobProductOperationQueue", attributes: [])

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

    fileprivate var job: Job! {
        if let job = delegate?.jobForJobInventoryViewController(self) {
            return job
        }
        return nil
    }

    fileprivate var queryString: String!

    fileprivate var reloadingJobProducts = false
    fileprivate var reloadingProductsCount = false

    fileprivate var totalProductsCount = -1

    fileprivate var addingJobProduct = false
    fileprivate var removingJobProduct = false

    fileprivate var showsAllProducts: Bool {
        return totalProductsCount == -1 || totalProductsCount <= maximumSearchlessProductsCount
    }

    fileprivate var renderQueryResults: Bool {
        return queryString != nil || showsAllProducts
    }

    fileprivate var queryResultsPickerViewController: ProductPickerViewController!
    fileprivate var queryResultsPickerTableViewCell: UITableViewCell! {
        if let queryResultsPickerViewController = queryResultsPickerViewController {
            return resolveTableViewCellForEmbeddedViewController(queryResultsPickerViewController)
        }
        return nil
    }

    fileprivate var jobProductsPickerViewController: ProductPickerViewController!
    fileprivate var jobProductsTableViewCell: UITableViewCell! {
        if let jobProductsPickerViewController = jobProductsPickerViewController {
            return resolveTableViewCellForEmbeddedViewController(jobProductsPickerViewController)
        }
        return nil
    }

    @IBOutlet fileprivate weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Setup Inventory"

        searchBar?.placeholder = ""
    }

    func addJobProduct(_ product: Product) {
        if job == nil {
            return
        }

        var jobProduct = job.jobProductForProduct(product)
        if jobProduct == nil {
            jobProductsPickerViewController?.products.append(product)
            let indexPaths = [IndexPath(row: (jobProductsPickerViewController?.products.count)! - 1, section: 0)]
            jobProductsPickerViewController?.collectionView.reloadItems(at: indexPaths)
            let cell = jobProductsPickerViewController?.collectionView.cellForItem(at: indexPaths.first!) as! PickerCollectionViewCell
            cell.showActivityIndicator()

            let params: [String : AnyObject] = [:]

            jobProductOperationQueue.async { [weak self] in
                while self!.addingJobProduct { }

                self!.addingJobProduct = true

                self!.job?.addJobProductForProduct(product, params: params,
                    onSuccess: { [weak self] statusCode, mappingResult in
                        cell.hideActivityIndicator()
                        self!.jobProductsPickerViewController?.reloadCollectionView()

                        jobProduct = self!.job.jobProductForProduct(product)

                        let jobProductCreationViewController = UIStoryboard("ProductCreation").instantiateViewController(withIdentifier: "JobProductCreationViewController") as! JobProductCreationViewController
                        jobProductCreationViewController.job = self!.job
                        jobProductCreationViewController.jobProduct = jobProduct
                        jobProductCreationViewController.jobProductCreationViewControllerDelegate = self!
                        jobProductCreationViewController.modalPresentationStyle = .popover
                        jobProductCreationViewController.preferredContentSize = CGSize(width: 300, height: 250)
                        jobProductCreationViewController.popoverPresentationController!.sourceView = cell
                        jobProductCreationViewController.popoverPresentationController!.permittedArrowDirections = [.left, .right]
                        jobProductCreationViewController.popoverPresentationController!.canOverlapSourceViewRect = false
                        self!.present(jobProductCreationViewController, animated: true) {
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

    func removeJobProduct(_ product: Product) {
        if job == nil {
            return
        }

        if let jobProduct = job.jobProductForProduct(product) {
            jobProductOperationQueue.async { [weak self] in
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier! == "ProductCreationViewControllerPopoverSegue" {
            segue.destination.preferredContentSize = CGSize(width: 400, height: 500)
            ((segue.destination as! UINavigationController).viewControllers.first! as! ProductCreationViewController).delegate = self
        } else if segue.identifier! == "QueryResultsProductPickerEmbedSegue" {
            queryResultsPickerViewController = segue.destination as! ProductPickerViewController
            queryResultsPickerViewController.delegate = self
        } else if segue.identifier! == "JobProductsProductPickerEmbedSegue" {
            jobProductsPickerViewController = segue.destination as! ProductPickerViewController
            jobProductsPickerViewController.delegate = self
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
        if jobProductsTableViewCell != nil && numberOfSections(in: tableView) == 1 {
            return jobProductsTableViewCell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if numberOfSections(in: tableView) == 1 {
            return "JOB MANIFEST"
        } else {
            if numberOfSections(in: tableView) == 2 && showsAllProducts {
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

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return !showsAllProducts
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
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

    // MARK: KTDraggableViewGestureRecognizerDelegate

    func draggableViewGestureRecognizer(_ gestureRecognizer: KTDraggableViewGestureRecognizer, shouldResetView view: UIView) -> Bool {
        if !draggableViewGestureRecognizer(gestureRecognizer, shouldAnimateResetView: view) {
            view.alpha = 0.0
        }
        return true
    }

    func draggableViewGestureRecognizer(_ gestureRecognizer: KTDraggableViewGestureRecognizer, shouldAnimateResetView view: UIView) -> Bool {
        if gestureRecognizer.isKind(of: JobProductsPickerCollectionViewCellGestureRecognizer.self) {
            return (gestureRecognizer as! JobProductsPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        } else if gestureRecognizer.isKind(of: QueryResultsPickerCollectionViewCellGestureRecognizer.self) {
            return (gestureRecognizer as! QueryResultsPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        }
        return true
    }

    func queryResultsPickerCollectionViewCellGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    func jobProductsPickerCollectionViewCellGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    // MARK: ProductCreationViewControllerDelegate

    func productCreationViewController(_ viewController: ProductCreationViewController, didCreateProduct product: Product) {
        dismissViewController(true)

        if totalProductsCount > -1 {
            totalProductsCount += 1

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

    func queryParamsForProductPickerViewController(_ viewController: ProductPickerViewController) -> [String : AnyObject]! {
        if let job = job {
            if jobProductsPickerViewController != nil && viewController == jobProductsPickerViewController {
                return ["job_id": job.id as AnyObject, "company_id": job.companyId as AnyObject]
            } else if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
                return ["company_id": job.companyId as AnyObject, "q": queryString != nil ? queryString as AnyObject : NSNull() as AnyObject]
            }
        }
        return nil
    }

    func productPickerViewController(_ viewController: ProductPickerViewController, didSelectProduct product: Product) {

    }

    func productPickerViewController(_ viewController: ProductPickerViewController, didDeselectProduct: Product) {

    }

    func productPickerViewControllerAllowsMultipleSelection(_ viewController: ProductPickerViewController) -> Bool {
        return false
    }

    func productsForPickerViewController(_ viewController: ProductPickerViewController) -> [Product] {
        return [Product]()
    }

    func selectedProductsForPickerViewController(_ viewController: ProductPickerViewController) -> [Product] {
        return [Product]()
    }

    func collectionViewScrollDirectionForPickerViewController(_ viewController: ProductPickerViewController) -> UICollectionViewScrollDirection {
        return .horizontal
    }

    func productPickerViewControllerCanRenderResults(_ viewController: ProductPickerViewController) -> Bool {
        if jobProductsPickerViewController != nil && viewController == jobProductsPickerViewController {
            if let job = job {
                return job.materials != nil
            }
        } else if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
            return true
        }
        return false
    }

    func productPickerViewController(_ viewController: ProductPickerViewController, collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        var cell: PickerCollectionViewCell!

        if viewController == queryResultsPickerViewController {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickerCollectionViewCell", for: indexPath) as! PickerCollectionViewCell
            let products = viewController.products

            if products.count > (indexPath as NSIndexPath).row - 1 {
                let product = products[(indexPath as NSIndexPath).row]

                cell.isSelected = viewController.isSelected(product)

                if cell.isSelected {
                    collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition())
                }

                cell.name = product.name

                if let profileImageUrl = product.barcodeDataURL {
                    cell.rendersCircularImage = false
                    cell.imageUrl = profileImageUrl
                }
            }
        } else if viewController == jobProductsPickerViewController {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "JobProductPickerCollectionViewCell", for: indexPath) as! PickerCollectionViewCell
            let products = viewController.products

            if products.count > (indexPath as NSIndexPath).row - 1 {
                let product = products[(indexPath as NSIndexPath).row]

                cell.isSelected = viewController.isSelected(product)

                if cell.isSelected {
                    collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition())
                }

                cell.name = product.name
                (cell as! JobProductPickerCollectionViewCell).jobProduct = job.jobProductForProduct(product)

                if let profileImageUrl = product.barcodeDataURL {
                    cell.rendersCircularImage = false
                    cell.imageUrl = profileImageUrl
                }
            }
        }

        if let gestureRecognizers = cell.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if gestureRecognizer.isKind(of: QueryResultsPickerCollectionViewCellGestureRecognizer.self)
                    || gestureRecognizer.isKind(of: JobProductsPickerCollectionViewCellGestureRecognizer.self) {
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

    func jobProductCreationViewController(_ viewController: JobProductCreationViewController, didUpdateJobProduct jobProduct: JobProduct) {
        viewController.presentingViewController?.dismissViewController(true)
        jobProductsPickerViewController.reloadCollectionView()
    }

    func jobProductCreationViewController(_ viewController: JobProductCreationViewController, didRemoveJobProduct jobProduct: JobProduct) {
        jobProductsPickerViewController.reloadCollectionView()
    }

    fileprivate func reloadJobProductsForPickerViewController(_ viewController: ProductPickerViewController) {
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

    fileprivate func reloadProducts() {
        reloadingProductsCount = true

        if let companyId = job?.companyId {
            queryResultsPickerViewController?.products = [Product]()
            queryResultsPickerViewController?.showActivityIndicator()
            tableView.reloadData()

            ApiService.sharedService().countProducts(["company_id": job.companyId as AnyObject],
                onTotalResultsCount: { totalResultsCount, error in
                    self.totalProductsCount = totalResultsCount
                    if totalResultsCount > -1 {
                        if totalResultsCount <= self.maximumSearchlessProductsCount {
                            let _ = ApiService.sharedService().fetchProducts(["company_id": companyId as AnyObject, "page": 1 as AnyObject, "rpp": totalResultsCount as AnyObject],
                                onSuccess: { (statusCode, mappingResult) -> () in
                                    self.queryResultsPickerViewController?.products = mappingResult?.array() as! [Product]
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

    fileprivate class QueryResultsPickerCollectionViewCellGestureRecognizer: KTDraggableViewGestureRecognizer {
        fileprivate var collectionView: UICollectionView!

        fileprivate var jobInventoryViewController: JobInventoryViewContoller!

        fileprivate var jobProductsPickerCollectionView: UICollectionView! {
            didSet {
                if let jobProductsPickerCollectionView = jobProductsPickerCollectionView {
                    initialJobProductsPickerCollectionViewBackgroundColor = jobProductsPickerCollectionView.backgroundColor
                }
            }
        }
        fileprivate var initialJobProductsPickerCollectionViewBackgroundColor: UIColor!

        fileprivate var shouldAddProduct = false

        fileprivate var window: UIWindow! {
            return UIApplication.shared.keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldAddProduct
        }

        init(viewController: JobInventoryViewContoller) {
            super.init(target: viewController, action: #selector(JobInventoryViewContoller.queryResultsPickerCollectionViewCellGestureRecognized(_:)))
            jobInventoryViewController = viewController
            jobProductsPickerCollectionView = viewController.jobProductsPickerViewController.collectionView
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
                    jobProductsPickerCollectionView.backgroundColor = initialJobProductsPickerCollectionViewBackgroundColor

                    if shouldAddProduct {
                        let indexPath = jobInventoryViewController.queryResultsPickerViewController.collectionView.indexPath(for: initialView as! UICollectionViewCell)!
                        jobInventoryViewController?.addJobProduct(jobInventoryViewController.queryResultsPickerViewController.products[(indexPath as NSIndexPath).row])
                    }

                    collectionView.isScrollEnabled = true
                    collectionView = nil

                    shouldAddProduct = false
                }
            }
        }

        fileprivate override func drag(_ xOffset: CGFloat, yOffset: CGFloat) {
            super.drag(xOffset, yOffset: yOffset)

            if initialView == nil || collectionView == nil {
                return
            }

            if jobInventoryViewController.searchBar.isFirstResponder {
                jobInventoryViewController.searchBar.resignFirstResponder()
            }

            let jobProductsPickerCollectionViewFrame = jobProductsPickerCollectionView.superview!.convert(jobProductsPickerCollectionView.frame, to: nil)
            shouldAddProduct = !jobInventoryViewController.addingJobProduct && initialView.frame.intersects(jobProductsPickerCollectionViewFrame)

            if shouldAddProduct {
                jobProductsPickerCollectionView.backgroundColor = Color.completedStatusColor().withAlphaComponent(0.8)
            } else {
                jobProductsPickerCollectionView.backgroundColor = initialJobProductsPickerCollectionViewBackgroundColor
            }
        }
    }

    fileprivate class JobProductsPickerCollectionViewCellGestureRecognizer: KTDraggableViewGestureRecognizer {
        fileprivate var collectionView: UICollectionView!

        fileprivate var jobInventoryViewController: JobInventoryViewContoller!

        fileprivate var jobProductsPickerCollectionView: UICollectionView! {
            didSet {
                if let jobProductsPickerCollectionView = jobProductsPickerCollectionView {
                    initialJobProductsPickerCollectionViewBackgroundColor = jobProductsPickerCollectionView.backgroundColor
                }
            }
        }
        fileprivate var initialJobProductsPickerCollectionViewBackgroundColor: UIColor!

        fileprivate var shouldRemoveJobProduct = false

        fileprivate var window: UIWindow! {
            return UIApplication.shared.keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldRemoveJobProduct
        }

        init(viewController: JobInventoryViewContoller) {
            super.init(target: viewController, action: #selector(JobInventoryViewContoller.jobProductsPickerCollectionViewCellGestureRecognized(_:)))
            jobInventoryViewController = viewController
            jobProductsPickerCollectionView = viewController.jobProductsPickerViewController.collectionView
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
                    jobProductsPickerCollectionView.backgroundColor = initialJobProductsPickerCollectionViewBackgroundColor

                    if shouldRemoveJobProduct {
                        let indexPath = jobProductsPickerCollectionView.indexPath(for: initialView as! UICollectionViewCell)!
                        jobInventoryViewController?.removeJobProduct(jobInventoryViewController.jobProductsPickerViewController.products[(indexPath as NSIndexPath).row])
                    }

                    collectionView?.isScrollEnabled = true
                    collectionView = nil

                    shouldRemoveJobProduct = false
                }
            }
        }

        fileprivate override func drag(_ xOffset: CGFloat, yOffset: CGFloat) {
            super.drag(xOffset, yOffset: yOffset)

            if initialView == nil || collectionView == nil {
                return
            }

            let jobProductsPickerCollectionViewFrame = jobProductsPickerCollectionView.superview!.convert(jobProductsPickerCollectionView.frame, to: nil)
            shouldRemoveJobProduct = !jobInventoryViewController.removingJobProduct && !initialView.frame.intersects(jobProductsPickerCollectionViewFrame)

            if shouldRemoveJobProduct {
                let accessoryImage = FAKFontAwesome.removeIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
                (initialView as! PickerCollectionViewCell).setAccessoryImage(accessoryImage, tintColor: Color.abandonedStatusColor())
            } else {
                (initialView as! PickerCollectionViewCell).accessoryImage = nil
            }
        }
    }
}
