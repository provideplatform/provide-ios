//
//  ProductPickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/14/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol ProductPickerViewControllerDelegate {
    func queryParamsForProductPickerViewController(viewController: ProductPickerViewController) -> [String : AnyObject]!
    func productPickerViewController(viewController: ProductPickerViewController, didSelectProduct product: Product)
    func productPickerViewController(viewController: ProductPickerViewController, didDeselectProduct: Product)
    func productPickerViewControllerAllowsMultipleSelection(viewController: ProductPickerViewController) -> Bool
    func productsForPickerViewController(viewController: ProductPickerViewController) -> [Product]
    func selectedProductsForPickerViewController(viewController: ProductPickerViewController) -> [Product]
    optional func collectionViewScrollDirectionForPickerViewController(viewController: ProductPickerViewController) -> UICollectionViewScrollDirection
    optional func productPickerViewControllerCanRenderResults(viewController: ProductPickerViewController) -> Bool
    optional func productPickerViewController(viewController: ProductPickerViewController, collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
}

class ProductPickerViewController: ViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var delegate: ProductPickerViewControllerDelegate! {
        didSet {
            if let delegate = delegate {
                if oldValue == nil {
                    if let _ = delegate.queryParamsForProductPickerViewController(self) {
                        reset()
                    } else {
                        products = [Product]()
                        for product in delegate.productsForPickerViewController(self) {
                            products.append(product)
                        }
                    }

                    selectedProducts = [Product]()
                    for product in delegate.selectedProductsForPickerViewController(self) {
                        selectedProducts.append(product)
                    }

                    reloadCollectionView()
                }
            }
        }
    }

    private var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: "dismiss:")
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        dismissItem.tintColor = UIColor.whiteColor()
        return dismissItem
    }

    private var inFlightRequestOperation: RKObjectRequestOperation!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            if let _ = collectionView {
                if let _ = delegate {
                    reloadCollectionView()
                }
            }
        }
    }

    private var refreshControl: UIRefreshControl!

    var products = [Product]() {
        didSet {
            if products.count == 0 {
                selectedProducts = [Product]()
            }

            reloadCollectionView()
        }
    }

    private var selectedProducts = [Product]()

    private var page = 1
    private let rpp = 15
    private var lastProductIndex = -1

    override func viewDidLoad() {
        super.viewDidLoad()

        if !isIPad() {
            navigationItem.leftBarButtonItems = [dismissItem]
        }

        activityIndicatorView?.startAnimating()
    }

    func dismiss(sender: UIBarButtonItem) {
        if let navigationController = navigationController {
            if navigationController.viewControllers.count > 1 {
                navigationController.popViewControllerAnimated(true)
            } else {
                navigationController.presentingViewController?.dismissViewController(animated: true)
            }
        }
    }

    func showActivityIndicator() {
        activityIndicatorView?.startAnimating()
    }

    func hideActivityIndicator() {
        activityIndicatorView?.stopAnimating()
    }

    func setCollectionViewMinimumInteritemSpacing(spacing: CGFloat) {
        if  let collectionView = collectionView {
            if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                flowLayout.minimumInteritemSpacing = spacing
                reloadCollectionView()
            }
        }
    }

    func setCollectionViewMinimumLineSpacing(spacing: CGFloat) {
        if  let collectionView = collectionView {
            if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                flowLayout.minimumLineSpacing = spacing
                reloadCollectionView()
            }
        }
    }

    func reloadCollectionView() {
        if let collectionView = collectionView {
            let collectionViewFlowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout

            if let scrollDirection = delegate?.collectionViewScrollDirectionForPickerViewController?(self) {
                collectionViewFlowLayout.scrollDirection = scrollDirection
            }

            collectionViewFlowLayout.itemSize = CGSize(width: 150.0, height: 100.0)

            var canRender = true
            if let canRenderResults = delegate?.productPickerViewControllerCanRenderResults?(self) {
                canRender = canRenderResults
            }

            if canRender {
                collectionView.allowsMultipleSelection = delegate.productPickerViewControllerAllowsMultipleSelection(self)

                selectedProducts = [Product]()
                for product in delegate.selectedProductsForPickerViewController(self) {
                    selectedProducts.append(product)
                }

                activityIndicatorView?.stopAnimating()
                refreshControl?.endRefreshing()
                collectionView.reloadData()
            } else {
                dispatch_after_delay(0.0) {
                    self.reloadCollectionView()
                }
            }
        }
    }

    private func setupPullToRefresh() {
        activityIndicatorView?.stopAnimating()

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "reset", forControlEvents: .ValueChanged)

        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true
    }

    func reset() {
        if refreshControl == nil {
            //setupPullToRefresh()
        }

        products = [Product]()
        page = 1
        lastProductIndex = -1
        refresh()
    }

    func refresh() {
        if page == 1 {
            refreshControl?.beginRefreshing()
        }

        if var params = delegate.queryParamsForProductPickerViewController(self) {
            params["page"] = page
            params["rpp"] = rpp

            if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
                params["company_id"] = defaultCompanyId
            }

            if let inFlightRequestOperation = inFlightRequestOperation {
                inFlightRequestOperation.cancel()
            }

            inFlightRequestOperation = ApiService.sharedService().fetchProducts(params,
                onSuccess: { statusCode, mappingResult in
                    self.inFlightRequestOperation = nil
                    let fetchedProducts = mappingResult.array() as! [Product]
                    if self.page == 1 {
                        self.products = [Product]()
                    }
                    self.products += fetchedProducts

                    self.page++
                    self.reloadCollectionView()
                },
                onError: { error, statusCode, responseString in
                    self.inFlightRequestOperation = nil
                }
            )
        } else {
            activityIndicatorView?.stopAnimating()
        }
    }

    func isSelected(product: Product) -> Bool {
        for p in selectedProducts {
            if p.id == product.id {
                return true
            }
        }
        return false
    }

    // MARK: UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if let cell = delegate?.productPickerViewController?(self, collectionView: collectionView, cellForItemAtIndexPath: indexPath) {
            return cell
        }

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PickerCollectionViewCell", forIndexPath: indexPath) as! PickerCollectionViewCell

        if products.count > indexPath.row - 1 {
            let product = products[indexPath.row]

            cell.selected = isSelected(product)

            if cell.selected {
                collectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: .None)
            }

            cell.name = product.name

            if let imageUrl = product.imageUrl {
                cell.imageUrl = imageUrl
            } else if let imageUrl = product.barcodeDataURL {
                cell.imageUrl = imageUrl
            }
        }

        return cell
    }

    // MARK: UICollectionViewDelegate

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let product = products[indexPath.row]
        delegate?.productPickerViewController(self, didSelectProduct: product)
    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let product = products[indexPath.row]
        delegate?.productPickerViewController(self, didDeselectProduct: product)
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}
