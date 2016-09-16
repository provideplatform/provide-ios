//
//  WorkOrderProductTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 12/11/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderProductTableViewCell: JobProductTableViewCell {

    var workOrderProduct: WorkOrderProduct! {
        didSet {
            if let workOrderProduct = workOrderProduct {
                jobProduct = workOrderProduct.jobProduct
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

    }
}
