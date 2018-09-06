//
//  WorkOrderDetailsHeaderView.swift
//  provide
//
//  Created by Kyle Thomas on 7/31/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderDetailsHeaderView: UIView, MKMapViewDelegate {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var gradientView: UIView!
    @IBOutlet private weak var ymmtLabel: UILabel!
    @IBOutlet private weak var vinLabel: UILabel!

    var workOrder: WorkOrder! {
        didSet {
            if let superview = superview {
                frame.size.width = superview.width
            }

            gradientView.backgroundColor = .black
            gradientView.alpha = 0.7
            bringSubview(toFront: gradientView)

            ymmtLabel.text = ""
            vinLabel.text = ""

            if let vehicle = workOrder.getVehicle() {
                ymmtLabel.text = vehicle.description
                vinLabel.text = vehicle.vin

                if let vehicleImageUrl = vehicle.vehicleImageUrl {
                    imageView?.contentMode = .scaleAspectFill
                    imageView?.sd_setImage(with: URL(string: vehicleImageUrl)!)
                }
            }

            ymmtLabel.sizeToFit()
            bringSubview(toFront: ymmtLabel)
            vinLabel.sizeToFit()
            bringSubview(toFront: vinLabel)

//            mapView.showsUserLocation = false
//            mapView.setCenterCoordinate(workOrder.coordinate!, zoomLevel: 12, animated: false)
//            mapView.addAnnotation(workOrder.annotationPin)
//
//            DispatchQueue.main.async { [weak self] in
//                if let strongSelf = self {
//                    if var coordinate = strongSelf.workOrder.coordinate {
//                        coordinate.latitude += strongSelf.mapView.region.span.latitudeDelta * 0.1
//                        coordinate.longitude += strongSelf.mapView.region.span.longitudeDelta * 0.4
//
//                        strongSelf.mapView.setCenterCoordinate(coordinate, zoomLevel: 12, animated: false)
//                    }
//                }
//            }
        }
    }
}
