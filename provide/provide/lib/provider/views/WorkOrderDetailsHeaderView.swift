//
//  WorkOrderDetailsHeaderView.swift
//  provide
//
//  Created by Kyle Thomas on 7/31/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
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
                frame.size.width = superview.width
            }

            gradientView.backgroundColor = .black
            gradientView.alpha = 0.7
            bringSubview(toFront: gradientView)

            customerLabel.text = ""
            addressLabel.text = ""

            if let customer = workOrder.customer {
                customerLabel.text = customer.displayName
                addressLabel.text = customer.contact.address
            } else if let user = workOrder.user {
                customerLabel.text = user.name
                if let destination = workOrder.config?["destination"] as? [String: AnyObject], let desc = destination["description"] as? String {
                    addressLabel.text = desc
                }
            }

            customerLabel.sizeToFit()
            bringSubview(toFront: customerLabel)

            addressLabel.sizeToFit()
            bringSubview(toFront: addressLabel)

            mapView.setCenterCoordinate(workOrder.coordinate, zoomLevel: 12, animated: false)
            mapView.addAnnotation(workOrder.annotation)

            DispatchQueue.main.async {
                if var coordinate = self.workOrder.coordinate {
                    coordinate.latitude += self.mapView.region.span.latitudeDelta * 0.1
                    coordinate.longitude += self.mapView.region.span.longitudeDelta * 0.4

                    self.mapView.setCenterCoordinate(coordinate, zoomLevel: 12, animated: false)
                }
            }
        }
    }
}
