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
    optional func durationPickerViewInteractionStarted(view: DurationPickerView)
    optional func durationPickerViewInteractionContinued(view: DurationPickerView)
    optional func durationPickerViewInteractionEnded(view: DurationPickerView)
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

    private var selectedDuration: CGFloat!

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

        let gestureRecognizer = PickerViewGestureRecognizer(pickerView: self)
        addGestureRecognizer(gestureRecognizer)

        initDefaultDurationValues()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        delegate = self
        dataSource = self

        let gestureRecognizer = PickerViewGestureRecognizer(pickerView: self)
        addGestureRecognizer(gestureRecognizer)

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

    func dispatchDidPickDurationDelegateCallback() {
        if let selectedDuration = selectedDuration {
            durationPickerViewDelegate?.durationPickerView(self, didPickDuration: selectedDuration)
        }
    }

    override func reloadAllComponents() {
        super.reloadAllComponents()

        dispatch_after_delay(0.0) {
            let row = self.selectedRowInComponent(0)
            self.pickerView(self, didSelectRow: row, inComponent: 0)
        }
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
            selectedDuration = values[row]
        }
    }


    private class PickerViewGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {

        private weak var pickerView: DurationPickerView!

        private weak var durationPickerViewDelegate: DurationPickerViewDelegate! {
            if let pickerView = pickerView {
                return pickerView.durationPickerViewDelegate
            }
            return nil
        }

        private var lastInProgressInteractionTimestamp: NSDate! // nil when interactionInProgress == false

        private var interactionInProgress = false {
            didSet {
                if !interactionInProgress {
                    lastInProgressInteractionTimestamp = nil
                } else {
                    lastInProgressInteractionTimestamp = NSDate()
                }
            }
        }

        private var timeIntervalSinceLastInteraction: NSTimeInterval {
            if let lastInProgressInteractionTimestamp = lastInProgressInteractionTimestamp {
                return NSDate().timeIntervalSinceDate(lastInProgressInteractionTimestamp)
            }
            return -1
        }

        private var interactionTimer: NSTimer!

        init(pickerView: DurationPickerView) {
            super.init(target: pickerView, action: "gestureRecognized:")
            self.pickerView = pickerView
            delegate = self
        }

        override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
            super.touchesBegan(touches, withEvent: event!)
            interactionInProgress = true
            durationPickerViewDelegate?.durationPickerViewInteractionStarted?(pickerView)
            cancelInteractionTimer()
        }

        override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
            super.touchesEnded(touches, withEvent: event!)
            interactionInProgress = false
            durationPickerViewDelegate?.durationPickerViewInteractionEnded?(pickerView)
            initInteractionTimer()
        }

        override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
            super.touchesCancelled(touches!, withEvent: event!)
            interactionInProgress = false
            durationPickerViewDelegate?.durationPickerViewInteractionEnded?(pickerView)
            cancelInteractionTimer()
        }

        override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
            super.touchesMoved(touches, withEvent: event!)
            interactionInProgress = true
            durationPickerViewDelegate?.durationPickerViewInteractionContinued?(pickerView)
            cancelInteractionTimer()
        }

        private func initInteractionTimer() {
            interactionTimer = NSTimer.scheduledTimerWithTimeInterval(1.5, target: pickerView, selector: "dispatchDidPickDurationDelegateCallback", userInfo: nil, repeats: false)
        }

        private func cancelInteractionTimer() {
            if let interactionTimer = interactionTimer {
                interactionTimer.invalidate()
                self.interactionTimer = nil
            }
        }
        
        deinit {
            cancelInteractionTimer()
        }

        // MARK: UIGestureRecognizerDelegate

        @objc func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        @objc func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
            return true
        }
        
    }
}
