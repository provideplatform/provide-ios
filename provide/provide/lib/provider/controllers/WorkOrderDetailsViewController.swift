//
//  WorkOrderDetailsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/23/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderDetailsViewController: ViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, ManifestViewControllerDelegate {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var headerView: WorkOrderDetailsHeaderView!
    private var mediaCollectionView: UICollectionView!

    private var timer: NSTimer!

    var workOrder: WorkOrder! {
        didSet {
            navigationItem.title = workOrder.customer.contact.name

            workOrder.reloadAttachments(
                { statusCode, mappingResult in
                    self.mediaCollectionView?.reloadData()
                    //self.mediaCollectionView.layoutIfNeeded()
                },
                onError: { error, statusCode, responseString in

                }
            )

            if let tableView = tableView {
                tableView.reloadData()
                tableView.layoutIfNeeded()
            }

            if let headerView = headerView {
                headerView.workOrder = workOrder
            }

            if workOrder.status == "in_progress" || workOrder.status == "en_route" {
                timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "refreshInProgress", userInfo: nil, repeats: true)
                timer.fire()
            }
        }
    }

    private var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "BACK", style: .Plain, target: self, action: "dismiss")
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return dismissItem
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItems = [dismissItem]

        tableView.frame = view.bounds

        headerView.frame.size.width = tableView.frame.width
        headerView.addDropShadow()
        headerView.workOrder = workOrder
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        tableView.reloadData()
        tableView.layoutIfNeeded()
    }

    func refreshInProgress() {
        if let tableView = tableView {
            var statusCell: NameValueTableViewCell!
            var durationCell: NameValueTableViewCell!

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

            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 4, inSection: 0)) as? NameValueTableViewCell {
                durationCell = cell

                if let duration = workOrder.humanReadableDuration {
                    durationCell.setName("DURATION", value: duration)
                }
            }
        }
    }

    func dismiss() {
        timer?.invalidate()

        if let navigationController = navigationController {
            navigationController.popViewControllerAnimated(true)
        }
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 200.0
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("mediaCollectionViewTableViewCellReuseIdentifier")! as UITableViewCell
        mediaCollectionView = cell.contentView.subviews.first as! UICollectionView
        mediaCollectionView.delegate = self
        mediaCollectionView.dataSource = self
        return cell
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("nameValueTableViewCellReuseIdentifier") as! NameValueTableViewCell
        cell.enableEdgeToEdgeDividers()

        switch indexPath.row {
        case 0:
            cell.setName("STATUS", value: workOrder.status)
            cell.backgroundView!.backgroundColor = workOrder.statusColor
        case 1:
            let scheduledStartAt = workOrder.scheduledStartAtDate == nil ? "--" : workOrder.scheduledStartAtDate.timeString!
            cell.setName("SCHEDULED START TIME", value: scheduledStartAt)
        case 2:
            let startedAt = workOrder.startedAtDate == nil ? "--" : workOrder.startedAtDate.timeString!
            cell.setName("STARTED AT", value: startedAt)
        case 3:
            if let endedAt = workOrder.endedAtDate {
                cell.setName("ENDED AT", value: endedAt.timeString!)
            } else if let abandonedAt = workOrder.abandonedAtDate {
                cell.setName("ABANDONED AT", value: abandonedAt.timeString!)
            } else if let canceledAt = workOrder.canceledAtDate {
                cell.setName("CANCELED AT", value: canceledAt.timeString!)
            } else if let _ = workOrder.startedAtDate {
                let providers = workOrder.workOrderProviders
                if providers.count > 0 {
                    cell.setName("OWNER", value: providers.first!.provider.contact.name)
                    //cell.setName("CREW", )
                }
            }
        case 4:
            let duration = workOrder.humanReadableDuration == nil ? "--" : workOrder.humanReadableDuration!
            cell.setName("DURATION", value: duration)
        case 5:
            cell.setName("INVENTORY DISPOSITION", value: workOrder.inventoryDisposition, valueFontSize: 13.0)
            cell.accessoryType = .DisclosureIndicator
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
            let manifestViewController = UIStoryboard("Provider").instantiateViewControllerWithIdentifier("ManifestViewController") as! ManifestViewController
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

    // MARK: ManifestViewControllerDelegate

    func workOrderForManifestViewController(viewController: UIViewController) -> WorkOrder! {
        return workOrder
    }

    func navigationControllerBackItemTitleForManifestViewController(viewController: UIViewController) -> String! {
        return "BACK"
    }
}
