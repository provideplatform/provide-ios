//
//  DurationPickerView.swift
//  provide
//
//  Created by Kyle Thomas on 12/27/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

@objc
protocol DurationPickerViewDelegate {
    func durationPickerView(_ view: DurationPickerView, didPickDuration duration: CGFloat)
    @objc optional func durationPickerViewInteractionStarted(_ view: DurationPickerView)
    @objc optional func durationPickerViewInteractionContinued(_ view: DurationPickerView)
    @objc optional func durationPickerViewInteractionEnded(_ view: DurationPickerView)
    @objc optional func componentsForDurationPickerView(_ view: DurationPickerView) -> [CGFloat]
    @objc optional func componentTitlesForDurationPickerView(_ view: DurationPickerView) -> [String]
    @objc optional func durationPickerView(_ view: DurationPickerView, widthForComponent component: Int) -> CGFloat
    @objc optional func durationPickerView(_ view: DurationPickerView, heightForComponent component: Int) -> CGFloat
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

    fileprivate var values = [CGFloat]()
    fileprivate var valueTitles = [String]()

    fileprivate var selectedDuration: CGFloat!

    fileprivate var valuesCount: Int {
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

    fileprivate func initDefaultDurationValues() {
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
            let row = self.selectedRow(inComponent: 0)
            self.pickerView(self, didSelectRow: row, inComponent: 0)
        }
    }

    func selectRowWithValue(_ value: CGFloat, animated: Bool = false) {
        if let index = values.index(of: value) {
            selectRow(index, inComponent: 0, animated: animated)
        }
    }

    // MARK: UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return valuesCount
    }

    // MARK: UIPickerViewDelegate

    // returns width of column and height of row for each component.
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
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

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
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

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
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


    fileprivate class PickerViewGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {

        fileprivate weak var pickerView: DurationPickerView!

        fileprivate weak var durationPickerViewDelegate: DurationPickerViewDelegate! {
            if let pickerView = pickerView {
                return pickerView.durationPickerViewDelegate
            }
            return nil
        }

        fileprivate var lastInProgressInteractionTimestamp: Date! // nil when interactionInProgress == false

        fileprivate var interactionInProgress = false {
            didSet {
                if !interactionInProgress {
                    lastInProgressInteractionTimestamp = nil
                } else {
                    lastInProgressInteractionTimestamp = Date()
                }
            }
        }

        fileprivate var timeIntervalSinceLastInteraction: TimeInterval {
            if let lastInProgressInteractionTimestamp = lastInProgressInteractionTimestamp {
                return Date().timeIntervalSince(lastInProgressInteractionTimestamp)
            }
            return -1
        }

        fileprivate var interactionTimer: Timer!

        init(pickerView: DurationPickerView) {
            super.init(target: pickerView, action: Selector(("gestureRecognized:")))
            self.pickerView = pickerView
            delegate = self
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event!)
            interactionInProgress = true
            durationPickerViewDelegate?.durationPickerViewInteractionStarted?(pickerView)
            cancelInteractionTimer()
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesEnded(touches, with: event!)
            interactionInProgress = false
            durationPickerViewDelegate?.durationPickerViewInteractionEnded?(pickerView)
            initInteractionTimer()
        }

        override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
            super.touchesCancelled(touches!, with: event!)
            interactionInProgress = false
            durationPickerViewDelegate?.durationPickerViewInteractionEnded?(pickerView)
            cancelInteractionTimer()
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesMoved(touches, with: event!)
            interactionInProgress = true
            durationPickerViewDelegate?.durationPickerViewInteractionContinued?(pickerView)
            cancelInteractionTimer()
        }

        fileprivate func initInteractionTimer() {
            interactionTimer = Timer.scheduledTimer(timeInterval: 1.5, target: pickerView, selector: #selector(DurationPickerView.dispatchDidPickDurationDelegateCallback), userInfo: nil, repeats: false)
        }

        fileprivate func cancelInteractionTimer() {
            if let interactionTimer = interactionTimer {
                interactionTimer.invalidate()
                self.interactionTimer = nil
            }
        }
        
        deinit {
            cancelInteractionTimer()
        }

        // MARK: UIGestureRecognizerDelegate

        @objc func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        @objc func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            return true
        }
        
    }
}
