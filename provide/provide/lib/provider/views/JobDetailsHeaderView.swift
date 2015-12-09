//
//  JobDetailsHeaderView.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobDetailsHeaderView: UIView, MKMapViewDelegate {

    @IBOutlet private weak var mapView: WorkOrderMapView!
    @IBOutlet private weak var gradientView: UIView!
    @IBOutlet private weak var customerLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!

    var job: Job! {
        didSet {
            if let job = job {
                if let superview = superview {
                    frame.size.width = superview.bounds.width
                }

                gradientView.backgroundColor = UIColor.blackColor()
                gradientView.alpha = 0.7
                bringSubviewToFront(gradientView)

                customerLabel.text = job.customer.displayName
                customerLabel.sizeToFit()
                bringSubviewToFront(customerLabel)

                addressLabel.text = job.customer.contact.address
                addressLabel.sizeToFit()
                bringSubviewToFront(addressLabel)

                mapView.setCenterCoordinate(job.coordinate, zoomLevel: 12, animated: false)
                mapView.addAnnotation(job.annotation)

                dispatch_after_delay(0.0) {
                    var coordinate = self.job.coordinate
                    coordinate.latitude += self.mapView.region.span.latitudeDelta * 0.1
                    coordinate.longitude += self.mapView.region.span.longitudeDelta * 0.4
                    
                    self.mapView.setCenterCoordinate(coordinate, zoomLevel: 12, animated: false)
                }
            }
        }
    }
}
