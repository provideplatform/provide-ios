//
//  CastingDemandTableViewCell.swift
//  startrack
//
//  Created by Kyle Thomas on 9/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CastingDemandTableViewCell: UITableViewCell {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var attributesLabel: UILabel!
    @IBOutlet private weak var quantityLabel: UILabel!
    @IBOutlet private weak var rateLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var scheduledStartAtLabel: UILabel!

    var castingDemand: CastingDemand! {
        didSet {
            contentView.backgroundColor = UIColor.clearColor()

            nameLabel?.text = castingDemand.actingRole.name

            attributesLabel?.text = ""
            quantityLabel?.text = "Quantity: \(castingDemand.quantityRemaining)"
            rateLabel?.text = "Rate: $\(castingDemand.rate) / \(castingDemand.estimatedDuration)"
            locationLabel?.text = "@ \(castingDemand.shooting.location.name)"
            scheduledStartAtLabel?.text = castingDemand.scheduledStartAtDate.timeString
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        contentView.backgroundColor = UIColor.clearColor()

        nameLabel?.text = ""
        attributesLabel?.text = ""
        quantityLabel?.text = ""
        rateLabel?.text = ""
        locationLabel?.text = ""
        scheduledStartAtLabel?.text = ""
    }
}
