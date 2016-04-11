//
//  BlueprintWorkOrderTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 4/11/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class BlueprintWorkOrderTableViewCell: UITableViewCell {

    weak var annotation: Annotation! {
        didSet {
             pinView?.image = pinView?.image?.imageWithRenderingMode(.AlwaysTemplate)

            if let annotation = annotation {
                pinView.annotation = annotation
                pinView.alpha = 1.0

                if let workOrder = annotation.workOrder {
                    titleLabel.text = "\(workOrder.category.name)"
                } else {
                    prepareForReuse()
                }
            } else {
                prepareForReuse()
            }
        }
    }

    weak var workOrder: WorkOrder! {
        if let annotation = annotation {
            return annotation.workOrder
        }
        return nil
    }

    @IBOutlet private weak var pinView: BlueprintPinView!
    @IBOutlet private weak var titleLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()

        pinView.annotation = nil
        pinView.category = nil
        pinView.alpha = 0.0

        titleLabel.text = ""
    }
}
