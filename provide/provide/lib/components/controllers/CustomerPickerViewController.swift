//
//  CustomerPickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol CustomerPickerViewControllerDelegate {
    func queryParamsForCustomerPickerViewController(viewController: CustomerPickerViewController) -> [String : AnyObject]!
    func customerPickerViewController(viewController: CustomerPickerViewController, didSelectCustomer customer: Customer)
    func customerPickerViewController(viewController: CustomerPickerViewController, didDeselectCustomer customer: Customer)
    func customerPickerViewControllerAllowsMultipleSelection(viewController: CustomerPickerViewController) -> Bool
    func customersForPickerViewController(viewController: CustomerPickerViewController) -> [Customer]
    func selectedCustomersForPickerViewController(viewController: CustomerPickerViewController) -> [Customer]
    optional func collectionViewScrollDirectionForPickerViewController(viewController: CustomerPickerViewController) -> UICollectionViewScrollDirection
    optional func customerPickerViewControllerCanRenderResults(viewController: CustomerPickerViewController) -> Bool
    optional func customerPickerViewController(viewController: CustomerPickerViewController, collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
}

class CustomerPickerViewController: ViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var delegate: CustomerPickerViewControllerDelegate! {
        didSet {
            if let delegate = delegate {
                if oldValue == nil {
                    if let _ = delegate.queryParamsForCustomerPickerViewController(self) {
                        reset()
                    } else {
                        customers = [Customer]()
                        for customer in delegate.customersForPickerViewController(self) {
                            customers.append(customer)
                        }
                    }

                    selectedCustomers = [Customer]()
                    for customer in delegate.selectedCustomersForPickerViewController(self) {
                        selectedCustomers.append(customer)
                    }

                    reloadCollectionView()
                }
            }
        }
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

    var customers = [Customer]() {
        didSet {
            if customers.count == 0 {
                selectedCustomers = [Customer]()
            }

            reloadCollectionView()
        }
    }

    private var selectedCustomers = [Customer]()

    private var page = 1
    private let rpp = 10
    private var lastCustomerIndex = -1

    override func viewDidLoad() {
        super.viewDidLoad()

        if let _ = inFlightRequestOperation {
            activityIndicatorView?.startAnimating()
        }
    }

    func showActivityIndicator() {
        activityIndicatorView?.startAnimating()
    }

    func hideActivityIndicator() {
        activityIndicatorView?.stopAnimating()
    }

    func reloadCollectionView() {
        if let collectionView = collectionView {
            let collectionViewFlowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout

            if let scrollDirection = delegate?.collectionViewScrollDirectionForPickerViewController?(self) {
                collectionViewFlowLayout.scrollDirection = scrollDirection
            }

            collectionViewFlowLayout.minimumInteritemSpacing = 0.0
            collectionViewFlowLayout.minimumLineSpacing = 0.0
            collectionViewFlowLayout.itemSize = CGSize(width: 100.0, height: 100.0)

            var canRender = true
            if let canRenderResults = delegate?.customerPickerViewControllerCanRenderResults?(self) {
                canRender = canRenderResults
            }

            if canRender {
                collectionView.allowsMultipleSelection = delegate.customerPickerViewControllerAllowsMultipleSelection(self)

                selectedCustomers = [Customer]()
                for customer in delegate.selectedCustomersForPickerViewController(self) {
                    selectedCustomers.append(customer)
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
        refreshControl.addTarget(self, action: #selector(CustomerPickerViewController.reset), forControlEvents: .ValueChanged)

        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true
    }

    func reset() {
        if refreshControl == nil {
            //setupPullToRefresh()
        }

        customers = [Customer]()
        page = 1
        lastCustomerIndex = -1
        refresh()
    }

    func refresh() {
        if page == 1 {
            refreshControl?.beginRefreshing()
        }

        if var params = delegate.queryParamsForCustomerPickerViewController(self) {
            params["page"] = page
            params["rpp"] = rpp

            if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
                params["company_id"] = defaultCompanyId
            }

            if let inFlightRequestOperation = inFlightRequestOperation {
                inFlightRequestOperation.cancel()
            }

            if let customerId = params["customer_id"] as? Int {
                showActivityIndicator()

                inFlightRequestOperation = ApiService.sharedService().fetchCustomerWithId(String(customerId),
                    onSuccess: { statusCode, mappingResult in
                        self.inFlightRequestOperation = nil
                        let fetchedCustomer = mappingResult.firstObject as! Customer
                        self.customers = [fetchedCustomer]

                        self.reloadCollectionView()
                    },
                    onError: { error, statusCode, responseString in
                        self.inFlightRequestOperation = nil
                    }
                )
            } else if let _ = params["q"] as? String {
                showActivityIndicator()
                
                inFlightRequestOperation = ApiService.sharedService().fetchCustomers(params,
                    onSuccess: { statusCode, mappingResult in
                        self.inFlightRequestOperation = nil
                        let fetchedCustomers = mappingResult.array() as! [Customer]
                        if self.page == 1 {
                            self.customers = [Customer]()
                        }
                        self.customers += fetchedCustomers

                        self.reloadCollectionView()
                    },
                    onError: { error, statusCode, responseString in
                        self.inFlightRequestOperation = nil
                    }
                )
            }
        }
    }

    func isSelected(customer: Customer) -> Bool {
        for p in selectedCustomers {
            if p.id == customer.id {
                return true
            }
        }
        return false
    }

    // MARK - UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return customers.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if let cell = delegate?.customerPickerViewController?(self, collectionView: collectionView, cellForItemAtIndexPath: indexPath) {
            return cell
        }

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PickerCollectionViewCell", forIndexPath: indexPath) as! PickerCollectionViewCell

        if customers.count > indexPath.row - 1 {
            let customer = customers[indexPath.row]

            cell.selected = isSelected(customer)

            if cell.selected {
                collectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: .None)
            }

            cell.name = customer.contact.name

            if let profileImageUrl = customer.profileImageUrl {
                cell.imageUrl = profileImageUrl
            } else {
                cell.renderInitials()
            }
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let customer = customers[indexPath.row]
        delegate?.customerPickerViewController(self, didSelectCustomer: customer)
    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let customer = customers[indexPath.row]
        delegate?.customerPickerViewController(self, didDeselectCustomer: customer)
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}
