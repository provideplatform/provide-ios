//
//  WorkOrderDetailsHeaderView.swift
//  provide
//
//  Created by Kyle Thomas on 7/31/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

class WorkOrderDetailsHeaderView: UIView, MKMapViewDelegate {

    @IBOutlet fileprivate weak var mapView: WorkOrderMapView!
    @IBOutlet fileprivate weak var gradientView: UIView!
    @IBOutlet fileprivate weak var customerLabel: UILabel!
    @IBOutlet fileprivate weak var addressLabel: UILabel!

    var workOrder: WorkOrder! {
        didSet {
            if let superview = superview {
                frame.size.width = superview.bounds.width
            }

            gradientView.backgroundColor = UIColor.black
            gradientView.alpha = 0.7
            bringSubview(toFront: gradientView)

            customerLabel.text = workOrder.customer.displayName
            customerLabel.sizeToFit()
            bringSubview(toFront: customerLabel)
            
            addressLabel.text = workOrder.customer.contact.address
            addressLabel.sizeToFit()
            bringSubview(toFront: addressLabel)

            mapView.setCenterCoordinate(workOrder.coordinate, zoomLevel: 12, animated: false)
            mapView.addAnnotation(workOrder.annotation)

            dispatch_after_delay(0.0) {
                var coordinate = self.workOrder.coordinate
                coordinate.latitude += self.mapView.region.span.latitudeDelta * 0.1
                coordinate.longitude += self.mapView.region.span.longitudeDelta * 0.4

                self.mapView.setCenterCoordinate(coordinate, zoomLevel: 12, animated: false)
            }
        }
    }
}
