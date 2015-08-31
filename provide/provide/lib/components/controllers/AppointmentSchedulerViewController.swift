//
//  AppointmentSchedulerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/5/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

@objc
protocol AppointmentSchedulerViewControllerDelegate {
    func appointmentSchedulerViewController(viewController: AppointmentSchedulerViewController, didSelectDesiredDate date: NSDate)
    func appointmentSchedulerViewController(viewController: AppointmentSchedulerViewController, didConfirmAppointmentDate date: NSDate)
    func appointmentSchedulerViewController(viewController: AppointmentSchedulerViewController, offeredAppointmentDateWithAvailableDates availableDates: [NSDate]) -> NSDate
    func appointmentSchedulerViewController(viewController: AppointmentSchedulerViewController, confimationTextForTextView textView: UITextView, offeredDate: NSDate) -> String
    func appointmentSchedulerViewController(viewController: AppointmentSchedulerViewController, confimationTextForTextView textView: UITextView, confirmedDate: NSDate) -> String

    optional func minimumDateForAppointmentSchedulerViewController(viewController: AppointmentSchedulerViewController) -> NSDate
    optional func maximumDateForAppointmentSchedulerViewController(viewController: AppointmentSchedulerViewController) -> NSDate
}

class AppointmentSchedulerViewController: ViewController, PDTSimpleCalendarViewDelegate {

    var availableAppointmentDates: [NSDate]! {
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

    private var offeredAppointmentDate: NSDate!

    private var calendarViewController: PDTSimpleCalendarViewController!

    @IBOutlet private var containerView: UIView!
    @IBOutlet private var confirmationView: UIView!
    @IBOutlet private var confirmationTextView: UITextView!
    @IBOutlet private var confirmationButton: RoundedButton!
    @IBOutlet private var declineButton: RoundedButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clearColor()
        view.alpha = 1

        confirmationView.alpha = 0

        confirmationButton.initialBackgroundColor = Color.confirmationGreenBackground()
        declineButton.initialBackgroundColor = Color.warningBackground()

        if let dates = availableAppointmentDates {
            availableAppointmentDates = dates // HACK
        }
    }

    private func offerAppointmentDate() {
        offeredAppointmentDate = delegate?.appointmentSchedulerViewController(self, offeredAppointmentDateWithAvailableDates: availableAppointmentDates)
        confirmationTextView.text = delegate?.appointmentSchedulerViewController(self, confimationTextForTextView: confirmationTextView, offeredDate: offeredAppointmentDate)
    }

    @IBAction private func appointmentTimeConfirmed(sender: RoundedButton!) {
        delegate?.appointmentSchedulerViewController(self, didConfirmAppointmentDate: offeredAppointmentDate)

        // HACK-- temporary
        confirmationTextView.text = delegate?.appointmentSchedulerViewController(self, confimationTextForTextView: confirmationTextView, confirmedDate: offeredAppointmentDate)
        confirmationButton.alpha = 0
        declineButton.alpha = 0
    }

    @IBAction private func appointmentTimeDeclined(sender: RoundedButton!) {
        availableAppointmentDates.removeObject(offeredAppointmentDate)
        if availableAppointmentDates.count > 0 {
            offerAppointmentDate()
        } else {
            availableAppointmentDates = []
        }
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "CalendarViewControllerEmbedSegue":
            calendarViewController = segue.destinationViewController as! PDTSimpleCalendarViewController
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

    func simpleCalendarViewController(controller: PDTSimpleCalendarViewController!, didSelectDate date: NSDate!) {
        delegate?.appointmentSchedulerViewController(self, didSelectDesiredDate: date)
    }

//    - (BOOL)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller isEnabledDate:(NSDate *)date;
//    - (BOOL)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller shouldUseCustomColorsForDate:(NSDate *)date;
//    - (UIColor *)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller circleColorForDate:(NSDate *)date;
//    - (UIColor *)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller textColorForDate:(NSDate *)date;

}
