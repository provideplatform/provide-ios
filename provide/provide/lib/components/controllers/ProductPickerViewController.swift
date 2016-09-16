//
//  ProductPickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/14/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import RestKit
import KTSwiftExtensions

@objc
protocol ProductPickerViewControllerDelegate {
    func queryParamsForProductPickerViewController(_ viewController: ProductPickerViewController) -> [String : AnyObject]!
    func productPickerViewController(_ viewController: ProductPickerViewController, didSelectProduct product: Product)
    func productPickerViewController(_ viewController: ProductPickerViewController, didDeselectProduct: Product)
    func productPickerViewControllerAllowsMultipleSelection(_ viewController: ProductPickerViewController) -> Bool
    func productsForPickerViewController(_ viewController: ProductPickerViewController) -> [Product]
    func selectedProductsForPickerViewController(_ viewController: ProductPickerViewController) -> [Product]
    @objc optional func collectionViewScrollDirectionForPickerViewController(_ viewController: ProductPickerViewController) -> UICollectionViewScrollDirection
    @objc optional func productPickerViewControllerCanRenderResults(_ viewController: ProductPickerViewController) -> Bool
    @objc optional func productPickerViewController(_ viewController: ProductPickerViewController, collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell
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

    fileprivate var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(ProductPickerViewController.dismiss(_:)))
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        dismissItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        return dismissItem
    }

    fileprivate var inFlightRequestOperation: RKObjectRequestOperation!

    @IBOutlet fileprivate weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            if let _ = collectionView {
                if let _ = delegate {
                    reloadCollectionView()
                }
            }
        }
    }

    fileprivate var refreshControl: UIRefreshControl!

    var products = [Product]() {
        didSet {
            if products.count == 0 {
                selectedProducts = [Product]()
            }

            reloadCollectionView()

            activityIndicatorView?.stopAnimating()
            refreshControl?.endRefreshing()
        }
    }

    fileprivate var selectedProducts = [Product]()

    fileprivate var page = 1
    fileprivate let rpp = 15
    fileprivate var lastProductIndex = -1

    override func viewDidLoad() {
        super.viewDidLoad()

        if !isIPad() {
            navigationItem.leftBarButtonItems = [dismissItem]
        }
    }

    func dismiss(_ sender: UIBarButtonItem) {
        if let navigationController = navigationController {
            if navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            } else {
                navigationController.presentingViewController?.dismissViewController(true)
            }
        }
    }

    func showActivityIndicator() {
        activityIndicatorView?.startAnimating()
    }

    func hideActivityIndicator() {
        activityIndicatorView?.stopAnimating()
    }

    func setCollectionViewMinimumInteritemSpacing(_ spacing: CGFloat) {
        if  let collectionView = collectionView {
            if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                flowLayout.minimumInteritemSpacing = spacing
                reloadCollectionView()
            }
        }
    }

    func setCollectionViewMinimumLineSpacing(_ spacing: CGFloat) {
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

    fileprivate func setupPullToRefresh() {
        activityIndicatorView?.stopAnimating()

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ProductPickerViewController.reset), for: .valueChanged)

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
            activityIndicatorView?.startAnimating()
        }

        if var params = delegate.queryParamsForProductPickerViewController(self) {
            params["page"] = page as AnyObject?
            params["rpp"] = rpp as AnyObject?

            if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
                params["company_id"] = defaultCompanyId as AnyObject?
            }

            if let inFlightRequestOperation = inFlightRequestOperation {
                inFlightRequestOperation.cancel()
            }

            inFlightRequestOperation = ApiService.sharedService().fetchProducts(params,
                onSuccess: { statusCode, mappingResult in
                    self.inFlightRequestOperation = nil
                    let fetchedProducts = mappingResult?.array() as! [Product]
                    if self.page == 1 {
                        self.products = [Product]()
                    }
                    self.products += fetchedProducts

                    self.page += 1
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

    func isSelected(_ product: Product) -> Bool {
        for p in selectedProducts {
            if p.id == product.id {
                return true
            }
        }
        return false
    }

    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = delegate?.productPickerViewController?(self, collectionView: collectionView, cellForItemAtIndexPath: indexPath) {
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickerCollectionViewCell", for: indexPath) as! PickerCollectionViewCell

        if products.count > (indexPath as NSIndexPath).row - 1 {
            let product = products[(indexPath as NSIndexPath).row]

            cell.isSelected = isSelected(product)

            if cell.isSelected {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition())
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = products[(indexPath as NSIndexPath).row]
        delegate?.productPickerViewController(self, didSelectProduct: product)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let product = products[(indexPath as NSIndexPath).row]
        delegate?.productPickerViewController(self, didDeselectProduct: product)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
}
