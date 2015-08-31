//
//  ConsumerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/5/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class ConsumerViewController: ViewController, ProviderPickerViewControllerDelegate, ServicePickerViewControllerDelegate, AppointmentSchedulerViewControllerDelegate {

    private var managedViewControllers = [ViewController]()

    @IBOutlet private weak var mapView: WorkOrderMapView!
    @IBOutlet private weak var tableView: UITableView!

    private var provider: Provider!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true

        let providerPickerViewController = UIStoryboard("ProviderPicker").instantiateInitialViewController() as! ProviderPickerViewController
        providerPickerViewController.delegate = self

        managedViewControllers.append(providerPickerViewController)

        view.addSubview(providerPickerViewController.view)

        ProviderService.sharedService().fetch(
            onProvidersFetched: { providers in
                providerPickerViewController.providers = providers
            }
        )
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        managedViewControllers.append(segue.destinationViewController as! ViewController)

        switch segue.identifier! {

        default:
            break
        }
    }

    // MARK: ProviderPickerViewControllerDelegate

    func providerPickerViewController(viewController: ProviderPickerViewController, didSelectProvider provider: Provider) {
        let servicePickerViewController = UIStoryboard("ServicePicker").instantiateInitialViewController() as! ServicePickerViewController
        servicePickerViewController.delegate = self
        servicePickerViewController.title = provider.name
        if let services = provider.services {
            servicePickerViewController.services = Array(services) as! [Service]
        }

        managedViewControllers.append(servicePickerViewController)

        navigationController?.pushViewController(servicePickerViewController, animated: true)

        dispatch_after_delay(0.25) {
            let fakeService1 = Service()
            fakeService1.name = "Hair Cut"

            let fakeService2 = Service()
            fakeService2.name = "Shampoo"

            servicePickerViewController.services = [fakeService1, fakeService2]
        }

        self.provider = provider
    }

    // MARK: ServicePickerViewControllerDelegate

    func servicePickerViewController(viewController: ServicePickerViewController, didSelectService service: Service) {
        let appointmentSchedulerViewController = UIStoryboard("AppointmentScheduler").instantiateInitialViewController() as! AppointmentSchedulerViewController
        appointmentSchedulerViewController.delegate = self
        appointmentSchedulerViewController.title = "When?"

        managedViewControllers.append(appointmentSchedulerViewController)

        navigationController?.pushViewController(appointmentSchedulerViewController, animated: true)
    }

    // MARK: AppointmentSchedulerViewControllerDelegate

    func minimumDateForAppointmentSchedulerViewController(viewController: AppointmentSchedulerViewController) -> NSDate {
        return NSDate()
    }

    func maximumDateForAppointmentSchedulerViewController(viewController: AppointmentSchedulerViewController) -> NSDate {
        return NSDate().dateByAddingTimeInterval(60 * 60 * 24 * 30)
    }

    func appointmentSchedulerViewController(viewController: AppointmentSchedulerViewController, didSelectDesiredDate date: NSDate) {
        ApiService.sharedService().fetchProviderAvailability(String(provider.id), params: ["date_range": "\(date)..\(date.dateByAddingTimeInterval(60*60*24))"],
            onSuccess: { (statusCode, mappingResult) -> () in
                var dates = [NSDate]()
                for dateString in mappingResult.array() {
                    dates.append(NSDate.fromString(dateString as! String))
                }
                self.pushConfirmationViewController(dates)
            }, onError: { (error, statusCode, responseString) -> () in

            }
        )
    }

    func appointmentSchedulerViewController(viewController: AppointmentSchedulerViewController, offeredAppointmentDateWithAvailableDates availableDates: [NSDate]) -> NSDate {
        var date: NSDate!
        let i = availableDates.count / 2
        if i <= availableDates.count - 1 {
            date = availableDates[i]
        }
        return date
    }

    func appointmentSchedulerViewController(viewController: AppointmentSchedulerViewController, confimationTextForTextView textView: UITextView, offeredDate: NSDate) -> String {
        return "\(provider.firstName) has a \(offeredDate.timeString) available on \(offeredDate.dayOfWeek), \(offeredDate.monthName) \(offeredDate.dayOfMonth). Does that work for you?"
    }

    func appointmentSchedulerViewController(viewController: AppointmentSchedulerViewController, confimationTextForTextView textView: UITextView, confirmedDate: NSDate) -> String {
        return "Congrats! You have an appointment scheduled with \(provider.firstName) on \(confirmedDate.dayOfWeek), \(confirmedDate.monthName) \(confirmedDate.dayOfMonth) at \(confirmedDate.timeString)."
    }

    private func pushConfirmationViewController(dates: [NSDate]) {
        let appointmentSchedulerViewController = UIStoryboard("AppointmentScheduler").instantiateInitialViewController() as! AppointmentSchedulerViewController
        appointmentSchedulerViewController.delegate = self
        appointmentSchedulerViewController.title = "Confirmation"
        appointmentSchedulerViewController.availableAppointmentDates = dates

        managedViewControllers.append(appointmentSchedulerViewController)

        navigationController?.pushViewController(appointmentSchedulerViewController, animated: true)
    }

    func appointmentSchedulerViewController(viewController: AppointmentSchedulerViewController, didConfirmAppointmentDate date: NSDate) {
        ApiService.sharedService().createWorkOrder(["company_id": "", "customer_id": "", "scheduled_start_at": "\(date)", "status": "scheduled"],
            onSuccess: { (statusCode, responseString) -> () in
                print("confirmed appointment date \(date)")
            }, onError: { (error, statusCode, responseString) -> () in
                
            }
        )
    }
}
