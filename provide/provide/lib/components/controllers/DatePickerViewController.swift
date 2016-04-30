//
//  DatePickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 4/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol DatePickerViewControllerDelegate {
    func datePickerViewController(viewController: DatePickerViewController, didSetDate date: NSDate)
}

class DatePickerViewController: UIViewController {

    private let defaultMinimumDate = NSDate()

    var delegate: DatePickerViewControllerDelegate!

    var initialDate: NSDate!
    var fieldName: String!

    @IBOutlet private weak var datePicker: UIDatePicker!
    @IBOutlet private weak var saveButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        datePicker?.minimumDate = defaultMinimumDate
        if let initialDate = initialDate {
            datePicker?.timeZone = NSTimeZone.localTimeZone()
            datePicker?.setDate(initialDate, animated: false)
        }

        saveButton?.addTarget(self, action: #selector(DatePickerViewController.save), forControlEvents: .TouchUpInside)
    }

    @IBAction func datePickerChanged(datePicker: UIDatePicker) {
        // no-op
    }

    func save(sender: UIButton) {
        if let date = datePicker?.date {
            delegate?.datePickerViewController(self, didSetDate: date)
        }
    }
}