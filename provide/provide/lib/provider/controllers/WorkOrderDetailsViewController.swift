//
//  WorkOrderDetailsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/23/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol WorkOrderDetailsViewControllerDelegate {
    func workOrderDetailsViewController(viewController: WorkOrderDetailsViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int!
    func workOrderDetailsViewController(viewController: WorkOrderDetailsViewController, cellForTableView tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell!
}

class WorkOrderDetailsViewController: ViewController,
                                      UITableViewDelegate,
                                      UITableViewDataSource,
                                      UICollectionViewDelegate,
                                      UICollectionViewDataSource,
                                      WorkOrderDetailsHeaderTableViewControllerDelegate,
                                      ManifestViewControllerDelegate {

    var workOrder: WorkOrder! {
        didSet {
            navigationItem.title = title == nil ? (workOrder.category != nil ? workOrder.category.name : workOrder.customer.contact.name) : title

            if workOrder.id > 0 {
//                workOrder.reload(
//                    onSuccess: { statusCode, mappingResult in
//                        self.reloadTableView()
//                    },
//                    onError: { error, statusCode, responseString in
//
//                    }
//                )

                workOrder.reloadAttachments(
                    { statusCode, mappingResult in
                        self.mediaCollectionView?.reloadData()
                    },
                    onError: { error, statusCode, responseString in

                    }
                )

//                workOrder.reloadExpenses(
//                    { statusCode, mappingResult in
//                        self.reloadTableView()
//                    },
//                    onError: { error, statusCode, responseString in
//
//                    }
//                )
//
//                workOrder.reloadInventory(
//                    { statusCode, mappingResult in
//                        self.reloadTableView()
//                    },
//                    onError: { error, statusCode, responseString in
//                        
//                    }
//                )

                if let headerView = headerView {
                    headerView.workOrder = workOrder
                }

                if let headerTableViewController = headerTableViewController {
                    headerTableViewController.workOrderDetailsHeaderTableViewControllerDelegate = self
                    headerTableViewController.workOrder = workOrder
                }
            }

            if let _ = tableView {
                reloadTableView()
            }
        }
    }

    @IBOutlet private weak var tableView: UITableView!

    @IBOutlet private weak var headerView: WorkOrderDetailsHeaderView!
    @IBOutlet private weak var headerTableViewController: WorkOrderDetailsHeaderTableViewController!

    private var mediaCollectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let workOrder = workOrder {
            if workOrder.jobId == 0 {
                dispatch_after_delay(0.0) {
                    if let tableView = self.tableView {
                        self.headerView?.frame.size.width = tableView.frame.width
                    } else {
                        dispatch_after_delay(0.0) {
                            self.headerView?.frame.size.width = self.view.frame.width
                        }
                    }

                    self.headerView?.addDropShadow()
                    self.headerView?.workOrder = self.workOrder
                }
            } else {
                headerView?.hidden = true
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "WorkOrderDetailsHeaderTableViewControllerEmbedSegue" {
            if let workOrderDetailsHeaderTableViewController = segue.destinationViewController as? WorkOrderDetailsHeaderTableViewController {
                headerTableViewController = workOrderDetailsHeaderTableViewController
                if let workOrder = workOrder {
                    headerTableViewController.workOrderDetailsHeaderTableViewControllerDelegate = self
                    headerTableViewController.workOrder = workOrder
                }
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        tableView?.reloadData()
    }

    func reloadTableView() {
        tableView?.reloadData()

        if let headerTableViewController = headerTableViewController {
            headerTableViewController.reloadTableView()
        }

        if let mediaCollectionView = mediaCollectionView {
            mediaCollectionView.reloadData()
        }
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75.0
    }

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!

        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell = tableView.dequeueReusableCellWithIdentifier("mediaCollectionViewTableViewCellReuseIdentifier")! as UITableViewCell
                mediaCollectionView = cell.contentView.subviews.first as! UICollectionView
                mediaCollectionView.delegate = self
                mediaCollectionView.dataSource = self
            default:
                break
            }
        default:
            break
        }

        return cell
    }

    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row == 5
    }

    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.row == 5 {
            return indexPath
        }
        return nil
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let navigationController = navigationController {
            let manifestViewController = UIStoryboard("Manifest").instantiateViewControllerWithIdentifier("ManifestViewController") as! ManifestViewController
            manifestViewController.delegate = self

            navigationController.pushViewController(manifestViewController, animated: true)
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    //    optional func numberOfSectionsInTableView(tableView: UITableView) -> Int // Default is 1 if not implemented
    //
    //    optional func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? // fixed font style. use custom view (UILabel) if you want something different
    //    optional func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String?
    //
    //    // Editing
    //
    //    // Individual rows can opt out of having the -editing property set for them. If not implemented, all rows are assumed to be editable.
    //    optional func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    //
    //    // Moving/reordering
    //
    //    // Allows the reorder accessory view to optionally be shown for a particular row. By default, the reorder control will be shown only if the datasource implements -tableView:moveRowAtIndexPath:toIndexPath:
    //    optional func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool
    //
    //    // Index
    //
    //    optional func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! // return list of section titles to display in section index view (e.g. "ABCD...Z#")
    //    optional func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int // tell table which section corresponds to section title/index (e.g. "B",1))
    //
    //    // Data manipulation - insert and delete support
    //
    //    // After a row has the minus or plus button invoked (based on the UITableViewCellEditingStyle for the cell), the dataSource must commit the change
    //    // Not called for edit actions using UITableViewRowAction - the action's handler will be invoked instead
    //    optional func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    //
    //    // Data manipulation - reorder / moving support
    //
    //    optional func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath)

    // MARK: UICollectionViewDelegate

//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
//        return UIEdgeInsetsMake(10.0, 10.0, 0.0, 0.0)
//    }

//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
//        return CGSize(width: 180.0, height: 180.0)
//    }

    // MARK: UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let attachments = workOrder.attachments {
            return attachments.count
        }
        return 0
    }

    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCollectionViewCellReuseIdentifier", forIndexPath: indexPath) as! ImageCollectionViewCell
        cell.imageUrl = workOrder.attachments[indexPath.row].url
        return cell
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
//    optional func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView

    // MARK: WorkOrderDetailsHeaderTableViewControllerDelegate

    func workOrderCreationViewControllerForDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController) -> WorkOrderCreationViewController! {
        return nil
    }

    func workOrderDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController, shouldStartWorkOrder workOrder: WorkOrder)  {

    }

    func workOrderDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController, shouldCancelWorkOrder workOrder: WorkOrder) {

    }

    func workOrderDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController, shouldCompleteWorkOrder workOrder: WorkOrder) {

    }

    func workOrderDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController, shouldSubmitForApprovalWorkOrder workOrder: WorkOrder) {

    }

    func workOrderDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController, shouldApproveWorkOrder workOrder: WorkOrder) {

    }

    func workOrderDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController, shouldRejectWorkOrder workOrder: WorkOrder) {

    }

    func workOrderDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController, shouldRestartWorkOrder workOrder: WorkOrder) {

    }

    // MARK: ManifestViewControllerDelegate

    func workOrderForManifestViewController(viewController: UIViewController) -> WorkOrder! {
        return workOrder
    }

    func navigationControllerBackItemTitleForManifestViewController(viewController: UIViewController) -> String! {
        return "BACK"
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
