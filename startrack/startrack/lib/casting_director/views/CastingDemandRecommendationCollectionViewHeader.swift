//
//  CastingDemandRecommendationCollectionViewHeader.swift
//  startrack
//
//  Created by Kyle Thomas on 9/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CastingDemandRecommendationCollectionViewHeader: UICollectionReusableView {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var attributesLabel: UILabel!
    @IBOutlet private weak var quantityLabel: UILabel!
    @IBOutlet private weak var rateLabel: UILabel!

    var castingDemand: CastingDemand! {
        didSet {
            nameLabel?.text = castingDemand.actingRole.name

            attributesLabel?.text = ""
            quantityLabel?.text = "Quantity: \(castingDemand.quantityRemaining)"
            rateLabel?.text = "Budget: $\(castingDemand.rate) / \(castingDemand.estimatedDuration)"
        }
    }
}
