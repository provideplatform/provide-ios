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
    @IBOutlet private weak var consumerLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!

    var workOrder: WorkOrder! {
        didSet {
            if let superview = superview {
                frame.size.width = superview.width
            }

            gradientView.backgroundColor = .black
            gradientView.alpha = 0.7
            bringSubview(toFront: gradientView)

            consumerLabel.text = ""
            addressLabel.text = ""

            if let user = workOrder.user {
                consumerLabel.text = user.name
                if let destination = workOrder.config?["destination"] as? [String: String], let desc = destination["description"] {
                    addressLabel.text = desc
                }
            }

            consumerLabel.sizeToFit()
            bringSubview(toFront: consumerLabel)

            addressLabel.sizeToFit()
            bringSubview(toFront: addressLabel)

            mapView.showsUserLocation = false
            mapView.setCenterCoordinate(workOrder.coordinate!, zoomLevel: 12, animated: false)
            mapView.addAnnotation(workOrder.annotationPin)

            DispatchQueue.main.async { [weak self] in
                if let strongSelf = self {
                    if var coordinate = strongSelf.workOrder.coordinate {
                        coordinate.latitude += strongSelf.mapView.region.span.latitudeDelta * 0.1
                        coordinate.longitude += strongSelf.mapView.region.span.longitudeDelta * 0.4

                        strongSelf.mapView.setCenterCoordinate(coordinate, zoomLevel: 12, animated: false)
                    }
                }
            }
        }
    }
}
