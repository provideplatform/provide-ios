//
//  WorkOrderDestinationHeaderViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import KTSwiftExtensions

class WorkOrderDestinationHeaderViewController: ViewController {

    var initialFrame: CGRect {
        return CGRect(
            x: view.frame.origin.x,
            y: view.frame.height * -2,
            width: view.frame.width,
            height: view.frame.height
        )
    }

    var targetView: UIView! {
        return workOrdersViewControllerDelegate.targetViewForViewController?(self)
    }

    weak var workOrder: WorkOrder! {
        return WorkOrderService.sharedService().nextWorkOrder ?? WorkOrderService.sharedService().inProgressWorkOrder
    }

    var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate!

    fileprivate let rendered = false

    @IBOutlet fileprivate weak var titleImageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var addressTextView: UITextView!

    func render() {
        view.removeFromSuperview()
        view.alpha = 0

        targetView.addSubview(view)
        targetView.bringSubview(toFront: view)

        titleLabel.text = ""
        addressTextView.text = ""

        if workOrder != nil {
            if let customer = workOrder.customer {
                if customer.profileImageUrl != nil {
                    // TODO -- load the image view using the profileImageUrl
                } else if let _ = customer.contact.email {
                    logWarn("Not rendering gravatar image view for work order contact email")
                }
                
                titleLabel.text = customer.displayName
                addressTextView.text = customer.contact.address
            } else if let user = workOrder.user {
                if user.profileImageUrl != nil {
                    // TODO -- load the image view using the profileImageUrl
                } else if let _ = user.email {
                    logWarn("Not rendering gravatar image view for work order contact email")
                }
                
                titleLabel.text = user.name
                if let destination = workOrder.config?["destination"] as? [String: AnyObject] {
                    if let formattedAddress = destination["formatted_address"] as? String {
                        addressTextView.text = formattedAddress
                    } else if let desc = destination["description"] as? String {
                        addressTextView.text = desc
                    }
                }
            }
            
            addressTextView.sizeToFit()
        }

        //var frame = initialFrame
        var frame = CGRect(
            x: 0.0,
            y: targetView.frame.height,
            width: targetView.frame.width,
            height: view.frame.height
        )

        if let navigationController = workOrdersViewControllerDelegate.navigationControllerForViewController?(self) {
            frame = CGRect(
                x: frame.origin.x,
                y: navigationController.navigationBar.frame.height + navigationController.navigationBar.frame.origin.y,
                width: navigationController.navigationBar.frame.width,
                height: frame.height
            )
        }

        view.frame = frame

        view.addDropShadow(CGSize(width: 1.0, height: 1.25), radius: 2.0, opacity: 0.3)

        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseIn,
            animations: {
                self.view.alpha = 1
                self.view.frame = CGRect(
                    x: frame.origin.x,
                    y: frame.origin.y,
                    width: frame.width,
                    height: frame.height
                )
            },
            completion: nil
        )
    }

    func unwind() {
        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseIn,
            animations: {
                self.view.alpha = 0
                self.view.frame = self.initialFrame

            },
            completion: { complete in
                self.view.removeFromSuperview()
            }
        )
    }

    // MARK Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "WorkOrderDestinationHeaderViewControllerUnwindSegue":
            assert(segue.source is WorkOrderDestinationHeaderViewController)
            assert(segue.destination is WorkOrdersViewController)
            unwind()
        default:
            break
        }
    }
}
