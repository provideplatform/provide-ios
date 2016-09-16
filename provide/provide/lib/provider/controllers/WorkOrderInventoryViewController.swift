//
//  WorkOrderInventoryViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/20/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import FontAwesomeKit
import KTSwiftExtensions
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


protocol WorkOrderInventoryViewControllerDelegate: NSObjectProtocol {
    func workOrderForWorkOrderInventoryViewController(_ viewController: WorkOrderInventoryViewController) -> WorkOrder!
    func workOrderInventoryViewController(_ viewController: WorkOrderInventoryViewController, didUpdateWorkOrderProduct workOrderProduct: WorkOrderProduct)
    func workOrderInventoryViewController(_ viewController: WorkOrderInventoryViewController, didRemoveWorkOrderProduct workOrderProduct: WorkOrderProduct)
}

class WorkOrderInventoryViewController: UITableViewController,
                                        UISearchBarDelegate,
                                        KTDraggableViewGestureRecognizerDelegate,
                                        ProductPickerViewControllerDelegate,
                                        WorkOrderProductCreationViewControllerDelegate {

    fileprivate let workOrderProductOperationQueue = DispatchQueue(label: "api.workOrderProductOperationQueue", attributes: [])

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

    fileprivate var workOrder: WorkOrder! {
        if let workOrder = delegate?.workOrderForWorkOrderInventoryViewController(self) {
            return workOrder
        }
        return nil
    }

    fileprivate var queryString: String!

    fileprivate var reloadingJobProducts = false
    fileprivate var reloadingJobProductsCount = false

    fileprivate var totalJobProductsCount = -1

    fileprivate var addingWorkOrderProduct = false
    fileprivate var removingWorkOrderProduct = false

    fileprivate var showsAllProducts: Bool {
        return totalJobProductsCount == -1 || totalJobProductsCount <= maximumSearchlessProductsCount
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

    fileprivate var workOrderProductsPickerViewController: ProductPickerViewController!
    fileprivate var workOrderProductsTableViewCell: UITableViewCell! {
        if let workOrderProductsPickerViewController = workOrderProductsPickerViewController {
            return resolveTableViewCellForEmbeddedViewController(workOrderProductsPickerViewController)
        }
        return nil
    }

    @IBOutlet fileprivate weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Setup Inventory"

        searchBar?.placeholder = ""
    }

    func addWorkOrderJobProduct(_ jobProduct: JobProduct) {
        if workOrder == nil {
            return
        }

        var workOrderProduct = workOrder.workOrderProductForJobProduct(jobProduct)
        if workOrderProduct == nil {
            workOrderProductsPickerViewController?.products.append(jobProduct.product)
            let indexPaths = [IndexPath(row: (workOrderProductsPickerViewController?.products.count)! - 1, section: 0)]
            workOrderProductsPickerViewController?.collectionView.reloadItems(at: indexPaths)
            let cell = workOrderProductsPickerViewController?.collectionView.cellForItem(at: indexPaths.first!) as! PickerCollectionViewCell
            cell.showActivityIndicator()

            let params: [String : AnyObject] = [:]

            workOrderProductOperationQueue.async { [weak self] in
                while self!.addingWorkOrderProduct { }

                self!.addingWorkOrderProduct = true

                self!.workOrder?.addWorkOrderProductForJobProduct(jobProduct, params: params,
                    onSuccess: { [weak self] statusCode, mappingResult in
                        cell.hideActivityIndicator()

                        workOrderProduct = self!.workOrder.workOrderProductForJobProduct(jobProduct)

                        let workOrderProductCreationViewController = UIStoryboard("ProductCreation").instantiateViewController(withIdentifier: "WorkOrderProductCreationViewController") as! WorkOrderProductCreationViewController
                        workOrderProductCreationViewController.workOrder = self!.workOrder
                        workOrderProductCreationViewController.workOrderProduct = workOrderProduct
                        workOrderProductCreationViewController.workOrderProductCreationViewControllerDelegate = self!
                        workOrderProductCreationViewController.modalPresentationStyle = .popover
                        workOrderProductCreationViewController.preferredContentSize = CGSize(width: 300, height: 250)
                        workOrderProductCreationViewController.popoverPresentationController!.sourceView = cell
                        workOrderProductCreationViewController.popoverPresentationController!.permittedArrowDirections = [.left, .right]
                        workOrderProductCreationViewController.popoverPresentationController!.canOverlapSourceViewRect = false
                        self!.present(workOrderProductCreationViewController, animated: true) {
                            self!.addingWorkOrderProduct = false
                        }
                    },
                    onError: { [weak self] error, statusCode, responseString in
                        self!.workOrderProductsPickerViewController?.products.removeObject(jobProduct.product)
                        self!.workOrderProductsPickerViewController?.reloadCollectionView()
                        self!.addingWorkOrderProduct = false
                    }
                )
            }
        }
    }

    func removeWorkOrderJobProduct(_ jobProduct: JobProduct) {
        if workOrder == nil {
            return
        }

        if let workOrderProduct = workOrder.workOrderProductForJobProduct(jobProduct) {
            workOrderProductOperationQueue.async { [weak self] in
                while self!.removingWorkOrderProduct { }

                self!.removingWorkOrderProduct = true

                self!.workOrder?.removeWorkOrderProduct(workOrderProduct,
                    onSuccess: { (statusCode, mappingResult) -> () in
                        self!.workOrderProductsPickerViewController?.products = self!.workOrder.materials.map({ $0.jobProduct.product })
                        self!.workOrderProductsPickerViewController?.reloadCollectionView()
                        self!.removingWorkOrderProduct = false
                        self!.delegate?.workOrderInventoryViewController(self!, didRemoveWorkOrderProduct: workOrderProduct)
                    },
                    onError: { (error, statusCode, responseString) -> () in
                        self!.workOrderProductsPickerViewController?.products.append(jobProduct.product)
                        self!.workOrderProductsPickerViewController?.reloadCollectionView()
                        self!.removingWorkOrderProduct = false
                    }
                )
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier! == "QueryResultsProductPickerEmbedSegue" {
            queryResultsPickerViewController = segue.destination as! ProductPickerViewController
            queryResultsPickerViewController.delegate = self
        } else if segue.identifier! == "ProductPickerEmbedSegue" {
            workOrderProductsPickerViewController = segue.destination as! ProductPickerViewController
            workOrderProductsPickerViewController.delegate = self
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
        if workOrderProductsTableViewCell != nil && numberOfSections(in: tableView) == 1 {
            return workOrderProductsTableViewCell
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
        if gestureRecognizer.isKind(of: WorkOrderProductsPickerCollectionViewCellGestureRecognizer.self) {
            return (gestureRecognizer as! WorkOrderProductsPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        } else if gestureRecognizer.isKind(of: QueryResultsPickerCollectionViewCellGestureRecognizer.self) {
            return (gestureRecognizer as! QueryResultsPickerCollectionViewCellGestureRecognizer).shouldAnimateViewReset
        }
        return true
    }

    func queryResultsPickerCollectionViewCellGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    func workOrderProductsPickerCollectionViewCellGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    // MARK: ProductCreationViewControllerDelegate

    func productCreationViewController(_ viewController: ProductCreationViewController, didCreateProduct product: Product) {
        dismissViewController(true)

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

    func queryParamsForProductPickerViewController(_ viewController: ProductPickerViewController) -> [String : AnyObject]! {
//        if let workOrder = workOrder {
//            if workOrderProductsPickerViewController != nil && viewController == workOrderProductsPickerViewController {
//                return ["work_order_id": workOrder.id, "company_id": workOrder.companyId]
//            } else if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
//                return ["company_id": workOrder.companyId, "q": queryString != nil ? queryString : NSNull()]
//            }
//        }
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
                        self!.reloadJobProductsForPickerViewController(viewController)
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

    func selectedProductsForPickerViewController(_ viewController: ProductPickerViewController) -> [Product] {
        return [Product]()
    }

    func collectionViewScrollDirectionForPickerViewController(_ viewController: ProductPickerViewController) -> UICollectionViewScrollDirection {
        return .horizontal
    }

    func productPickerViewControllerCanRenderResults(_ viewController: ProductPickerViewController) -> Bool {
        if workOrderProductsPickerViewController != nil && viewController == workOrderProductsPickerViewController {
            if let workOrder = workOrder {
                return workOrder.materials != nil
            }
        } else if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
            return true
        }
        return false
    }

    func productPickerViewController(_ viewController: ProductPickerViewController, collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickerCollectionViewCell", for: indexPath) as! PickerCollectionViewCell
        let products = viewController.products

        if products.count > (indexPath as NSIndexPath).row - 1 {
            let product = products[(indexPath as NSIndexPath).row]

            cell.isSelected = viewController.isSelected(product)

            if cell.isSelected {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition())
            }

            cell.name = product.name

            if let imageUrl = product.imageUrl {
                cell.imageUrl = imageUrl
            } else if let profileImageUrl = product.barcodeDataURL {
                cell.rendersCircularImage = false
                cell.imageUrl = profileImageUrl
            }
        }

        if let gestureRecognizers = cell.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if gestureRecognizer.isKind(of: QueryResultsPickerCollectionViewCellGestureRecognizer.self)
                    || gestureRecognizer.isKind(of: WorkOrderProductsPickerCollectionViewCellGestureRecognizer.self) {
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

    func workOrderProductCreationViewController(_ viewController: WorkOrderProductCreationViewController, didUpdateWorkOrderProduct workOrderProduct: WorkOrderProduct) {
        viewController.presentingViewController?.dismissViewController(true)
        delegate?.workOrderInventoryViewController(self, didUpdateWorkOrderProduct: workOrderProduct)
    }

    fileprivate func reloadJobProductsForPickerViewController(_ viewController: ProductPickerViewController) {
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

    fileprivate func reloadWorkOrderProductsForPickerViewController(_ viewController: ProductPickerViewController) {
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

    fileprivate class QueryResultsPickerCollectionViewCellGestureRecognizer: KTDraggableViewGestureRecognizer {
        fileprivate var collectionView: UICollectionView!

        fileprivate var workOrderInventoryViewController: WorkOrderInventoryViewController!

        fileprivate var workOrderProductsPickerCollectionView: UICollectionView! {
            didSet {
                if let workOrderProductsPickerCollectionView = workOrderProductsPickerCollectionView {
                    initialWorkOrderProductsPickerCollectionViewBackgroundColor = workOrderProductsPickerCollectionView.backgroundColor
                }
            }
        }
        fileprivate var initialWorkOrderProductsPickerCollectionViewBackgroundColor: UIColor!

        fileprivate var shouldAddProduct = false

        fileprivate var window: UIWindow! {
            return UIApplication.shared.keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldAddProduct
        }

        init(viewController: WorkOrderInventoryViewController) {
            super.init(target: viewController, action: #selector(WorkOrderInventoryViewController.queryResultsPickerCollectionViewCellGestureRecognized(_:)))
            workOrderInventoryViewController = viewController
            workOrderProductsPickerCollectionView = viewController.workOrderProductsPickerViewController.collectionView
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
                    workOrderProductsPickerCollectionView.backgroundColor = initialWorkOrderProductsPickerCollectionViewBackgroundColor

                    if shouldAddProduct {
                        let indexPath = workOrderInventoryViewController.queryResultsPickerViewController.collectionView.indexPath(for: initialView as! UICollectionViewCell)!
                        if let jobProduct = workOrderInventoryViewController?.workOrder?.job?.jobProductForProduct(workOrderInventoryViewController.queryResultsPickerViewController.products[(indexPath as NSIndexPath).row]) {
                            workOrderInventoryViewController?.addWorkOrderJobProduct(jobProduct)
                        }
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

            if workOrderInventoryViewController.searchBar.isFirstResponder {
                workOrderInventoryViewController.searchBar.resignFirstResponder()
            }

            let workOrderProductsPickerCollectionViewFrame = workOrderProductsPickerCollectionView.superview!.convert(workOrderProductsPickerCollectionView.frame, to: nil)
            shouldAddProduct = !workOrderInventoryViewController.addingWorkOrderProduct && initialView.frame.intersects(workOrderProductsPickerCollectionViewFrame)

            if shouldAddProduct {
                workOrderProductsPickerCollectionView.backgroundColor = Color.completedStatusColor().withAlphaComponent(0.8)
            } else {
                workOrderProductsPickerCollectionView.backgroundColor = initialWorkOrderProductsPickerCollectionViewBackgroundColor
            }
        }
    }

    fileprivate class WorkOrderProductsPickerCollectionViewCellGestureRecognizer: KTDraggableViewGestureRecognizer {
        fileprivate var collectionView: UICollectionView!

        fileprivate var workOrderInventoryViewController: WorkOrderInventoryViewController!

        fileprivate var workOrderProductsPickerCollectionView: UICollectionView! {
            didSet {
                if let workOrderProductsPickerCollectionView = workOrderProductsPickerCollectionView {
                    initialWorkOrderProductsPickerCollectionViewBackgroundColor = workOrderProductsPickerCollectionView.backgroundColor
                }
            }
        }
        fileprivate var initialWorkOrderProductsPickerCollectionViewBackgroundColor: UIColor!

        fileprivate var shouldRemoveWorkOrderProduct = false

        fileprivate var window: UIWindow! {
            return UIApplication.shared.keyWindow!
        }

        var shouldAnimateViewReset: Bool {
            return !shouldRemoveWorkOrderProduct
        }

        init(viewController: WorkOrderInventoryViewController) {
            super.init(target: viewController, action: #selector(WorkOrderInventoryViewController.workOrderProductsPickerCollectionViewCellGestureRecognized(_:)))
            workOrderInventoryViewController = viewController
            workOrderProductsPickerCollectionView = viewController.workOrderProductsPickerViewController.collectionView
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
                    workOrderProductsPickerCollectionView.backgroundColor = initialWorkOrderProductsPickerCollectionViewBackgroundColor

                    if shouldRemoveWorkOrderProduct {
                        let indexPath = workOrderProductsPickerCollectionView.indexPath(for: initialView as! UICollectionViewCell)!
                        if let jobProduct = workOrderInventoryViewController?.workOrder?.job?.jobProductForProduct(workOrderInventoryViewController.workOrderProductsPickerViewController.products[(indexPath as NSIndexPath).row]) {
                            workOrderInventoryViewController?.removeWorkOrderJobProduct(jobProduct)
                        }
                    }

                    collectionView.isScrollEnabled = true
                    collectionView = nil

                    shouldRemoveWorkOrderProduct = false
                }
            }
        }

        fileprivate override func drag(_ xOffset: CGFloat, yOffset: CGFloat) {
            super.drag(xOffset, yOffset: yOffset)

            if initialView == nil || collectionView == nil {
                return
            }

            let workOrderProductsPickerCollectionViewFrame = workOrderProductsPickerCollectionView.superview!.convert(workOrderProductsPickerCollectionView.frame, to: nil)
            shouldRemoveWorkOrderProduct = !workOrderInventoryViewController.removingWorkOrderProduct && !initialView.frame.intersects(workOrderProductsPickerCollectionViewFrame)
            
            if shouldRemoveWorkOrderProduct {
                let accessoryImage = FAKFontAwesome.removeIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
                (initialView as! PickerCollectionViewCell).setAccessoryImage(accessoryImage, tintColor: Color.abandonedStatusColor())
            } else {
                (initialView as! PickerCollectionViewCell).accessoryImage = nil
            }
        }
    }
}
