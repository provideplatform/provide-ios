//
//  WorkOrderProductPickerCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 1/5/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderProductPickerCollectionViewCell: JobProductPickerCollectionViewCell {

    var workOrderProduct: WorkOrderProduct! {
        didSet {
            if let workOrderProduct = workOrderProduct {
                jobProduct = workOrderProduct.jobProduct

                if let product = jobProduct.product {
                    var quantityString = NSString(format: "%.03f", workOrderProduct.quantity) as String
                    if let unitOfMeasure = product.unitOfMeasure {
                        quantityString = "\(quantityString) \(unitOfMeasure)"
                    }

                    quantityLabel?.text = "\(quantityString) budgeted"
                    quantityLabel?.sizeToFit()
                } else {
                    quantityLabel?.text = ""
                }
            }
        }
    }
}
