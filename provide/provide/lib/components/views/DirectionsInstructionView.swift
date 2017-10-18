//
//  DirectionsInstructionView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
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
            backgroundView?.frame.size.width = frame.width
            backgroundView?.addDropShadow(CGSize(width: 1.0, height: 1.0), radius: 2.5, opacity: 0.9)
        }
    }

    var routeLeg: RouteLeg! {
        didSet {
            if let routeLeg = routeLeg {
                remainingDistanceLabel.text = routeLeg.distanceString

                remainingTimeLabel.text = routeLeg.durationString

                if let time = Date().addingTimeInterval(routeLeg.duration).timeString {
                    etaLabel.text = "\(time) arrival"
                }

                if let icon = routeLeg.currentManeuver?.maneuverIcon {
                    self.icon.image = icon
                } else {
                    icon.image = nil
                }

                if let distance = routeLeg.currentManeuver?.remainingDistanceString {
                    stepDistanceLabel.text = distance
                }

                if let instruction = routeLeg.currentManeuver?.instruction {
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
