//
//  WorkOrderDetailsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/23/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol WorkOrderDetailsViewControllerDelegate {
    func workOrderDetailsViewController(_ viewController: WorkOrderDetailsViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int!
    func workOrderDetailsViewController(_ viewController: WorkOrderDetailsViewController, cellForTableView tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell!
}

class WorkOrderDetailsViewController: ViewController,
                                      UITableViewDelegate,
                                      UITableViewDataSource,
                                      UICollectionViewDelegate,
                                      UICollectionViewDataSource,
                                      WorkOrderDetailsHeaderTableViewControllerDelegate {

    var workOrder: WorkOrder! {
        didSet {
            dispatch_after_delay(0.0) {
                self.refresh()
            }
        }
    }

    @IBOutlet fileprivate weak var tableView: UITableView!

    @IBOutlet fileprivate weak var headerView: WorkOrderDetailsHeaderView!
    @IBOutlet fileprivate weak var headerTableViewController: WorkOrderDetailsHeaderTableViewController!

    fileprivate var mediaCollectionView: UICollectionView!

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
                headerView?.isHidden = true
            }
        }
    }

    fileprivate func refresh() {
        navigationItem.title = title == nil ? workOrder.customer.contact.name : title

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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier! == "WorkOrderDetailsHeaderTableViewControllerEmbedSegue" {
            if let workOrderDetailsHeaderTableViewController = segue.destination as? WorkOrderDetailsHeaderTableViewController {
                headerTableViewController = workOrderDetailsHeaderTableViewController
                if let workOrder = workOrder {
                    headerTableViewController.workOrderDetailsHeaderTableViewControllerDelegate = self
                    headerTableViewController.workOrder = workOrder
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
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

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!

        switch (indexPath as NSIndexPath).section {
        case 0:
            switch (indexPath as NSIndexPath).row {
            case 0:
                cell = tableView.dequeueReusableCell(withIdentifier: "mediaCollectionViewTableViewCellReuseIdentifier")! as UITableViewCell
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

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return (indexPath as NSIndexPath).row == 5
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if (indexPath as NSIndexPath).row == 5 {
            return indexPath
        }
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let attachments = workOrder.attachments {
            return attachments.count
        }
        return 0
    }

    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCollectionViewCellReuseIdentifier", for: indexPath) as! ImageCollectionViewCell
        cell.imageUrl = workOrder.attachments[(indexPath as NSIndexPath).row].url
        return cell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
//    optional func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView

    // MARK: WorkOrderDetailsHeaderTableViewControllerDelegate

    func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldStartWorkOrder workOrder: WorkOrder)  {

    }

    func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldCancelWorkOrder workOrder: WorkOrder) {

    }

    func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldCompleteWorkOrder workOrder: WorkOrder) {

    }

    func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldSubmitForApprovalWorkOrder workOrder: WorkOrder) {

    }

    func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldApproveWorkOrder workOrder: WorkOrder) {

    }

    func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldRejectWorkOrder workOrder: WorkOrder) {

    }

    func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldRestartWorkOrder workOrder: WorkOrder) {

    }

    // MARK: ManifestViewControllerDelegate

    func workOrderForManifestViewController(_ viewController: UIViewController) -> WorkOrder! {
        return workOrder
    }

    func navigationControllerBackItemTitleForManifestViewController(_ viewController: UIViewController) -> String! {
        return "BACK"
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
