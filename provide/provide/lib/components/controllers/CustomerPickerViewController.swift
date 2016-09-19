//
//  CustomerPickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/12/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import RestKit
import KTSwiftExtensions

@objc
protocol CustomerPickerViewControllerDelegate {
    func queryParamsForCustomerPickerViewController(_ viewController: CustomerPickerViewController) -> [String : AnyObject]!
    func customerPickerViewController(_ viewController: CustomerPickerViewController, didSelectCustomer customer: Customer)
    func customerPickerViewController(_ viewController: CustomerPickerViewController, didDeselectCustomer customer: Customer)
    func customerPickerViewControllerAllowsMultipleSelection(_ viewController: CustomerPickerViewController) -> Bool
    func customersForPickerViewController(_ viewController: CustomerPickerViewController) -> [Customer]
    func selectedCustomersForPickerViewController(_ viewController: CustomerPickerViewController) -> [Customer]
    @objc optional func collectionViewScrollDirectionForPickerViewController(_ viewController: CustomerPickerViewController) -> UICollectionViewScrollDirection
    @objc optional func customerPickerViewControllerCanRenderResults(_ viewController: CustomerPickerViewController) -> Bool
    @objc optional func customerPickerViewController(_ viewController: CustomerPickerViewController, collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell
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

    var customers = [Customer]() {
        didSet {
            if customers.count == 0 {
                selectedCustomers = [Customer]()
            }

            reloadCollectionView()
        }
    }

    fileprivate var selectedCustomers = [Customer]()

    fileprivate var page = 1
    fileprivate let rpp = 10
    fileprivate var lastCustomerIndex = -1

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

    fileprivate func setupPullToRefresh() {
        activityIndicatorView?.stopAnimating()

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(CustomerPickerViewController.reset), for: .valueChanged)

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
            params["page"] = page as AnyObject
            params["rpp"] = rpp as AnyObject

            if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
                params["company_id"] = defaultCompanyId as AnyObject
            }

            if let inFlightRequestOperation = inFlightRequestOperation {
                inFlightRequestOperation.cancel()
            }

            if let customerId = params["customer_id"] as? Int {
                showActivityIndicator()

                inFlightRequestOperation = ApiService.sharedService().fetchCustomerWithId(String(customerId),
                    onSuccess: { statusCode, mappingResult in
                        self.inFlightRequestOperation = nil
                        let fetchedCustomer = mappingResult?.firstObject as! Customer
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
                        let fetchedCustomers = mappingResult?.array() as! [Customer]
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

    func isSelected(_ customer: Customer) -> Bool {
        for p in selectedCustomers {
            if p.id == customer.id {
                return true
            }
        }
        return false
    }

    // MARK - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return customers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = delegate?.customerPickerViewController?(self, collectionView: collectionView, cellForItemAtIndexPath: indexPath) {
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickerCollectionViewCell", for: indexPath) as! PickerCollectionViewCell

        if customers.count > (indexPath as NSIndexPath).row - 1 {
            let customer = customers[(indexPath as NSIndexPath).row]

            cell.isSelected = isSelected(customer)

            if cell.isSelected {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition())
            }

            cell.name = customer.contact.name

            if let profileImageUrl = customer.profileImageUrl {
                cell.imageUrl = profileImageUrl
            } else if let email = customer.contact?.email {
                cell.gravatarEmail = email
            } else {
                cell.renderInitials()
            }
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let customer = customers[(indexPath as NSIndexPath).row]
        delegate?.customerPickerViewController(self, didSelectCustomer: customer)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let customer = customers[(indexPath as NSIndexPath).row]
        delegate?.customerPickerViewController(self, didDeselectCustomer: customer)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
}
