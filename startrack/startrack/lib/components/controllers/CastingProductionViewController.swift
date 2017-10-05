//
//  CastingProductionViewController.swift
//  provide
//
//  Created by Kyle Thomas on 9/11/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class CastingProductionViewController: ViewController, PDTSimpleCalendarViewDelegate, CastingDemandsViewControllerDelegate {

    var production: Production! {
        didSet {
            navigationItem.title = production?.name.uppercaseString

            production?.fetchUniqueShootingDates(
                { statusCode, mappingResult in
                    self.presentCalendarViewController()
                },
                onError: { error, statusCode, responseString in
                }
            )
        }
    }

    private var selectedDate: NSDate!

    private var minimumDateForCalendarViewController: NSDate! {
        if production?.shootingDates.count == 0 {
            return NSDate()
        }
        return production?.shootingDates.first?.date
    }

    private var maximumDateForCalendarViewController: NSDate! {
        if production?.shootingDates.count == 0 {
            return NSDate()
        }
        return production?.shootingDates.last?.date
    }

    private var calendarViewController: PDTSimpleCalendarViewController!

    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var confirmationView: UIView!
    @IBOutlet private var confirmationTextView: UITextView!
    @IBOutlet private var confirmationButton: RoundedButton!
    @IBOutlet private var declineButton: RoundedButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicatorView.startAnimating()

        //view.backgroundColor = UIColor.clearColor()
        view.alpha = 1

        confirmationView?.alpha = 0

        confirmationButton?.initialBackgroundColor = Color.confirmationGreenBackground()
        declineButton?.initialBackgroundColor = Color.warningBackground()
    }

    private func presentCalendarViewController() {
        PDTSimpleCalendarViewCell.appearance().circleSelectedColor = Color.darkBlueBackground()
        PDTSimpleCalendarViewCell.appearance().textDisabledColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)

        calendarViewController = UIStoryboard("CastingDirector").instantiateViewControllerWithIdentifier("PDTSimpleCalendarViewController") as! PDTSimpleCalendarViewController
        calendarViewController.delegate = self

        calendarViewController.weekdayHeaderEnabled = true

        if let minimumDate = minimumDateForCalendarViewController {
            calendarViewController.firstDate = minimumDate
        }

        if let maximumDate = maximumDateForCalendarViewController {
            calendarViewController.lastDate = maximumDate
        }

        calendarViewController.view.frame = containerView.frame
        containerView.addSubview(calendarViewController.view)

        activityIndicatorView.stopAnimating()
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
            case "CastingDemandsViewControllerSegue":
                (segue.destinationViewController as! CastingDemandsViewController).delegate = self
        default:
            break
        }
    }

    // MARK: PDTSimpleCalendarViewDelegate

    func simpleCalendarViewController(controller: PDTSimpleCalendarViewController!, didSelectDate date: NSDate!) {
        selectedDate = date

        performSegueWithIdentifier("CastingDemandsViewControllerSegue", sender: self)
    }

    func simpleCalendarViewController(controller: PDTSimpleCalendarViewController!, isEnabledDate date: NSDate!) -> Bool {
        if production.allShootingDates.indexOf(date) != nil {
            return date.timeIntervalSinceDate(NSDate().atMidnight) >= 0
        }
        return false
    }

//    - (BOOL)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller isEnabledDate:(NSDate *)date;
//    - (BOOL)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller shouldUseCustomColorsForDate:(NSDate *)date;
//    - (UIColor *)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller circleColorForDate:(NSDate *)date;
//    - (UIColor *)simpleCalendarViewController:(PDTSimpleCalendarViewController *)controller textColorForDate:(NSDate *)date;

    // MARK: CastingDemandsViewControllerDelegate

    func queryParamsForCastingDemandsViewController(viewController: CastingDemandsViewController) -> [String : AnyObject] {
        return [
            "production_id": String(production.id),
            "shooting_date": selectedDate.dateString,
            "unfilled": "true"
        ]
    }
}
