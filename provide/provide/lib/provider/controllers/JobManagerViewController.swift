//
//  JobManagerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobManagerViewControllerDelegate {
    func jobManagerViewController(viewController: JobManagerViewController, numberOfSectionsInTableView tableView: UITableView) -> Int
    func jobManagerViewController(viewController: JobManagerViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func jobManagerViewController(viewController: JobManagerViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    func jobManagerViewController(viewController: JobManagerViewController, cellForTableView tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell!
    func jobManagerViewController(viewController: JobManagerViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    func jobManagerViewController(viewController: JobManagerViewController, didCreateExpense expense: Expense)
}

class JobManagerViewController: ViewController, PDTSimpleCalendarViewDelegate {

    var delegate: JobManagerViewControllerDelegate!

    weak var job: Job! {
        didSet {
            if let job = job {
                navigationItem.title = title == nil ? job.name : title

                //            job.reloadAttachments(
                //                { statusCode, mappingResult in
                //                    self.mediaCollectionView?.reloadData()
                //                },
                //                onError: { error, statusCode, responseString in
                //
                //                }
                //            )
                //
                //            job.reloadExpenses(
                //                { statusCode, mappingResult in
                //                    self.reloadTableView()
                //                },
                //                onError: { error, statusCode, responseString in
                //
                //                }
                //            )
                //
                //            job.reloadInventory(
                //                { statusCode, mappingResult in
                //                    self.reloadTableView()
                //                },
                //                onError: { error, statusCode, responseString in
                //
                //                }
                //            )
                
                if let tableView = tableView {
                    tableView.reloadData()
                }
                
                if let headerView = headerView {
                    headerView.job = job
                }
                
                if job.status == "in_progress" || job.status == "en_route" {
                    timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "refreshInProgress", userInfo: nil, repeats: true)
                }
            }
        }
    }

    @IBOutlet private weak var tableView: UITableView!

    @IBOutlet private weak var headerView: JobDetailsHeaderView!

    private var mediaCollectionView: UICollectionView!

    private var timer: NSTimer!

    override func viewDidLoad() {
        super.viewDidLoad()

        dispatch_after_delay(0.0) {
            self.headerView.frame.size.width = self.tableView.frame.width
            self.headerView.addDropShadow()
            self.headerView.job = self.job
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadData()
    }

    func reloadTableView() {
        tableView.reloadData()

        if let mediaCollectionView = mediaCollectionView {
            mediaCollectionView.reloadData()
        }
    }

    func refreshInProgress() {
        if let tableView = tableView {
            var statusCell: NameValueTableViewCell!
//            var durationCell: NameValueTableViewCell!

            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? NameValueTableViewCell {
                statusCell = cell

                UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseIn,
                    animations: {
                        statusCell.backgroundView!.backgroundColor = Color.completedStatusColor()

                        let alpha = statusCell.backgroundView!.alpha == 0.0 ? 0.9 : 0.0
                        statusCell.backgroundView!.alpha = CGFloat(alpha)
                    },
                    completion: { complete in

                    }
                )
            }

//            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 4, inSection: 0)) as? NameValueTableViewCell {
//                durationCell = cell
//
                // FIXME
//                if let duration = job.humanReadableDuration {
//                    durationCell.setName("DURATION", value: duration)
//                }
//            }
        }
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let delegate = delegate {
            delegate.jobManagerViewController(self, tableView: tableView, heightForRowAtIndexPath: indexPath)
        }
        return 0.0
    }

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let delegate = delegate {
            return delegate.jobManagerViewController(self, numberOfSectionsInTableView: tableView)
        }
        return 0
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let delegate = delegate {
            return delegate.jobManagerViewController(self, tableView: tableView, numberOfRowsInSection: section)
        }
        return 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let delegate = delegate {
            delegate.jobManagerViewController(self, cellForTableView: tableView, atIndexPath: indexPath)
        }
        return UITableViewCell()
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
            //manifestViewController.delegate = self

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
        if let attachments = job.attachments {
            return attachments.count
        }
        return 0
    }

    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCollectionViewCellReuseIdentifier", forIndexPath: indexPath) as! ImageCollectionViewCell
        cell.imageUrl = job.attachments[indexPath.row].url
        return cell
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
    //    optional func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView
    
    // MARK: ManifestViewControllerDelegate
    
    func workOrderForManifestViewController(viewController: UIViewController) -> WorkOrder! {
        return nil //workOrder
    }
    
    func navigationControllerBackItemTitleForManifestViewController(viewController: UIViewController) -> String! {
        return "BACK"
    }

    // MARK: PDTSimpleCalendarViewControllerDelegate

    func simpleCalendarViewController(controller: PDTSimpleCalendarViewController!, didSelectDate date: NSDate!) {
        //        workOrder.scheduledStartAt = date.format("yyyy-MM-dd'T'HH:mm:ssZZ")
        //        isDirty = true
        //        refreshRightBarButtonItems()
    }

    func simpleCalendarViewController(controller: PDTSimpleCalendarViewController!, isEnabledDate date: NSDate!) -> Bool {
        //        if let scheduledStartAtDate = workOrder.scheduledStartAtDate {
        //            return scheduledStartAtDate.atMidnight != date.atMidnight
        //        }
        return true
    }
    
    deinit {
        timer?.invalidate()
    }
}
