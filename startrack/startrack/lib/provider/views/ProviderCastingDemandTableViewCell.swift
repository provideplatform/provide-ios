//
//  CastingDemandTableViewCell.swift
//  startrack
//
//  Created by Kyle Thomas on 9/18/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ProviderCastingDemandTableViewCell: UITableViewCell {

    @IBOutlet private weak var avatarImageView: UIImageView!

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var attributesLabel: UILabel!
    @IBOutlet private weak var roleLabel: UILabel!
    @IBOutlet private weak var rateLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var scheduledStartAtLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!

    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!

    var workOrder: WorkOrder! {
        didSet {
            addBorder(1.0, color: UIColor.lightGrayColor())
            roundCorners(4.0)

            contentView.backgroundColor = UIColor.clearColor()

            castingDemand = workOrder.castingDemand
        }
    }

    var castingDemand: CastingDemand! {
        didSet {
            nameLabel?.text = castingDemand.actingRole.productionName

            attributesLabel?.text = ""
            roleLabel?.text = castingDemand.actingRole.name
            rateLabel?.text = "Rate: $\(castingDemand.rate) / \(castingDemand.estimatedDuration)"
            locationLabel?.text = "@ \(castingDemand.shooting.location.name)"
            scheduledStartAtLabel?.text = "\(castingDemand.scheduledStartAtDate.dateString) @ \(castingDemand.scheduledStartAtDate.timeString!)"
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        prepareForReuse()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        contentView.backgroundColor = UIColor.clearColor()

        nameLabel?.text = ""
        attributesLabel?.text = ""
        roleLabel?.text = ""
        rateLabel?.text = ""
        locationLabel?.text = ""
        scheduledStartAtLabel?.text = ""
        statusLabel?.text = ""

        confirmButton.alpha = 0.0
        cancelButton.alpha = 0.0

        confirmButton.enabled = false
        cancelButton.enabled = false
    }
}
