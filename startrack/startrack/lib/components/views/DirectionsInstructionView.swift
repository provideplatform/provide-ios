//
//  DirectionsInstructionView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class DirectionsInstructionView: UIView {

    @IBOutlet private weak var backgroundView: UIView!

    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var etaLabel: UILabel!
    @IBOutlet private weak var instructionLabel: UILabel!
    @IBOutlet private weak var stepDistanceLabel: UILabel!
    @IBOutlet private weak var remainingDistanceLabel: UILabel!
    @IBOutlet private weak var remainingTimeLabel: UILabel!

    override var frame: CGRect {
        didSet {
            if backgroundView != nil {
                backgroundView.frame.size.width = frame.width
                backgroundView.addDropShadow(CGSizeMake(1.0, 1.0), radius: 2.5, opacity: 0.9)
            }
        }
    }

    var routeLeg: RouteLeg! {
        didSet {
            if routeLeg != nil {
                remainingDistanceLabel.text = routeLeg.distanceString

                remainingTimeLabel.text = routeLeg.durationString

                if let time = NSDate().dateByAddingTimeInterval(routeLeg.duration as NSTimeInterval).timeString {
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
                    instructionLabel.text = instruction
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