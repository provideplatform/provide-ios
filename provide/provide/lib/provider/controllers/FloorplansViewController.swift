//
//  FloorplansViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/18/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol FloorplansViewControllerDelegate {
    optional func floorplansViewController(viewController: FloorplansViewController, didSelectFloorplan floorplan: Floorplan)
    optional func companyIdForFloorplansViewController(viewController: FloorplansViewController) -> Int
    optional func customerIdForFloorplansViewController(viewController: FloorplansViewController) -> Int
}

class FloorplansViewController: ViewController,
                                UIPopoverPresentationControllerDelegate,
                                UICollectionViewDelegate,
                                UICollectionViewDataSource,
                                FloorplanCreationViewControllerDelegate {

    var delegate: FloorplansViewControllerDelegate! {
        didSet {
            if let _ = delegate {
                collectionView?.reloadData()
            }
        }
    }

    @IBOutlet private weak var collectionView: UICollectionView!

    @IBOutlet private weak var addFloorplanBarButtonItem: UIBarButtonItem! {
        didSet {
            if let addFloorplanBarButtonItem = addFloorplanBarButtonItem {
                addFloorplanBarButtonItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
            }
        }
    }

    private var floorplanCreationViewController: FloorplanCreationViewController!

    private var floorplans = [Floorplan]()

    private var page = 1
    private let rpp = 10
    private var lastFloorplanIndex = -1

    private var refreshControl: UIRefreshControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "FLOORPLANS"

        setupPullToRefresh()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "FloorplanViewControllerSegue" {
            if let sender = sender {
                //let navigationController = segue.destinationViewController as! UINavigationController
                //let floorplanViewController = navigationController.viewControllers.first! as! FloorplanViewController
                let floorplanViewController = segue.destinationViewController as! FloorplanViewController
                floorplanViewController.floorplan = (sender as! FloorplanCollectionViewCell).floorplan
            }
        } else if segue.identifier == "FloorplanCreationViewControllerPopoverSegue" {
            let navigationController = segue.destinationViewController as! UINavigationController
            navigationController.preferredContentSize = CGSizeMake(view.frame.width * 0.6, 650)
            navigationController.popoverPresentationController!.delegate = self

            floorplanCreationViewController = navigationController.viewControllers.first! as! FloorplanCreationViewController
            floorplanCreationViewController.delegate = self
        }
    }

    private func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "reset", forControlEvents: .ValueChanged)

        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true

        refresh()
    }

    func reset() {
        floorplans = [Floorplan]()
        page = 1
        lastFloorplanIndex = -1
        refresh()
    }

    func refresh() {
        if page == 1 {
            refreshControl.beginRefreshing()
        }

        let companyId = delegate?.companyIdForFloorplansViewController?(self) != nil ? delegate?.companyIdForFloorplansViewController?(self) : ApiService.sharedService().defaultCompanyId
        let customerId: Int! = delegate?.customerIdForFloorplansViewController?(self) != nil ? delegate?.customerIdForFloorplansViewController?(self) : nil

        if (companyId == nil || companyId > 0)
                && (customerId == nil || customerId > 0) {
            FloorplanService.sharedService().fetch(page,
                                                   rpp: rpp,
                                                   companyId: companyId,
                                                   customerId: customerId) { floorplans in
                self.floorplans += floorplans
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }

    }

    // MARK: UICollectionViewDelegate

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let floorplanIndex = indexPath.row
        if floorplanIndex == floorplans.count - 1 && floorplanIndex > lastFloorplanIndex {
            page += 1
            lastFloorplanIndex = floorplanIndex
            refresh()
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let floorplan = floorplans[indexPath.row]
        if let fn = delegate?.floorplansViewController {
            fn(self, didSelectFloorplan: floorplan)
        } else {
            performSegueWithIdentifier("FloorplanViewControllerSegue", sender: collectionView.cellForItemAtIndexPath(indexPath))
        }
    }

    // MARK: UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return floorplans.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("floorplanCollectionViewCellReuseIdentifier", forIndexPath: indexPath) as! FloorplanCollectionViewCell
        cell.floorplan = floorplans[indexPath.row]
        return cell
    }

//    @available(iOS 6.0, *)
//    optional public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
//
//    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
//    @available(iOS 6.0, *)
//    optional public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView
//
//    @available(iOS 9.0, *)
//    optional public func collectionView(collectionView: UICollectionView, canMoveItemAtIndexPath indexPath: NSIndexPath) -> Bool
//    @available(iOS 9.0, *)
//    optional public func collectionView(collectionView: UICollectionView, moveItemAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath)

    // MARK: FloorplanCreationViewControllerDelegate

    func floorplanCreationViewController(viewController: FloorplanCreationViewController, didCreateFloorplan floorplan: Floorplan) {
        print("created floorplan \(floorplan)")
    }

    func floorplanCreationViewController(viewController: FloorplanCreationViewController, didUpdateFloorplan floorplan: Floorplan) {
        // no-op
    }
}
