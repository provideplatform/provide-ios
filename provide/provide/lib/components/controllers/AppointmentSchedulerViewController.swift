//
//  AppointmentSchedulerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/5/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import PDTSimpleCalendar
import KTSwiftExtensions

@objc
protocol AppointmentSchedulerViewControllerDelegate {
    func appointmentSchedulerViewController(_ viewController: AppointmentSchedulerViewController, didSelectDesiredDate date: Date)
    func appointmentSchedulerViewController(_ viewController: AppointmentSchedulerViewController, didConfirmAppointmentDate date: Date)
    func appointmentSchedulerViewController(_ viewController: AppointmentSchedulerViewController, offeredAppointmentDateWithAvailableDates availableDates: [Date]) -> Date
    func appointmentSchedulerViewController(_ viewController: AppointmentSchedulerViewController, confimationTextForTextView textView: UITextView, offeredDate: Date) -> String
    func appointmentSchedulerViewController(_ viewController: AppointmentSchedulerViewController, confimationTextForTextView textView: UITextView, confirmedDate: Date) -> String

    @objc optional func minimumDateForAppointmentSchedulerViewController(_ viewController: AppointmentSchedulerViewController) -> Date
    @objc optional func maximumDateForAppointmentSchedulerViewController(_ viewController: AppointmentSchedulerViewController) -> Date
}

class AppointmentSchedulerViewController: ViewController, PDTSimpleCalendarViewDelegate {

    var availableAppointmentDates: [Date]! {
        didSet {
            let rendered = containerView != nil && confirmationTextView != nil
            if rendered == true {
                if availableAppointmentDates.count > 0 {
                    containerView.alpha = 0
                    confirmationView.alpha = 1

                    offerAppointmentDate()
                } else {
                    confirmationView.alpha = 0
                    containerView.alpha = 1
                }
            }
        }
    }

    var delegate: AppointmentSchedulerViewControllerDelegate!

    fileprivate var offeredAppointmentDate: Date!

    fileprivate var calendarViewController: CalendarViewController!

    @IBOutlet fileprivate var containerView: UIView!
    @IBOutlet fileprivate var confirmationView: UIView!
    @IBOutlet fileprivate var confirmationTextView: UITextView!
    @IBOutlet fileprivate var confirmationButton: RoundedButton!
    @IBOutlet fileprivate var declineButton: RoundedButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear
        view.alpha = 1

        confirmationView.alpha = 0

        confirmationButton.initialBackgroundColor = Color.confirmationGreenBackground()
        declineButton.initialBackgroundColor = Color.warningBackground()

        if let dates = availableAppointmentDates {
            availableAppointmentDates = dates // HACK
        }
    }

    fileprivate func offerAppointmentDate() {
        offeredAppointmentDate = delegate?.appointmentSchedulerViewController(self, offeredAppointmentDateWithAvailableDates: availableAppointmentDates)
        confirmationTextView.text = delegate?.appointmentSchedulerViewController(self, confimationTextForTextView: confirmationTextView, offeredDate: offeredAppointmentDate)
    }

    @IBAction fileprivate func appointmentTimeConfirmed(_ sender: RoundedButton!) {
        delegate?.appointmentSchedulerViewController(self, didConfirmAppointmentDate: offeredAppointmentDate)

        // HACK-- temporary
        confirmationTextView.text = delegate?.appointmentSchedulerViewController(self, confimationTextForTextView: confirmationTextView, confirmedDate: offeredAppointmentDate)
        confirmationButton.alpha = 0
        declineButton.alpha = 0
    }

    @IBAction fileprivate func appointmentTimeDeclined(_ sender: RoundedButton!) {
        availableAppointmentDates.removeObject(offeredAppointmentDate)
        if availableAppointmentDates.count > 0 {
            offerAppointmentDate()
        } else {
            availableAppointmentDates = []
        }
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "CalendarViewControllerEmbedSegue":
            calendarViewController = segue.destination as! CalendarViewController
            calendarViewController.delegate = self

            if let minimumDate = delegate?.minimumDateForAppointmentSchedulerViewController?(self) {
                calendarViewController.firstDate = minimumDate
            }

            if let maximumDate = delegate?.maximumDateForAppointmentSchedulerViewController?(self) {
                calendarViewController.lastDate = maximumDate
            }
            break
        default:
            break
        }
    }

    // MARK: PDTSimpleCalendarViewDelegate

    func simpleCalendarViewController(_ controller: PDTSimpleCalendarViewController!, didSelect date: Date!) {
        delegate?.appointmentSchedulerViewController(self, didSelectDesiredDate: date)
    }
}
