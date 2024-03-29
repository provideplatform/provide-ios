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
            backgroundView?.addDropShadow(radius: 2.5, opacity: 0.9)
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

                icon.image = routeLeg.currentManeuver?.maneuverIcon

                if let distance = routeLeg.currentManeuver?.remainingDistanceString {
                    stepDistanceLabel.text = distance
                }

                if let instruction = routeLeg.currentManeuver?.instruction {
                    instructionLabel.text = instruction.stringByStrippingHTML()
                }
            } else {
                icon.image = nil
                [stepDistanceLabel, etaLabel, instructionLabel, remainingDistanceLabel, remainingTimeLabel].forEach { $0.text = "" }
            }
        }
    }
}
