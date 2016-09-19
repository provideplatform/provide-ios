//
//  DirectionsInstructionView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class DirectionsInstructionView: UIView {

    @IBOutlet fileprivate weak var backgroundView: UIView!

    @IBOutlet fileprivate weak var icon: UIImageView!
    @IBOutlet fileprivate weak var etaLabel: UILabel!
    @IBOutlet fileprivate weak var instructionLabel: UILabel!
    @IBOutlet fileprivate weak var stepDistanceLabel: UILabel!
    @IBOutlet fileprivate weak var remainingDistanceLabel: UILabel!
    @IBOutlet fileprivate weak var remainingTimeLabel: UILabel!

    override var frame: CGRect {
        didSet {
            if backgroundView != nil {
                backgroundView.frame.size.width = frame.width
                backgroundView.addDropShadow(CGSize(width: 1.0, height: 1.0), radius: 2.5, opacity: 0.9)
            }
        }
    }

    var routeLeg: RouteLeg! {
        didSet {
            if routeLeg != nil {
                remainingDistanceLabel.text = routeLeg.distanceString

                remainingTimeLabel.text = routeLeg.durationString

                if let time = Date().addingTimeInterval(routeLeg.duration as TimeInterval).timeString {
                    etaLabel.text = "\(time) arrival"
                }

                if let icon = routeLeg.currentStep?.maneuverIcon {
                    self.icon.image = icon
                } else {
                    icon.image = nil
                }

                if let distance = routeLeg.currentStep?.remainingDistanceString {
                    stepDistanceLabel.text = distance
                }

                if let instruction = routeLeg.nextStep?.instruction {
                    instructionLabel.text = instruction.stringByStrippingHTML()
                }
            } else {
                icon.image = nil
                stepDistanceLabel.text = ""
                etaLabel.text = ""
                instructionLabel.text = ""
                remainingDistanceLabel.text = ""
                remainingTimeLabel.text = ""
            }
        }
    }
}
