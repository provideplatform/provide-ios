//
//  WorkOrderInventoryViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/20/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol WorkOrderInventoryViewControllerDelegate: NSObjectProtocol {
    func workOrderForWorkOrderInventoryViewController(viewController: WorkOrderInventoryViewController) -> WorkOrder!
}

class WorkOrderInventoryViewController: UITableViewController,
                                        UISearchBarDelegate,
                                        DraggableViewGestureRecognizerDelegate,
                                        ProductPickerViewControllerDelegate,
                                        WorkOrderProductCreationViewControllerDelegate {

    private let workOrderProductOperationQueue = dispatch_queue_create("api.workOrderProductOperationQueue", DISPATCH_QUEUE_SERIAL)

    let maximumSearchlessProductsCount = 25

    weak var delegate: WorkOrderInventoryViewControllerDelegate! {
        didSet {
            if let _ = delegate {
                if let workOrderProductsPickerViewController = workOrderProductsPickerViewController {
                    reloadWorkOrderProductsForPickerViewController(workOrderProductsPickerViewController)
                }
            }
        }
    }

    private var workOrder: WorkOrder! {
        if let workOrder = delegate?.workOrderForWorkOrderInventoryViewController(self) {
            return workOrder
        }
        return nil
    }

    private var queryString: String!

    private var reloadingJobProducts = false
    private var reloadingJobProductsCount = false

    private var totalJobProductsCount = -1

    private var addingWorkOrderProduct = false
    private var removingWorkOrderProduct = false

    private var showsAllProducts: Bool {
        return totalJobProductsCount == -1 || totalJobProductsCount <= maximumSearchlessProductsCount
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

    private var workOrderProductsPickerViewController: ProductPickerViewController!
    private var workOrderProductsTableViewCell: UITableViewCell! {
        if let workOrderProductsPickerViewController = workOrderProductsPickerViewController {
            return resolveTableViewCellForEmbeddedViewController(workOrderProductsPickerViewController)
        }
        return nil
    }

    @IBOutlet private weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Setup Inventory"

        searchBar?.placeholder = ""
    }

    func addWorkOrderJobProduct(jobProduct: JobProduct) {
        if workOrder == nil {
            return
        }

        var workOrderProduct = workOrder.workOrderProductForJobProduct(jobProduct)
        if workOrderProduct == nil {
            workOrderProductsPickerViewController?.products.append(jobProduct.product)
            let indexPaths = [NSIndexPath(forRow: (workOrderProductsPickerViewController?.products.count)! - 1, inSection: 0)]
            workOrderProductsPickerViewController?.collectionView.reloadItemsAtIndexPaths(indexPaths)
            let cell = workOrderProductsPickerViewController?.collectionView.cellForItemAtIndexPath(indexPaths.first!) as! PickerCollectionViewCell
            cell.showActivityIndicator()

            let params: [String : AnyObject] = [:]

            dispatch_async(workOrderProductOperationQueue) { [weak self] in
                while ((self?.addingWorkOrderProduct) != nil) { }

                self?.addingWorkOrderProduct = true

                self?.workOrder?.addWorkOrderProductForJobProduct(jobProduct, params: params,
                    onSuccess: { [weak self] statusCode, mappingResult in
                        if let s = self {
                            cell.hideActivityIndicator()

                            workOrderProduct = s.workOrder.workOrderProductForJobProduct(jobProduct)

                            let workOrderProductCreationViewController = UIStoryboard("ProductCreation").instantiateViewControllerWithIdentifier("WorkOrderProductCreationViewController") as! WorkOrderProductCreationViewController
                            workOrderProductCreationViewController.workOrder = s.workOrder
                            workOrderProductCreationViewController.workOrderProduct = workOrderProduct
                            workOrderProductCreationViewController.workOrderProductCreationViewControllerDelegate = s
                            workOrderProductCreationViewController.modalPresentationStyle = .Popover
                            workOrderProductCreationViewController.preferredContentSize = CGSizeMake(300, 250)
                            workOrderProductCreationViewController.popoverPresentationController!.sourceView = cell
                            workOrderProductCreationViewController.popoverPresentationController!.permittedArrowDirections = [.Left, .Right]
                            workOrderProductCreationViewController.popoverPresentationController!.canOverlapSourceViewRect = false
                            s.presentViewController(workOrderProductCreationViewController, animated: true) {
                                s.addingWorkOrderProduct = false
                            }
                        }
                    },
                    onError: { [weak self] error, statusCode, responseString in
                        self?.workOrderProductsPickerViewController?.products.removeObject(jobProduct.product)
                        self?.workOrderProductsPickerViewController?.reloadCollectionView()
                        self?.addingWorkOrderProduct = false
                    }
                )
            }
        }
    }

    func removeWorkOrderJobProduct(jobProduct: JobProduct) {
        if workOrder == nil {
            return
        }

        if let workOrderProduct = workOrder.workOrderProductForJobProduct(jobProduct) {
            dispatch_async(workOrderProductOperationQueue) { [weak self] in
                while ((self?.removingWorkOrderProduct) != nil) { }

                self?.removingWorkOrderProduct = true

                self?.workOrder?.removeWorkOrderProduct(workOrderProduct,
                    onSuccess: { (statusCode, mappingResult) -> () in
                        if let s = self {
                            s.workOrderProductsPickerViewController?.products = s.workOrder.materials.map({ $0.jobProduct.product })
                            s.workOrderProductsPickerViewController?.reloadCollectionView()
                            s.removingWorkOrderProduct = false
                        }
                    },
                    onError: { (error, statusCode, responseString) -> () in
                        self?.workOrderProductsPickerViewController?.products.append(jobProduct.product)
                        self?.workOrderProductsPickerViewController?.reloadCollectionView()
                        self?.removingWorkOrderProduct = false
                    }
                )
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "QueryResultsProductPickerEmbedSegue" {
            queryResultsPickerViewController = segue.destinationViewController as! ProductPickerViewController
            queryResultsPickerViewController.delegate = self
        } else if segue.identifier! == "ProductPickerEmbedSegue" {
            workOrderProductsPickerViewController = segue.destinationViewController as! ProductPickerViewController
            workOrderProductsPickerViewController.delegate = self
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
        if workOrderProductsTableViewCell != nil && numberOfSectionsInTableView(tableView) == 1 {
            return workOrderProductsTableViewCell
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
        if gestureRecognizer.isKindOfClass(WorkOrderProductsPickerCollectionViewCellGestureRecognizer) {
            return (gestureRecognizer as! WorkOrderProductsPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        } else if gestureRecognizer.isKindOfClass(QueryResultsPickerCollectionViewCellGestureRecognizer) {
            return (gestureRecognizer as! QueryResultsPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        }
        return true
    }

    func queryResultsPickerCollectionViewCellGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    func workOrderProductsPickerCollectionViewCellGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    // MARK: ProductCreationViewControllerDelegate

    func productCreationViewController(viewController: ProductCreationViewController, didCreateProduct product: Product) {
        dismissViewController(animated: true)

//        if totalJobProductsCount > -1 {
//            totalJobProductsCount++
//
//            if showsAllProducts {
//                queryResultsPickerViewController?.products.append(product)
//                queryResultsPickerViewController?.reloadCollectionView()
//
//                searchBar.placeholder = "Showing all \(totalProductsCount) products"
//            } else {
//                searchBar.placeholder = "Search \(totalProductsCount) products"
//            }
//        }
    }

    // MARK: ProductPickerViewControllerDelegate

    func queryParamsForProductPickerViewController(viewController: ProductPickerViewController) -> [String : AnyObject]! {
//        if let workOrder = workOrder {
//            if workOrderProductsPickerViewController != nil && viewController == workOrderProductsPickerViewController {
//                return ["work_order_id": workOrder.id, "company_id": workOrder.companyId]
//            } else if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
//                return ["company_id": workOrder.companyId, "q": queryString != nil ? queryString : NSNull()]
//            }
//        }
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
        if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
            if let job = workOrder?.job {
                if let materials = job.materials {
                    dispatch_after_delay(0.0) {
                        viewController.hideActivityIndicator()
                    }
                    return materials.map({ $0.product })
                } else {
                    reloadJobProductsForPickerViewController(viewController)
                }
            } else if workOrder?.jobId > 0 {
                workOrder.reloadJob(
                    { [weak self] statusCode, mappingResult in
                        self?.reloadJobProductsForPickerViewController(viewController)
                    },
                    onError: { error, statusCode, responseString in

                    }
                )
            }
        } else if workOrderProductsPickerViewController != nil && viewController == workOrderProductsPickerViewController {
            if let materials = workOrder?.materials {
                dispatch_after_delay(0.0) {
                    viewController.hideActivityIndicator()
                }
                return materials.map({ $0.jobProduct.product })
            } else {
                // should never be called at current...
                //reloadJobProductsForPickerViewController(viewController)
            }
        }
        return [Product]()
    }

    func selectedProductsForPickerViewController(viewController: ProductPickerViewController) -> [Product] {
        return [Product]()
    }

    func collectionViewScrollDirectionForPickerViewController(viewController: ProductPickerViewController) -> UICollectionViewScrollDirection {
        return .Horizontal
    }

    func productPickerViewControllerCanRenderResults(viewController: ProductPickerViewController) -> Bool {
        if workOrderProductsPickerViewController != nil && viewController == workOrderProductsPickerViewController {
            if let workOrder = workOrder {
                return workOrder.materials != nil
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
                    || gestureRecognizer.isKindOfClass(WorkOrderProductsPickerCollectionViewCellGestureRecognizer) {
                        cell.removeGestureRecognizer(gestureRecognizer)
                }
            }
        }

        if viewController == workOrderProductsPickerViewController {
            let gestureRecognizer = WorkOrderProductsPickerCollectionViewCellGestureRecognizer(viewController: self)
            gestureRecognizer.draggableViewGestureRecognizerDelegate = self
            cell.addGestureRecognizer(gestureRecognizer)
        } else if viewController == queryResultsPickerViewController {
            let gestureRecognizer = QueryResultsPickerCollectionViewCellGestureRecognizer(viewController: self)
            gestureRecognizer.draggableViewGestureRecognizerDelegate = self
            cell.addGestureRecognizer(gestureRecognizer)
        }

        return cell
    }

    // MARK: WorkOrderProductCreationViewControllerDelegate

    func workOrderProductCreationViewController(viewController: WorkOrderProductCreationViewController, didUpdateWorkOrderProduct workOrderProduct: WorkOrderProduct) {
        viewController.presentingViewController?.dismissViewController(animated: true)
    }

    private func reloadJobProductsForPickerViewController(viewController: ProductPickerViewController) {
        if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
            if !reloadingJobProducts {
                if let job = workOrder?.job {
                    dispatch_async_main_queue {
                        viewController.showActivityIndicator()
                    }

                    reloadingJobProducts = true

//                    reloadProducts()

                    job.reloadMaterials(
                        { (statusCode, mappingResult) -> () in
                            viewController.products = job.materials.map({ $0.product })
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

    private func reloadWorkOrderProductsForPickerViewController(viewController: ProductPickerViewController) {
        if workOrderProductsPickerViewController != nil && viewController == workOrderProductsPickerViewController {
            viewController.products = self.workOrder.materials.map({ $0.jobProduct.product })
            viewController.reloadCollectionView()
            viewController.hideActivityIndicator()
            //self.reloadingWorkOrderProducts = false
//            if !reloadingWorkOrderProducts {
//                if let _ = workOrder {
//                    dispatch_async_main_queue {
//                        viewController.showActivityIndicator()
//                    }
//
//                    reloadingWorkOrderProducts = true
//
//                    reloadProducts()
//
//                    viewController.products = self.workOrder.materials.map({ $0.jobProduct.product })
//                    viewController.reloadCollectionView()
//                    self.reloadingWorkOrderProducts = false
//
//
////                    workOrder.reloadMaterials(
////                        { (statusCode, mappingResult) -> () in
////                            viewController.products = self.workOrder.materials.map({ $0.product })
////                            viewController.reloadCollectionView()
////                            self.reloadingWorkOrderProducts = false
////                        },
////                        onError: { (error, statusCode, responseString) -> () in
////                            viewController.reloadCollectionView()
////                            self.reloadingWorkOrderProducts = false
////                        }
////                    )
//                }
//            }
        }
    }

//    private func reloadProducts() {
//        reloadingProductsCount = true
//
//        if let companyId = workOrder?.companyId {
//            queryResultsPickerViewController?.products = [Product]()
//            queryResultsPickerViewController?.showActivityIndicator()
//            tableView.reloadData()
//
//            ApiService.sharedService().countProducts(["company_id": workOrder.companyId],
//                onTotalResultsCount: { totalResultsCount, error in
//                    self.totalProductsCount = totalResultsCount
//                    if totalResultsCount > -1 {
//                        if totalResultsCount <= self.maximumSearchlessProductsCount {
//                            ApiService.sharedService().fetchProducts(["company_id": companyId, "page": 1, "rpp": totalResultsCount],
//                                onSuccess: { (statusCode, mappingResult) -> () in
//                                    self.queryResultsPickerViewController?.products = mappingResult.array() as! [Product]
//                                    self.tableView.reloadData()
//                                    self.searchBar.placeholder = "Showing all \(totalResultsCount) products"
//                                    self.reloadingProductsCount = false
//                                },
//                                onError: { (error, statusCode, responseString) -> () in
//                                    self.queryResultsPickerViewController?.products = [Product]()
//                                    self.tableView.reloadData()
//                                    self.reloadingProductsCount = false
//                            })
//                        } else {
//                            self.searchBar.placeholder = "Search \(totalResultsCount) products"
//                            self.tableView.reloadData()
//                            self.reloadingProductsCount = false
//                        }
//                    }
//                }
//            )
//        }
//    }

    private class QueryResultsPickerCollectionViewCellGestureRecognizer: DraggableViewGestureRecognizer {
        private var collectionView: UICollectionView!

        private var workOrderInventoryViewController: WorkOrderInventoryViewController!

        private var workOrderProductsPickerCollectionView: UICollectionView! {
            didSet {
                if let workOrderProductsPickerCollectionView = workOrderProductsPickerCollectionView {
                    initialWorkOrderProductsPickerCollectionViewBackgroundColor = workOrderProductsPickerCollectionView.backgroundColor
                }
            }
        }
        private var initialWorkOrderProductsPickerCollectionViewBackgroundColor: UIColor!

        private var shouldAddProduct = false

        private var window: UIWindow! {
            return UIApplication.sharedApplication().keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldAddProduct
        }

        init(viewController: WorkOrderInventoryViewController) {
            super.init(target: viewController, action: "queryResultsPickerCollectionViewCellGestureRecognized:")
            workOrderInventoryViewController = viewController
            workOrderProductsPickerCollectionView = viewController.workOrderProductsPickerViewController.collectionView
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
                    workOrderProductsPickerCollectionView.backgroundColor = initialWorkOrderProductsPickerCollectionViewBackgroundColor

                    if shouldAddProduct {
                        let indexPath = workOrderInventoryViewController.queryResultsPickerViewController.collectionView.indexPathForCell(initialView as! UICollectionViewCell)!
                        if let jobProduct = workOrderInventoryViewController?.workOrder?.job?.jobProductForProduct(workOrderInventoryViewController.queryResultsPickerViewController.products[indexPath.row]) {
                            workOrderInventoryViewController?.addWorkOrderJobProduct(jobProduct)
                        }
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

            if workOrderInventoryViewController.searchBar.isFirstResponder() {
                workOrderInventoryViewController.searchBar.resignFirstResponder()
            }

            let workOrderProductsPickerCollectionViewFrame = workOrderProductsPickerCollectionView.superview!.convertRect(workOrderProductsPickerCollectionView.frame, toView: nil)
            shouldAddProduct = !workOrderInventoryViewController.addingWorkOrderProduct && CGRectIntersectsRect(initialView.frame, workOrderProductsPickerCollectionViewFrame)

            if shouldAddProduct {
                workOrderProductsPickerCollectionView.backgroundColor = Color.completedStatusColor().colorWithAlphaComponent(0.8)
            } else {
                workOrderProductsPickerCollectionView.backgroundColor = initialWorkOrderProductsPickerCollectionViewBackgroundColor
            }
        }
    }

    private class WorkOrderProductsPickerCollectionViewCellGestureRecognizer: DraggableViewGestureRecognizer {
        private var collectionView: UICollectionView!

        private var workOrderInventoryViewController: WorkOrderInventoryViewController!

        private var workOrderProductsPickerCollectionView: UICollectionView! {
            didSet {
                if let workOrderProductsPickerCollectionView = workOrderProductsPickerCollectionView {
                    initialWorkOrderProductsPickerCollectionViewBackgroundColor = workOrderProductsPickerCollectionView.backgroundColor
                }
            }
        }
        private var initialWorkOrderProductsPickerCollectionViewBackgroundColor: UIColor!

        private var shouldRemoveWorkOrderProduct = false

        private var window: UIWindow! {
            return UIApplication.sharedApplication().keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldRemoveWorkOrderProduct
        }

        init(viewController: WorkOrderInventoryViewController) {
            super.init(target: viewController, action: "workOrderProductsPickerCollectionViewCellGestureRecognized:")
            workOrderInventoryViewController = viewController
            workOrderProductsPickerCollectionView = viewController.workOrderProductsPickerViewController.collectionView
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
                    workOrderProductsPickerCollectionView.backgroundColor = initialWorkOrderProductsPickerCollectionViewBackgroundColor

                    if shouldRemoveWorkOrderProduct {
                        let indexPath = workOrderProductsPickerCollectionView.indexPathForCell(initialView as! UICollectionViewCell)!
                        if let jobProduct = workOrderInventoryViewController?.workOrder?.job?.jobProductForProduct(workOrderInventoryViewController.workOrderProductsPickerViewController.products[indexPath.row]) {
                            workOrderInventoryViewController?.removeWorkOrderJobProduct(jobProduct)
                        }
                    }

                    collectionView.scrollEnabled = true
                    collectionView = nil

                    shouldRemoveWorkOrderProduct = false
                }
            }
        }

        private override func drag(xOffset: CGFloat, yOffset: CGFloat) {
            super.drag(xOffset, yOffset: yOffset)

            if initialView == nil || collectionView == nil {
                return
            }

            let workOrderProductsPickerCollectionViewFrame = workOrderProductsPickerCollectionView.superview!.convertRect(workOrderProductsPickerCollectionView.frame, toView: nil)
            shouldRemoveWorkOrderProduct = !workOrderInventoryViewController.removingWorkOrderProduct && !CGRectIntersectsRect(initialView.frame, workOrderProductsPickerCollectionViewFrame)
            
            if shouldRemoveWorkOrderProduct {
                let accessoryImage = FAKFontAwesome.removeIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
                (initialView as! PickerCollectionViewCell).setAccessoryImage(accessoryImage, tintColor: Color.abandonedStatusColor())
            } else {
                (initialView as! PickerCollectionViewCell).accessoryImage = nil
            }
        }
    }
}
