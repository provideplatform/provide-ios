//
//  WorkOrderDestinationHeaderViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

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
        return WorkOrderService.sharedService().nextWorkOrder
    }

    var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate!

    private let rendered = false

    @IBOutlet private weak var titleImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.933, green: 0.937, blue: 0.945, alpha: 1.00)
    }

    func render() {
        view.removeFromSuperview()
        view.alpha = 0

        targetView.addSubview(view)
        targetView.bringSubviewToFront(view)

        if workOrder != nil {
            if workOrder.customer.profileImageUrl != nil {
                // TODO -- load the image view using the profileImageUrl
            } else if workOrder.customer.contact.email != nil {
                let gravatarImageView = UIImageView(frame: titleImageView.frame)
//                gravatarImageView.email = workOrder.contact.email
//                gravatarImageView.load { error in
//                    gravatarImageView.makeCircular()
//                    self.view.insertSubview(gravatarImageView, aboveSubview: self.titleImageView)
//                    self.titleImageView.alpha = 0
//                    gravatarImageView.alpha = 1
//                }
            }

            titleLabel.text = workOrder.customer.displayName
            addressTextView.text = workOrder.customer.contact.address
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

        view.addDropShadow(CGSizeMake(1.0, 1.25), radius: 2.0, opacity: 0.3)

        UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseIn,
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
        UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseIn,
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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "WorkOrderDestinationHeaderViewControllerUnwindSegue":
            assert(segue.sourceViewController is WorkOrderDestinationHeaderViewController)
            assert(segue.destinationViewController is WorkOrdersViewController)
            unwind()
        default:
            break
        }
    }
}
