//
//  DatePickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 4/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol DatePickerViewControllerDelegate {
    func datePickerViewController(_ viewController: DatePickerViewController, didSetDate date: Date)
    func datePickerViewController(_ viewController: DatePickerViewController, requiresDateAfter refDate: Date) -> Bool
}

class DatePickerViewController: UIViewController {

    fileprivate let defaultMinimumDate = Date()

    var delegate: DatePickerViewControllerDelegate!

    var initialDate: Date!
    var fieldName: String!

    @IBOutlet fileprivate weak var datePicker: UIDatePicker!
    @IBOutlet fileprivate weak var saveButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        datePicker?.minimumDate = defaultMinimumDate
        if let initialDate = initialDate {
            datePicker?.timeZone = TimeZone.autoupdatingCurrent
            datePicker?.setDate(initialDate, animated: false)
        }

        saveButton?.addTarget(self, action: #selector(DatePickerViewController.save), for: .touchUpInside)
    }

    @IBAction func datePickerChanged(_ datePicker: UIDatePicker) {
        var validDate = true
        if let requiresLaterDate = delegate?.datePickerViewController(self, requiresDateAfter: datePicker.date) {
            validDate = !requiresLaterDate
        }

        saveButton?.isEnabled = validDate
    }

    func save(_ sender: UIButton) {
        if let date = datePicker?.date {
            delegate?.datePickerViewController(self, didSetDate: date)
        }
    }

    func tick(_ animated: Bool = true) {
        let fiveMinutes = 5.0 * 60.0
        datePicker?.setDate(datePicker.date.addingTimeInterval(fiveMinutes), animated: animated)
    }
}
