//
//  DurationPickerView.swift
//  provide
//
//  Created by Kyle Thomas on 12/27/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol DurationPickerViewDelegate {
    func durationPickerView(view: DurationPickerView, didPickDuration duration: CGFloat)
    optional func componentsForDurationPickerView(view: DurationPickerView) -> [CGFloat]
    optional func componentTitlesForDurationPickerView(view: DurationPickerView) -> [String]
    optional func durationPickerView(view: DurationPickerView, widthForComponent component: Int) -> CGFloat
    optional func durationPickerView(view: DurationPickerView, heightForComponent component: Int) -> CGFloat
}

class DurationPickerView: UIPickerView,
                          UIPickerViewDelegate,
                          UIPickerViewDataSource {

    var durationPickerViewDelegate: DurationPickerViewDelegate! {
        didSet {
            if let _ = durationPickerViewDelegate {
                reloadAllComponents()
            }
        }
    }

    private var values = [CGFloat]()
    private var valueTitles = [String]()

    private var valuesCount: Int {
        var values: [CGFloat]!
        if let vals = durationPickerViewDelegate?.componentsForDurationPickerView?(self) {
            values = vals
        } else {
            values = self.values
        }
        return values.count
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        delegate = self
        dataSource = self

        initDefaultDurationValues()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        delegate = self
        dataSource = self

        initDefaultDurationValues()
    }

    private func initDefaultDurationValues() {
        var value: CGFloat = 15.0
        while value <= 600.0 {
            values.append(value)
            valueTitles.append(NSString(format: "%.02f hours", value / 60.0) as String)
            value += 15.0
        }

        reloadAllComponents()
    }

    func selectRowWithValue(value: CGFloat, animated: Bool = false) {
        if let index = values.indexOf(value) {
            selectRow(index, inComponent: 0, animated: animated)
        }
    }

    // MARK: UIPickerViewDataSource
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return valuesCount
    }

    // MARK: UIPickerViewDelegate

    // returns width of column and height of row for each component.
    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if let width = durationPickerViewDelegate?.durationPickerView?(self, widthForComponent: component) {
            return width
        } else if let superview = superview {
            return superview.frame.width
        }
        return 20.0
    }

    //    optional public func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat

    //    // these methods return either a plain NSString, a NSAttributedString, or a view (e.g UILabel) to display the row for the component.
    //    // for the view versions, we cache any hidden and thus unused views and pass them back for reuse.
    //    // If you return back a different object, the old one will be released. the view will be centered in the row rect

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var title: String?
        var componentTitles: [String]!
        if let titles = durationPickerViewDelegate?.componentTitlesForDurationPickerView?(self) {
            componentTitles = titles
        } else {
            componentTitles = self.valueTitles
        }
        if row <= componentTitles.count - 1 {
            title = componentTitles[row]
        }
        return title
    }

    //    optional public func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? // attributed title is favored if both methods are implemented
    //    optional public func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var values: [CGFloat]!
        if let v = durationPickerViewDelegate.componentsForDurationPickerView?(self) {
            values = v
        } else {
            values = self.values
        }
        if row <= values.count - 1 {
            let duration = values[row]
            durationPickerViewDelegate.durationPickerView(self, didPickDuration: duration)
        }
    }
}
