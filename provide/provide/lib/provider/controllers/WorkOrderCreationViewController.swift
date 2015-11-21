//
//  WorkOrderCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/18/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol WorkOrderCreationViewControllerDelegate {
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, numberOfSectionsInTableView tableView: UITableView) -> Int
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, cellForTableView tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell!
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCreateWorkOrder workOrder: WorkOrder)
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, shouldBeDismissedWithWorkOrder workOrder: WorkOrder!)

}

class WorkOrderCreationViewController: WorkOrderDetailsViewController, ProviderPickerViewControllerDelegate, PDTSimpleCalendarViewDelegate {

    var delegate: WorkOrderCreationViewControllerDelegate!

    private var cancelItem: UIBarButtonItem! {
        let cancelItem = UIBarButtonItem(title: "CANCEL", style: .Plain, target: self, action: "cancel:")
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return cancelItem
    }

    private var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .Plain, target: self, action: "dismiss:")
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return dismissItem
    }

    private var saveItem: UIBarButtonItem! {
        let saveItem = UIBarButtonItem(title: "SAVE", style: .Plain, target: self, action: "createWorkOrder:")
        saveItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return saveItem
    }

    private var disabledSaveItem: UIBarButtonItem! {
        let saveItem = UIBarButtonItem(title: "SAVE", style: .Plain, target: self, action: "createWorkOrder:")
        saveItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Normal)
        saveItem.enabled = false
        return saveItem
    }

    private var activityIndicatorView: UIActivityIndicatorView {
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }

    private var isDirty = false

    private var isSaved: Bool {
        if let workOrder = workOrder {
            return workOrder.id > 0
        }
        return false
    }

    private var isValid: Bool {
        if let workOrder = workOrder {
            let validProviders = workOrder.providers.count > 0
            let validDate = workOrder.scheduledStartAt != nil
            return validProviders && validDate
        }
        return false
    }

    func cancel(sender: UIBarButtonItem!) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .Alert : .ActionSheet
        let alertController = UIAlertController(title: "Are you sure you want to cancel and discard changes?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Don't Cancel", style: .Default, handler: nil)
        alertController.addAction(cancelAction)

        let discardAction = UIAlertAction(title: "Discard", style: .Destructive) { action in
            self.delegate?.workOrderCreationViewController(self, shouldBeDismissedWithWorkOrder: nil)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(discardAction)

        presentViewController(alertController, animated: true)
    }

    func dismiss(sender: UIBarButtonItem!) {
        delegate?.workOrderCreationViewController(self, shouldBeDismissedWithWorkOrder: workOrder)
    }

    func createWorkOrder(sender: UIBarButtonItem) {
        navigationItem.titleView = activityIndicatorView

        workOrder.save(
            onSuccess: { statusCode, mappingResult in
                self.isDirty = false
                self.refreshUI()
                self.delegate?.workOrderCreationViewController(self, didCreateWorkOrder: self.workOrder)
            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    private func refreshUI() {
        refreshLeftBarButtonItems()
        refreshRightBarButtonItems()
        navigationItem.title = self.workOrder.customer.contact.name
        navigationItem.titleView = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //navigationItem.leftBarButtonItems = [cancelItem]
        //navigationItem.rightBarButtonItems = [disabledSaveItem]

        title = "CREATE WORK ORDER"

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "WORK ORDER", style: .Plain, target: nil, action: nil)

        refreshUI()
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let height = delegate?.workOrderCreationViewController(self, tableView: tableView, heightForRowAtIndexPath: indexPath) {
            return height
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sectionCount = delegate?.workOrderCreationViewController(self, numberOfSectionsInTableView: tableView) {
            return sectionCount
        }
        return super.numberOfSectionsInTableView(tableView)
    }

    // MARK: UITableViewDataSource

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let rowCount = delegate?.workOrderCreationViewController(self, tableView: tableView, numberOfRowsInSection: section) {
            return rowCount
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!

        if let c = delegate?.workOrderCreationViewController(self, cellForTableView: tableView, atIndexPath: indexPath) {
            cell = c
        } else {
            cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }

        return cell
    }

    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return tableView.cellForRowAtIndexPath(indexPath)?.accessoryType == .DisclosureIndicator
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if tableView.cellForRowAtIndexPath(indexPath)?.accessoryType == .DisclosureIndicator {
            return indexPath
        }
        return nil
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let navigationController = navigationController {
            var viewController: UIViewController!

            switch indexPath.row {
            case 0:
                print("0")
            case 1:
                viewController = UIStoryboard("ProviderPicker").instantiateInitialViewController()
                (viewController as! ProviderPickerViewController).delegate = self
                ApiService.sharedService().fetchProviders([:],
                    onSuccess: { statusCode, mappingResult in
                        let providers = mappingResult.array() as! [Provider]
                        (viewController as! ProviderPickerViewController).providers = providers
                    },
                    onError: { error, statusCode, responseString in

                    }
                )
            case 2:
                PDTSimpleCalendarViewCell.appearance().circleSelectedColor = Color.darkBlueBackground()
                PDTSimpleCalendarViewCell.appearance().textDisabledColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)

                let calendarViewController = PDTSimpleCalendarViewController()
                calendarViewController.delegate = self
                calendarViewController.weekdayHeaderEnabled = true
                calendarViewController.firstDate = NSDate()

                viewController = calendarViewController
            case 3:
                print("3")
            case 4:
                print("4")
            case 5:
                viewController = UIStoryboard("Provider").instantiateViewControllerWithIdentifier("ManifestViewController")
                (viewController as! ManifestViewController).delegate = self
            default:
                break
            }

            if let vc = viewController {
                navigationController.pushViewController(vc, animated: true)
            }
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    func refreshLeftBarButtonItems() {
        if isSaved {
            navigationItem.leftBarButtonItems = [dismissItem]
        } else {
            navigationItem.leftBarButtonItems = [cancelItem]
        }
    }

    func refreshRightBarButtonItems() {
        refreshSaveButton()
    }

    private func refreshSaveButton() {
        if isValid && isDirty {
            navigationItem.rightBarButtonItems = [saveItem]
        } else {
            navigationItem.rightBarButtonItems = [disabledSaveItem]
        }
    }

    // MARK: ProviderPickerViewControllerDelegate

    func providerPickerViewController(viewController: ProviderPickerViewController, didSelectProvider provider: Provider) {
        if !workOrder.hasProvider(provider) {
            let workOrderProvider = WorkOrderProvider()
            workOrderProvider.provider = provider

            workOrder.workOrderProviders.append(workOrderProvider)
            isDirty = true
        }
        refreshRightBarButtonItems()
    }

    func providerPickerViewController(viewController: ProviderPickerViewController, didDeselectProvider provider: Provider) {
        workOrder.removeProvider(provider)
        isDirty = true
        refreshRightBarButtonItems()
    }

    func providerPickerViewControllerAllowsMultipleSelection(viewController: ProviderPickerViewController) -> Bool {
        return true
    }

    func selectedProvidersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider] {
        return workOrder.workOrderProviders.map({ $0.provider })
    }

    // MARK: PDTSimpleCalendarViewControllerDelegate

    func simpleCalendarViewController(controller: PDTSimpleCalendarViewController!, didSelectDate date: NSDate!) {
        workOrder.scheduledStartAt = date.format("yyyy-MM-dd'T'HH:mm:ssZZ")
        isDirty = true
        refreshRightBarButtonItems()
    }

    func simpleCalendarViewController(controller: PDTSimpleCalendarViewController!, isEnabledDate date: NSDate!) -> Bool {
        if let scheduledStartAtDate = workOrder.scheduledStartAtDate {
            return scheduledStartAtDate.atMidnight != date.atMidnight
        }
        return true
    }
}
