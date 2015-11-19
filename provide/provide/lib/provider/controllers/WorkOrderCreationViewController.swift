//
//  WorkOrderCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/18/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol WorkOrderCreationViewControllerDelegate {
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, shouldBeDismissedWithWorkOrder workOrder: WorkOrder!)
}

class WorkOrderCreationViewController: WorkOrderDetailsViewController, ProviderPickerViewControllerDelegate {

    var delegate: WorkOrderCreationViewControllerDelegate!

    private var cancelItem: UIBarButtonItem! {
        let cancelItem = UIBarButtonItem(title: "CANCEL", style: .Plain, target: self, action: "cancel:")
        cancelItem.setTitleTextAttributes(AppearenceProxy.cancelBarButtonItemTitleTextAttributes(), forState: .Normal)
        return cancelItem
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

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItems = [cancelItem]

        title = "CREATE WORK ORDER"

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "WORK ORDER", style: .Plain, target: nil, action: nil)
    }

    // MARK: UITableViewDataSource

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("nameValueTableViewCellReuseIdentifier") as! NameValueTableViewCell
        cell.enableEdgeToEdgeDividers()

        switch indexPath.row {
        case 0:
            cell.setName("STATUS", value: workOrder.status)
            cell.backgroundView!.backgroundColor = workOrder.statusColor
        case 1:
            let providers = "\(workOrder.workOrderProviders.count) assigned"
            cell.setName("PROVIDERS", value: providers)
            cell.accessoryType = .DisclosureIndicator
        case 2:
            cell.setName("SCHEDULED START TIME", value: "")
            cell.accessoryType = .DisclosureIndicator
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
            let cost = workOrder.estimatedDuration == nil ? "--" : workOrder.humanReadableDuration!
            cell.setName("ESTIMATED COST", value: cost)
            cell.accessoryType = .DisclosureIndicator
        case 5:
            let inventoryDisposition = workOrder.inventoryDisposition == nil ? "--" : workOrder.inventoryDisposition
            cell.setName("INVENTORY DISPOSITION", value: inventoryDisposition, valueFontSize: 13.0)
            cell.accessoryType = .DisclosureIndicator
        default:
            break
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
                print("2")
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

    // MARK: ProviderPickerViewControllerDelegate

    func providerPickerViewController(viewController: ProviderPickerViewController, didSelectProvider provider: Provider) {
        if !workOrder.hasProvider(provider) {
            let workOrderProvider = WorkOrderProvider()
            workOrderProvider.provider = provider

            workOrder.workOrderProviders.append(workOrderProvider)
        }

        print("work order providers: \(workOrder.workOrderProviders)")
    }

    func providerPickerViewController(viewController: ProviderPickerViewController, didDeselectProvider provider: Provider) {
        workOrder.removeProvider(provider)
        print("work order providers: \(workOrder.workOrderProviders)")
    }

    func providerPickerViewControllerAllowsMultipleSelection(viewController: ProviderPickerViewController) -> Bool {
        return true
    }

    func selectedProvidersForPickerViewControllerAllowsMultipleSelection(viewController: ProviderPickerViewController) -> [Provider] {
        return workOrder.workOrderProviders.map({ $0.provider })
    }
}
