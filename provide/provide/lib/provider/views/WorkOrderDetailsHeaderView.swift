//
//  WorkOrderDetailsHeaderView.swift
//  provide
//
//  Created by Kyle Thomas on 7/31/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderDetailsHeaderView: UIView, MKMapViewDelegate {

    @IBOutlet private weak var mapView: WorkOrderMapView!
    @IBOutlet private weak var gradientView: UIView!
    @IBOutlet private weak var customerLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!

    var workOrder: WorkOrder! {
        didSet {
            if let superview = superview {
                frame.size.width = superview.bounds.width
            }

            gradientView.backgroundColor = UIColor.blackColor()
            gradientView.alpha = 0.7
            bringSubviewToFront(gradientView)

            customerLabel.text = workOrder.customer.displayName
            customerLabel.sizeToFit()
            bringSubviewToFront(customerLabel)
            
            addressLabel.text = workOrder.customer.contact.address
            addressLabel.sizeToFit()
            bringSubviewToFront(addressLabel)

            mapView.setCenterCoordinate(workOrder.coordinate, zoomLevel: 12, animated: false)
            mapView.addAnnotation(workOrder)

            dispatch_after_delay(0.0) {
                var coordinate = self.workOrder.coordinate
                coordinate.latitude += self.mapView.region.span.latitudeDelta * 0.1
                coordinate.longitude += self.mapView.region.span.longitudeDelta * 0.4

                self.mapView.setCenterCoordinate(coordinate, zoomLevel: 12, animated: false)
            }
        }
    }
}
